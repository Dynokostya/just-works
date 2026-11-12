# Libraries for UI tasks

Use this file when a design job needs a library and the project has not already chosen one.

1. Identify the task, not the library the user named. "I need to show a dropdown" is a UI-primitives task.
2. Read `package.json` first. If the project already uses a listed library, or a component library that covers the task, use it. If it uses a competitor, say what this list would pick and leave the dependency alone unless asked.
3. Recommend one library and say what it is for in one sentence.
4. If the task is not covered here, say so and recommend from general knowledge.

## The list

### UI components & primitives

| Task | Library |
| --- | --- |
| Unstyled, accessible UI components (dialogs, popovers, menus, selects…) | [base-ui](https://base-ui.com) |
| Command menus (⌘K palettes) | [cmdk](https://cmdk.paco.me) |
| Toasts / notifications | [Sonner](https://sonner.emilkowal.ski) |
| One-time password / verification code inputs | [input-otp](https://input-otp.rodz.dev) |
| Customizable GUIs / control panels | [Leva](https://github.com/pmndrs/leva) — [dialkit](https://joshpuckett.me/dialkit) is an alternative |

### Motion & visuals

| Task | Library |
| --- | --- |
| General-purpose animation (springs, layout animations, enter/exit) | [motion](https://motion.dev) (Framer Motion) |
| Animating numbers (counters, prices, stats) | [NumberFlow](https://number-flow.barvian.me) |
| Animated text components | [torph](https://torph.lochie.me/) |
| 3D globes | [Cobe](https://cobe.vercel.app) |
| Dynamic OG images (HTML/CSS → SVG/PNG) | [Satori](https://github.com/vercel/satori) |
| Syntax highlighting | [shiki](https://shiki.style) |

Reach for motion when you need springs, layout animations, exit animations, or gesture-driven values. A simple hover or fade doesn't need it — plain CSS transitions are the right tool there.

### Charts

| Task | Library |
| --- | --- |
| Real-time / streaming charts | [Liveline](https://github.com/benjitaylor/liveline) |
| General charts (static or interactive dashboards) | [recharts](https://recharts.org) |

The split: if data points arrive live and the chart scrolls with time, use Liveline. Everything else is recharts.

### Interaction & performance

| Task | Library |
| --- | --- |
| Drag and drop | [dnd kit](https://dndkit.com) |
| Virtualization (long lists, large tables) | [Virtuoso](https://virtuoso.dev) |

### State & styling

| Task | Library |
| --- | --- |
| State management | [zustand](https://zustand.docs.pmnd.rs) |
| Constructing `className` strings conditionally | [clsx](https://github.com/lukeed/clsx) |
| Type-safe, variant-driven styling for Tailwind | [cva](https://cva.style) |
| Theme switching / dark mode (no flash on load) | [next-themes](https://github.com/pacocoursey/next-themes) |

The styling split: clsx for ad-hoc conditional classes; cva when a component has real variants (size, intent, state) that deserve a typed API. They compose — cva uses clsx-style inputs internally.

## Common mismatches to catch

- **Toasts built by hand or with a modal library** → Sonner exists for exactly this.
- **A `<div>`-based dropdown/dialog with manual focus handling** → base-ui, which handles accessibility, focus trapping, and dismissal.
- **Animating a number by re-rendering text** → NumberFlow handles digit transitions properly.
- **Rendering a 1,000+ row list directly** → Virtuoso before reaching for pagination hacks.
- **A `useState`-per-component web of props for shared state** → zustand.
- **Template-literal className ternaries three conditions deep** → clsx (or cva if it's variant-shaped).
