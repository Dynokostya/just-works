---
name: typescript-coding
description: Apply when writing or editing TypeScript (.ts and .tsx) files — language-level rules; React-specific patterns live in react-coding. Behavioral corrections for error handling, async patterns, type system, module system, security defaults, and common antipatterns. Project conventions always override these defaults.
---

# TypeScript Coding

Match the project's existing conventions. When uncertain, read 2-3 existing files to infer the local style. Check `tsconfig.json` for `strict` mode, `target`, `module`, and `moduleResolution` settings. Check `package.json` for runtime (Node.js, Deno, Bun) and dependency versions. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and vulnerabilities regardless of project style.

- **Never use `any`** — contagious type erasure that disables all downstream checking. Use `unknown` and narrow with type guards, or use generics with constraints.
- **Never use `@ts-ignore`** — permanently suppresses errors with no feedback when conditions change. Use `@ts-expect-error` with a justification comment; it fails the build when the suppressed error disappears.
- **Never use `as` type assertions on external data** — zero runtime validation; the program continues with corrupted state until it crashes far from the source. Validate at system boundaries with Zod `safeParse` or equivalent runtime validators.
- **Never use `!` non-null assertion without proof** — tells TypeScript a value is not `null` without any runtime check. Use nullish coalescing (`??`), optional chaining (`?.`), or explicit `if` checks.
- **Never leave a Promise floating** — unhandled rejections cause silent failures or process termination. Always `await`, chain `.catch()`, or prefix with `void` and add an error handler.
- **Never mutate function parameters** — objects and arrays are passed by reference; mutation silently corrupts the caller's data. Spread or `structuredClone()` before mutating. Mark parameters `readonly`.
- **Never use `delete` on typed objects** — violates the type contract, creating objects that no longer match their type. Destructure to omit properties (`const { removed, ...rest } = obj`). For arrays, use `splice()` or `filter()`.
- **Never use `export *` in barrel files** — re-exported names collide silently across modules, and IDE navigation and refactoring degrade (go-to-definition lands on the barrel, renames miss consumers). Use explicit named re-exports.
- **Never omit `type` on type-only imports** — retains unnecessary import statements in compiled output, bloats bundles, and breaks isolated transpilers. Use `import type { }` or inline `type` qualifiers. Enable `verbatimModuleSyntax`.
- **Never use `enum`** — emits runtime IIFE code, introduces nominal typing friction, and numeric enums silently accept any number. Use `as const` objects with derived union types.
- **Never trust array index access without `noUncheckedIndexedAccess`** — TypeScript types `items[0]` as `T` even when the array could be empty. Enable `noUncheckedIndexedAccess: true` in tsconfig.
- **Never skip exhaustiveness checks in switch/union handling** — adding a new union member silently falls through without a compile error. Add a `default` case that assigns to `never`: `const _exhaustive: never = value`.
- **Never use `JSON.parse()` without runtime validation at system boundaries** — returns `any`, and assigning to a typed variable provides zero runtime guarantees. Validate with Zod `safeParse` or equivalent.

## Error handling

Use custom error classes with a machine-readable `code` and `cause` support:

```typescript
class AppError extends Error {
  constructor(
    message: string,
    readonly code: string,
    options?: ErrorOptions,
  ) {
    super(message, options);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} ${id} not found`, 'NOT_FOUND');
  }
}
```

Catch blocks receive `unknown` — always narrow before accessing properties:

```typescript
try {
  await fetchUser(id);
} catch (error) {
  if (error instanceof NotFoundError) {
    return null;
  }
  throw new AppError('Failed to fetch user', 'FETCH_ERROR', { cause: error });
}
```

Result pattern using discriminated unions for expected domain failures:

```typescript
type Result<T, E = Error> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly error: E };

function parseConfig(raw: string): Result<Config, ValidationError> {
  const parsed = ConfigSchema.safeParse(JSON.parse(raw));
  if (!parsed.success) {
    return { ok: false, error: new ValidationError(parsed.error) };
  }
  return { ok: true, value: parsed.data };
}
```

Chain error causes (ES2022) to preserve the original stack:

```typescript
throw new AppError('Order processing failed', 'ORDER_ERROR', { cause: error });
```

| Situation | Strategy | Reason |
|-----------|----------|--------|
| Programmer mistake (bad argument) | `throw` | Fail fast, fix the bug |
| Expected domain failure (not found, validation) | `Result` | Caller must handle it |
| Public API boundary | `Result` | Explicit contract, no surprise throws |
| Internal implementation | `throw` | Simpler, caught at boundary |

## Resource cleanup

`using` / `await using` (TypeScript 5.2+) with `Symbol.dispose` / `Symbol.asyncDispose` is the preferred pattern — cleanup runs automatically when the scope exits:

```typescript
class TempFile implements Disposable {
  readonly path: string;

