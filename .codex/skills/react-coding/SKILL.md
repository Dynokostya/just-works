---
name: react-coding
description: Apply when writing or editing React (.tsx/.jsx) files. Behavioral corrections for hooks, state management, component structure, memoization, security, and common antipatterns. Project conventions always override these defaults.
---

# React Coding

Match the project's existing conventions. When uncertain, read 2-3 existing components to infer the local style. Check `tsconfig.json` for strictness settings, `package.json` for React version, and framework config (Next.js, Remix, Vite) for routing and rendering conventions. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs, wasted renders, and vulnerabilities regardless of project style.

- **Never `useEffect` for derived state** -- if a value can be computed from props or state, compute it during render. `useEffect` + `setState` for derivable values causes an unnecessary extra render cycle. This is the most common React mistake.

```tsx
// Wrong: extra render cycle for a value computable from props
const [fullName, setFullName] = useState("");
useEffect(() => {
  setFullName(`${first} ${last}`);
}, [first, last]);

// Correct: compute during render
const fullName = `${first} ${last}`;
```

- **Never `useEffect` for event-driven logic** -- user-triggered actions belong in event handlers, not effects keyed to state flags. Effects are for synchronizing with external systems.

```tsx
// Wrong: effect triggered by state flag
const [submitted, setSubmitted] = useState(false);
useEffect(() => {
  if (submitted) sendAnalytics();
}, [submitted]);

// Correct: logic in the event handler
function handleSubmit() {
  sendAnalytics();
  navigate("/done");
}
```

- **Never fetch data in `useEffect` without cleanup** -- missing `AbortController` causes race conditions on rapid prop changes. Prefer TanStack Query or framework data fetching over raw `useEffect` fetching entirely.

```tsx
// Wrong: no abort, race condition on rapid userId changes
useEffect(() => {
  fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser);
}, [userId]);

// Correct: AbortController for cleanup
useEffect(() => {
  const controller = new AbortController();
  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(r => r.json())
    .then(setUser)
    .catch(e => { if (e.name !== "AbortError") throw e; });
  return () => controller.abort();
}, [userId]);

// Best: TanStack Query handles caching, deduplication, and cancellation
const { data: user } = useQuery({
  queryKey: ["user", userId],
  queryFn: () => fetchUser(userId),
});
```

- **Never chain `useEffect` calls that sync state to other state** -- cascading effects create render waterfalls (render, effect, setState, render, effect, setState…). Each link in the chain adds a full render cycle, so three chained effects means four renders for one user action — visible jank and wasted CPU. Compute derived values inline or batch updates in event handlers.

- **Never mutate state directly** -- React detects changes by reference. `array.push()` and `obj.prop = x` won't trigger re-renders. Use spread, `structuredClone`, or non-mutating methods like `.toSorted()` (not `.sort()` which mutates).

```tsx
// Wrong: mutates existing array, React sees same reference
items.push(newItem);
setItems(items);

// Correct: new array reference, non-mutating sort
setItems([...items, newItem].toSorted((a, b) => a.name.localeCompare(b.name)));
```

- **Never use array index as `key` for dynamic lists** -- index keys cause React to reuse DOM nodes incorrectly when items are reordered, inserted, or removed, corrupting component state. Use stable unique IDs.

```tsx
// Wrong: index key breaks on reorder/insert/delete
{items.map((item, i) => <ListItem key={i} item={item} />)}

// Correct: stable unique ID
{items.map(item => <ListItem key={item.id} item={item} />)}
```

- **Never add `"use client"` by default** -- in Next.js App Router, components are Server Components by default. Adding `"use client"` unnecessarily pushes components and their entire subtree to the client bundle, losing server-side rendering, data fetching, and streaming benefits. Only add it when the component uses hooks (`useState`, `useEffect`), event handlers, or browser APIs. Place the boundary as low in the tree as possible.

- **Never use `forwardRef` in React 19+** -- `ref` is a regular prop in React 19+. `forwardRef` is deprecated. In React 18, `forwardRef` is still required.

