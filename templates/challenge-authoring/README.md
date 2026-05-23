# Coding Challenge Authoring

This folder helps create real-world, verifiable coding challenges from
open-source repositories.

The templates are intended for reusable, public-friendly challenge creation.
They are generic, platform-neutral, and designed to support tasks that can be
validated through deterministic tests.

## Lifecycle

Use the templates in this folder to move through the full authoring lifecycle:

1. Select a suitable public repository.
2. Pin an immutable commit hash.
3. Write a clear problem description.
4. Design deterministic tests.
5. Create a minimal reference solution.
6. Define a reproducible Docker environment.
7. Run final review before submission or publication.

## Authoring Principles

- Use real production-level codebases.
- Describe the desired behavior, not the implementation.
- Keep tests deterministic and behavior-focused.
- Avoid network access during test runtime.
- Keep solution changes minimal and scoped.
- Review all diffs for secrets, private details, and unrelated edits.

## Files

- `repository-selection-checklist.md`: repository and task suitability checks.
- `problem-description-template.md`: challenge statement template.
- `test-design-template.md`: deterministic test design checklist.
- `dockerfile-template.md`: reproducible environment template.
- `test-sh-template.md`: portable test runner template.
- `solution-patch-checklist.md`: reference solution patch review checklist.
- `submission-checklist.md`: final end-to-end validation checklist.
- `spec-planning-prompt.md`: planning prompt for turning an issue or feature idea
  into a verifiable challenge specification.
