# Testing shadcn/ui components

Reference for the shadcn-ui-coding skill.

## Portal rendering

Dialog, Popover, Sheet, Select, and DropdownMenu content render into a portal at `document.body`. Query by role, not by DOM hierarchy:

```tsx
// Wrong: content is not inside the trigger's DOM subtree
const content = within(triggerParent).getByText("Option A");

// Correct: query from screen (portaled to body)
const content = screen.getByRole("option", { name: "Option A" });
```

## User events

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

## JSDOM limitations

JSDOM does not implement `pointerdown` or `resize` observers fully. For components that rely on these (Sheet, Drawer, Resizable), test in a real browser environment (Playwright) or mock the specific Radix primitive.
