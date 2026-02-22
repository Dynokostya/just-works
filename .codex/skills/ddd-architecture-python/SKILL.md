---
name: ddd-architecture-python
description: Apply when implementing Domain-Driven Design patterns in Python (.py) files. Covers tactical patterns (entities, value objects, aggregates, domain events, repositories), layered architecture with dependency inversion, persistence strategies, validation boundaries, and common DDD anti-patterns. Best suited for projects with complex business rules spanning multiple entities.
---

# Domain-Driven Design in Python

Match the project's existing domain model conventions. When uncertain, read 2-3 existing aggregate or entity modules to infer the local style. Check for existing base classes, event infrastructure, and repository patterns before introducing new ones. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent structural defects regardless of project style.

- **Never put business logic in service layers while domain models are empty data bags.** This is the anemic domain model. If all methods live in services and entities are just data carriers, you have Transaction Scripts with extra mapping cost. Move behavior that enforces invariants into the entity or aggregate that owns the state.
- **Never create repositories for anything other than aggregate roots.** Repositories exist per aggregate root, not per entity. Accessing child entities bypassing the aggregate root breaks consistency boundaries. `OrderLineRepository` is always wrong if `OrderLine` belongs to an `Order` aggregate.
- **Never use `@dataclass(frozen=True)` for entities.** Frozen dataclasses enforce structural equality (compare all fields). Entities have identity -- two `User` objects with the same `id` are the same user even if `email` changed. Use `@dataclass(eq=False, slots=True)` and implement identity-based `__eq__` and `__hash__` on the id field.
- **Never use `unsafe_hash=True` on mutable dataclasses.** It makes mutable objects hashable, causing subtle bugs when attributes change after insertion into sets or dict keys. Use frozen for value objects, custom hash for entities.
- **Never let domain models import from infrastructure.** The dependency arrow points inward: infrastructure -> application -> domain. Domain models must not import SQLAlchemy, Pydantic, httpx, or any external framework.
- **Never duplicate validation between API layer and domain layer.** Pydantic validates input shape at the boundary (type coercion, required fields). Domain validates business invariants (order total can't be negative, user can't have more than 5 active subscriptions). These are different concerns.
- **Never apply tactical DDD patterns to CRUD-only modules.** If a bounded context has no business invariants beyond "save and retrieve," use plain service functions or direct ORM operations. Strategic DDD (bounded contexts, ubiquitous language) is almost always valuable; tactical DDD is conditional.

## Tactical patterns

| Pattern | Python Implementation | Use When | Skip When |
|---------|----------------------|----------|-----------|
| **Value Object** | `@dataclass(frozen=True, slots=True)` | Equality by value (Money, Email, DateRange) | Simple strings/ints with no validation |
| **Entity** | `@dataclass(eq=False, slots=True)` + custom `__eq__`/`__hash__` on id | Objects with lifecycle and identity | Lookup tables, config records |
| **Aggregate Root** | Entity + `_events: list[Event]` + invariant methods | Multi-entity consistency boundaries | Single-entity modules |
| **Domain Event** | `@dataclass(frozen=True)` inheriting from `Event` base | Side effects: notifications, indexing, cross-context sync | Simple CRUD with no cross-context effects |
| **Repository** | Protocol in domain, implementation in infrastructure | Aggregate root persistence abstraction | Simple modules -- use ORM directly |
| **Domain Service** | Plain function or class in domain layer | Logic spanning multiple aggregates | Logic that belongs on a single entity |
| **Application Service** | Orchestrates repositories, domain objects, UoW | Use case coordination | Don't mix with domain logic |
| **Factory** | `@classmethod` on entity or aggregate | Complex construction with invariants | Simple `__init__` suffices |

### Value object

```python
@dataclass(frozen=True, slots=True)
class Money:
    amount: Decimal
    currency: str

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")
        if len(self.currency) != 3:
            raise ValueError("Currency must be ISO 4217 code")

    def add(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise ValueError(f"Cannot add {self.currency} to {other.currency}")
        return Money(amount=self.amount + other.amount, currency=self.currency)
```

### Entity with identity equality

