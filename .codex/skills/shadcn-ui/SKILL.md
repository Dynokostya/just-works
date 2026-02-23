---
name: shadcn-ui
description: Apply when generating shadcn/ui code. Covers the copy-paste component model, Radix UI compound components, theming with CSS variables, Form/DataTable integrations, and CLI conventions. Does NOT cover general React or Tailwind CSS patterns.
---

# shadcn/ui

Match project conventions. Read `components.json` for style, Tailwind version, aliases, and RSC settings. Check `components/ui/` for local component source and `package.json` for React version (18 vs 19) and Radix package format (unified `radix-ui` vs individual `@radix-ui/react-*`). These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent runtime errors, accessibility breakage, and infinite re-renders regardless of project style.

- **Never import shadcn components from npm** -- shadcn is not a package. Import from the local alias.

```tsx
// Wrong: shadcn is not an npm package
import { Button } from "shadcn/ui";
import { Button } from "@shadcn/ui";

// Correct: import from the local alias defined in components.json
import { Button } from "@/components/ui/button";
```

- **Never flatten Radix compound components** -- Dialog, DropdownMenu, Select, AlertDialog, Menubar, NavigationMenu, ContextMenu, and Tabs require their nested structure. Removing wrapper layers breaks ARIA roles and keyboard navigation.

```tsx
// Wrong: missing compound structure, broken accessibility
<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogTitle>Title</DialogTitle>
  <DialogDescription>Desc</DialogDescription>
</Dialog>

// Correct: full compound structure preserved
<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
      <DialogDescription>Desc</DialogDescription>
    </DialogHeader>
  </DialogContent>
</Dialog>
```

- **Never omit `asChild` when wrapping custom elements in Trigger components** -- without `asChild`, the Trigger renders its own `<button>`, creating button-in-button nesting (invalid HTML, broken accessibility).

```tsx
// Wrong: renders <button><button>...</button></button>
<DialogTrigger>
  <Button variant="outline">Open</Button>
</DialogTrigger>

// Correct: Slot merges props onto the child element
<DialogTrigger asChild>
  <Button variant="outline">Open</Button>
</DialogTrigger>
```

- **Never use hardcoded colors** -- use CSS variable tokens. Hardcoded values bypass dark mode and break theme consistency.

```tsx
// Wrong: hardcoded color, breaks in dark mode
<div className="bg-blue-500 text-white">

// Correct: CSS variable tokens, theme-aware
<div className="bg-primary text-primary-foreground">
```

- **Never compose classNames with template literals** -- use `cn()` (clsx + tailwind-merge). Template literals can't resolve Tailwind class conflicts.

```tsx
// Wrong: conflicting classes not resolved
<div className={`px-2 ${className}`}>

// Correct: tailwind-merge resolves conflicts, last wins
import { cn } from "@/lib/utils";
<div className={cn("px-2", className)}>
```

- **Never spread `{...field}` on Select, Checkbox, or Switch** -- these use `onValueChange`/`onCheckedChange`, not `onChange`. Spreading `field` binds `onChange`, which is silently ignored.

```tsx
// Wrong: onChange is ignored by Radix Select
<Select {...field}>

// Correct: wire value and handler explicitly
<Select onValueChange={field.onChange} value={field.value}>
```

- **Never define DataTable columns inside the component** -- new object references each render cause infinite re-renders with TanStack Table's referential equality checks.

```tsx
// Wrong: new columns array every render, infinite loop
function UsersTable({ data }: { data: User[] }) {
  const columns: ColumnDef<User>[] = [
    { accessorKey: "name", header: "Name" },
  ];
  return <DataTable columns={columns} data={data} />;
}

// Correct: stable reference, defined outside component
const columns: ColumnDef<User>[] = [
  { accessorKey: "name", header: "Name" },
];
function UsersTable({ data }: { data: User[] }) {
  return <DataTable columns={columns} data={data} />;
}
```

