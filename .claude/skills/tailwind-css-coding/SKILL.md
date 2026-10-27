---
name: tailwind-css-coding
description: Apply when writing or editing Tailwind CSS utility classes in a project that uses Tailwind CSS. Behavioral corrections for dynamic styling, class composition, responsive design, dark mode, interaction states, accessibility, and common antipatterns.
---

# Tailwind CSS Coding

Project conventions override these defaults. Read 2-3 nearby components and check the Tailwind version in `package.json` first. v4 signals: `@tailwindcss/postcss` or `@tailwindcss/vite`, `@import "tailwindcss"`, `@theme {}` blocks. v3 signals: `tailwind.config.js`, `@tailwind base;` directives, a separate `autoprefixer`.

## Never rules

- **Never construct class names dynamically.** The compiler scans source as plain text and never runs code, so `` `bg-${color}-500` `` produces no CSS. Use a lookup map of complete static strings. For truly dynamic values (user-set colors, computed positions) use an inline `style` prop.

```tsx
const bgMap = { red: "bg-red-500", blue: "bg-blue-500" } as const;
const cls = bgMap[color];
```

- **Never compose classes by string concatenation.** When two utilities set the same property (`p-4 p-6`), stylesheet order decides the winner, not class order in the string. Merge with `cn()` and set one value per property. Do not restate defaults (`flex flex-row`).
- **Never use an arbitrary value when a token exists.** `p-[16px]` is `p-4`, `w-[100%]` is `w-full`, `text-[14px]` is `text-sm`. Prefer semantic tokens over raw palette colors when the project defines them (`bg-primary`, not `bg-blue-500`); see shadcn-ui-coding.
- **Never ship interactive elements without states.** Buttons need `hover:`, `focus-visible:`, `disabled:`, and `transition-colors`; inputs need `focus:`, `disabled:`, `placeholder:`; links need `hover:` and `focus-visible:`. Use `focus-visible:` rather than `focus:` for buttons and links so mouse clicks show no ring. In v4 also add `cursor-pointer` to buttons; Preflight no longer sets it.
- **Never use `@apply` for patterns that can be a component.** Reserve it for third-party library overrides, CMS or Markdown HTML, and non-component template languages.
- **Never leave colors unthemed in a project that supports dark mode.** See Dark mode.
- **Never read `sm:` as "small screens".** It means 640px and above; unprefixed utilities apply everywhere. Write mobile styles first, then layer breakpoints upward.
- **Never skip accessibility.** Icon-only buttons need `<span className="sr-only">Label</span>` (and `aria-hidden` on the icon); skip links use `sr-only focus:not-sr-only`. Check contrast on hover and focus states in both color schemes.

## Class composition

`cn()` combines `clsx` (conditional joining) with `tailwind-merge` (conflict resolution). Use it for conditional classes and whenever merging a caller's `className` into internal defaults, so the caller's value wins:

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
<div className={cn("rounded bg-white p-4", isActive && "ring-2", className)} />
```

For variant-driven components, use a lookup map of static strings; with two or more variant dimensions, use `cva` (class-variance-authority).

Classes that appear only in dynamic data (CMS, database) must be safelisted: v4 `@source inline("bg-{red,blue}-500")` (one pattern per directive), v3 the `safelist` array.

## Responsive design

Write breakpoint variants in ascending order (`sm:` then `md:`, `lg:`, `xl:`, `2xl:`) for readability; class order has no CSS effect. v4 has built-in container queries: mark the parent `@container` and use `@md:`/`@lg:` on children for component-scoped layouts.

## Dark mode

Prefer semantic tokens defined as CSS variables, which theme both modes in one declaration and need no `dark:` variants (`bg-surface text-on-surface`). With raw palette utilities, every `bg-`, `text-`, and `border-` color needs a `dark:` counterpart. Projects without dark mode need neither.

```css
@theme {
  --color-surface: #ffffff;
  --color-on-surface: #111827;
}
@custom-variant dark (&:where(.dark, .dark *));
.dark {
  --color-surface: #111827;
  --color-on-surface: #f9fafb;
}
```

## v4 differences

Configuration lives in CSS (`@import "tailwindcss"`, `@theme {}`); Autoprefixer is built in. Define custom utilities with `@utility name {}` rather than `@layer components`. Spacing derives from a single `--spacing` variable, so write `calc(var(--spacing) * 6)`; there is no `--spacing-6`.

Renamed utilities. v3 names still compile in v4 but point at different sizes (v4 `shadow-sm` equals v3 `shadow`), so unrenamed v3 markup changes appearance silently, with no warning. When porting v3 markup, rename to keep the look:

| v3 | v4 |
|----|----|
| `shadow-sm`, `shadow` | `shadow-xs`, `shadow-sm` |
| `rounded-sm`, `rounded` | `rounded-xs`, `rounded-sm` |
| `blur-sm`, `blur` | `blur-xs`, `blur-sm` |
| `drop-shadow-sm`, `drop-shadow` | `drop-shadow-xs`, `drop-shadow-sm` |
| `ring` (3px, blue) | `ring-3`; bare `ring` is now 1px `currentColor` |
| `outline-none` | `outline-hidden` |

Other syntax changes:

- `bg-opacity-50` becomes `bg-black/50`.
- `bg-[--brand]` becomes `bg-(--brand)`.
- `!bg-red-500` becomes `bg-red-500!`.
- `first:*:pt-0` becomes `*:first:pt-0` (variants stack left to right).
- Default border color is `currentColor`, not `gray-200`; add an explicit color if the v3 default was relied on.
- `hover:` applies only on hover-capable devices, so never carry critical information in hover alone.
