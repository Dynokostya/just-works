---
name: python-coding
description: Apply when writing or editing Python (.py) files. Behavioral corrections for error handling, resource management, async patterns, data modeling, type safety, security defaults, and common antipatterns. Project conventions always override these defaults.
---

# Python Coding

Match the project's existing conventions. When uncertain, read 2-3 existing modules to infer the local style. Check `pyproject.toml` for Python version target, linter config, and tooling. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and vulnerabilities regardless of project style.

- **Never `except: pass`** or bare `except Exception` without re-raise. Catch specific exception types. Broad catches silently swallow bugs — a `KeyError` from a typo looks the same as a network failure, and you'll spend hours debugging something the traceback would have told you instantly.
- **Never `datetime.now()` or `datetime.utcnow()`** -- both produce naive datetimes that lose timezone info. Naive datetimes cause subtle bugs when code crosses timezone boundaries (servers, users, DST). Use `datetime.now(tz=timezone.utc)`. Use `zoneinfo.ZoneInfo` for other timezones, not `pytz`.
- **Never `random` for security** -- `random` uses a predictable PRNG; an attacker who observes a few outputs can predict future ones. Use `secrets.token_hex()`, `secrets.token_urlsafe()`, or `secrets.token_bytes()` for tokens, keys, session IDs.
- **Never `shell=True` in `subprocess`** -- shell interpretation enables command injection if any argument contains user input. Use argument lists: `subprocess.run(["cmd", arg1, arg2])`.
- **Never string formatting in SQL** -- SQL injection is one of the most exploited vulnerabilities. Use parameterized queries only. `f"SELECT * FROM users WHERE id = {uid}"` is always a defect.
- **Never `yaml.load()`** without `SafeLoader` -- use `yaml.safe_load()`. Unsafe YAML loading deserializes arbitrary Python objects, enabling remote code execution from a crafted YAML file.
- **Never `pickle.load()` on untrusted data** -- pickle executes arbitrary code during deserialization by design. Use JSON, MessagePack, or Protocol Buffers for data interchange.
- **Never `eval()` or `exec()` on external input** -- use `ast.literal_eval()` for safe evaluation of literals.
- **Never mutable default arguments** -- `def f(items=[])` shares one list across all calls. Appending in one call mutates the default for every subsequent call. Use `None` sentinel: `def f(items: list[str] | None = None)` then `items = items or []`.
- **Never shadow builtins** -- don't use `list`, `dict`, `id`, `type`, `input`, `hash`, `map`, `set`, `filter` as variable names. Shadowing causes confusing errors when you later need the builtin in the same scope.
- **Never blocking calls in async** -- no `time.sleep()`, bare `open()`, or `requests.get()` inside `async def`. These block the entire event loop, freezing all concurrent tasks. Use `asyncio.sleep()`, `aiofiles`, `httpx`.
- **Never `+=` string concatenation in loops** -- use `"".join(parts)`. Python strings are immutable, so each `+=` allocates a new string and copies all previous content — O(n²) at scale. At 10k iterations this turns milliseconds into seconds.

## Error handling

Always use `raise ... from e` when re-raising at I/O boundaries. This preserves the original traceback -- essential for production debugging. Use `raise ... from None` only when the original exception is genuinely irrelevant to the caller.

```python
async def get_user(user_id: int) -> User:
    try:
        result = await db.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
    except asyncpg.PostgresError as e:
        raise DatabaseError(f"Failed to query user {user_id}") from e
    if result is None:
        raise UserNotFoundError(user_id)
    return User(**result)
```

Create custom exception types when callers need to distinguish failure modes:

```python
class AppError(Exception):
    """Base exception."""

class NotFoundError(AppError):
    def __init__(self, resource: str, id: Any) -> None:
        self.resource = resource
        self.id = id
        super().__init__(f"{resource} not found: {id}")
```

When logging a caught exception, always preserve the traceback:

```python
# Wrong: traceback lost
except httpx.HTTPStatusError as e:
    logger.error(f"API call failed: {e}")
    raise

# Correct: logger.exception() includes full traceback
except httpx.HTTPStatusError:
    logger.exception("API call failed")
    raise
```

Use `exc_info=True` for non-error log levels: `logger.warning("retrying", exc_info=True)`.

## Resource cleanup

Use context managers for anything that needs cleanup -- clients, connections, file handles. Never instantiate `httpx.AsyncClient()`, database pools, or similar without a context manager or explicit `finally` cleanup.

For managing multiple async resources, use `AsyncExitStack`:

```python
from contextlib import AsyncExitStack

async def setup_resources() -> AsyncIterator[Resources]:
    async with AsyncExitStack() as stack:
        db = await stack.enter_async_context(create_pool(dsn))
        cache = await stack.enter_async_context(create_redis(url))
        yield Resources(db=db, cache=cache)
```

For custom resource lifecycles where no built-in context manager exists:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_session(config: Config) -> AsyncIterator[Session]:
    session = await Session.connect(config)
    try:
        yield session
    finally:
        await session.disconnect()
```

## Async patterns

**Prefer `TaskGroup` (3.11+) over `gather` for most concurrent work.** TaskGroup enforces structured concurrency: if one task fails, siblings are cancelled and errors are raised as `ExceptionGroup`. `gather(return_exceptions=True)` silently mixes exceptions into results, which is error-prone. Use `gather` when you genuinely need partial results despite failures, or when targeting Python < 3.11.

```python
async with asyncio.TaskGroup() as tg:
    task1 = tg.create_task(fetch_users())
    task2 = tg.create_task(fetch_orders())