- **Never put more or fewer than one child inside FormControl** -- uses Radix Slot internally, merges props onto exactly one child. Zero or multiple children is a runtime error.
- **Never build custom modals, dropdowns, or tooltips** -- use shadcn components (Dialog, DropdownMenu, Tooltip, Popover, Sheet). Hand-built versions lack focus trapping, keyboard nav, and portals.
- **Never nest TooltipProvider** -- mount once at app root. Nesting creates separate delay contexts.
- **Never hallucinate props** -- shadcn components only have props defined in their local source. Read `components/ui/` if unsure.
- **Never use `npx shadcn-ui@latest`** -- correct CLI is `npx shadcn@latest`.
- **Never use Toast** -- deprecated. Use Sonner (`npx shadcn@latest add sonner`).

## Component architecture

### Directory structure

```
components/
  ui/           # CLI-managed shadcn source -- avoid editing directly
    button.tsx
    dialog.tsx
    ...
  app/          # App-specific wrappers and compositions
    confirm-dialog.tsx   # wraps Dialog with app-specific logic
    user-avatar.tsx      # wraps Avatar with business defaults
```

Create wrappers in `components/app/` for app-specific behavior. Edit `components/ui/` directly only for global style changes.

### cn() utility

`cn()` from `@/lib/utils` combines `clsx` (conditional classes) and `tailwind-merge` (conflict resolution):

```tsx
import { cn } from "@/lib/utils";

function Card({ className, isActive, ...props }: CardProps) {
  return (
    <div
      className={cn(
        "rounded-lg border bg-card p-6",
        isActive && "border-primary",
        className
      )}
      {...props}
    />
  );
}
```

### CVA (class-variance-authority)

shadcn components use CVA for variants. Export `*Variants` separately to style non-native elements (e.g., `<Link className={cn(buttonVariants({ variant: "outline" }))}>`). Use `VariantProps<typeof xVariants>` for type-safe variant props.

## Theming

### CSS variables

Format depends on Tailwind version:

**Tailwind v4 (current):** OKLCH color format, `@theme inline` directive:

```css
@theme inline {
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);
  --color-primary: oklch(0.205 0 0);
  --color-primary-foreground: oklch(0.985 0 0);
}
```

**Tailwind v3 (legacy):** HSL format (e.g., `--primary: 222.2 47.4% 11.2%`) in `@layer base`, referenced as `hsl(var(--primary))` in `tailwind.config.ts`.

### Dark mode

**Tailwind v4:** Use `@custom-variant` with `:where()` (not `:is()`) and include both `.dark` and `.dark *`:

```css
@custom-variant dark (&:where(.dark, .dark *));
```

**Tailwind v3:** `darkMode: "class"` in `tailwind.config.ts`.

Use `next-themes` for the theme provider. Never implement manual dark mode toggling.

### Adding custom colors

Define the variable in the theme, then reference with the semantic token:

```css
@theme inline {
  --color-brand: oklch(0.6 0.2 250);
  --color-brand-foreground: oklch(0.98 0 0);
}
```

```tsx
<div className="bg-brand text-brand-foreground">
```

## Composition patterns

### Compound components and Slot

Radix compound components use React context. Each piece must be nested correctly. `asChild` swaps the rendered element for its child via Slot (prop merging):

```tsx
// Slot merges Trigger's event handlers and ARIA props onto the Link
<NavigationMenuLink asChild>
  <Link href="/about">About</Link>
</NavigationMenuLink>
```

### DropdownMenu + Dialog combo

Wrap both in a shared parent. Use `e.preventDefault()` in the menu item's `onSelect` to prevent the menu from stealing focus from the dialog. Manage dialog state with `useState`, not `DialogTrigger` — the trigger lives inside the menu, not the dialog.

### Sidebar

The Sidebar component is complex (30+ sub-components). Minimum viable setup:

```tsx
import { SidebarProvider, SidebarTrigger, SidebarInset } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <header>
          <SidebarTrigger />
        </header>
        <main>{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
```

## Forms

shadcn Form wraps react-hook-form with automatic ARIA wiring. Don't bypass with raw `register()`.

### Standard pattern

