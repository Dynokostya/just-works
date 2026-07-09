---
name: csharp-coding
description: Apply when writing or editing C# (.cs) files. Behavioral corrections for error handling, resource management, async patterns, data modeling, type safety, nullability, security defaults, and common antipatterns. Project conventions always override these defaults.
---

# C# Coding

Match the project's existing conventions. When uncertain, read 2-3 existing files to infer the local style. Check `.csproj` for `TargetFramework` (`net10.0` LTS or `net9.0` STS in 2026), C# `LangVersion` (default `latest`; assume C# 14 on .NET 10), nullable settings, and analyzer config. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and vulnerabilities regardless of project style.

- **Never `catch { }` or `catch (Exception) { }` without rethrow or logging** — catch specific types; at a boundary, log and rethrow or convert to a meaningful error.
- **Never `throw ex`** — it resets the stack trace; use `throw` or wrap: `throw new XException("msg", ex)`.
- **Never `DateTime.Now`** — use `DateTime.UtcNow` or `DateTimeOffset.UtcNow`. `DateTime.Now` produces local time that varies by server timezone and breaks across DST transitions. `DateTimeOffset` is preferred when the timezone context matters.
- **Never `async void`** except event handlers — unawaitable, and exceptions crash the process unobserved; use `async Task`.
- **Never `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` on tasks** — these block the calling thread and cause deadlocks in ASP.NET Core and UI contexts. Use `await` instead. If you're in a sync context that genuinely cannot be made async, use `Task.Run(() => AsyncMethod()).GetAwaiter().GetResult()` as a last resort with a comment explaining why — the `Task.Run` hop runs the async work on a thread-pool thread with no `SynchronizationContext` to marshal back to, which is what sidesteps the deadlock the bare construct causes.
- **Never `Random` for security** — use `RandomNumberGenerator.GetBytes()`/`GetInt32()` for tokens, keys, and session IDs.
- **Never string interpolation or concatenation in SQL** — parameterized queries only (`@param` with `SqlCommand.Parameters` or the ORM's parameterization).
- **Never `GC.Collect()`** — the GC is self-tuning; forcing collection promotes short-lived objects and hurts performance.
- **Never mutable static fields** — shared across all threads; use DI, `IOptions<T>`, or `ConcurrentDictionary` for genuinely shared state.
- **Never `+` string concatenation in loops** — use `StringBuilder`.
- **Never `dynamic` for typed data** — it defeats compile-time checking; use generics, interfaces, or pattern matching. Reserve `dynamic` for COM interop.
- **Never `Thread.Sleep()` in async code** — use `await Task.Delay()`; sleeping blocks a thread-pool thread.

## Error handling

Use `throw` (not `throw ex`) when re-throwing to preserve the original stack trace. Wrap with inner exception when converting exception types at boundaries:

```csharp
try
{
    var result = await httpClient.GetAsync(url, cancellationToken);
    result.EnsureSuccessStatusCode();
}
catch (HttpRequestException ex)
{
    throw new ServiceUnavailableException($"Failed to reach {url}", ex);
}
```

Use exception filters (`when`) to catch conditionally without unwinding the stack:

```csharp
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
{
    return null;
}
catch (HttpRequestException ex) when (ex.StatusCode >= HttpStatusCode.InternalServerError)
{
    logger.LogWarning(ex, "Transient server error from {Url}", url);
    throw;
}
```

Create custom exception types when callers need to distinguish failure modes — carry context as properties (resource, id) and provide an inner-exception constructor.

## Resource cleanup

Use `using` declarations for anything that implements `IDisposable` or `IAsyncDisposable`. Never instantiate `HttpClient`, database connections, streams, or similar without `using` or explicit `finally` cleanup.

```csharp
// C# 8+ using declaration — disposed at end of scope
using var stream = File.OpenRead(path);
using var reader = new StreamReader(stream);
var content = await reader.ReadToEndAsync(cancellationToken);
```

For async disposables:

```csharp
await using var connection = new SqlConnection(connectionString);
await connection.OpenAsync(cancellationToken);
```

For multiple resources or complex lifecycles, use explicit `try/finally`:

```csharp
var connection = new SqlConnection(connectionString);
try
{
    await connection.OpenAsync(cancellationToken);
    // work
}
finally
{
    await connection.DisposeAsync();
}
```

When implementing `IDisposable`, follow the pattern only if you hold unmanaged resources or own other disposables. Don't implement `IDisposable` on classes that don't own anything disposable — it adds ceremony for no benefit.

## Async patterns

**Always pass `CancellationToken` through the call chain.** Accept it as the last parameter and forward it to every async API. Omitting it means your code cannot be cancelled, leading to wasted resources and hung requests.

```csharp
public async Task<User> GetUserAsync(int id, CancellationToken cancellationToken = default)
{
    var response = await _httpClient.GetAsync($"/users/{id}", cancellationToken);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadFromJsonAsync<User>(cancellationToken: cancellationToken)
        ?? throw new NotFoundException("User", id);
}
```

**Prefer `Task` over `ValueTask`** unless profiling shows allocation pressure from a hot path that frequently completes synchronously. `ValueTask` has restrictions (can only be awaited once, no concurrent awaits) that make it error-prone as a default choice.

**Use `ConfigureAwait(false)` in library code** (NuGet packages, shared class libraries) to avoid deadlocks in non-ASP.NET Core consumers. In ASP.NET Core application code, it's unnecessary — the default `SynchronizationContext` is null.

**Use `Task.WhenAll` for independent concurrent work** — don't await independent operations sequentially.

**Consider eliding `async`/`await` on pure passthroughs only in measured hot paths.** Returning the task directly skips the state machine, but it also drops the method from async stack traces — default to keeping `async`/`await`. Always keep it when the method uses `using`, `try/catch`, or does work before/after the awaited call.

```csharp
// Hot path only — no state machine, but the method disappears from async stack traces
public Task<User> GetUserAsync(int id, CancellationToken ct)
    => _repository.GetByIdAsync(id, ct);
```

## C# 13 params collections

`params` is no longer limited to arrays. Use `params ReadOnlySpan<T>` for zero-allocation variadic APIs; use `params IEnumerable<T>` when the caller may pass a lazy source:

```csharp
public static int Sum(params ReadOnlySpan<int> values)
{
    var total = 0;
    foreach (var v in values) total += v;
    return total;
}

Sum(1, 2, 3); // no heap allocation
```

## System.Threading.Lock (.NET 9+)

For shared-state synchronization on .NET 9+, prefer the dedicated `System.Threading.Lock` type over `lock` on a plain `object`; on older targets keep the classic `private readonly object` pattern:

```csharp
private readonly Lock _gate = new();

void AppendSafely(string item)
{
    using (_gate.EnterScope()) { _items.Add(item); }
}
```

## Nullability

Enable nullable reference types (`<Nullable>enable</Nullable>` in .csproj). Use the compiler's flow analysis — don't add redundant null checks where the type system already guarantees non-null. Use `??` for defaults, `?.` for optional chains, and `??=` for lazy initialization.

**Guard clause for required non-null arguments** — use `ArgumentNullException.ThrowIfNull` (.NET 6+):

```csharp
public UserService(IUserRepository repository, ILogger<UserService> logger)
{
    ArgumentNullException.ThrowIfNull(repository);
    ArgumentNullException.ThrowIfNull(logger);
    _repository = repository;
    _logger = logger;
}
```

For DI services, prefer primary constructors (C# 12) — Microsoft.Extensions.DependencyInjection injects through constructors only, so a service exposing its dependencies as `required` properties is unconstructible by the default container. Reserve `required` properties for types built with object initializers (DTOs, options):

```csharp
public sealed class SmtpOptions
{
    public required string Host { get; init; }
    public required int Port { get; init; }
}
```

C# 14: use the `field` keyword in property accessors to add validation without declaring an explicit backing field:

```csharp
public string Email
{
    get;
    set => field = !string.IsNullOrWhiteSpace(value)
        ? value
        : throw new ArgumentException("Email required");
}
```

## Pattern matching

Use switch expressions over if/else chains for exhaustive branching, property patterns (`order is { Status: OrderStatus.Shipped, TrackingNumber: not null } shipped`) for combined shape checks, and relational patterns (`>= 90 => "Gold"`) for range mapping.

Null-conditional assignment (C# 14):

```csharp
// Before C# 14:
if (customer is not null) { customer.Order = GetCurrentOrder(); }

// C# 14:
customer?.Order = GetCurrentOrder();
```

The right side is evaluated only when the left is non-null.

## Data modeling

| Use Case | Choice | Reason |
|----------|--------|--------|
| API request/response DTOs | record | Immutable, value equality, concise syntax |
| Configuration | record or POCO + IOptions<T> | Framework support, binding |
| Domain entities with identity | class | Reference equality, mutable state |
| Simple value objects | readonly record struct | Stack-allocated, no GC pressure, value semantics |

Records for DTOs:

```csharp
public sealed record CreateUserRequest(string Email, string Name);

public sealed record UserResponse(int Id, string Email, string Name);
```

Primary constructors (C# 12) for service classes:

```csharp
public sealed class UserService(IUserRepository repository, ILogger<UserService> logger)
{
    public async Task<User> GetByIdAsync(int id, CancellationToken ct)
    {
        logger.LogDebug("Fetching user {UserId}", id);
        return await repository.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("User", id);
    }
}
```

Use `init` properties when you need object initializer syntax with immutability:

```csharp
public sealed class PaginationOptions
{
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
```

## Dependency injection

Use constructor injection (primary constructors) — dependencies stay explicit and testable. Register by interface (`services.AddScoped<IUserRepository, UserRepository>()`), and match the project's DI container rather than mixing container-specific APIs. Lifetimes: transient for stateless services, scoped for per-request state (DbContext, unit of work), singleton for thread-safe shared state (caches, configuration).

## Enums

Use enums for known fixed value sets, not raw strings or magic numbers. When enums cross serialization boundaries (APIs, databases), configure the JSON serializer to emit string names — don't scatter `ToString()`/`Enum.Parse()` through business logic.

## Imports

Use `global using` directives (C# 10+) in a single `GlobalUsings.cs` file for project-wide imports. Don't duplicate common usings across every file. Match existing project convention — if there's no `GlobalUsings.cs`, use regular per-file usings.

Order: `System.*`, third-party, project namespaces. Let the IDE/formatter sort them.

## Logging

Use `ILogger<T>` with structured logging. Use message templates with named placeholders — never string interpolation:

```csharp
// Wrong — interpolation defeats structured logging
logger.LogInformation($"User {userId} created order {orderId}");

// Correct — structured, searchable, parameterized
logger.LogInformation("User {UserId} created order {OrderId}", userId, orderId);
```

For hot paths, use `LoggerMessage.Define` to avoid allocation:

```csharp
private static readonly Action<ILogger, int, Exception?> LogUserCreated =
    LoggerMessage.Define<int>(LogLevel.Information, new EventId(1), "User {UserId} created");

// Usage
LogUserCreated(logger, user.Id, null);
```

Or with .NET 6+ source generators:

```csharp
[LoggerMessage(Level = LogLevel.Information, Message = "User {UserId} created")]
private static partial void LogUserCreated(ILogger logger, int userId);
```

## Testing

Match the project's test runner (xUnit, NUnit, MSTest) and mocking library (Moq, NSubstitute, FakeItEasy).

When to mock: external HTTP APIs, databases, third-party services, and anything with side effects or costs. When to use real instances: pure logic, in-memory implementations, value objects.

Test behavior, not implementation — test what a method returns or what side effects it produces, not how it internally works.

The example below is illustrative (NUnit + NSubstitute) — match the project's stack:

```csharp
[Test]
public async Task GetUser_WhenExists_ReturnsUser()
{
    // Arrange
    var repository = Substitute.For<IUserRepository>();
    repository.GetByIdAsync(42, Arg.Any<CancellationToken>())
        .Returns(new User { Id = 42, Name = "Alice" });
    var service = new UserService(repository, NullLogger<UserService>.Instance);

    // Act
    var result = await service.GetByIdAsync(42, CancellationToken.None);

    // Assert
    Assert.That(result.Name, Is.EqualTo("Alice"));
}
```
