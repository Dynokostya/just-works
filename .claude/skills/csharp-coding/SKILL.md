---
name: csharp-coding
description: Apply when writing or editing C# (.cs) files. Behavioral corrections for error handling, resource management, async patterns, data modeling, type safety, nullability, security defaults, and common antipatterns. Project conventions always override these defaults.
---

# C# Coding

Match the project's existing conventions. When uncertain, read 2-3 existing files to infer the local style. Check `.csproj` for `TargetFramework` (`net10.0` LTS or `net9.0` STS in 2026), C# `LangVersion` (default `latest`; assume C# 14 on .NET 10), nullable settings, and analyzer config. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and vulnerabilities regardless of project style.

- **Never `catch { }` or `catch (Exception) { }` without rethrow or logging.** Broad catches silently swallow bugs — a NullReferenceException from a typo looks the same as a transient network failure. Catch specific exception types. If you must catch broadly at a boundary, always log and rethrow or convert to a meaningful error.
- **Never `throw ex`** — use `throw` or `throw new XException("msg", ex)`. `throw ex` resets the stack trace, destroying the origin of the error. You'll spend hours debugging something the original stack trace would have shown instantly.
- **Never `DateTime.Now`** — use `DateTime.UtcNow` or `DateTimeOffset.UtcNow`. `DateTime.Now` produces local time that varies by server timezone and breaks across DST transitions. `DateTimeOffset` is preferred when the timezone context matters.
- **Never `async void`** — except for event handlers. `async void` methods cannot be awaited, their exceptions crash the process unobserved, and they break structured error handling. Use `async Task` instead.
- **Never `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` on tasks** — these block the calling thread and cause deadlocks in ASP.NET Core and UI contexts. Use `await` instead. If you're in a sync context that genuinely cannot be made async, use `Task.Run(() => AsyncMethod()).GetAwaiter().GetResult()` as a last resort with a comment explaining why.
- **Never `Random` for security** — `Random` is not cryptographically secure and is predictable. Use `RandomNumberGenerator.GetBytes()`, `RandomNumberGenerator.GetInt32()`, or `Convert.ToHexString(RandomNumberGenerator.GetBytes(n))` for tokens, keys, session IDs.
- **Never string interpolation or concatenation in SQL** — use parameterized queries only. `$"SELECT * FROM users WHERE id = {uid}"` is always a SQL injection vulnerability. Use `@param` placeholders with `SqlCommand.Parameters` or your ORM's parameterization.
- **Never `GC.Collect()`** — the GC is self-tuning. Forcing collection hurts performance in nearly all cases by promoting short-lived objects to higher generations. If you think you need it, you have a design problem to fix instead.
- **Never mutable static fields** — statics are shared across all threads. Mutable statics cause race conditions that are extremely hard to reproduce and debug. Use `IOptions<T>`, dependency injection, or `ConcurrentDictionary` if shared state is genuinely needed.
- **Never `+` string concatenation in loops** — use `StringBuilder`. Strings are immutable in C#, so each `+` allocates a new string and copies all previous content — O(n^2) at scale. At 10k iterations this turns milliseconds into seconds.
- **Never `dynamic` for typed data** — `dynamic` bypasses compile-time type checking, turns type errors into runtime exceptions, and kills IntelliSense. Use generics, interfaces, or pattern matching instead. Reserve `dynamic` for COM interop or truly dynamic scenarios.
- **Never `Thread.Sleep()` in async code** — use `await Task.Delay()`. `Thread.Sleep` blocks the thread pool thread, starving other async operations. In ASP.NET Core this can exhaust the thread pool under load.

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

Create custom exception types when callers need to distinguish failure modes:

```csharp
public class AppException : Exception
{
    public AppException(string message) : base(message) { }
    public AppException(string message, Exception inner) : base(message, inner) { }
}

public class NotFoundException : AppException
{
    public string Resource { get; }
    public object Id { get; }

    public NotFoundException(string resource, object id)
        : base($"{resource} not found: {id}")
    {
        Resource = resource;
        Id = id;
    }
}
```

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

