# Submission Checklist

Use this final checklist before publishing, submitting, or archiving a challenge.

## Repository State

- [ ] A clean repository clone was used for final validation.
- [ ] The exact immutable commit is checked out.
- [ ] The commit hash is recorded in the challenge metadata or notes.
- [ ] No unrelated local changes are present.

## Test Patch Validation

- [ ] The test patch applies cleanly.
- [ ] Base tests pass before applying the solution.
- [ ] New tests fail before applying the solution.
- [ ] New tests fail for the expected behavior gap.

## Solution Patch Validation

- [ ] The solution patch applies cleanly.
- [ ] The solution patch does not conflict with the test patch.
- [ ] New tests pass after applying the solution.
- [ ] Existing tests still pass after applying the solution.
- [ ] The solution diff is minimal and reviewed.

## Docker Validation

- [ ] Docker build succeeds.
- [ ] Container test execution succeeds.
- [ ] Container tests work without network access.
- [ ] Dependencies are installed during build, not runtime.
- [ ] Runtime does not require host-specific files or credentials.

## Final Review

- [ ] No secrets are present.
- [ ] No private or internal context is present.
- [ ] Final diff has been reviewed.
- [ ] Markdown files render cleanly.
- [ ] Instructions are generic and platform-neutral.
