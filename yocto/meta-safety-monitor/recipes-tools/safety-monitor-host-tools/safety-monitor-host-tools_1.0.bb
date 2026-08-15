SUMMARY = "Host-side diagnostics tooling for the Zephyr safety monitor node"
DESCRIPTION = "Installs the Python Twister-report parser used to diagnose the \
Zephyr safety monitor firmware from a Yocto-built Linux companion image, \
e.g. a Cortex-A host running alongside a Cortex-M/R Zephyr safety core."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

# Illustrative skeleton: not bitbake-verified in this sandbox. Adjust the
# search path below to wherever this layer is checked out relative to the
# firmware repository before building.
FILESEXTRAPATHS:prepend := "${TOPDIR}/../../scripts:"
SRC_URI = "file://parse_test_results.py"

S = "${WORKDIR}"

RDEPENDS:${PN} = "python3-core"

do_install() {
	install -d ${D}${bindir}
	install -m 0755 ${S}/parse_test_results.py ${D}${bindir}/safety-monitor-parse-results
}

FILES:${PN} = "${bindir}/safety-monitor-parse-results"
