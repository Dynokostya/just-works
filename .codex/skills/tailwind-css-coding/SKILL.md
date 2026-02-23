---
name: tailwind-css-coding
description: Apply when writing or editing Tailwind CSS classes in any template or component file. Behavioral corrections for dynamic styling, class composition, responsive design, dark mode, interaction states, accessibility, and common antipatterns. Project conventions always override these defaults.
---

# Tailwind CSS Coding

Match the project's existing conventions. When uncertain, read 2-3 existing components to infer the local style. Check `package.json` for the `tailwindcss` version. v4 signals: `@tailwindcss/postcss` or `@tailwindcss/vite` in deps, `@import "tailwindcss"` in CSS, `@theme {}` blocks. v3 signals: `tailwind.config.js` with `module.exports`, `@tailwind base;` directives, `autoprefixer` as separate dep. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent broken builds, invisible bugs, and inaccessible UI regardless of project style.

- **Never construct class names dynamically** -- Tailwind's compiler scans source files as plain text with regex. It never executes code. Template literals, string concatenation, and interpolation produce classes the compiler cannot find. Use lookup maps of complete static strings.

```tsx
// Wrong: compiler cannot extract "bg-red-500" from this
const cls = `bg-${color}-500`;

// Correct: every class is a complete static string
const bgMap = {
  red: "bg-red-500",
  blue: "bg-blue-500",
} as const;
const cls = bgMap[color];
```

- **Never use template literal concatenation for class composition** -- CSS source order determines which class wins when two utilities target the same property, not HTML attribute order. `p-4 p-6` is unpredictable. Use `cn()` (clsx + tailwind-merge) to merge classes safely.

```tsx
// Wrong: conflicting padding, last-in-source wins (not last-in-string)
className={`p-4 ${isLarge ? "p-6" : ""}`}

// Correct: tailwind-merge resolves conflicts deterministically
import { cn } from "@/lib/utils";
className={cn("p-4", isLarge && "p-6")}
```

- **Never use arbitrary values when a design token exists** -- `p-[16px]` is `p-4`. `bg-[#3b82f6]` is `bg-blue-500`. `w-[100%]` is `w-full`. `text-[14px]` is `text-sm`. Arbitrary values bypass the design system and create inconsistency.

- **Never omit interaction states on interactive elements** -- every button and link needs `hover:`, `focus-visible:`, and `disabled:` states. Add `transition-colors` for smooth feedback. In v4: add `cursor-pointer` explicitly -- Preflight no longer sets it on buttons.

```tsx
// Wrong: no interaction feedback
<button className="bg-blue-500 text-white px-4 py-2 rounded">Save</button>

// Correct: full interaction states (v4: include cursor-pointer)
<button className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer">
  Save
</button>
```

- **Never use `@apply` for patterns extractable to components** -- extract a React/Vue/Svelte component instead. `@apply` is only for third-party library overrides, CMS/Markdown HTML, and non-component template languages.

- **Never forget dark mode counterparts** -- every `bg-`, `text-`, and `border-` color needs a `dark:` variant, or use CSS variable theming to handle both modes in one declaration.

- **Never use `sm:` thinking it means "small screens"** -- `sm:` means 640px AND ABOVE. Unprefixed utilities apply to all screens (mobile-first). Write base styles for mobile, then layer breakpoints upward.

```html
<!-- Wrong mental model: "sm means small phones" -->
<div class="hidden sm:block">Only on small screens</div>

<!-- Correct: sm:block means "show at 640px and above" -->
<div class="block sm:hidden">Mobile only</div>
<div class="hidden sm:block">Desktop only</div>
```

- **Never hallucinate class names** -- common fakes: `flex-center` (use `flex items-center justify-center`), `text-bold` (use `font-bold`), `bg-grey-500` (American spelling: `bg-gray-500`), `d-flex` (Bootstrap, not Tailwind).

- **Never output conflicting utilities** -- `p-4 p-6` is unpredictable. One value per CSS property. Don't redundantly set defaults (`flex flex-row`, `flex flex-nowrap`).

- **Never forget accessibility** -- use `sr-only` for icon-only button labels, `focus:not-sr-only` for skip links. Every interactive element needs visible focus indication via `focus-visible:`.

## Dynamic styling

For conditional classes, use `cn()` (clsx + tailwind-merge). For truly dynamic values that cannot be enumerated (user-set colors, computed positions), use inline `style` props -- these bypass the compiler entirely and always work.

```tsx
// Conditional classes: cn()
<div className={cn("rounded p-4", isActive && "ring-2 ring-blue-500")} />

// Truly dynamic: inline style
<div className="rounded p-4" style={{ backgroundColor: user.brandColor }} />
```

For variant-driven styling, use a lookup map with complete static strings:

```tsx
const sizeClasses = {
  sm: "px-2 py-1 text-sm",
  md: "px-4 py-2 text-base",
  lg: "px-6 py-3 text-lg",
} as const;

function Button({ size = "md", className, ...props }: ButtonProps) {
  return <button className={cn(sizeClasses[size], className)} {...props} />;
}
```

For components with 2+ variant dimensions, consider `cva` from class-variance-authority.

