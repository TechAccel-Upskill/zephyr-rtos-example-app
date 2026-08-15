/* SPDX-License-Identifier: Apache-2.0 */

#ifndef APP_RESOURCE_MONITOR_H_
#define APP_RESOURCE_MONITOR_H_

/**
 * @brief Start periodic CPU/stack resource reporting.
 *
 * No-op if CONFIG_APP_RESOURCE_MONITOR is disabled.
 */
void resource_monitor_start(void);

#endif /* APP_RESOURCE_MONITOR_H_ */
