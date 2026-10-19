# shadcn/ui CLI and decision tables

Reference for the shadcn-ui-coding skill.

## CLI commands

```bash
npx shadcn@latest init                    # initialize the project, creates components.json
npx shadcn@latest init -b radix           # choose the primitive library: base, radix, aria
npx shadcn@latest init --pointer          # add cursor-pointer to buttons (--no-pointer to skip)
npx shadcn@latest add button              # add a component
npx shadcn@latest add button --diff       # show differences from upstream
npx shadcn@latest add button --dry-run    # preview changes without writing files
npx shadcn@latest search @shadcn -q card  # search registries
npx shadcn@latest view <item>             # preview a registry item before installing
npx shadcn@latest docs <component>        # usage, API, and Composition tree for a component
npx shadcn@latest info                    # project info (add --json for scripts)
npx shadcn@latest apply <preset>          # apply a preset (add --only theme or --only font for a part)
npx shadcn@latest migrate radix           # run a migration: cn, icons, base-color, radix, rtl
npx shadcn@latest build                   # build your own registry JSON
```

`create` is an alias for `init`.

## components.json

| Field | Effect |
|---|---|
| `style` | Prefix names the primitive library (`radix-*`, `base-*`, `aria-*`); legacy `new-york` is Radix. Fixed at initialization. `"default"` is deprecated. |
| `rsc` | `true` adds `"use client"` to components that need it |
| `aliases.components` | Import path prefix (for example `@/components`) |
| `aliases.utils` | Path to the `cn()` helper (for example `@/lib/utils`) |

## Migrations

| Old | New |
|---|---|
| `tailwindcss-animate` | `tw-animate-css` |
| Individual `@radix-ui/react-*` packages | Unified `radix-ui` package (`npx shadcn@latest migrate radix`) |

## Overlay selection

| Need | Component | Key trait |
|---|---|---|
| Confirm a destructive action | AlertDialog | Blocks interaction, requires an explicit response |
| Form or complex content | Dialog | Focus-trapped modal |
| Side panel (filters, nav, detail) | Sheet | Slides from an edge |
| Mobile bottom panel | Drawer | Touch-friendly, swipe to dismiss |
| Anchored, lightweight | Popover | Positioned to the trigger, no overlay |
| Brief hint | Tooltip | Hover/focus only, no interactive content |
| Rich preview on hover | HoverCard | Delayed, supports interactive content |
| Action list from a trigger | DropdownMenu | Click to open, keyboard-navigable |
| Action list from right-click | ContextMenu | Same API as DropdownMenu |

## Selection component

| Need | Component |
|---|---|
| Fixed list, fewer than 10 items | Select |
| Searchable list | Combobox (popover + command) |
| Searchable with groups or actions | Command (standalone) |
| Multi-select from a small set | ToggleGroup |