  constructor(prefix: string) {
    this.path = `${tmpdir()}/${prefix}-${Date.now()}`;
    writeFileSync(this.path, '');
  }

  [Symbol.dispose](): void {
    rmSync(this.path, { force: true });
  }
}

function processData(): void {
  using tmp = new TempFile('data');
  writeFileSync(tmp.path, serialize(data));
  transform(tmp.path);
  // tmp is disposed here, even on throw
}
```

`AbortSignal` as universal cancellation token — use `AbortSignal.timeout(ms)` instead of manual `AbortController` + `setTimeout` bookkeeping, and `AbortSignal.any([...])` to compose signals:

```typescript
async function fetchWithTimeout(url: string, ms: number, signal?: AbortSignal): Promise<Response> {
  const timeout = AbortSignal.timeout(ms);
  return fetch(url, { signal: signal ? AbortSignal.any([signal, timeout]) : timeout });
}
```

Event listener cleanup with `{ signal }`:

```typescript
const controller = new AbortController();
element.addEventListener('click', handleClick, { signal: controller.signal });
element.addEventListener('keydown', handleKey, { signal: controller.signal });
// cleanup all at once:
controller.abort();
```

Use `try/finally` as fallback when `using` is not available.

## Async patterns

Promise combinators — pick the right one:

| Combinator | Settles when | Use case |
|------------|-------------|----------|
| `Promise.all` | All fulfill (or first reject) | Independent concurrent work, fail fast |
| `Promise.allSettled` | All settle | Batch operations where partial success is OK |
| `Promise.race` | First settles | Timeout racing, first-response-wins |
| `Promise.any` | First fulfills (or all reject) | Fallback chains, redundant sources |

Concurrent execution for independent work — avoid sequential `await` in loops:

```typescript
// Bad: sequential, N round trips
for (const id of ids) {
  const user = await fetchUser(id);
  results.push(user);
}

// Good: concurrent
const results = await Promise.all(ids.map((id) => fetchUser(id)));
```

Propagate `AbortSignal` through call chains:

```typescript
async function processOrder(
  orderId: string,
  signal?: AbortSignal,
): Promise<Order> {
  signal?.throwIfAborted();
  const order = await fetchOrder(orderId, { signal });
  const validated = await validateInventory(order, { signal });
  return await chargePayment(validated, { signal });
}
```

Async generators for paginated or streaming data:

```typescript
async function* fetchPages<T>(
  url: string,
  signal?: AbortSignal,
): AsyncGenerator<T[]> {
  let cursor: string | undefined;

  do {
    const params = cursor ? `?cursor=${cursor}` : '';
    const res = await fetch(`${url}${params}`, { signal });
    const data = PageSchema.parse(await res.json());
    yield data.items;
    cursor = data.nextCursor;
  } while (cursor);
}

for await (const page of fetchPages<User>('/api/users', signal)) {
  await processBatch(page);
}
```

Concurrency limiting — prefer `p-limit`; hand-rolled limiters routinely get ordering and rejection handling wrong (the common `results.push(...)` + floating `.finally()` version returns completion order and leaks unhandled rejections):

```typescript
import pLimit from 'p-limit';

