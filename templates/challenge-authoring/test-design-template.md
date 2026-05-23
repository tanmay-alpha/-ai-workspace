# Test Design Template

Use this checklist to design deterministic tests that verify behavior rather
than implementation details.

## Determinism

- [ ] Tests do not depend on timing-sensitive behavior.
- [ ] Tests do not depend on randomness.
- [ ] Tests do not require network access during runtime.
- [ ] Tests do not depend on machine-specific paths, users, locales, or state.
- [ ] Tests use stable fixtures or generated data with fixed values.
- [ ] Tests clean up any temporary files they create.

## Behavioral Coverage

- [ ] Assertions focus on observable behavior.
- [ ] Tests avoid checking private implementation details.
- [ ] Tests cover the primary expected behavior.
- [ ] Tests cover at least one relevant edge case.
- [ ] Tests fail before the solution is applied.
- [ ] Tests pass after the solution is applied.
- [ ] Existing tests still pass.

## Test Suite Shape

- [ ] The test suite is concise.
- [ ] The tests are easy to understand.
- [ ] The tests avoid duplicating repository internals.
- [ ] The tests do not introduce unnecessary dependencies.
- [ ] The tests follow existing repository conventions.
- [ ] JUnit XML output is produced if required by the evaluator.

## Notes

- Prefer behavior-focused assertions over snapshots when possible.
- Avoid tests that only verify a specific function call sequence.
- Avoid tests that pass because they mirror the reference implementation.
