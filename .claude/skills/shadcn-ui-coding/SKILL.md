---
name: shadcn-ui-coding
description: Apply when generating shadcn/ui code, signaled by components.json in the project root and components under components/ui/. Covers the copy-paste component model, compound components, theming with CSS variables, Field/DataTable integrations, and CLI conventions. Does NOT cover general React or Tailwind CSS patterns.
---

# shadcn/ui coding

Project conventions override these defaults. Read `components.json` first: `style` (its prefix names the primitive library), `tailwind`, `aliases`, `rsc`. Then read the local source in `components/ui/` and `package.json` for the React version; the local source is the truth for props and structure.

## Primitive library

The `style` prefix in `components.json` tells you which primitives the components wrap: `base-*` is Base UI, `radix-*` and the older `new-york` are Radix UI, `aria-*` is React Aria. This changes the API:

| | Radix UI | Base UI |
|---|---|---|
| Swap the rendered element | `asChild` on the parent | `render={<Button variant="outline" />}` |
| Package | unified `radix-ui` (older projects: `@radix-ui/react-*`) | `@base-ui/react` |

Both libraries use `onValueChange` for Select-like inputs and `onCheckedChange` for Checkbox and Switch. React Aria projects: read the local source before composing. For any component, `npx shadcn@latest docs <component>` prints its usage and its Composition tree (what wraps what).

## Never rules

- **Never import shadcn components from npm.** shadcn is not a package. Import from the alias in `components.json`: `import { Button } from "@/components/ui/button"`.
- **Never flatten compound components.** Dialog, DropdownMenu, Select, AlertDialog, Menubar, NavigationMenu, ContextMenu, and Tabs need their nested structure (for example `Dialog > DialogContent > DialogHeader > DialogTitle`); removing wrappers breaks ARIA roles and keyboard navigation.
- **Never nest a `<Button>` inside a Trigger.** Triggers render their own `<button>`, so nesting produces invalid HTML. Use `asChild` (Radix) or `render` (Base UI) to render your element instead.

```tsx
// Radix
<DialogTrigger asChild><Button variant="outline">Open</Button></DialogTrigger>
// Base UI
<DialogTrigger render={<Button variant="outline" />}>Open</DialogTrigger>
```

- **Never hardcode colors or compose `className` with template literals.** Use semantic tokens (`bg-primary text-primary-foreground`) and `cn()`; the rules live in tailwind-css-coding.
- **Never spread `{...field}` on Select, Checkbox, or Switch.** They take `onValueChange` / `onCheckedChange`, not `onChange`, so the spread's `onChange` is silently ignored. Wire `value` and the handler explicitly.
- **Never define DataTable `columns` inside the component.** A new array every render triggers TanStack Table's referential-equality checks and loops. Define them at module level.
- **Never build custom modals, dropdowns, or tooltips.** Use Dialog, DropdownMenu, Tooltip, Popover, or Sheet; hand-built versions lack focus trapping, keyboard navigation, and portals.
- **Never nest `TooltipProvider`.** Mount it once at the app root.
- **Never invent props.** Components only have the props in their local source.
- **Never use `npx shadcn-ui@latest`.** The CLI is `npx shadcn@latest`.
- **Never use the old Radix `toast` component** (deprecated in favor of Sonner). Use the toast library the project already has (Sonner, or the newer `toast` component on Base UI styles), and add one with `npx shadcn@latest add sonner` only if none exists.

## Component architecture

`components/ui/` is CLI-managed shadcn source. Put app-specific behavior in wrappers under `components/app/` (for example a `ConfirmDialog` built on `Dialog`) and edit `components/ui/` directly only for global style changes. Compare against upstream with `npx shadcn@latest add <component> --diff`.

shadcn components use `cva` (class-variance-authority). Export `*Variants` separately to style non-native elements: `<Link className={cn(buttonVariants({ variant: "outline" }))}>`. Use `VariantProps<typeof xVariants>` for variant prop types.

Blocks are pre-composed layouts (dashboard, auth, forms). Install them from the official registry or from third-party registries declared in `components.json` under `registries` (`"@acme": "https://example.com/registry/{name}.json"`).

