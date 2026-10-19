---
name: csharp-coding
description: Apply when writing or editing C# (.cs) files. Behavioral corrections for error handling, resource management, async patterns, data modeling, type safety, nullability, security defaults, and common antipatterns.
---

# C# Coding

Project conventions override these defaults. Read 2-3 nearby files first, and check the project's own target in the `.csproj`: `TargetFramework`, `LangVersion`, nullable setting, analyzer config. Use only language and library features that target supports (C# 13 needs .NET 9, C# 14 needs .NET 10).

## Never rules

- **Never write an empty `catch`**, or a `catch (Exception)` that neither rethrows nor logs. Catch specific types; at a boundary, log and rethrow or convert to a meaningful error.
- **Never `throw ex`.** It resets the stack trace. Use `throw;`, or wrap with an inner exception: `throw new XException("msg", ex)`.
- **Never use `DateTime.Now` for stored or compared timestamps.** It is server-local time and breaks across time zones and DST. Take time from an injected `TimeProvider` (.NET 8+) so tests can control it; otherwise use `DateTimeOffset.UtcNow` or `DateTime.UtcNow`. Local time is for display only.
- **Never `async void`** except event handlers. It cannot be awaited and its exceptions crash the process.
- **Never block on a task** with `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`. It deadlocks in UI and ASP.NET Core contexts. Use `await`. If a synchronous caller truly cannot be made async, `Task.Run(() => MethodAsync()).GetAwaiter().GetResult()` avoids the deadlock (the work runs on a thread-pool thread with no `SynchronizationContext`); add a comment saying why.
- **Never use `Random` for tokens, keys, or session IDs.** Use `RandomNumberGenerator.GetBytes()` / `GetInt32()`.
- **Never concatenate or interpolate values into SQL.** Use parameters (`SqlCommand.Parameters` or the ORM's parameterization).
- **Avoid mutable `static` fields** that hold request or user state; they are shared across threads. Use DI, `IOptions<T>`, or a thread-safe type (`ConcurrentDictionary`, `Lock`-guarded state). Constants, `static readonly` values, and lazily built immutable caches are fine.

## Resource cleanup

Use `using` / `await using` declarations for `IDisposable` and `IAsyncDisposable` objects you create. `HttpClient` is the exception: do not create and dispose one per call (it exhausts ports). Create clients through `IHttpClientFactory`, or share a long-lived instance with `PooledConnectionLifetime` set. Implement `IDisposable` only when the class owns unmanaged resources or other disposables.

## Async patterns

- Accept `CancellationToken` as the last parameter and forward it to every async call.
- Prefer `Task` over `ValueTask` unless profiling shows allocation pressure on a hot path that often completes synchronously; `ValueTask` can be awaited only once.
- Use `ConfigureAwait(false)` in library code; it is unnecessary in ASP.NET Core application code.
- Run independent operations with `Task.WhenAll`, not sequential `await`s.
- Return a task directly (eliding `async`/`await`) only on measured hot paths, never when the method uses `using`, `try/catch`, or does work around the await: eliding drops the method from async stack traces.

## Modern language features

C# 13 `params` accepts collections: use `params ReadOnlySpan<T>` for allocation-free variadic APIs.

On .NET 9+, prefer `System.Threading.Lock` over `lock` on an `object`; older targets keep `private readonly object`.

```csharp
private readonly Lock _gate = new();
void Add(string item) { using (_gate.EnterScope()) { _items.Add(item); } }
```

C# 14: the `field` keyword adds accessor logic without a declared backing field, and null-conditional assignment (`customer?.Order = GetCurrentOrder();`) evaluates the right side only when the left is non-null.

```csharp
public string Email
{
    get;
    set => field = !string.IsNullOrWhiteSpace(value) ? value : throw new ArgumentException("Email required");
}
```

## Nullability and construction

Enable nullable reference types and trust the compiler's flow analysis; do not add null checks the type system already guarantees. Use `ArgumentNullException.ThrowIfNull` for required public arguments.

For DI services, use primary constructors: the default container injects through constructors only, so a service exposing its dependencies as `required` properties cannot be built. Reserve `required` properties for types created with object initializers (DTOs, options).

## Data modeling

| Use case | Choice |
|----------|--------|
| API request/response DTOs | `sealed record` |
| Configuration | record or POCO bound through `IOptions<T>` |
| Domain entities with identity | `class` |
| Simple value objects | `readonly record struct` |

Configure the JSON serializer to emit enum names as strings at serialization boundaries; do not scatter `ToString()` / `Enum.Parse()` through business logic.

## Logging

Use `ILogger<T>` with message templates and named placeholders, never string interpolation, which defeats structured logging: `logger.LogInformation("User {UserId} created order {OrderId}", userId, orderId)`. On hot paths, use the `[LoggerMessage]` source generator.

## Testing

Match the project's test runner (xUnit, NUnit, MSTest) and mocking library. Mock external HTTP APIs, databases, and anything with side effects or cost; use real instances for pure logic and value objects. Test behavior (return values, observable side effects), not internals.
