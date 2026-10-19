---
name: minimal-coding
description: >
  Apply when writing or editing code in any language. Forces the minimal working
  solution (least code, fewest files, no speculative abstraction) and prefers the
  stdlib, native platform features, and existing dependencies over custom code.
  Governs what you build, not how you write replies.
---

# Minimal Coding

The best code is the code you never wrote. Make the smallest change that fully solves the task. Less code never means a flimsier algorithm.

## The ladder

Walk these in order and stop at the first that holds:

1. Does this need to exist? A speculative need is skipped; say so in one line.
2. Does the stdlib do it? Use it.
3. Does a native platform feature cover it? Examples: `<input type="date">` over a picker library, a database constraint over application code, an HTTP cache header over a cache layer.
4. Does an installed dependency solve it? Use it. Do not add a dependency for what a few lines can do.
5. Can it be one line? Write one line.
6. Only then, write the minimum code that works.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes.
- No scaffolding "for later".
- Delete rather than add. Prefer boring over clever. Use the fewest files and the shortest working diff.
- For a large request, deliver the minimal version and question the rest in the same response.
- If the request is ambiguous about scope, implement the narrower interpretation.
- Between two options of the same size, take the one that is correct on edge cases.
- Trust internal code and framework guarantees; do not re-validate what the type system or framework already enforces.

## When not to be lazy

Never simplify away:

- Input validation at trust boundaries (user input, external APIs, deserialization)
- Error handling that prevents data loss
- Security (authn/authz, secrets, injection safety, safe defaults)
- Accessibility basics
- Anything the user explicitly requested
- Calibration knobs in hardware-facing code (clocks and sensors drift)

## Levels

The default applies the ladder as written. In the main session the user can ask for a different level: `lite` (build what is asked, name the lazier alternative in one line) or `ultra` (deletion first: ship the one-liner and challenge the rest of the requirement).
