/* SPDX-License-Identifier: Apache-2.0 */

#include <app/resource_monitor.h>

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/debug/thread_analyzer.h>

LOG_MODULE_REGISTER(resource_monitor, CONFIG_APP_LOG_LEVEL);

/*
 * IRQ-mask read: returns 1 if IRQs are currently masked, 0 otherwise. Each
 * Arm profile exposes this through a different register, so this is a real,
 * compilable example of the same bare-metal technique across Cortex-M,
 * Cortex-R and Cortex-A (verify these Kconfig symbols against your pinned
 * Zephyr revision; only the Cortex-M path is exercised by this app's boards).
 */
#if defined(CONFIG_CPU_CORTEX_M)
static inline uint32_t read_irq_mask(void)
{
	uint32_t primask;

	__asm__ volatile("mrs %0, primask" : "=r"(primask));
	return primask & 0x1U;
}
#elif defined(CONFIG_CPU_CORTEX_R)
/* AArch32 Cortex-R: CPSR bit 7 (I) masks IRQs. */
static inline uint32_t read_irq_mask(void)
{
	uint32_t cpsr;

	__asm__ volatile("mrs %0, cpsr" : "=r"(cpsr));
	return (cpsr >> 7) & 0x1U;
}
#elif defined(CONFIG_ARM64)
/* AArch64 Cortex-A: DAIF bit 7 (I) masks IRQs. */
static inline uint32_t read_irq_mask(void)
{
	uint64_t daif;

	__asm__ volatile("mrs %0, daif" : "=r"(daif));
	return (uint32_t)((daif >> 7) & 0x1U);
}
#else
static inline uint32_t read_irq_mask(void)
{
	return 0U;
}
#endif

static struct k_work_delayable report_work;

static void report_work_handler(struct k_work *work)
{
	ARG_UNUSED(work);

	/* cppcheck-suppress knownConditionTrueFalse ; depends on CONFIG_CPU_CORTEX_M */
	LOG_INF("Resource snapshot: irq_masked=%u", read_irq_mask() != 0U);
	thread_analyzer_print(0U);

	k_work_schedule(&report_work, K_MSEC(CONFIG_APP_RESOURCE_MONITOR_PERIOD_MS));
}

void resource_monitor_start(void)
{
	if (!IS_ENABLED(CONFIG_APP_RESOURCE_MONITOR)) {
		return;
	}

	k_work_init_delayable(&report_work, report_work_handler);
	k_work_schedule(&report_work, K_MSEC(CONFIG_APP_RESOURCE_MONITOR_PERIOD_MS));
}
