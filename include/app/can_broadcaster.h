/* SPDX-License-Identifier: Apache-2.0 */

#ifndef APP_CAN_BROADCASTER_H_
#define APP_CAN_BROADCASTER_H_

#include <zephyr/device.h>

#include <app/safety_monitor.h>

/** CAN identifier used to broadcast the current safety state. */
#define CAN_BROADCASTER_STATE_ID 0x100

/**
 * @brief Send the current safety state as a single-byte CAN data frame.
 *
 * @param can_dev CAN controller device instance.
 * @param state Safety state to broadcast.
 *
 * @retval 0 on success.
 * @retval -errno Negative errno code from can_send() on failure.
 */
int can_broadcaster_send_state(const struct device *can_dev,
			       enum safety_monitor_state state);

#endif /* APP_CAN_BROADCASTER_H_ */
