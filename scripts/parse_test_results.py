#!/usr/bin/env python3
"""Summarize a Zephyr Twister JSON report for Linux CI consumption.

Usage: parse_test_results.py <path-to-twister.json>

Exits non-zero if any test case did not pass, so it can gate CI on Linux
runners alongside `west twister`.
"""
import argparse
import json
import sys
from collections import Counter


def iter_testcases(report):
    for suite in report.get("testsuites", []):
        name = suite.get("name", "<unknown-suite>")
        cases = suite.get("testcases") or [{"status": suite.get("status")}]
        for case in cases:
            yield name, case.get("identifier", name), case.get("status", "unknown")


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", help="Path to twister.json")
    args = parser.parse_args(argv)

    with open(args.report, encoding="utf-8") as handle:
        report = json.load(handle)

    counts = Counter()
    failures = []
    for suite_name, case_id, status in iter_testcases(report):
        counts[status] += 1
        if status not in ("passed", "skipped"):
            failures.append(f"{suite_name}::{case_id} -> {status}")

    total = sum(counts.values())
    print(f"Total test cases: {total}")
    for status, count in sorted(counts.items()):
        print(f"  {status}: {count}")

    if failures:
        print("\nFailures:")
        for failure in failures:
            print(f"  {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
