/* SPDX-License-Identifier: Apache-2.0 */

#include <zephyr/ztest.h>

#include <app/safety_monitor.h>

static struct safety_monitor monitor;

static void setup(void *fixture)
{
	ARG_UNUSED(fixture);

	safety_monitor_init(&monitor, &(const struct safety_monitor_config){
		.warning_samples = 2,
		.emergency_samples = 4,
		.fault_samples = 3,
	});
}

ZTEST(safety_monitor, test_hazard_escalates_after_consecutive_samples)
{
	zassert_equal(safety_monitor_update(&monitor, true, true),
		      SAFETY_MONITOR_NORMAL, NULL);
	zassert_equal(safety_monitor_update(&monitor, true, true),
		      SAFETY_MONITOR_WARNING, NULL);
	zassert_equal(safety_monitor_update(&monitor, true, true),
		      SAFETY_MONITOR_WARNING, NULL);
	zassert_equal(safety_monitor_update(&monitor, true, true),
		      SAFETY_MONITOR_EMERGENCY, NULL);
}

ZTEST(safety_monitor, test_clear_returns_to_normal)
{
	safety_monitor_update(&monitor, true, true);
	safety_monitor_update(&monitor, true, true);
	zassert_equal(safety_monitor_update(&monitor, true, false),
		      SAFETY_MONITOR_NORMAL, NULL);
}

ZTEST(safety_monitor, test_invalid_samples_enter_fault)
{
	zassert_equal(safety_monitor_update(&monitor, false, false),
		      SAFETY_MONITOR_NORMAL, NULL);
	zassert_equal(safety_monitor_update(&monitor, false, false),
		      SAFETY_MONITOR_NORMAL, NULL);
	zassert_equal(safety_monitor_update(&monitor, false, false),
		      SAFETY_MONITOR_FAULT, NULL);
	zassert_equal(safety_monitor_update(&monitor, true, false),
		      SAFETY_MONITOR_NORMAL, NULL);
}

ZTEST_SUITE(safety_monitor, NULL, NULL, setup, NULL, NULL);