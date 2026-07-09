---
name: swift-coding
description: Apply when writing or editing Swift (.swift) files. Behavioral corrections for error handling, concurrency, memory management, type safety, protocol-oriented design, security defaults, and common antipatterns. Project conventions always override these defaults.
---

# Swift Coding

Match the project's existing conventions. When uncertain, read 2-3 existing files to infer the local style. Check `Package.swift` or `.xcodeproj`/`.xcworkspace` for Swift version, platform targets, and dependencies. New Xcode 26+ app projects default to Approachable Concurrency (Swift 6.2+) with main-actor isolation for app module code — assume this default unless the project explicitly disables it. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and vulnerabilities regardless of project style.

- **Never force unwrap (`!`) outside tests and controlled contexts** — crashes at runtime with no recovery path. Use `guard let`, `if let`, `??`, or optional chaining. Force unwrap is acceptable in tests, `@IBOutlet`, and when failure is provably a programmer error with an explaining comment.
- **Never `try!` outside tests** — crashes on any error. Use `do`-`catch`, `try?`, or propagate with `throws`. A network timeout, a missing file, a malformed response — any of these kill your process silently with no chance to recover or report.
- **Never bare `catch { }` without handling** — silently swallows errors. Catch specific error types, or log and rethrow. A decode failure looks the same as a permission error, and you'll never know which one is happening in production.
- **Never `[weak self]` without checking for nil** — accessing self after capture without `guard let self` leads to silent no-ops or partial execution. Half-completed operations are worse than failures because they corrupt state without raising errors.
- **Never mutable global or static state** — shared mutable state causes data races. Use actors, `@MainActor`, or dependency injection. The Swift 6 concurrency model will flag these as compile errors, so fix them now.
- **Never blocking calls on MainActor** — no `Thread.sleep()`, synchronous network calls, or heavy computation on the main thread. Use `Task`, `async`/`await`, or dispatch to a background context. Blocking main freezes the UI and triggers watchdog kills on iOS.
- **Never `x = x + y` to build strings in loops** — use `+=` or `append(contentsOf:)`, which grow the buffer in place (amortized, via copy-on-write), or `joined(separator:)` for collections. `x = x + y` allocates and copies a fresh string every iteration.
- **Never hand-roll cryptographic key material** — use CryptoKit (`SymmetricKey(size:)`) or `SecRandomCopyBytes` for keys, tokens, and session IDs. For general randomness, `Int.random(in:)` and `SystemRandomNumberGenerator` are fine — the system RNG is cryptographically secure.
- **Never `print()` in production code** — use `os.Logger` or `OSLog`. `print` is not filterable, not structured, and persists in release builds. It cannot be searched in Console.app and adds noise to device logs.
- **Never `class` when `struct` suffices** — default to value types. Use `class` only when you need reference semantics, inheritance, or identity. Value types avoid retain/release overhead and are safe to copy across threads — though closure captures, existential boxes, and CoW buffers can still put struct storage on the heap.
- **Never retain cycles in closures** — escaping closures capturing `self` in classes must use `[weak self]` or `[unowned self]`. Retain cycles cause silent memory leaks that accumulate over app lifetime, eventually triggering OOM kills.
- **Never `Any` or `AnyObject` when a protocol or generic suffices** — type erasure disables compile-time checking. Use generics, `some`, or `any` with specific protocols. A runtime cast failure is always worse than a compile error.

## Error handling

Use `throws` and `do`-`catch` at system boundaries. Propagate errors with `throws` through internal layers and handle them at the outermost boundary where you can take meaningful action.

```swift
enum NetworkError: Error {
    case invalidURL(String)
    case requestFailed(statusCode: Int)
    case decodingFailed(underlying: Error)
}

func fetchUser(id: Int) async throws -> User {
    guard let url = URL(string: "https://api.example.com/users/\(id)") else {
        throw NetworkError.invalidURL("/users/\(id)")
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw NetworkError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    do {
        return try JSONDecoder().decode(User.self, from: data)
    } catch {
        throw NetworkError.decodingFailed(underlying: error)
    }
}
```

