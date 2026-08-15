/*
 * Copyright (c) 2021 Nordic Semiconductor ASA
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/logging/log.h>
#include <zephyr/shell/shell.h>
#include <zephyr/timing/timing.h>
#include <zephyr/pm/pm.h>

#include <app/drivers/blink.h>

#include <app_version.h>

LOG_MODULE_REGISTER(main, CONFIG_APP_LOG_LEVEL);

#define BLINK_PERIOD_MS_STEP 100U
#define BLINK_PERIOD_MS_MAX  1000U

/* Stack size and priority for the metrics reporting thread */
#define METRICS_STACK_SIZE 1024
#define METRICS_PRIORITY   7
#define METRICS_INTERVAL_MS 2000

K_THREAD_STACK_DEFINE(metrics_stack, METRICS_STACK_SIZE);
static struct k_thread metrics_thread_data;

/**
 * @brief Report per-thread CPU usage and basic system timing stats.
 *
 * This thread wakes every METRICS_INTERVAL_MS milliseconds and logs:
 *  - Each Zephyr thread's total execution cycles and CPU share.
 *  - A simple interrupt-latency estimate using the Zephyr timing API.
 *
 * The data is intended to be captured over UART and analysed offline
 * as part of the firmware optimisation demonstration.
 */
static void metrics_thread(void *p1, void *p2, void *p3)
{
	ARG_UNUSED(p1);
	ARG_UNUSED(p2);
	ARG_UNUSED(p3);

	while (1) {
#ifdef CONFIG_THREAD_RUNTIME_STATS
		struct k_thread_runtime_stats stats;
		struct k_thread_runtime_stats total_stats;
		int rc;

		rc = k_thread_runtime_stats_all_get(&total_stats);
		if (rc == 0) {
			LOG_INF("=== CPU Load Report ===");
			LOG_INF("Total execution cycles: %llu",
				(unsigned long long)total_stats.execution_cycles);
		}

		struct k_thread *t = _kernel.threads;

		while (t != NULL) {
			rc = k_thread_runtime_stats_get(t, &stats);
			if (rc == 0 && total_stats.execution_cycles > 0) {
				uint64_t pct = (stats.execution_cycles * 100ULL) /
					       total_stats.execution_cycles;
				LOG_INF("  Thread %p '%s': cycles=%llu cpu=%llu%%",
					(void *)t,
					k_thread_name_get(t),
					(unsigned long long)stats.execution_cycles,
					(unsigned long long)pct);
			}
			t = (struct k_thread *)t->next_thread;
		}
#endif /* CONFIG_THREAD_RUNTIME_STATS */

		k_sleep(K_MSEC(METRICS_INTERVAL_MS));
	}
}

/* Shell command: metrics — print a one-shot CPU report on demand */
static int cmd_metrics(const struct shell *sh, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

#ifdef CONFIG_THREAD_RUNTIME_STATS
	struct k_thread_runtime_stats total_stats;

	if (k_thread_runtime_stats_all_get(&total_stats) == 0) {
		shell_print(sh, "Total execution cycles: %llu",
			    (unsigned long long)total_stats.execution_cycles);
	} else {
		shell_error(sh, "Failed to read runtime stats");
	}
#else
	shell_warn(sh, "CONFIG_THREAD_RUNTIME_STATS not enabled");
#endif
	return 0;
}

SHELL_CMD_REGISTER(metrics, NULL, "Print CPU-load metrics", cmd_metrics);

int main(void)
{
	int ret;
	unsigned int period_ms = BLINK_PERIOD_MS_MAX;
	const struct device *sensor, *blink;
	struct sensor_value last_val = { 0 }, val;

	printk("Zephyr + TFA Firmware Optimisation Demo %s\n", APP_VERSION_STRING);

	sensor = DEVICE_DT_GET(DT_NODELABEL(example_sensor));
	if (!device_is_ready(sensor)) {
		LOG_ERR("Sensor not ready");
		return 0;
	}

	blink = DEVICE_DT_GET(DT_NODELABEL(blink_led));
	if (!device_is_ready(blink)) {
		LOG_ERR("Blink LED not ready");
		return 0;
	}

	ret = blink_off(blink);
	if (ret < 0) {
		LOG_ERR("Could not turn off LED (%d)", ret);
		return 0;
	}

	/* Start the background metrics reporting thread */
	k_thread_create(&metrics_thread_data, metrics_stack,
			K_THREAD_STACK_SIZEOF(metrics_stack),
			metrics_thread, NULL, NULL, NULL,
			METRICS_PRIORITY, 0, K_NO_WAIT);
	k_thread_name_set(&metrics_thread_data, "metrics");

	printk("Use the sensor to change LED blinking period\n");
	printk("Type 'metrics' in the shell for a CPU-load snapshot\n");

	while (1) {
		ret = sensor_sample_fetch(sensor);
		if (ret < 0) {
			LOG_ERR("Could not fetch sample (%d)", ret);
			return 0;
		}

		ret = sensor_channel_get(sensor, SENSOR_CHAN_PROX, &val);
		if (ret < 0) {
			LOG_ERR("Could not get sample (%d)", ret);
			return 0;
		}

		if ((last_val.val1 == 0) && (val.val1 == 1)) {
			if (period_ms == 0U) {
				period_ms = BLINK_PERIOD_MS_MAX;
			} else {
				period_ms -= BLINK_PERIOD_MS_STEP;
			}

			printk("Proximity detected, setting LED period to %u ms\n",
			       period_ms);
			blink_set_period_ms(blink, period_ms);
		}

		last_val = val;

		k_sleep(K_MSEC(100));
	}

	return 0;
}

