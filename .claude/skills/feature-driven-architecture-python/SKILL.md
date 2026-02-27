---
name: feature-driven-architecture-python
description: Apply when structuring Python projects by business capability (vertical slices). Covers directory layout, feature boundaries, inter-feature communication, database model ownership, migration strategies, boundary enforcement, testing across features, and migration from layered architectures. Best suited for FastAPI and Flask projects with 5+ distinct features.
---

# Feature-Driven Architecture

Match the project's existing structure. When uncertain, read 3-5 existing feature directories to infer the local conventions. Check for import-linter or PyTestArch configuration in `pyproject.toml`. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent coupling and boundary erosion regardless of project style.

- **Never import another feature's ORM models directly.** Features own their models. Cross-feature data access goes through the owning feature's service layer or shared read models. `from src.billing.models import Invoice` inside `src.auth/` is always a defect.
- **Never create circular imports between features.** If Feature A imports from Feature B and Feature B imports from Feature A, the feature boundaries are drawn wrong. Refactor using events, a shared service, or merge the features.
- **Never put business logic in routers/views.** Routers handle HTTP concerns (status codes, response formatting). Business logic lives in `service.py` or domain functions within the feature.
- **Never share Pydantic request/response schemas across features.** Each feature defines its own schemas. Identical DTOs in two features today will diverge tomorrow — duplication is cheaper than the wrong shared abstraction.
- **Never skip boundary enforcement tooling.** Setup is 15 minutes — a single `independence` contract in `pyproject.toml` and `lint-imports` in CI. Kraken Technologies found that violations appear even on small teams under deadline pressure, and compound quickly. Code review catches logic issues; import-linter catches structural invariants that are tedious and error-prone to verify manually in diffs.
- **Never use ForeignKey across feature boundaries in new code.** Use plain integer ID fields between features. The referential integrity cost is real but coupling cost is worse. Shared read models are the escape hatch.
- **Never put feature-specific code in the shared layer.** `shared/` or `core/` contains only cross-cutting infrastructure: auth middleware, database session factory, base classes, pagination, response schemas. If it's specific to one feature, it belongs in that feature.
- **Never use `extend_existing=True` for cross-feature read models.** It silently merges column definitions into a shared `Table` object (SQLAlchemy issues #7366, #8925). Use database VIEWs mapped to separate ORM classes instead.

## Directory structure

Each feature is a self-contained Python package:

```
src/
├── auth/
│   ├── __init__.py
│   ├── router.py          # FastAPI APIRouter with endpoints
│   ├── schemas.py         # Pydantic request/response models
│   ├── models.py          # SQLAlchemy/ORM models
│   ├── service.py         # Business logic
│   ├── dependencies.py    # FastAPI Depends() callables
│   ├── exceptions.py      # Feature-specific errors
│   └── tests/
├── billing/
│   └── ...                # Same structure per feature
├── shared/
│   ├── config.py          # Pydantic BaseSettings
│   ├── database.py        # Session factory, Base model
│   ├── middleware.py       # CORS, logging, request tracing
│   └── exceptions.py      # Application-wide exception base classes
└── main.py                # App factory, router registration
```

Not every feature needs every file. A simple CRUD feature might have only `router.py`, `schemas.py`, and `service.py`. A complex domain feature might add `domain.py`, `events.py`, `repository.py`. Let complexity emerge per-slice.

**Key pattern:** Routers delegate to service functions. Services import only their own feature's models and schemas. Wire features in the app factory via `app.include_router()`.

## Inter-feature communication

Four patterns, ordered by coupling (tightest to loosest):

| Pattern | When to use | Example |
|---------|-------------|---------|
| **Direct service import** | Read-only access, simple projects, <5 features | `from src.auth.service import get_user` |
| **FastAPI Depends()** | Request-scoped shared state, auth context | `user = Depends(get_current_user)` |
| **Shared read models** | Cross-feature queries without write coupling | Database VIEWs mapped to read-only ORM classes |
| **Events (pub/sub)** | Fire-and-forget: emails, analytics, indexing | `BackgroundTasks`, blinker `send_async()`, or task queue |

**Default to direct service imports** for small projects. Introduce events only when features genuinely don't need synchronous responses. Don't build event infrastructure speculatively.

**Batch service calls to avoid N+1.** When a feature lists entities that reference another feature's data, always provide a batch method alongside the single-item method:

```python
# src/auth/service.py
async def get_users_by_ids(user_ids: list[int]) -> dict[int, User]:
    """Batch fetch — single query with WHERE id IN (...)."""
    async with get_session() as session:
        stmt = select(User).where(User.id.in_(user_ids))
        result = await session.execute(stmt)
        return {u.id: u for u in result.scalars().all()}
```

```python
# src/billing/service.py — WRONG: N+1 service calls
async def list_invoices_with_users() -> list[InvoiceDetail]:
    invoices = await get_invoices()
    return [
        InvoiceDetail(invoice=inv, user_name=(await get_user_by_id(inv.user_id)).name)
        for inv in invoices  # 1 query per invoice
    ]

# RIGHT: batch fetch — 2 queries total regardless of N
async def list_invoices_with_users() -> list[InvoiceDetail]:
    invoices = await get_invoices()
    users_map = await get_users_by_ids(list({inv.user_id for inv in invoices}))
    return [
        InvoiceDetail(invoice=inv, user_name=users_map[inv.user_id].name)
        for inv in invoices
    ]
```

**FastAPI dependency injection** for cross-feature auth context: define `get_current_user` in `src/auth/dependencies.py`, then inject via `Depends(get_current_user)` in other features' routers. Features import only `dependencies.py`, never auth internals.

**Event-driven decoupling** when synchronous coupling is unacceptable:

| Mechanism | Latency coupling | When to use |
|-----------|-----------------|-------------|
| `blinker send_async()` | Awaits all receivers | Receivers are fast, <50ms each |
| `BackgroundTasks` | None — runs post-response | Side effects the caller doesn't wait for |
| Task queue (Celery, ARQ) | None — separate worker | Retries, persistence, or heavy processing needed |

Prefer `BackgroundTasks` for simple fire-and-forget (emails, analytics). Use `blinker` signals only when you need a publish/subscribe pattern with multiple listeners. Note: `send_async()` still awaits all receivers — it's async but not decoupled. For true fire-and-forget, use `BackgroundTasks` or a task queue.

## Database model ownership

The hardest problem in feature-driven architecture. Three strategies:

| Strategy | Tradeoff | When to use |
|----------|----------|-------------|
| **Feature-private models** | Full isolation, no cross-feature FKs | Distinct data domains (auth, notifications) |
| **ID-based references** | Loses referential integrity, risks N+1 | Features that reference but don't own shared data |
| **Shared read layer** | Adds a shared dependency, but read-only | Heavy cross-feature reporting/querying |

Feature-private models (preferred) — use plain `int` for cross-feature IDs, never `ForeignKey`:

```python
# src/billing/models.py
class Invoice(Base):
    __tablename__ = "invoices"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column()  # plain int, NOT ForeignKey("users.id")
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2))
```

For reporting that needs JOINs across feature boundaries, use database VIEWs with a write-protection mixin:

```python
# src/shared/read_models.py
class ReadOnlyModel:
    """Mixin — prevents accidental writes to VIEW-backed models."""
    pass

@event.listens_for(Session, "before_flush")
def _prevent_readonly_flush(session, flush_context, instances):
    for obj in session.new | session.dirty | session.deleted:
        if isinstance(obj, ReadOnlyModel):
            raise RuntimeError(f"Attempted to write to read-only model {type(obj).__name__}")

class InvoiceWithUser(ReadOnlyModel, Base):
    __tablename__ = "v_invoices_with_users"  # database VIEW, not a table
    id: Mapped[int] = mapped_column(primary_key=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    user_email: Mapped[str]
```

Create the VIEW in an Alembic migration with `op.execute("CREATE VIEW ...")` / `op.execute("DROP VIEW ...")`.

## Migration ownership

When features own their models, someone must own the migration files. Two practical strategies:

**Strategy A: Centralized migrations (start here).** Single `alembic/versions/` directory. Any developer runs `alembic revision --autogenerate`. Simple, linear history, easy CI. Tradeoff: merge conflicts when multiple teams change models simultaneously. Use when team size <5.

**Strategy B: Per-feature directories with branch labels.** Alembic supports `version_locations` for multiple migration directories. Each feature gets a branch label (`--head=base --branch-label=auth --version-path=src/auth/migrations`). Apply all branches with `alembic upgrade heads` (plural). Tradeoff: `autogenerate` cannot auto-detect which feature a model change belongs to. Use when 5+ developers and merge conflicts are frequent.

For strongest isolation (approaching microservice extraction), each feature can use its own PostgreSQL schema — but this has significant infrastructure overhead and is rarely needed.

**CI guard for all strategies:** Always run `alembic upgrade heads` against an empty database in CI.

## Cross-feature testing

Layered testing strategy — per-slice unit tests are straightforward; cross-feature integration is where teams get stuck.

```
tests/
    conftest.py                # Shared factory fixtures (db_session, make_user, make_invoice)
    features/
        auth/
            conftest.py        # Auth-specific fakes and helpers
            test_service.py    # Unit: test with fakes
        billing/
            conftest.py
            test_service.py
    integration/
        test_billing_auth.py   # Integration: billing + auth, real DB
    workflows/
        test_purchase_flow.py  # E2E: full request chain via test client
```

**Layer 1: Unit tests with fakes** (per feature, fast). Each feature tests its service layer in isolation:

```python
# tests/features/billing/test_service.py
class FakeUserService:
    def __init__(self, users: dict[int, User] | None = None):
        self._users = users or {}

    async def get_users_by_ids(self, user_ids: list[int]) -> dict[int, User]:
        return {uid: self._users[uid] for uid in user_ids if uid in self._users}

async def test_list_invoices_includes_user_names(db_session):
    fake_users = FakeUserService(users={1: User(id=1, name="Alice")})
    svc = BillingService(session=db_session, user_service=fake_users)
    invoices = await svc.list_invoices_with_users()
    assert invoices[0].user_name == "Alice"
```

**Layer 2: Integration tests with factory fixtures** (cross-feature, real DB). Shared factory fixtures in root `conftest.py` create real domain objects:

```python
# tests/conftest.py
@pytest.fixture
def make_user(db_session):
    async def _make(email="test@example.com", **kwargs):
        user = User(email=email, **kwargs)
        db_session.add(user)
        await db_session.flush()
        return user
    return _make
```

**Layer 3: Workflow tests** (E2E, real HTTP). Test full request chains through multiple features using the FastAPI test client. Keep these minimal — they're slow and brittle.

**Key rules:**
- Never import a feature's service directly from another feature's tests. Use factory fixtures or fakes.
- Keep feature-specific fixtures in feature-level `conftest.py`. Only cross-feature factories go in root `conftest.py`.
- Separate fast and slow tests with markers: `pytest -m "not integration"` for fast feedback, full suite in CI.
- If using fakes, test them against the same contract as the real implementation to prevent drift.

## Boundary enforcement

**import-linter** — the minimum viable boundary enforcement. Add to `pyproject.toml`:

```toml
[tool.importlinter]
root_package = "src"

[[tool.importlinter.contracts]]
name = "Features are independent"
type = "independence"
modules = [
    "src.auth",
    "src.billing",
    "src.notifications",
]

[[tool.importlinter.contracts]]
name = "Shared layer does not depend on features"
type = "forbidden"
source_modules = ["src.shared"]
forbidden_modules = [
    "src.auth",
    "src.billing",
    "src.notifications",
]
```

Run in CI: `lint-imports`. Add as a pre-commit hook. Alternative: **PyTestArch** for teams that prefer executable architecture tests in pytest.

**Exception to independence:** Features MAY import another feature's `dependencies.py` for FastAPI `Depends()` injection. Configure via `ignore_imports` in the independence contract:

```toml
ignore_imports = [
    "src.billing.router -> src.auth.dependencies",
    "src.notifications.router -> src.auth.dependencies",
]
```

## When to use this pattern

| Use when | Don't use when |
|----------|----------------|
| 5+ distinct business capabilities | Primarily CRUD with minimal logic |
| 3+ developers with team ownership | 1-2 developers touching everything |
| Features change independently | Codebase under 5,000 lines |
| FastAPI or Flask project | Django with tight admin integration |
| Incremental monolith migration | Features share data via complex JOINs |
| Team comfortable with refactoring | Domain boundaries are unclear |

## Migration from layered architecture

Strangler Fig pattern — replace one feature at a time.

**Phase 1: Map.** Identify which files change together. Those clusters are your features. Add integration tests for the first feature to migrate.

**Phase 2: Extract shared.** Create `shared/` with cross-cutting concerns: database session factory, auth middleware, base model classes, response schemas.

**Phase 3: Migrate one feature.** Pick the most isolated feature. Create a new package with router, schemas, service, and models. Wire alongside the old code. Verify with tests. Delete the old code.

**Phase 4: Handle models.** Move models owned by a single feature into that feature's package. For shared models, decide: keep in `shared/data/`, or duplicate with ID-based references.

**Phase 5: Handle migrations.** Start with centralized migrations (Strategy A). Graduate to per-feature branches (Strategy B) when merge conflicts become frequent.

**Phase 6: Enforce.** Add import-linter contracts. Start descriptive, then tighten to enforced. Add to CI.

**Phase 7: Iterate.** Apply Rule of Three for shared logic extraction. Decompose features exceeding ~1,500 lines of business logic. Add events for cross-feature triggers that don't need synchronous responses.

## Anti-patterns

- **Folder-only refactoring.** Moving files into feature directories without restructuring imports and dependencies. "Shuffling folders and calling it VSA" changes nothing.
- **Premature abstraction.** Creating `IUserRepository`, `IOrderService` interfaces for one implementation. Python's Protocols provide structural typing where needed — don't add Java-style ceremony.
- **Per-endpoint slicing.** Creating a directory for every single endpoint (`create_user/`, `get_user/`, `delete_user/`). This mirrors .NET MediatR patterns but is not idiomatic Python. Group by feature, not by operation.
- **Event bus for everything.** Building event infrastructure before you have a single cross-feature trigger that doesn't need a synchronous response. Direct service calls are simpler and debuggable.
- **God feature.** One slice absorbs most business logic. Start with procedural service functions, extract domain classes only when complexity warrants it.
- **Shared model coupling.** Putting all ORM models in a central `models/` directory "for convenience." This recreates the layered architecture you were trying to escape.
- **DRY over independence.** Extracting shared utilities after seeing the same pattern in two features. Wait for three. Duplication is cheaper than the wrong abstraction.
- **N+1 service calls.** Calling `get_user_by_id` in a loop instead of `get_users_by_ids` with `WHERE id IN (...)`. Always provide batch methods for cross-feature data access.
- **Synchronous side effects in signal handlers.** Using blinker `send()` with I/O listeners — this blocks the caller. Use `BackgroundTasks` or a task queue.
