# Contributing

This repository is both a firmware project and an interview practice record.
Keep changes small enough to review and make the reasoning behind safety
behavior visible in tests and documentation.

## Local Checks

```sh
west twister -T app --integration
west twister -T tests --integration
```

For a fast policy-only check without a Zephyr workspace:

```sh
cc -std=c11 -Wall -Wextra -Werror -Iinclude \
  -fsyntax-only app/src/safety_monitor.c
```

Pull requests should include tests for new state transitions or driver error
paths and should explain any changes to timing, memory, or failure behavior.

## Commit Style

Use short imperative subjects, for example:

```text
drivers: propagate GPIO read errors
tests: cover emergency escalation
docs: explain sensor fault policy
```