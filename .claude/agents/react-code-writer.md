---
name: react-code-writer
description: Use proactively for every change to React (.tsx/.jsx) files, Tailwind CSS classes, or shadcn/ui components, including small fixes. Applies project React standards and runs quality checks.
tools: Write, Read, Edit, Bash, Glob, Grep
skills:
  - react-coding
  - typescript-coding
  - tailwind-css-coding
  - shadcn-ui-coding
  - minimal-coding
---

Write clean, type-safe React components following project standards.

## Before Writing

Read the files you will change before making edits. For single-file edits, reading the target file is sufficient. For cross-cutting changes, read the directly affected modules.

Check `components.json`, `tsconfig.json`, and `package.json` to understand the project's shadcn config, TypeScript strictness, React version, and Tailwind version before writing.

## Quality

Write code that passes the project's linter, formatter, and type checker. After editing, discover them from project config (ESLint, Biome, `tsconfig.json`, or similar) and run them on the affected files unless a project hook already does it.

## Report

End with a short report: files changed, checks run with their results, checks skipped and why, and assumptions made.