```tsx
const schema = z.object({
  name: z.string().min(1, "Required"),
  role: z.string().min(1, "Select a role"),
});

function CreateUserForm() {
  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { name: "", role: "" }, // required: avoids controlled/uncontrolled warnings
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        {/* Text input: spread field directly */}
        <FormField control={form.control} name="name" render={({ field }) => (
          <FormItem>
            <FormLabel>Name</FormLabel>
            <FormControl><Input {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )} />

        {/* Select: wire onValueChange explicitly, never spread field */}
        <FormField control={form.control} name="role" render={({ field }) => (
          <FormItem>
            <FormLabel>Role</FormLabel>
            <Select onValueChange={field.onChange} value={field.value}>
              <FormControl>
                <SelectTrigger><SelectValue placeholder="Select a role" /></SelectTrigger>
              </FormControl>
              <SelectContent>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="member">Member</SelectItem>
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )} />

        <Button type="submit">Create</Button>
      </form>
    </Form>
  );
}
```

Checkbox/Switch: use `checked={field.value} onCheckedChange={field.onChange}` (never spread `{...field}`).

### FormField nesting order

Always: `FormField > FormItem > FormLabel + FormControl > [input] + FormDescription + FormMessage`. FormControl must wrap exactly one child element (Slot constraint).

## Data tables

### File structure

```
components/
  users/
    columns.tsx      # column definitions (stable reference, outside component)
    data-table.tsx   # reusable DataTable shell (pagination, sorting, filtering)
    page.tsx         # fetches data, renders <DataTable columns={columns} data={data} />
```

### Column rules

Pair column features with table feature configuration:

| Column Feature | Required Table Config |
|---|---|
| `enableSorting` on column | `getSortedRowModel()` in useReactTable |
| `enableColumnFilter` | `getFilteredRowModel()` |
| `cell` with row actions | Column with `id: "actions"`, no `accessorKey` |

### Row selection

Use `onCheckedChange` (not `onChange`) for the checkbox column:

```tsx
{
  id: "select",
  header: ({ table }) => (
    <Checkbox
      checked={table.getIsAllPageRowsSelected()}
      onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
    />
  ),
  cell: ({ row }) => (
    <Checkbox
      checked={row.getIsSelected()}
      onCheckedChange={(value) => row.toggleSelected(!!value)}
    />
  ),
}
```

## Accessibility

Radix primitives provide: focus trapping in modals, arrow-key navigation in menus, `aria-expanded`/`aria-controls` on triggers, `role` attributes, Escape to close, screen reader announcements.

You handle: `FormLabel` association with inputs (via FormField), visible focus rings (`focus-visible:ring-2`), color contrast (WCAG AA minimum), skip-to-content links, meaningful `alt` text on images, `DialogTitle` and `DialogDescription` in every Dialog (required by Radix, warns if missing).

## CLI and configuration

### Commands

```bash
npx shadcn@latest init          # initialize project, creates components.json
npx shadcn@latest add button    # add a component
npx shadcn@latest add sonner    # add sonner (toast replacement)
npx shadcn@latest diff button   # show upstream changes to a component
npx shadcn@latest create        # scaffold a new registry block (Dec 2025+)
```

### components.json

Key settings:

| Field | Effect |
|---|---|
| `style` | `"new-york"` only. `"default"` is deprecated. |
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

## Testing

### Portal rendering

Dialog, Popover, Sheet, Select, and DropdownMenu content render into a portal at `document.body`. Query by role, not by DOM hierarchy:

```tsx
// Wrong: content is not inside the trigger's DOM subtree
const content = within(triggerParent).getByText("Option A");

// Correct: query from screen (portaled to body)
const content = screen.getByRole("option", { name: "Option A" });
```

### User events

Radix components listen on `pointerdown`, not `click`. Use `userEvent.setup()` (not `fireEvent`):

```tsx
import userEvent from "@testing-library/user-event";

it("opens the dialog", async () => {
  const user = userEvent.setup();
  render(<MyDialog />);
  await user.click(screen.getByRole("button", { name: "Open" }));
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});
```

### JSDOM limitations

JSDOM does not implement `pointerdown` or `resize` observers fully. For components that rely on these (Sheet, Drawer, Resizable), test in a real browser environment (Playwright) or mock the specific Radix primitive.
