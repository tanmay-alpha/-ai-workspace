# Repository Selection Checklist

Use this checklist before investing time in a coding challenge.

## Repository Suitability

- [ ] The repository is public.
- [ ] The repository has a clear open-source license.
- [ ] The license is permissive enough for challenge use.
- [ ] The codebase is active or recently maintained.
- [ ] The repository has recent commits.
- [ ] The selected task is based on an immutable commit hash.
- [ ] The exact commit hash is recorded.
- [ ] The codebase is production-level, not a toy example.
- [ ] The language and framework are suitable for the evaluator environment.
- [ ] Dependencies can be installed reproducibly.
- [ ] The project has an existing test or validation pattern.

## Task Suitability

- [ ] The task describes a realistic behavior change or bug fix.
- [ ] The fix is not already merged at the selected commit.
- [ ] The task can be verified with deterministic tests.
- [ ] The task does not require private services, credentials, or paid APIs.
- [ ] The task does not depend on machine-specific state.
- [ ] The task can be solved with a focused patch.
- [ ] The task is not artificial or purely contrived.
- [ ] The task is not a broad rewrite.
- [ ] The task does not require unrelated refactoring.

## Exclusion Checks

- [ ] The repository is not abandoned in a way that blocks setup or validation.
- [ ] The repository does not require unavailable infrastructure to run tests.
- [ ] The challenge does not depend on an already-merged upstream fix.
- [ ] The challenge does not expose private data, secrets, or internal context.
