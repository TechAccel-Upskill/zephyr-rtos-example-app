/*
 * Copyright (c) 2021 Nordic Semiconductor ASA
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/logging/log.h>

#include <app/drivers/blink.h>
#include <app/safety_monitor.h>
#include <app/resource_monitor.h>

#include <zephyr/app_version.h>

LOG_MODULE_REGISTER(main, CONFIG_APP_LOG_LEVEL);

#define WARNING_BLINK_PERIOD_MS   500U
#define EMERGENCY_BLINK_PERIOD_MS 100U
#define FAULT_BLINK_PERIOD_MS     250U

static const char *state_name(enum safety_monitor_state state)
{
	switch (state) {
	case SAFETY_MONITOR_NORMAL:
		return "NORMAL";
	case SAFETY_MONITOR_WARNING:
		return "WARNING";
	case SAFETY_MONITOR_EMERGENCY:
		return "EMERGENCY";
	case SAFETY_MONITOR_FAULT:
		return "FAULT";
	default:
		return "UNKNOWN";
	}
}

static unsigned int state_blink_period(enum safety_monitor_state state)
{
	switch (state) {
	case SAFETY_MONITOR_WARNING:
		return WARNING_BLINK_PERIOD_MS;
	case SAFETY_MONITOR_EMERGENCY:
		return EMERGENCY_BLINK_PERIOD_MS;
	case SAFETY_MONITOR_FAULT:
		return FAULT_BLINK_PERIOD_MS;
	case SAFETY_MONITOR_NORMAL:
	default:
		return 0U;
	}
}

int main(void)
{
	int ret;
	const struct device *sensor, *blink;
	struct sensor_value val;
	struct safety_monitor monitor;
	enum safety_monitor_state previous_state;

	safety_monitor_init(&monitor, &(const struct safety_monitor_config){
		.warning_samples = CONFIG_APP_WARNING_SAMPLES,
		.emergency_samples = CONFIG_APP_EMERGENCY_SAMPLES,
		.fault_samples = CONFIG_APP_FAULT_SAMPLES,
	});
	previous_state = safety_monitor_state(&monitor);
	resource_monitor_start();

	printk("Zephyr Safety Monitor Node %s\n", APP_VERSION_STRING);

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

	printk("Safety monitor ready: warning=%u samples, emergency=%u samples\n",
	       CONFIG_APP_WARNING_SAMPLES, CONFIG_APP_EMERGENCY_SAMPLES);

	while (1) {
		int sample_ret = sensor_sample_fetch(sensor);

		if (sample_ret == 0) {
			sample_ret = sensor_channel_get(sensor, SENSOR_CHAN_PROX, &val);
		}

		enum safety_monitor_state state = safety_monitor_update(
			&monitor, sample_ret == 0, sample_ret == 0 && val.val1 != 0);

		if (sample_ret < 0) {
			LOG_ERR("Sensor sample failed (%d)", sample_ret);
		}

		if (state != previous_state) {
			int blink_ret;

			LOG_INF("Safety state: %s -> %s", state_name(previous_state),
				state_name(state));
			blink_ret = blink_set_period_ms(blink, state_blink_period(state));
			if (blink_ret < 0) {
				LOG_ERR("Could not update safety indicator (%d)", blink_ret);
			}
			previous_state = state;
		}

		k_sleep(K_MSEC(CONFIG_APP_SAMPLE_PERIOD_MS));
	}

	return 0;
}

