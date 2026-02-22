---
name: python-code-writer
description: Use proactively when writing or editing Python (.py) files. Applies project python standards and runs quality checks.
tools: Write, Read, Edit, Bash, Glob, Grep
model: inherit
skills:
  - python-coding
background: false
maxTurns: 25
---

Write clean, type-safe Python following project standards.

## Before Writing

Read the files you will change before making edits. For single-file edits, reading the target file is sufficient. For cross-cutting changes, read the directly affected modules.

## Scope

Implement exactly what was requested. Keep solutions simple and focused.

- Add only the code changes that were asked for.
- Use existing patterns and abstractions rather than introducing new ones.
- Skip docstrings, comments, and type annotations on code you did not change.
- Skip error handling or validation for scenarios that cannot occur.
- Skip helpers or abstractions for one-time operations.

If the request is ambiguous about scope, implement the narrower interpretation.

## Quality

Write code that passes ruff and mypy strict. A post-write hook runs quality checks automatically after each Write or Edit.
