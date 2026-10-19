# Testing shadcn/ui components

Reference for the shadcn-ui-coding skill.

## Portal rendering

Dialog, Popover, Sheet, Select, and DropdownMenu content render into a portal on `document.body`. Query by role from `screen`, not by DOM hierarchy:

```tsx
// Wrong: content is not inside the trigger's DOM subtree
const content = within(triggerParent).getByText("Option A");

// Correct
const content = screen.getByRole("option", { name: "Option A" });
```

## User events

Use `userEvent.setup()` rather than `fireEvent`. Triggers such as Select and DropdownMenu respond to pointer events, and `userEvent` dispatches the full pointer sequence while `fireEvent.click` sends only a click:

```tsx
import userEvent from "@testing-library/user-event";

it("opens the dialog", async () => {
  const user = userEvent.setup();
  render(<MyDialog />);
  await user.click(screen.getByRole("button", { name: "Open" }));
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});
```

## jsdom gaps

jsdom implements `PointerEvent` but not `ResizeObserver`, pointer capture (`hasPointerCapture`, `releasePointerCapture`), or `scrollIntoView`. Components that call them (Select, Sheet, Drawer, Resizable) throw until the test setup stubs them:

```ts
globalThis.ResizeObserver ??= class {
  observe() {}
  unobserve() {}
  disconnect() {}
};
Element.prototype.hasPointerCapture ??= () => false;
Element.prototype.releasePointerCapture ??= () => {};
Element.prototype.scrollIntoView ??= () => {};
```

For behavior that depends on real layout or gestures (resizing, swipe to dismiss), use a real browser environment such as Playwright.
