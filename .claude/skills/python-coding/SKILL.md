---
name: python-coding
description: Apply when writing or editing Python (.py) files. Behavioral corrections for error handling, async patterns, resource management, data modeling, type safety, security defaults, and common antipatterns.
---

# Python Coding

Project conventions override these defaults. Read 2-3 nearby modules and `pyproject.toml` (Python target, linter, tooling) before writing.

## Never rules

- **Never `except: pass`**, and never a broad `except Exception` without re-raise or logging. Catch specific types; a broad catch makes a typo-induced `KeyError` look like a network failure.
- **Never use naive datetimes.** `datetime.now()` and `datetime.utcnow()` (deprecated since 3.12) return naive values. Use `datetime.now(tz=timezone.utc)`, and `zoneinfo.ZoneInfo` rather than `pytz` for other zones.
- **Never `random` for tokens, keys, or session IDs.** Use `secrets`.
- **Never `shell=True` when any argument can contain external input.** Pass an argument list.
- **Never trust external input in parsers or queries.** Parameterize SQL instead of formatting strings, use `yaml.safe_load`, never `pickle.load` untrusted data, and never `eval`/`exec` external input (`ast.literal_eval` for literals).
- **Never block the event loop in `async def`.** No `time.sleep()`, `requests`, or synchronous file I/O. Use `asyncio.sleep()`, `httpx`, or `asyncio.to_thread()`.

## Error handling

Re-raise at I/O boundaries with `raise ... from e` to keep the original traceback. Use `from None` only when the cause is irrelevant to the caller. Define custom exception types when callers must tell failure modes apart.

```python
try:
    result = await db.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
except asyncpg.PostgresError as e:
    raise DatabaseError(f"Failed to query user {user_id}") from e
```

Log a caught exception with its traceback: `logger.exception("API call failed")` inside the `except` block, or `exc_info=True` at lower levels. `logger.error(f"...{e}")` loses the traceback.

## Resource cleanup

Use a context manager (or `finally`) for every client, connection pool, and file handle; never create `httpx.AsyncClient()` or a pool bare. Use `AsyncExitStack` when entering several async resources in one function.

## Async patterns

Prefer `asyncio.TaskGroup` (3.11+) over `gather`. A failing task cancels its siblings and raises an `ExceptionGroup`, handled with `except*`. `gather(return_exceptions=True)` mixes exceptions into results; use `gather` only when partial results matter or the target is below 3.11.

Share one `httpx.AsyncClient` with an explicit `timeout` across concurrent requests instead of creating one per call.

```python
async with httpx.AsyncClient(base_url=BASE_URL, timeout=30.0) as client:
    async with asyncio.TaskGroup() as tg:
        users = tg.create_task(client.get("/users"))
        orders = tg.create_task(client.get("/orders"))
```

## Type hints

- Use `object`, not `Any`, for "accepts anything". `Any` disables checking; reserve it for what the type system cannot express.
- Accept abstract types in parameters (`Sequence`, `Mapping`, `Iterable`) and return concrete ones (`list`, `dict`).
- Use `class Repository[T]` syntax when the project targets 3.12+, `TypeVar` otherwise.

## Data modeling

| Use case | Choice |
|----------|--------|
| API request/response, config from env or files | Pydantic (validation at the boundary) |
| Internal data transfer, value objects | dataclass; `frozen=True` for value objects, `slots=True` for many instances |
| Fixed value sets | `StrEnum` (`IntEnum` only for integer codes required by other systems) |

## Retries

Retry only transient failures (network errors, 429, 5xx) with tenacity; let other 4xx errors propagate. Pass the shared client into the retried function so each attempt reuses the connection pool.

```python
def _is_transient(e: BaseException) -> bool:
    if isinstance(e, httpx.HTTPStatusError):
        return e.response.status_code >= 500 or e.response.status_code == 429
    return isinstance(e, httpx.RequestError)

@retry(
    retry=retry_if_exception(_is_transient),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True,
)
async def fetch(client: httpx.AsyncClient, url: str) -> dict[str, Any]:
    response = await client.get(url)
    response.raise_for_status()
    return response.json()
```

## Imports and testing

- Use `pathlib.Path` over `os.path`. Keep imports free of side effects (no connections, file reads, or computation at module level).
- Match the project's test runner and async plugin (`pytest-asyncio` `mode = "auto"` needs no `@pytest.mark.asyncio`; check for an `anyio` setup).
