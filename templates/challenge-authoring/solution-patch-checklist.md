# Solution Patch Checklist

Use this checklist before accepting a reference solution patch.

## Patch Format

- [ ] The solution is a valid unified diff.
- [ ] The patch applies cleanly to the selected immutable commit.
- [ ] The patch does not conflict with the test patch.
- [ ] The patch includes only files required for the solution.
- [ ] The patch excludes generated files unless they are required.

## Implementation Quality

- [ ] Changes are minimal and scoped.
- [ ] Changes follow existing repository patterns.
- [ ] Changes avoid unrelated refactors.
- [ ] Changes avoid filler code.
- [ ] Changes avoid unnecessary dependencies.
- [ ] Changes preserve existing public behavior unless the challenge requires a
  behavior change.
- [ ] Changes are readable and maintainable.

## Validation

- [ ] Existing tests pass after the solution.
- [ ] New challenge tests pass after the solution.
- [ ] New challenge tests fail before the solution.
- [ ] The solution works in the Docker environment.
- [ ] The final diff contains no secrets or private data.