## Theming

- **Tailwind v4:** OKLCH colors with `@theme inline` (`--color-primary: oklch(0.205 0 0);`).
- **Tailwind v3:** HSL values (`--primary: 222.2 47.4% 11.2%`) in `@layer base`, referenced as `hsl(var(--primary))` in `tailwind.config.ts`.

Add a custom color by defining the variable and its `-foreground` pair in the theme, then use the semantic class (`bg-brand text-brand-foreground`). Dark mode setup is in tailwind-css-coding. In Next.js use `next-themes`; elsewhere use the framework's equivalent or a small provider that toggles `.dark` and persists the choice.

## Composition patterns

- **DropdownMenu opening a Dialog (Radix):** wrap both in a shared parent, call `e.preventDefault()` in the menu item's `onSelect` so the menu does not steal focus from the dialog, and control the dialog with `useState` rather than `DialogTrigger`, since the trigger sits inside the menu.
- **Sidebar:** `SidebarProvider` wraps `AppSidebar` and `SidebarInset`; `SidebarTrigger` goes in the inset's header and page content below it.

## Forms

Current shadcn styles compose forms from `Field`, `FieldLabel`, `FieldError`, `FieldDescription`, and `FieldGroup` with react-hook-form's `Controller` (not the older `Form` wrapper). Set `data-invalid` on `Field` and `aria-invalid` on the control. Always provide `defaultValues`, which avoids controlled/uncontrolled warnings.

```tsx
const form = useForm<z.infer<typeof schema>>({
  resolver: zodResolver(schema),
  defaultValues: { name: "", role: "" },
});

<form onSubmit={form.handleSubmit(onSubmit)}>
  <FieldGroup>
    <Controller name="name" control={form.control} render={({ field, fieldState }) => (
      <Field data-invalid={fieldState.invalid}>
        <FieldLabel htmlFor={field.name}>Name</FieldLabel>
        <Input {...field} id={field.name} aria-invalid={fieldState.invalid} />
        {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
      </Field>
    )} />
    <Controller name="role" control={form.control} render={({ field, fieldState }) => (
      <Field data-invalid={fieldState.invalid}>
        <FieldLabel htmlFor="role">Role</FieldLabel>
        <Select name={field.name} value={field.value} onValueChange={field.onChange}>
          <SelectTrigger id="role" aria-invalid={fieldState.invalid}><SelectValue placeholder="Select a role" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="member">Member</SelectItem>
          </SelectContent>
        </Select>
        {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
      </Field>
    )} />
  </FieldGroup>
</form>
```

Projects on the legacy `new-york` style may still use the `Form` wrapper (`FormField` > `FormItem` > `FormLabel` + `FormControl` > input + `FormMessage`). If the project has `components/ui/form.tsx`, keep that pattern: `FormControl` must wrap exactly one child (it uses a Slot), and Select still takes explicit `onValueChange`.

## Data tables

Keep `columns.tsx` (stable module-level definitions), a reusable `data-table.tsx` shell (pagination, sorting, filtering), and a page that fetches data and renders `<DataTable columns={columns} data={data} />`. Pair column features with table configuration:

| Column feature | Required table config |
|---|---|
| `enableSorting` | `getSortedRowModel()` in `useReactTable` |
| `enableColumnFilter` | `getFilteredRowModel()` |
| Row actions cell | Column with `id: "actions"` and no `accessorKey` |

For a selection column, the header and cell Checkboxes use `onCheckedChange={(value) => row.toggleSelected(!!value)}` (and `table.toggleAllPageRowsSelected(!!value)` in the header).

## Accessibility

The primitives handle focus trapping, arrow-key menu navigation, `aria-expanded`/`aria-controls`, and Escape to close. You handle `FormLabel`/`FieldLabel` association, visible focus rings, color contrast (WCAG AA), `alt` text, and a `DialogTitle` and `DialogDescription` in every Dialog (the primitives warn when missing).

## References

- `references/cli-and-tables.md`: CLI commands, `components.json` fields, deprecations, and decision tables for overlay and selection components.
- `references/testing.md`: testing portaled components, `userEvent`, and jsdom gaps.