When the compiler must see classes that only appear in dynamic data (CMS content, database values), safelist them. In v4: `@source inline("bg-red-500 bg-blue-500")`. In v3: `safelist` array in `tailwind.config.js`.

## Class composition

The `cn()` helper combines `clsx` (conditional joining) with `tailwind-merge` (conflict resolution). Standard setup:

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

Use `cn()` whenever merging external `className` props with internal defaults -- raw concatenation silently breaks when both sides set the same property.

```tsx
// Wrong: parent's p-6 may or may not override internal p-4
function Card({ className }: { className?: string }) {
  return <div className={`rounded bg-white p-4 ${className}`} />;
}

// Correct: tailwind-merge ensures parent overrides win
function Card({ className }: { className?: string }) {
  return <div className={cn("rounded bg-white p-4", className)} />;
}
```

## Responsive design

Mobile-first: write base styles for the smallest screen, then add breakpoints upward. Always order breakpoints `sm:` -> `md:` -> `lg:` -> `xl:` -> `2xl:`. Never skip to `lg:` without considering the gap.

```html
<!-- Single column on mobile, two on tablet, three on desktop -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
```

In v4: container queries are built-in (no plugin). Use `@container` for component-scoped responsive design:

```tsx
// Parent declares a container
<div className="@container">
  {/* Child responds to container width, not viewport */}
  <div className="flex flex-col @md:flex-row @lg:grid @lg:grid-cols-3 gap-4">
    {children}
  </div>
</div>
```

## Dark mode

Cover every visible color. A component with `bg-white text-gray-900` needs `dark:bg-gray-900 dark:text-white`. Missing a single `dark:` variant causes unreadable text or invisible elements.

Better approach -- CSS variable theming. Define colors once, switch palettes:

```css
/* v4: @theme block */
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

Then use `bg-surface text-on-surface` everywhere -- no `dark:` variants needed per component.

## Interaction states

Minimum states for buttons: `hover:`, `focus-visible:`, `disabled:`, `transition-colors`. Minimum for inputs: `focus:`, `disabled:`, `placeholder:`. Minimum for links: `hover:`, `focus-visible:`.

```tsx
// Complete button pattern
<button className={cn(
  "px-4 py-2 rounded font-medium transition-colors",
  "bg-blue-600 text-white",
  "hover:bg-blue-700",
  "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600",
  "disabled:opacity-50 disabled:cursor-not-allowed",
  "cursor-pointer" // v4: Preflight no longer sets cursor:pointer on buttons
)}>
```

Complete input pattern:

```tsx
<input className={cn(
  "w-full rounded border px-3 py-2 transition-colors",
  "border-gray-300 bg-white text-gray-900",
  "dark:border-gray-600 dark:bg-gray-800 dark:text-white",
  "placeholder:text-gray-400 dark:placeholder:text-gray-500",
  "focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500",
  "disabled:cursor-not-allowed disabled:bg-gray-100 disabled:opacity-50",
)} />
```

In v4: `hover:` only fires on hover-capable devices (`@media (hover: hover)`). Touch-only devices skip hover styles entirely -- don't rely on hover for critical information.

## Accessibility

Icon-only buttons need screen reader text:

```tsx
<button className="p-2 rounded hover:bg-gray-100">
  <SearchIcon className="h-5 w-5" aria-hidden="true" />
  <span className="sr-only">Search</span>
</button>
```

Skip links use `sr-only` that becomes visible on focus:

```tsx
<a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-white focus:text-black focus:rounded">
  Skip to main content
</a>
```

Every focusable element needs a visible focus indicator. `focus-visible:` is preferred over `focus:` -- it only shows for keyboard navigation, not mouse clicks.

Ensure sufficient color contrast on interactive states. A `hover:bg-blue-700` on `bg-blue-600` is barely visible -- test both light and dark modes.

## v4 configuration

In v4, configuration lives in CSS, not JavaScript. Entry point is `@import "tailwindcss"`. Autoprefixer is built-in (don't add it separately).

```css
@import "tailwindcss";

@theme {
  --font-display: "Inter", sans-serif;
  --color-brand: #4f46e5;
  --breakpoint-3xl: 1920px;
}

@utility card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: var(--spacing-6);
}
```

Key v4 renames (old names still work via compat but generate warnings):

```
v3                    v4
shadow            ->  shadow-sm       ring              ->  ring-3
shadow-sm         ->  shadow-xs       outline-none      ->  outline-hidden
rounded           ->  rounded-sm      bg-gradient-to-r  ->  bg-linear-to-r
rounded-sm        ->  rounded-xs      blur              ->  blur-sm
```

Other v4 changes inline:

```tsx
// v3: bg-opacity-50       -> v4: bg-black/50 (opacity modifier)
// v3: bg-[--brand-color]  -> v4: bg-(--brand-color) (CSS variable syntax)
// v3: !bg-red-500         -> v4: bg-red-500! (important modifier at end)
// v3: first:*:pt-0        -> v4: *:first:pt-0 (variant stacking left-to-right)
```

Borders default to `currentColor` in v4, not `gray-200`. Add explicit border colors if the v3 default was relied upon. Custom utilities via `@utility name {}` not `@layer components {}`. Safelist via `@source inline("...")` not `safelist` array.
