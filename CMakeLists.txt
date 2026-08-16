# Copyright (c) 2021 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0
#
# This CMake file is picked by the Zephyr build system because it is defined
# as the module CMake entry point (see zephyr/module.yml).


# Register custom driver system calls with Zephyr's syscall generator.
zephyr_syscall_header(include/app/drivers/blink.h)

zephyr_include_directories(include)

add_subdirectory(drivers)
add_subdirectory(lib)
