---
name: react-coding
description: Apply when writing or editing React (.tsx/.jsx) files. Behavioral corrections for hooks, state management, component structure, memoization, security, and common antipatterns.
---

# React Coding

Project conventions override these defaults. Read 2-3 nearby components, `package.json` (React version, compiler), `tsconfig.json`, and the framework config (Next.js, Remix, Vite) before writing.

## Never rules

- **Never use `useEffect` for derived state.** Compute the value during render; effect plus `setState` adds a render cycle. This is the most common React mistake.

```tsx
// Wrong
const [fullName, setFullName] = useState("");
useEffect(() => setFullName(`${first} ${last}`), [first, last]);

// Correct
const fullName = `${first} ${last}`;
```

- **Never mutate state.** React compares by reference. Use spread, `structuredClone`, or non-mutating methods such as `.toSorted()` (not `.sort()`).
- **Never use an array index as `key` in dynamic lists.** Reordering or removal reuses DOM nodes and corrupts component state. Use stable IDs.
- **Never add `"use client"` by default.** In the Next.js App Router, components are Server Components unless marked. Add it only for hooks, event handlers, or browser APIs, and place the boundary as low in the tree as possible.
- **Never use `forwardRef` in React 19+ code.** `ref` is a regular prop. React 18 still requires `forwardRef`.
- **Never define a component inside another component.** It gets a new identity every render and loses all state.
- **Never suppress `react-hooks/exhaustive-deps`.** It hides stale closures. Fix the code: extract functions, use updater functions, or move objects inside the effect.
- **Never mirror props in state.** `useState(prop)` ignores later prop changes. Use the prop directly, or name it `initialX` to signal intent.
- **Never generate class components.** The exception is error boundaries (or use `react-error-boundary`).
- **Never use `dangerouslySetInnerHTML` without sanitizing** (DOMPurify or similar).
- **Never render `React.lazy` components without `<Suspense>`** and an error boundary.

## Effects

Before writing `useEffect`, walk this list:

1. Can the value be computed from props or state? Compute it during render.
2. Is it a response to a user event? Put it in the event handler, not in an effect keyed to a state flag.
3. Does state need to reset when a prop changes? Use `key` on the component (`<Profile key={userId} />`), not an effect.
4. Is it synchronization with an external system (DOM, network subscription, third-party widget)? That is a valid effect; return cleanup.
5. Is it data fetching? Prefer framework data fetching or TanStack Query. In a raw effect, abort on cleanup and capture errors in state (a rethrow inside `.catch` becomes an unhandled rejection).

```tsx
useEffect(() => {
  const controller = new AbortController();
  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(r => r.json())
    .then(setUser)
    .catch(e => { if (e.name !== "AbortError") setError(e); });
  return () => controller.abort();
}, [userId]);
```

Chained effects that set state for other effects cause render waterfalls (one extra render per link). Compute inline or batch in the event handler.

## Memoization

New code does not need manual `useMemo`, `useCallback`, or `React.memo` when React Compiler is enabled (it supports React 17-19; check the build config). Do not strip memoization from existing code: removing it can change compiler output. Keep `useMemo`/`useCallback` where precise control matters, such as a memoized value used as an effect dependency.

Without the compiler, memoize only at measured bottlenecks. When passing props to a memoized child, hoist static objects out of the component: `style={{ color: "red" }}` creates a new reference every render and defeats `React.memo`.

## Hooks

- Call hooks only at the top level of components and custom hooks: never in conditions, loops, nested functions, `try`/`catch`, or after early returns.
- `use()` (React 19) is the exception: it can be called conditionally. Use `use(promise)` with `<Suspense>` and an error boundary instead of `useEffect` + `useState` for request-response data in Server Components and async flows.

## React 19 APIs

- Ref callbacks can return a cleanup function: `ref={(node) => { attach(node); return () => detach(node); }}`.
- `<ThemeContext value="dark">` replaces `<ThemeContext.Provider>`.
- Forms: pass an async function to `<form action={fn}>`; use `useActionState` for state and pending, `useFormStatus` in descendants, and `useOptimistic` for optimistic UI. Do not hand-roll `isSubmitting` state.

```tsx
const [error, submitAction, isPending] = useActionState(
  async (_: unknown, formData: FormData) => {
    const name = formData.get("name");
    if (typeof name !== "string" || name === "") return "Name is required";
    const result = await updateName(name);
    return result.error ?? null;
  },
  null,
);
```

## Component typing

Use plain function declarations with an explicit props interface, not `React.FC`. Model impossible prop combinations with discriminated unions (`{ variant: "link"; href: string; onClick?: never } | { variant: "button"; onClick: () => void; href?: never }`).
