---
name: typescript-coding
description: Apply when writing or editing TypeScript (.ts and .tsx) files — language-level rules; React-specific patterns live in react-coding. Behavioral corrections for error handling, async patterns, type system, module system, security defaults, and common antipatterns.
---

# TypeScript Coding

Project conventions override these defaults. Read 2-3 nearby files, `tsconfig.json` (`strict`, `target`, `module`, `moduleResolution`), and `package.json` (runtime, dependency versions) before writing.

## Never rules

- **Never use `any`.** Use `unknown` and narrow with type guards, or generics with constraints.
- **Never use `@ts-ignore`.** Use `@ts-expect-error` with a reason; it fails the build once the error disappears.
- **Never use `as` on external data** (API responses, `JSON.parse`, storage, env, form data). It performs no runtime check. Validate at the boundary with Zod `safeParse` or an equivalent.
- **Never use `!` without proof.** Prefer `??`, `?.`, or an explicit `if`.
- **Never leave a Promise floating.** `await` it, chain `.catch()`, or `void` it with an error handler.
- **Never mutate parameters or shared objects.** Copy (`structuredClone`, spread) before changing; destructure to omit properties instead of using `delete`.
- **Never use `export *` in barrel files.** Names collide silently and go-to-definition lands on the barrel. Use explicit named re-exports, one barrel level at most, at package boundaries.
- **Never import types without `type`.** Use `import type` or inline `type` qualifiers, and `verbatimModuleSyntax` where the project can enable it.
- **Prefer `as const` objects with a derived union over `enum`.** Enums emit runtime code, numeric enums accept arbitrary numbers, and enums fail under `erasableSyntaxOnly` and Node's type stripping. Keep `enum` where the project already uses it.
- **Never leave a `switch` over a union without an exhaustiveness check.** End with `default: { const _exhaustive: never = value; }`.
- **Treat `items[0]` as possibly `undefined`.** Without `noUncheckedIndexedAccess`, TypeScript types it as `T`. Narrow before use, and suggest the flag in new projects; do not change an existing project's `tsconfig.json` unprompted.

## Error handling

Use `throw` for programmer mistakes and internal code. Use a `Result` discriminated union for expected domain failures and public API boundaries, so the caller must handle them. When wrapping an error, pass `{ cause: error }` (`new Error(msg, { cause: error })`, or a custom error class with a machine-readable `code`) to keep the original stack. `catch (error)` is `unknown`: narrow with `instanceof` before reading properties.

```typescript
type Result<T, E = Error> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly error: E };
```

## Resource cleanup

Prefer `using` / `await using` (TS 5.2+, `Symbol.dispose` / `Symbol.asyncDispose`); fall back to `try/finally` where unavailable. For cancellation, use `AbortSignal.timeout(ms)` and `AbortSignal.any([...])` rather than manual `AbortController` plus `setTimeout`, pass the signal through call chains, and register event listeners with `{ signal }` so one `abort()` removes them all.

## Async patterns

- Run independent work concurrently with `Promise.all`, not `await` inside a loop. Use `allSettled` when partial success is acceptable.
- Limit concurrency with `p-limit`. Hand-rolled limiters usually return results in completion order and leak unhandled rejections.

## Data modeling

| Use case | Choice |
|----------|--------|
| API shape that needs runtime validation | Zod schema, `type X = z.infer<typeof Schema>` as the single source of truth |
| Fixed strings, type only | String union |
| Fixed strings needed at runtime | `as const` object plus derived union |
| Public object contract | `interface` |
| Union of different shapes | Discriminated union with a `kind` or `type` tag |
| IDs that must not be mixed (`UserId`, `OrderId`) | Branded types |
| Entity with invariants | Class with private constructor; `#private` fields for runtime privacy |

```typescript
const Status = { Active: 'active', Inactive: 'inactive' } as const;
type Status = (typeof Status)[keyof typeof Status];
```

Zod: `z.email()` is Zod 4 only. In Zod 3 (and deprecated in 4) use `z.string().email()`; check the installed version.

`x == null` / `x != null` is the one accepted loose-equality idiom (matches `null` and `undefined`).

## Module system

Default to ESM (`"type": "module"`). Relative-import extensions depend on `moduleResolution`: under `NodeNext`/`Node16`, ESM imports need the emitted extension (`'./api.js'` even for `api.ts`); under `bundler`, follow the project and omit it.

## Testing

Use Vitest unless the project is standardized on Jest. Mock at boundaries (HTTP, database, clock) and test logic directly. Type mocks with `vi.fn<...>()` and `vi.mocked()` so they cannot drift from the real interface.