```python
@dataclass(eq=False, slots=True)
class Order:
    id: int
    customer_id: int
    lines: list[OrderLine]
    status: OrderStatus
    _events: list[Event] = field(default_factory=list, repr=False)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Order):
            return NotImplemented
        return self.id == other.id

    def __hash__(self) -> int:
        return hash(self.id)

    def add_line(self, sku: str, qty: int, price: Money) -> None:
        if self.status != OrderStatus.DRAFT:
            raise OrderFinalizedError(self.id)
        line = OrderLine(sku=sku, qty=qty, price=price)
        self.lines.append(line)

    def confirm(self) -> None:
        if not self.lines:
            raise EmptyOrderError(self.id)
        self.status = OrderStatus.CONFIRMED
        self._events.append(OrderConfirmed(order_id=self.id))

    def collect_events(self) -> list[Event]:
        events = self._events[:]
        self._events.clear()
        return events
```

Wrong -- frozen dataclass for an entity:

```python
# WRONG: frozen enforces structural equality, entities have identity
@dataclass(frozen=True, slots=True)
class Order:
    id: int
    customer_id: int
    status: OrderStatus  # can't mutate status transitions
```

## Persistence strategy

Three approaches, ordered by coupling:

| Strategy | Tradeoff | Use When |
|----------|----------|----------|
| **Domain models = ORM models** | Coupling to SQLAlchemy, but zero mapping | <3 aggregates, team <3, domain is simple |
| **Imperative mapping** (`map_imperatively`) | Clean separation, moderate setup | Business logic complex enough to test without DB |
| **Separate models + manual mapping** | Full isolation, high boilerplate | Domain and persistence schemas diverge significantly |

Start with Strategy A. Move to Strategy B when you need to unit-test domain logic without touching the database. Move to Strategy C only when the persistence schema genuinely differs from the domain model.

### Imperative mapping

```python
# domain/model.py -- pure Python, no SQLAlchemy imports
@dataclass(eq=False, slots=True)
class Product:
    id: int
    sku: str
    batches: list[Batch]

# infrastructure/orm.py -- SQLAlchemy mapping, called once at startup
from sqlalchemy import Table, Column, Integer, String
from sqlalchemy.orm import registry, relationship

mapper_registry = registry()

product_table = Table(
    "products",
    mapper_registry.metadata,
    Column("id", Integer, primary_key=True),
    Column("sku", String(255)),
)

def start_mappers() -> None:
    mapper_registry.map_imperatively(Product, product_table, properties={
        "batches": relationship(Batch),
    })
```

## Dependency inversion

| Mechanism | Use When |
|-----------|----------|
| **Protocol** | Domain ports consumed by application/infrastructure. No inheritance required. |
| **ABC** | Infrastructure base classes where implementations share common behavior |
| **Constructor args** | Default for everything. Explicit, testable, no framework. |
| **FastAPI Depends** | Request-scoped injection in web handlers |

Protocol for domain ports, constructor injection for wiring:

```python
# domain/ports.py
from typing import Protocol

class OrderRepository(Protocol):
    async def get(self, order_id: int) -> Order: ...
    async def save(self, order: Order) -> None: ...

# application/services.py
class ConfirmOrderHandler:
    def __init__(self, repo: OrderRepository, bus: MessageBus) -> None:
        self._repo = repo
        self._bus = bus

    async def handle(self, command: ConfirmOrder) -> None:
        order = await self._repo.get(command.order_id)
        order.confirm()
        await self._repo.save(order)
        for event in order.collect_events():
            await self._bus.publish(event)
```

Wrong -- generic repository with leaked ORM abstractions:

```python
# WRONG: this is a leaked ORM, not a domain repository
class Repository[T]:
    async def filter(self, **kwargs: Any) -> list[T]: ...
    async def all(self) -> list[T]: ...

# RIGHT: domain-meaningful methods
class OrderRepository(Protocol):
    async def get(self, order_id: int) -> Order: ...
    async def get_pending_orders(self) -> list[Order]: ...
    async def save(self, order: Order) -> None: ...
```

## Domain events

Use `@dataclass(frozen=True)` events collected on aggregates. Dispatch via a simple message bus.

