/* SPDX-License-Identifier: Apache-2.0 */

#include <app/safety_monitor.h>

static uint8_t at_least_one(uint8_t value)
{
	return value == 0U ? 1U : value;
}

void safety_monitor_init(struct safety_monitor *monitor,
			 const struct safety_monitor_config *config)
{
	monitor->config.warning_samples = at_least_one(config->warning_samples);
	monitor->config.emergency_samples = at_least_one(config->emergency_samples);
	monitor->config.fault_samples = at_least_one(config->fault_samples);
	monitor->state = SAFETY_MONITOR_NORMAL;
	monitor->consecutive_detections = 0U;
	monitor->consecutive_faults = 0U;
}

enum safety_monitor_state safety_monitor_update(struct safety_monitor *monitor,
						bool sample_valid,
						bool hazard_detected)
{
	if (!sample_valid) {
		monitor->consecutive_faults++;
		monitor->consecutive_detections = 0U;
		if (monitor->consecutive_faults >= monitor->config.fault_samples) {
			monitor->state = SAFETY_MONITOR_FAULT;
		}
		return monitor->state;
	}

	monitor->consecutive_faults = 0U;
	if (!hazard_detected) {
		monitor->consecutive_detections = 0U;
		monitor->state = SAFETY_MONITOR_NORMAL;
		return monitor->state;
	}

	if (monitor->consecutive_detections < UINT8_MAX) {
		monitor->consecutive_detections++;
	}
	if (monitor->consecutive_detections >= monitor->config.emergency_samples) {
		monitor->state = SAFETY_MONITOR_EMERGENCY;
	} else if (monitor->consecutive_detections >= monitor->config.warning_samples) {
		monitor->state = SAFETY_MONITOR_WARNING;
	}

	return monitor->state;
}