**Use `Task.WhenAll` for independent concurrent work:**

```csharp
var usersTask = GetUsersAsync(cancellationToken);
var ordersTask = GetOrdersAsync(cancellationToken);

await Task.WhenAll(usersTask, ordersTask);

var users = await usersTask;
var orders = await ordersTask;
```

**Never use `async` on a method that just returns another task.** Remove the state machine overhead:

```csharp
// Wrong — unnecessary async state machine
public async Task<User> GetUserAsync(int id, CancellationToken ct)
    => await _repository.GetByIdAsync(id, ct);

// Correct — direct passthrough
public Task<User> GetUserAsync(int id, CancellationToken ct)
    => _repository.GetByIdAsync(id, ct);
```

Exception: keep `async`/`await` when you need `using`, `try/catch`, or when the method does work before/after the awaited call.

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

For shared-state synchronization, prefer `System.Threading.Lock` over `lock (someObject)` where available:

```csharp
private readonly Lock _gate = new();

void AppendSafely(string item)
{
    using (_gate.EnterScope()) { _items.Add(item); }
}
```

## Nullability

Enable nullable reference types (`<Nullable>enable</Nullable>` in .csproj). Use the compiler's flow analysis — don't add redundant null checks where the type system already guarantees non-null.

**Use `??` for defaults and `?.` for optional chains:**

```csharp
var name = user.DisplayName ?? user.Email ?? "Anonymous";
var city = user.Address?.City;
```

**Use `??=` for lazy initialization:**

```csharp
_cache ??= new Dictionary<string, object>();
```

**Guard clause pattern for required non-null arguments:**

```csharp
public UserService(IUserRepository repository, ILogger<UserService> logger)
{
    _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
}
```

With C# 11+ and nullable enabled, prefer `required` keyword or primary constructors over null checks for constructor injection when the DI container guarantees non-null.

C# 11+: prefer `required` properties with object initializers when the DI container guarantees non-null:

```csharp
public sealed class UserService
{
    public required IUserRepository Repository { get; init; }
    public required ILogger<UserService> Logger { get; init; }
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

Use switch expressions for exhaustive branching. Clearer than if/elif chains for type checks, property destructuring, and value mapping.

```csharp
var message = result switch
{
    { IsSuccess: true, Value: var v } => $"Got {v}",
    { Error: NotFoundError e } => $"{e.Resource} not found",
    { Error: ValidationError e } => $"Invalid: {string.Join(", ", e.Errors)}",
    _ => "Unknown error"
};
```

Property patterns for conditional logic:

```csharp
if (order is { Status: OrderStatus.Shipped, TrackingNumber: not null } shipped)
{
    NotifyCustomer(shipped.TrackingNumber);
}
```

Relational and logical patterns:

```csharp
var tier = score switch
{
    >= 90 => "Gold",
    >= 70 => "Silver",
    >= 50 => "Bronze",
    _ => "None"
};
```

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

Constructor injection. Dependencies are explicit and testable.

```csharp
public sealed class OrderService(
    IOrderRepository repository,
    IPaymentClient payments,
    ILogger<OrderService> logger)
{
    // ...
}
```

**Service lifetimes:**
- **Transient** — lightweight, stateless services. New instance per injection.
- **Scoped** — per-request state (DbContext, unit of work, caller context). One instance per HTTP request.
- **Singleton** — thread-safe shared state (caches, configuration, HTTP client factories). One instance for app lifetime.

Match the project's DI container (Microsoft.Extensions.DependencyInjection, Autofac, etc.). Don't mix container-specific APIs across the codebase.

**Register by interface, not concrete type:**

```csharp
services.AddScoped<IUserRepository, UserRepository>();
services.AddSingleton<ICacheService, RedisCacheService>();
```

## Enums

Use enums for known fixed value sets. Don't use raw strings or magic numbers.

```csharp
public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled
}
```

For enums that need string serialization (APIs, databases), configure the JSON serializer to use string names rather than integer values. Don't scatter `ToString()` / `Enum.Parse()` calls through business logic.

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
