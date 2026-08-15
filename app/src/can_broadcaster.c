/* SPDX-License-Identifier: Apache-2.0 */

#include <app/can_broadcaster.h>

#include <zephyr/drivers/can.h>

int can_broadcaster_send_state(const struct device *can_dev,
			       enum safety_monitor_state state)
{
	const struct can_frame frame = {
		.id = CAN_BROADCASTER_STATE_ID,
		.dlc = 1,
		.data = { (uint8_t)state },
	};

	return can_send(can_dev, &frame, K_MSEC(100), NULL, NULL);
}
