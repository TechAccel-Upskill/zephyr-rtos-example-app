/* SPDX-License-Identifier: Apache-2.0 */

#ifndef APP_SAFETY_MONITOR_H_
#define APP_SAFETY_MONITOR_H_

#include <stdbool.h>
#include <stdint.h>

enum safety_monitor_state {
	SAFETY_MONITOR_NORMAL,
	SAFETY_MONITOR_WARNING,
	SAFETY_MONITOR_EMERGENCY,
	SAFETY_MONITOR_FAULT,
};

struct safety_monitor_config {
	uint8_t warning_samples;
	uint8_t emergency_samples;
	uint8_t fault_samples;
};

struct safety_monitor {
	struct safety_monitor_config config;
	enum safety_monitor_state state;
	uint8_t consecutive_detections;
	uint8_t consecutive_faults;
};

void safety_monitor_init(struct safety_monitor *monitor,
			 const struct safety_monitor_config *config);

enum safety_monitor_state safety_monitor_update(struct safety_monitor *monitor,
						bool sample_valid,
						bool hazard_detected);

static inline enum safety_monitor_state
safety_monitor_state(const struct safety_monitor *monitor)
{
	return monitor->state;
}

#endif