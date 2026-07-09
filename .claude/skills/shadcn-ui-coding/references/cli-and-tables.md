# shadcn/ui CLI and decision tables

Reference for the shadcn-ui-coding skill.

## CLI and configuration

### Commands

```bash
npx shadcn@latest init                # initialize project, creates components.json
npx shadcn@latest init --pointer      # init with cursor-pointer on buttons (Apr 2026+)
npx shadcn@latest add button          # add a component
npx shadcn@latest add button --diff   # show upstream changes (replaces the old diff command)
npx shadcn@latest add sonner          # add sonner (toast replacement)
npx shadcn@latest search <query>      # search items across registries
npx shadcn@latest view <item>         # preview a registry item before install
npx shadcn@latest apply <preset>      # apply a preset (theme/fonts) to existing project
npx shadcn@latest apply <preset> --only=theme  # partial preset apply
npx shadcn@latest migrate radix       # run a built-in migration
npx shadcn@latest build               # build your own registry JSON
npx shadcn@latest info                # display project info
npx shadcn@latest docs <component>    # retrieve component documentation
npx shadcn@latest create              # scaffold a new registry block
```

### components.json

Key settings:

| Field | Effect |
|---|---|
| `style` | `"new-york"` or `"sera"` (Apr 2026+). `"default"` is deprecated. |
| `rsc` | `true` adds `"use client"` to components automatically |
| `aliases.components` | Import path prefix (e.g., `@/components`) |
| `aliases.utils` | Path to `cn()` utility (e.g., `@/lib/utils`) |

### Deprecations and migrations

| Deprecated | Replacement |
|---|---|
| `shadcn-ui` CLI package | `shadcn` (use `npx shadcn@latest`) |
| `"default"` style | `"new-york"` style |
| Toast component | Sonner |
| `tailwindcss-animate` | `tw-animate-css` |
| Individual `@radix-ui/react-*` | Unified `radix-ui` package |

## Decision tables

### Overlay selection

| Need | Component | Key Trait |
|---|---|---|
| Confirm destructive action | AlertDialog | Blocks interaction, requires explicit response |
| Form or complex content | Dialog | Focus-trapped modal, closes on overlay click |
| Side panel (filters, nav, detail) | Sheet | Slides from edge, good for secondary content |
| Mobile-friendly bottom panel | Drawer | Touch-friendly, swipe to dismiss (uses vaul) |
| Anchored to trigger, lightweight | Popover | Positioned relative to trigger, no overlay |
| Brief hint on hover | Tooltip | Hover/focus only, no interactive content |
| Rich preview on hover | HoverCard | Hover card with delay, supports interactive content |
| Action list from trigger | DropdownMenu | Click to open, keyboard-navigable menu |
| Action list from right-click | ContextMenu | Right-click triggered, same API as DropdownMenu |

### Selection component

| Need | Component |
|---|---|
| Fixed list, <10 items | Select |
| Searchable list | Combobox (popover + command) |
| Searchable with groups/actions | Command (standalone) |
| Multi-select from small set | ToggleGroup |

### Customization approach

| Situation | Approach |
|---|---|
| Global style change (border radius, colors) | Edit `components/ui/` directly |
| App-specific defaults (icon + label combos) | Wrapper in `components/app/` |
| One-off layout composition | Inline composition in the page/feature |