```tsx
// Wrong (React 19): forwardRef is deprecated
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => (
  <input ref={ref} {...props} />
));

// Correct (React 19): ref is a regular prop
function Input({ ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}

// React 18: forwardRef is still required
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => (
  <input ref={ref} {...props} />
));
```

- **Never define components inside other components** -- the inner component is recreated every render, destroying all state and DOM on each cycle.

```tsx
// Wrong: Child is a new component identity every render
function Parent() {
  function Child() { return <div>child</div>; }
  return <Child />;
}

// Correct: Child defined outside
function Child() { return <div>child</div>; }
function Parent() { return <Child />; }
```

- **Never suppress `react-hooks/exhaustive-deps`** -- `eslint-disable` for this rule masks stale closures, where an effect captures an old value of a prop or state and silently operates on outdated data. The resulting bugs are intermittent and hard to trace because the component appears to work until a specific re-render order exposes the stale value. Fix the code: extract functions, use updater functions for state, or move objects inside the effect.

- **Never mirror props in state** -- `useState(prop)` captures the initial value only. Subsequent prop changes are silently ignored. Use the prop directly, or name it `initialX` to signal intent.

```tsx
// Wrong: color prop changes are silently ignored after mount
function Badge({ color }: { color: string }) {
  const [badgeColor, setBadgeColor] = useState(color);
  return <span style={{ color: badgeColor }}>badge</span>;
}

// Correct: use the prop directly
function Badge({ color }: { color: string }) {
  return <span style={{ color }}>badge</span>;
}
```

- **Never use `useEffect` to reset state on prop change** -- use the `key` prop to unmount/remount the component, which resets all state automatically.

```tsx
// Wrong: effect to reset state when userId changes
function Profile({ userId }: { userId: string }) {
  const [comment, setComment] = useState("");
  useEffect(() => { setComment(""); }, [userId]);
  return <textarea value={comment} onChange={e => setComment(e.target.value)} />;
}

// Correct: key forces remount, all state resets
<Profile key={userId} userId={userId} />
```

- **Never generate class components** -- all modern React features (Server Components, Suspense, hooks, React Compiler) require function components. The only exception: error boundaries (which still require class components or `react-error-boundary`).

- **Never use `dangerouslySetInnerHTML` without sanitization** -- renders raw HTML, enabling XSS attacks. Always sanitize with DOMPurify or similar. Prefer React's built-in escaping over raw HTML injection entirely.

```tsx
// Wrong: unsanitized HTML injection
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// Correct: sanitize first
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

- **Never use `React.lazy` without a `<Suspense>` boundary** -- lazy components suspend during loading. Without `<Suspense>`, the thrown promise is unhandled and crashes the app. Wrap with `<Suspense>` and an error boundary.

```tsx
// Wrong: no Suspense boundary, crashes on load
const Dashboard = lazy(() => import("./Dashboard"));
function App() { return <Dashboard />; }

// Correct: Suspense with fallback and error boundary
const Dashboard = lazy(() => import("./Dashboard"));
function App() {
  return (
    <ErrorBoundary fallback={<p>Something went wrong.</p>}>
      <Suspense fallback={<p>Loading...</p>}>
        <Dashboard />
      </Suspense>
    </ErrorBoundary>
  );
}
```

## Memoization

**With React Compiler (v19.x + compiler enabled):** The compiler auto-memoizes components, hooks, and JSX elements. Remove manual `useMemo`, `useCallback`, and `React.memo` -- they add noise and the compiler may deopt on components where it cannot preserve manual memoization. Let the compiler handle it.

**Without React Compiler:** Memoize at measured bottlenecks only. Don't wrap everything in `useMemo`/`useCallback`/`React.memo` preemptively. When you do memoize, avoid creating new object/array literals in JSX props to memoized children -- `style={{ color: "red" }}` creates a new reference every render, defeating `React.memo`. Hoist static objects outside the component.

```tsx
// Wrong: new style object every render defeats React.memo on Child
function Parent() {
  return <MemoizedChild style={{ color: "red" }} />;
}