# Both guaranteed complete here. If either failed, ExceptionGroup is raised.

# Handle multiple failure types with except*
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(operation_a())
        tg.create_task(operation_b())
except* ConnectionError as eg:
    for exc in eg.exceptions:
        logger.error(f"Connection failed: {exc}")
except* ValueError as eg:
    for exc in eg.exceptions:
        logger.error(f"Validation failed: {exc}")
```

Share a single `AsyncClient` across concurrent requests -- don't create one per call. Configure timeouts explicitly:

```python
async with httpx.AsyncClient(base_url="https://api.example.com", timeout=30.0) as client:
    async with asyncio.TaskGroup() as tg:
        task1 = tg.create_task(client.get("/users"))
        task2 = tg.create_task(client.get("/orders"))
```

## Type hints

Use modern syntax: `list[str]`, `dict[str, Any]`, `X | None`. Use native type parameter syntax when the project targets 3.12+; fall back to `TypeVar` for older targets.

```python
class Repository[T]:
    def __init__(self, model_class: type[T]) -> None:
        self._model_class = model_class
        self._items: dict[int, T] = {}

    def get(self, id: int) -> T | None:
        return self._items.get(id)
```

**Use `object` instead of `Any`** when you mean "accepts anything." `Any` silently disables type checking -- it's a hole in type safety. Reserve `Any` for when the type system genuinely cannot express something.

**Covariant inputs, concrete outputs.** Function parameters should accept abstract types (`Sequence`, `Mapping`, `Iterable`); return types should be concrete (`list`, `dict`):

```python
from collections.abc import Sequence, Mapping

def process_items(items: Sequence[str]) -> list[str]:  # accepts tuple, list, etc.
    return [item.upper() for item in items]

def merge_configs(base: Mapping[str, Any], override: Mapping[str, Any]) -> dict[str, Any]:
    return {**base, **override}
```

**Use `TYPE_CHECKING` for import-only types.** When a type is only needed for annotations (not at runtime), import it under `TYPE_CHECKING` to avoid circular imports and reduce startup cost:

```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from myapp.services import PaymentService

class OrderProcessor:
    def __init__(self, payments: PaymentService) -> None:
        self._payments = payments
```

## Pattern matching

Use `match`/`case` (3.10+) when branching on structure — it's clearer than if/elif chains for destructuring dicts, tuples, or typed objects. Don't use it as a substitute for simple value comparisons where `if/elif` reads fine.

```python
match event:
    case {"type": "click", "target": target}:
        handle_click(target)
    case {"type": "scroll", "offset": int(offset)} if offset > 0:
        handle_scroll(offset)
    case _:
        logger.warning("Unhandled event: %s", event.get("type"))
```

## Data modeling

| Use Case | Choice | Reason |
|----------|--------|--------|
| API request/response | Pydantic | Validation, serialization, OpenAPI |
| Config from env/files | Pydantic | Built-in settings management |
| Internal data transfer | dataclass | Lighter weight, no runtime validation |
| Simple value objects | dataclass | Minimal boilerplate |

Pydantic at system boundaries:

```python
class UserCreate(BaseModel):
    email: str = Field(..., min_length=5)
    name: str = Field(..., min_length=1, max_length=100)

class UserResponse(BaseModel):
    id: int
    email: str
    model_config = {"from_attributes": True}
```

Dataclasses internally. Use `frozen=True` for value objects, `slots=True` when you have many instances:

```python
@dataclass(frozen=True, slots=True)
class CacheKey:
    namespace: str
    id: str
```

## Dependency injection

Constructor injection. Dependencies are explicit, testable, and swappable.

```python
class UserService:
    def __init__(self, repository: UserRepository, email_client: EmailClient) -> None:
        self._repository = repository
        self._email_client = email_client
```

## Protocol

Use Protocol for structural interfaces -- duck typing with full type safety, no inheritance required.

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Serializable(Protocol):
    def to_dict(self) -> dict[str, Any]: ...
```

## Enums

Use `StrEnum` instead of raw string literals for known value sets. Catches typos at type-check time. Use `IntEnum` only when interfacing with systems that require integer codes.

```python
from enum import StrEnum, unique

@unique
class OrderStatus(StrEnum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
```

## Imports

Import order: standard library, third-party, local. Define `__all__` if the project convention uses it. Use `pathlib.Path` over `os.path`. No import-time side effects -- don't connect to databases, read files, or run computations at module level. Defer to first use.

## Retry logic

Use tenacity for transient errors: network failures, rate limits, 5xx responses. Let 4xx errors propagate -- they indicate a request problem, not a transient failure.

```python
@retry(
    retry=retry_if_exception_type((httpx.RequestError, httpx.HTTPStatusError)),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,
)
async def fetch_with_retry(url: str) -> dict[str, Any]:
    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=30.0)
        response.raise_for_status()
        return response.json()
```

## Logging

Match the project's logging library (stdlib `logging`, `structlog`, etc.). With stdlib, use `__name__` and pass structured data via `extra`:

```python
logger = logging.getLogger(__name__)
logger.info("User created", extra={"user_id": user.id})
```

## Testing

Match the project's test runner and async plugin. Check for `pytest-asyncio` `mode = "auto"` (no manual `@pytest.mark.asyncio` needed) or `anyio`-based setup.

When to mock: external APIs with rate limits/costs, error paths, deterministic results. When to use real services: verifying actual integration behavior, sandbox/test modes available. Test behavior, not implementation -- test what a function returns, not how it does it internally.