Use `guard` for early exits. It keeps the happy path unindented and makes preconditions explicit:

```swift
func process(order: Order?) throws -> Receipt {
    guard let order else { throw AppError.missingOrder }
    guard order.items.isEmpty == false else { throw AppError.emptyOrder }
    guard order.total > 0 else { throw AppError.invalidTotal(order.total) }
    return Receipt(order: order, timestamp: .now)
}
```

When to use `Result` vs `throws`: prefer `throws` for most code. Use `Result` when you need to store an outcome for later processing, pass it across non-throwing boundaries, or work with callback-based APIs that cannot be made async.

Swift 6 typed throws allow callers to handle specific error types without type erasure:

```swift
func validate(input: String) throws(ValidationError) -> Validated {
    guard input.count >= 3 else { throw .tooShort(minimum: 3) }
    return Validated(value: input)
}
```

## Resource cleanup

Use `defer` for cleanup — file handles, locks, temporary state restoration. `defer` executes when the scope exits regardless of how (return, throw, break):

```swift
func writeData(_ data: Data, to path: String) throws {
    let handle = try FileHandle(forWritingTo: URL(filePath: path))
    defer { try? handle.close() }
    handle.write(data)
}
```

With structured concurrency, child tasks are automatically cancelled when their parent scope exits. Prefer structured concurrency (`async let`, `TaskGroup`) over unstructured `Task { }` to get automatic cleanup for free.

## Async patterns

Use `async`/`await` for all asynchronous work. Prefer structured concurrency over unstructured tasks.

`TaskGroup` for concurrent work with dynamic fan-out:

```swift
func fetchAllUsers(ids: [Int]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask { try await fetchUser(id: id) }
        }
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

Actors for shared mutable state — they serialize access automatically:

```swift
actor ImageCache {
    private var cache: [URL: Data] = [:]

    func image(for url: URL) -> Data? { cache[url] }

    func store(_ data: Data, for url: URL) { cache[url] = data }
}
```

Use `@MainActor` for UI work. Apply it to the type when all members need main-thread access, or to individual methods when only some do:

```swift
@MainActor
@Observable
final class ViewModel {
    var items: [Item] = []

    func refresh() async throws {
        let fetched = try await service.fetchItems()
        items = fetched
    }
}
```

`Sendable` conformance is required for values crossing actor boundaries. Structs and enums with all-Sendable stored properties conform automatically. For classes, use a `final class` with only `let` stored properties, declared `Sendable` — or `@unchecked Sendable` with internal synchronization.

`sending` parameters and returns (Swift 6.0+) let you pass a non-Sendable value across isolation boundaries exactly once. Use when you need ownership transfer without requiring `Sendable`:

```swift
func enqueue(_ work: sending () async -> Void) async { /* ... */ }

actor Pipeline {
    func submit(_ task: sending SomeNonSendable) async { /* ownership moves here */ }
}
```

Check cancellation in long-running work:

```swift
for item in largeCollection {
    try Task.checkCancellation()
    await process(item)
}
```

When to use structured vs unstructured concurrency: use `async let` and `TaskGroup` (structured) for work scoped to a function. Use `Task { }` (unstructured) only for fire-and-forget work or bridging from synchronous contexts. Structured concurrency handles cancellation and error propagation automatically.

## Type system

`some` (opaque) returns one concrete type hidden from the caller — preserves type identity and compiler optimization. `any` (existential) is a type-erased box — reserve it for heterogeneous collections or genuinely dynamic dispatch; it costs boxing and blocks specialization.

## Value vs reference types

Default to structs. Use classes when you need reference semantics (shared mutable state), inheritance, or Objective-C interop. Use enum as a namespace (caseless enum) for grouping constants and static functions:

```swift
enum API {
    // Force unwrap is safe: hard-coded literal is a valid URL, so failure is a programmer error
    static let baseURL = URL(string: "https://api.example.com")!
    static let timeout: TimeInterval = 30
}
```

Collections use copy-on-write — passing an array to a function does not copy until mutation. This means value semantics are cheap in practice for standard library types.

## Data modeling

Choose by semantics: `Codable` structs for API payloads (declare them `Sendable` — they cross concurrency boundaries in async networking), enums with associated values for fixed sets of states, `@Observable` classes for SwiftUI UI state, and class or actor only where identity or shared mutable state is the point.

## Observation (SwiftUI)

`@Observable` (Swift 5.9+) replaces the `ObservableObject` + `@Published` + Combine pairing. SwiftUI views observe only the properties they actually read — automatic, granular, no manual `@Published`.

```swift
@Observable
final class Cart {
    var items: [Item] = []
    var total: Decimal = 0
}