```python
# domain/events.py
@dataclass(frozen=True)
class Event:
    pass

@dataclass(frozen=True)
class OrderConfirmed(Event):
    order_id: int

# infrastructure/messagebus.py
EVENT_HANDLERS: dict[type[Event], list[Callable]] = {
    OrderConfirmed: [send_confirmation_email, update_inventory],
}

async def handle(event: Event) -> None:
    for handler in EVENT_HANDLERS.get(type(event), []):
        await handler(event)
```

Domain events are in-process. Integration events cross service boundaries via message queues -- different concern, different infrastructure.

## Validation layers

| Layer | Responsibility | Tool |
|-------|---------------|------|
| **API boundary** | Shape, types, required fields | Pydantic `BaseModel` |
| **Domain** | Business invariants | Entity/aggregate methods, `__post_init__` |
| **Cross-aggregate** | Multi-aggregate rules | Domain services |

Don't validate the same thing twice. Pydantic checks "is this a valid email string." Domain checks "can this user register with this email given their account state."

## Project structure

### Pragmatic DDD (start here)

```
src/
├── ordering/                  # Bounded context = package
│   ├── domain/
│   │   ├── model.py           # Entities, VOs, aggregates
│   │   ├── events.py          # Domain events
│   │   └── ports.py           # Repository protocols
│   ├── application/
│   │   └── handlers.py        # Command/query handlers (thin)
│   ├── infrastructure/
│   │   ├── orm.py             # SQLAlchemy mapping
│   │   └── repository.py      # Repository implementations
│   └── interface/
│       ├── router.py          # FastAPI routes
│       └── schemas.py         # Pydantic request/response
├── shared/
│   ├── messagebus.py          # Event dispatch
│   └── uow.py                # Unit of Work
└── main.py
```

Import rules: interface -> application -> domain. Infrastructure -> domain (implements ports). Domain imports nothing from other layers.

### Simple DDD (CRUD-heavy bounded contexts)

```
src/
├── notifications/             # Simple context -- no tactical DDD
│   ├── router.py
│   ├── schemas.py
│   ├── service.py             # Business logic (thin)
│   └── models.py              # ORM models directly
```

Not every bounded context needs full DDD. Apply tactical patterns where business rules are complex.

## When to use DDD

| Criterion | Use DDD | Skip DDD |
|-----------|---------|----------|
| Business invariants | Span multiple entities, enforced transactionally | Single-entity CRUD |
| Domain complexity | Domain experts disagree on rules | Rules fit on one page |
| Team size | 3+ developers, domain knowledge distributed | Solo developer, full context in head |
| Change frequency | Business rules change independently of tech | Schema-driven CRUD, logic is trivial |
| Bounded contexts | 2+ contexts with different models of same concept | Monolithic domain, single model |

## Anti-patterns

- **Anemic domain model.** All logic in services, entities are bags of data. You have Transaction Scripts with extra mapping cost.
- **Repository per entity.** Repositories exist only for aggregate roots. `UserRepository`, `OrderRepository` -- yes. `OrderLineRepository` -- no.
- **DDD theater.** Using vocabulary (aggregate, bounded context, ubiquitous language) without actually modeling the domain. If your "aggregates" don't enforce any invariants, they're just database records.
- **Over-abstraction.** `IUserRepositoryFactory`, `AbstractDomainServiceBase` -- Python doesn't need this. Protocol + constructor injection is the ceiling.
- **Premature event sourcing.** Event sourcing is a persistence strategy, not a default. Use it when you need a full audit log or temporal queries. For everything else, it adds rebuild complexity, eventual consistency headaches, and schema evolution pain.
- **Wrong aggregate boundaries.** If you load an aggregate and it pulls 50 related entities from the database, the boundary is too wide. If you can't enforce a business rule without loading two aggregates, the boundary is too narrow or the rule belongs in a domain service.
- **Generic repository.** `Repository[T]` with `.filter()` and `.all()` is a leaked ORM abstraction. Repositories expose domain-meaningful methods: `get_pending_orders()`, not `filter(status="pending")`.
- **Pydantic in domain layer.** Domain models should be pure Python (dataclasses). Pydantic belongs at system boundaries. Coupling domain logic to Pydantic makes unit testing slower and ties domain evolution to a serialization library.
- **Importing Java/C# patterns wholesale.** Python has no interfaces, no private fields, no explicit getters/setters. Use Protocol (not Interface), `_convention` (not private fields), properties only when computation is needed.
