/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Verifies the CAN automotive-bus state broadcaster against a loopback
 * controller, i.e. an automotive driver integration test that runs as a
 * native Linux process (no physical CAN hardware required).
 */

#include <zephyr/ztest.h>
#include <zephyr/drivers/can.h>

#include <app/can_broadcaster.h>

static const struct device *can_dev;
static struct k_msgq state_msgq;
static char state_msgq_buf[4 * sizeof(struct can_frame)];

static void rx_callback(const struct device *dev, struct can_frame *frame, void *user_data)
{
	ARG_UNUSED(dev);
	ARG_UNUSED(user_data);

	(void)k_msgq_put(&state_msgq, frame, K_NO_WAIT);
}

static void *suite_setup(void)
{
	const struct can_filter filter = {
		.id = CAN_BROADCASTER_STATE_ID,
		.mask = CAN_STD_ID_MASK,
	};

	can_dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_canbus));
	zassert_true(device_is_ready(can_dev), "CAN loopback device not ready");

	k_msgq_init(&state_msgq, state_msgq_buf, sizeof(struct can_frame), 4);

	zassert_equal(can_start(can_dev), 0, "Could not start CAN controller");
	zassert_true(can_add_rx_filter(can_dev, rx_callback, NULL, &filter) >= 0,
		    "Could not add RX filter");

	return NULL;
}

ZTEST(can_broadcaster, test_send_state_is_received)
{
	struct can_frame received;

	zassert_ok(can_broadcaster_send_state(can_dev, SAFETY_MONITOR_EMERGENCY),
		  "Could not send state frame");

	zassert_ok(k_msgq_get(&state_msgq, &received, K_MSEC(100)),
		  "Did not receive looped-back frame");
	zassert_equal(received.id, CAN_BROADCASTER_STATE_ID, "Unexpected CAN ID");
	zassert_equal(received.data[0], SAFETY_MONITOR_EMERGENCY, "Unexpected payload");
}

ZTEST_SUITE(can_broadcaster, NULL, suite_setup, NULL, NULL, NULL);