// Correct: hoist static objects outside the component
const childStyle = { color: "red" } as const;
function Parent() {
  return <MemoizedChild style={childStyle} />;
}
```

## React 19 APIs

- **Document metadata.** Render `<title>`, `<meta>`, and `<link>` anywhere in the tree — React hoists them to `<head>`. Skip framework-specific `<Head>` helpers for simple cases.
- **Stylesheet precedence.** `<link rel="stylesheet" href="..." precedence="default" />` lets React manage insertion order.
- **Resource preloading from `react-dom`.** `preinit`, `preload`, `prefetchDNS`, `preconnect` — call at module scope or in event handlers to prime the browser before navigation.
- **Ref cleanup.** Return a cleanup function from a ref callback: `ref={(node) => { attach(node); return () => detach(node); }}`. React calls it on unmount.
- **`<Context>` as provider.** `<ThemeContext value="dark">...</ThemeContext>` — no more `.Provider`.

## Hooks

Rules of hooks -- no exceptions:
- Call hooks at the top level of function components and custom hooks only.
- Never call hooks inside conditions, loops, nested functions, `try`/`catch`, or after early returns.
- The `use()` API (React 19) is the exception — it can be called conditionally. Use it to read promises and context during render, integrating with Suspense:

  ```tsx
  function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
    const user = use(userPromise);
    return <div>{user.name}</div>;
  }

  // Wrap in Suspense for loading fallback and ErrorBoundary for errors.
  ```
  Prefer `use(promise)` + `<Suspense>` over `useEffect`+`useState` for request-response fetching in Server Components and async data flows.

**`useEffect` decision tree -- ask before writing any effect:**

1. Can the value be computed from existing props/state? Compute during render.
2. Is this responding to a user event? Put it in the event handler.
3. Do you need to reset state when a prop changes? Use `key` on the component.
4. Do you need to sync with an external system (DOM, network, third-party widget)? This is a valid `useEffect`. Add cleanup.
5. Do you need to fetch data? Prefer framework data fetching or TanStack Query. If raw `useEffect`, always use `AbortController`.

## Actions (React 19+)

Actions are async functions that perform mutations. React tracks pending state, errors, and optimistic updates for you.

- **Form actions.** Pass an async function to `<form action={fn}>`. React runs it in a transition, shows pending state, and resets the form on success.
- **`useActionState(reducer, initial)`** — returns `[state, dispatchAction, isPending]`. Use for form submissions and state-mutation workflows.
- **`useFormStatus()`** — read pending/data of the nearest form from a descendant. Use for in-form submit buttons.
- **`useOptimistic(state, reducer)`** — render an optimistic value until the async action settles. Use for UI that should appear to have updated immediately.

```tsx
function UpdateNameForm({ name }: { name: string }) {
  const [error, submitAction, isPending] = useActionState(
    async (_: unknown, formData: FormData) => {
      const result = await updateName(formData.get("name") as string);
      return result.error ?? null;
    },
    null,
  );

  return (
    <form action={submitAction}>
      <input name="name" defaultValue={name} />
      <button type="submit" disabled={isPending}>Save</button>
      {error && <p>{error}</p>}
    </form>
  );
}
```

Don't roll your own `isSubmitting` state — `useActionState` and `useFormStatus` own that state and integrate with Suspense/error boundaries.

## Component typing

**Prefer typed function declarations over `React.FC`.** `React.FC` is no longer broken (implicit `children` was removed in React 18 types), but plain function declarations are clearer, support generics naturally, and are the community standard.

```tsx
interface UserCardProps {
  user: User;
  onSelect: (id: string) => void;
  variant?: "compact" | "full";
}

function UserCard({ user, onSelect, variant = "full" }: UserCardProps) {
  return ( /* JSX */ );
}
```

Generic components:

```tsx
function List<T>({ items, renderItem, keyExtractor }: {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
  keyExtractor: (item: T) => string;
}) {
  return (
    <ul>
      {items.map(item => (
        <li key={keyExtractor(item)}>{renderItem(item)}</li>
      ))}
    </ul>
  );
}
```

Use discriminated unions for impossible states:

```tsx
type ButtonProps =
  | { variant: "link"; href: string; onClick?: never }
  | { variant: "button"; onClick: () => void; href?: never };
```
