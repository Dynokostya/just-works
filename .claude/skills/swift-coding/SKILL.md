---
name: swift-coding
description: Apply when writing or editing Swift (.swift) files. Behavioral corrections for error handling, concurrency, memory management, type safety, protocol-oriented design, security defaults, and common antipatterns.
---

# Swift Coding

Project conventions override these defaults. Read 2-3 nearby files first, and check the project's own target: `Package.swift` or the `.xcodeproj` for Swift version, language mode, platform targets, and the concurrency build settings (strict concurrency level, default actor isolation). Do not assume a concurrency default the project has not set.

## Never rules

- **Never force unwrap (`!`) or `try!` outside tests**, `@IBOutlet`, and provable programmer errors (a hard-coded URL literal) with an explaining comment. Use `guard let`, `if let`, `??`, `do`-`catch`, or `try?`.
- **Never use a bare `catch { }` that swallows the error.** Catch specific types, or log and rethrow.
- **Never keep mutable global or static state.** Use actors, `@MainActor`, or dependency injection. Swift 6 language mode reports these as errors.
- **Never block `@MainActor`.** No `Thread.sleep()`, synchronous network calls, or heavy computation on the main actor; use `async`/`await` or a background context.
- **Never `print()` in production code.** Use `os.Logger`: it is filterable, structured, and searchable in Console.app.
- **Never generate key material by hand.** Use CryptoKit (`SymmetricKey(size:)`) or `SecRandomCopyBytes` for keys, tokens, and session IDs. `SystemRandomNumberGenerator` and `Int.random(in:)` are fine for general use.
- **Never use `Any` or `AnyObject` where a protocol or generic works.** Prefer generics, `some`, or `any` with a specific protocol.
- **Default to `struct`.** Use `class` only for reference semantics, identity, inheritance, or Objective-C interop.

## Closure capture and memory

Use `[weak self]` (or `[unowned self]` when the closure cannot outlive `self`) only when a retain cycle is possible: `self` stores the closure (directly or through an object it owns) and the closure uses `self`. Typical cases are closures kept in properties, long-lived callbacks and observers, and `Task` loops that never finish. Do not add it to non-escaping closures, one-shot `Task { }` bodies, `TaskGroup` child tasks, or closures `self` does not retain; it only adds optional unwrapping. After a weak capture, unwrap with `guard let self else { return }` before doing work. A capture list such as `[currentCount]` snapshots a value at closure creation. Delegates are `weak var` with an `AnyObject` protocol. (Source: The Swift Programming Language, "Automatic Reference Counting", strong reference cycles for closures.)

## Error handling

Propagate with `throws` through internal layers and handle at the outermost boundary that can act on it. Use `Result` only to store an outcome, cross a non-throwing boundary, or wrap a callback API that cannot be made `async`. Use typed throws (`throws(ValidationError)`, Swift 6) when callers should handle a specific error type without erasure. Use `guard` for early exits and `defer` for cleanup (file handles, locks, restoring state).

## Concurrency

- Prefer structured concurrency (`async let`, `TaskGroup`) for work scoped to a function; child tasks are cancelled with their parent. Use unstructured `Task { }` only for fire-and-forget work or to bridge from synchronous code.
- Use actors for shared mutable state and `@MainActor` for UI work (on the type when every member needs it, on individual methods otherwise).
- `Sendable` is required across actor boundaries. Structs and enums with `Sendable` members conform automatically; a `final class` needs only `let` properties, or `@unchecked Sendable` with internal synchronization. Use `sending` parameters (Swift 6.0+) to hand a non-`Sendable` value across an isolation boundary once.
- Check `try Task.checkCancellation()` inside long loops.
- `some` returns one hidden concrete type and keeps optimizations. Reserve `any` for heterogeneous collections and genuinely dynamic dispatch.

## Data modeling and SwiftUI

Use `Codable` structs (declared `Sendable`) for API payloads, enums with associated values for fixed state sets, and `@Observable` classes for SwiftUI state. `@Observable` (Swift 5.9+) replaces `ObservableObject` plus `@Published`, and views re-render only for properties they read; pair it with `@MainActor` when the model is UI-bound.

## Pattern matching

Add `@unknown default` when switching over enums from external modules, so the compiler warns when a new case ships.

## Testing

Use Swift Testing (`@Test`, `#expect`, `#require`, `@Suite`, `arguments:` for parameterized tests) for new tests; use XCTest for UI tests and projects standardized on it.

## Concurrency migration (Swift 6)

Enable strict concurrency incrementally: `-strict-concurrency=targeted`, then `complete`, then Swift 6 language mode. Fix bottom-up, starting with leaf modules; mark cross-isolation closures `@Sendable`. Use `nonisolated` on actor members that touch only immutable or `Sendable` state.