const limit = pLimit(5);
const users = await Promise.all(ids.map((id) => limit(() => fetchUser(id))));
```

Dependency-free alternative — a fixed worker pool over a shared iterator. Indexed writes preserve input order; every worker promise is awaited, so no rejection floats:

```typescript
async function mapConcurrent<T, R>(
  items: readonly T[],
  concurrency: number,
  fn: (item: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  const queue = items.entries();
  const workers = Array.from({ length: Math.min(concurrency, items.length) }, async () => {
    for (const [i, item] of queue) results[i] = await fn(item);
  });
  await Promise.all(workers);
  return results;
}
```

## Type system

Generics with constraints and defaults:

```typescript
function merge<T extends Record<string, unknown>>(
  target: T,
  ...sources: Partial<T>[]
): T {
  return Object.assign({}, target, ...sources);
}

type ApiResponse<T, E = Error> = Result<T, E> & { statusCode: number };
```

Discriminated unions:

```typescript
type Event =
  | { type: 'created'; payload: { id: string } }
  | { type: 'updated'; payload: { id: string; changes: string[] } }
  | { type: 'deleted'; payload: { id: string } };

function handleEvent(event: Event): void {
  switch (event.type) {
    case 'created':
      onCreate(event.payload.id);
      break;
    case 'updated':
      onUpdate(event.payload.id, event.payload.changes);
      break;
    case 'deleted':
      onDelete(event.payload.id);
      break;
  }
}
```

Branded types for domain IDs:

```typescript
type Brand<T, B extends string> = T & { readonly __brand: B };
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

function createUserId(id: string): UserId { return id as UserId; }

function getUser(id: UserId): Promise<User> { /* ... */ }
// getUser(orderId) — compile error, prevents mixing IDs
```

`satisfies` operator (TS 4.9+) — validate without widening:

```typescript
const config = {
  port: 3000,
  host: 'localhost',
  debug: true,
} satisfies Record<string, string | number | boolean>;
// config.port is number, not string | number | boolean
```

`as const` and const type parameters (TS 5.0+):

```typescript
function createRoute<const T extends readonly string[]>(methods: T) {
  return { methods };
}
const route = createRoute(['GET', 'POST']);
// route.methods is readonly ['GET', 'POST'], not string[]
```

## Data modeling

| Use Case | Choice | Reason |
|----------|--------|--------|
| API response/request shape | `type` + Zod schema | Single source of truth with runtime validation |
| Fixed string constants (type only) | String union | Zero runtime cost |
| Fixed string constants (need runtime) | `as const` object + derived union | Tree-shakeable, iterable |
| Object contract for public API | `interface` | Declaration merging, clearer errors |
| Union of different shapes | Discriminated union with `kind` tag | Exhaustive checking, best narrowing |
| Structurally identical but semantically different values | Branded types | Prevents mixing `UserId` with `OrderId` |
| Immutable configuration | `as const` + `Readonly` | Compile-time literal types + immutability |
| Entity with invariants and behavior | Class with private constructor | Constructor enforces rules |

In classes, use `#private` fields for true runtime privacy — TypeScript's `private` keyword is compile-time only.

Zod schema as single source of truth:

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.email(),
  name: z.string().min(1),
  createdAt: z.coerce.date(),
});

type User = z.infer<typeof UserSchema>;
```

`as const` object with derived union:

```typescript
const Status = {
  Active: 'active',
  Inactive: 'inactive',
  Suspended: 'suspended',
} as const;

type Status = (typeof Status)[keyof typeof Status];
// 'active' | 'inactive' | 'suspended'
```

## Pattern matching

Discriminated unions with `switch`:

```typescript
type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'rectangle'; width: number; height: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'rectangle':
      return shape.width * shape.height;
  }
}
```

Type guard functions for filtering and narrowing:

```typescript
function isNonNull<T>(value: T | null | undefined): value is T {
  return value != null;
}

const items = [1, null, 2, undefined, 3].filter(isNonNull);
// items: number[]
```

`x == null` / `x != null` is the one sanctioned loose-equality idiom — it matches both `null` and `undefined` in a single check.

## Module system

ESM as the default — set `"type": "module"` in `package.json`. Use `import type` for type-only imports and enable `verbatimModuleSyntax: true` in tsconfig to enforce it.

```typescript
import type { User, Config } from './types.js';
import { fetchUser } from './api.js';
```

Avoid deep barrel export chains — they slow IDE indexing and obscure module boundaries. One level of barrel at package boundaries is acceptable:

```typescript
// packages/auth/index.ts — acceptable
export { AuthService } from './auth-service.js';
export type { AuthToken, AuthConfig } from './types.js';
```

## Testing

Use Vitest as the default test runner. Use Jest for legacy projects already standardized on it.

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('UserService', () => {
  it('returns user when found', async () => {
    const mockRepo = { findById: vi.fn<(id: string) => Promise<User | null>>() };
    mockRepo.findById.mockResolvedValue({ id: '1', name: 'Alice' });

    const service = new UserService(mockRepo);
    const user = await service.getUser('1');

    expect(user).toEqual({ id: '1', name: 'Alice' });
    expect(mockRepo.findById).toHaveBeenCalledWith('1');
  });
});
```

Mock at boundaries (HTTP, DB, clock), test logic directly. Use the AAA pattern: Arrange (set up data and mocks), Act (call the function), Assert (verify the outcome). Type-safe mocking with `vi.fn()` and `vi.mocked()` — avoid untyped mocks that drift from the real interface.
