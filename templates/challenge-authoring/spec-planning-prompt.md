# Spec Planning Prompt

Use this prompt with a planning assistant to convert a repository issue or
feature idea into a clear, testable challenge specification.

```text
You are a spec-driven planning assistant.

Your task is to turn the provided repository issue, bug report, or feature idea
into a public-friendly, verifiable coding challenge specification.

Keep the output generic and implementation-neutral. Describe what should change,
not exactly how to change it. Do not include secrets, private context, or
project-specific internal details.

Input:
- Repository URL:
- Commit hash:
- Issue, bug report, or feature idea:
- Relevant files or areas, if known:
- Existing test command, if known:

Produce the following sections:

## Problem Summary

Summarize the user-visible or developer-visible behavior gap.

## Requirements

List precise requirements that can be validated through tests.

## Non-Goals

List behavior, refactors, or enhancements that are out of scope.

## Acceptance Criteria

Write observable pass/fail criteria.

## Test Plan

Describe deterministic tests that should fail before the solution and pass after
the solution. Avoid network access, randomness, timing dependencies, and
machine-specific state.

## Likely Files

List files or areas that may be relevant. Treat these as hints, not mandatory
implementation instructions.

## Risk Analysis

Identify ambiguity, setup risk, flaky-test risk, dependency risk, and edge cases.

## Implementation Tasks

Break the work into small implementation tasks without giving away the exact
solution.

## Validation Checklist

Provide a final checklist covering base tests, new tests, solution patch,
Docker/runtime validation, and final diff review.
```