struct CartView: View {
    let cart: Cart
    var body: some View {
        Text("Items: \(cart.items.count)") // only rebuilds when items changes
    }
}
```

Combine `@Observable` with `@MainActor` when the model is UI-bound:

```swift
@MainActor
@Observable
final class ViewModel { /* ... */ }
```

## Memory management

ARC manages memory automatically, but you must handle reference cycles. Strong references (the default) keep objects alive. Use `weak` for optional back-references and delegates. Use `unowned` only when the referenced object is guaranteed to outlive the reference.

Delegate pattern with `weak`:

```swift
protocol DownloadDelegate: AnyObject {
    func downloadDidFinish(_ result: Result<Data, Error>)
}

class Downloader {
    weak var delegate: DownloadDelegate?

    func start() async {
        do {
            let data = try await fetchData()
            delegate?.downloadDidFinish(.success(data))
        } catch {
            delegate?.downloadDidFinish(.failure(error))
        }
    }
}
```

Closure capture lists — always unwrap `weak self` before doing work:

```swift
service.onComplete = { [weak self] result in
    guard let self else { return }
    self.items = result.items
    self.tableView.reloadData()
}
```

Use value captures to snapshot a value at closure creation time:

```swift
let currentCount = items.count
Task { [currentCount] in
    await reportAnalytics(itemCount: currentCount)
}
```

## Pattern matching

Enum switches are compiler-enforced exhaustive. Add `@unknown default` when switching on enums from external modules — the switch stays exhaustive today and the compiler warns when a future SDK version adds a case.

## Naming conventions

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): argument labels form grammatical phrases at the call site (`move(to:)`, `remove(at:)` — omit the label for direct objects), booleans read as assertions (`isEmpty`, `canFly`), and mutating/nonmutating pairs follow `sort()`/`sorted()`, `formUnion()`/`union()`.

## Testing

Use Swift Testing (`@Test`, `#expect`, `#require`, `@Suite`) for new tests; use XCTest for UI tests and when the project is already standardized on it. `#expect` replaces the `XCTAssert*` family, `#require` replaces `XCTUnwrap`, and `arguments:` gives parameterized tests.

```swift
@Suite("UserService")
struct UserServiceTests {
    let service = UserService(repository: MockRepository())

    @Test("Returns user when found")
    func userFound() async throws {
        let user = try await service.getUser(id: 42)
        #expect(user.name == "Alice")
    }

    @Test("Throws not found for missing user")
    func userNotFound() async {
        await #expect(throws: AppError.notFound) {
            try await service.getUser(id: 999)
        }
    }
}
```

## Concurrency migration (Swift 6)

Enable strict concurrency checking incrementally. Start with warnings (`-strict-concurrency=targeted`), then move to `complete`, then enable the Swift 6 language mode.

Fix bottom-up: start with leaf modules that have no dependencies, make their types `Sendable`, then work up the dependency graph. Mark callbacks and closures as `@Sendable` when they cross isolation boundaries.

Use `nonisolated` to opt methods out of an actor's isolation when they only access immutable or `Sendable` state:

```swift
actor SessionManager {
    let configuration: AppConfiguration  // immutable

    nonisolated var appName: String {
        configuration.name
    }
}
```

On Swift 6.2+, enable the "Approachable Concurrency" build setting and "Default Actor Isolation = MainActor" for UI-facing modules. These ship as defaults for new Xcode 26 app targets and make single-threaded code simpler to write while keeping the migration path to full concurrency open.
