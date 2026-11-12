# Motion

Use this file to build an animation, to review existing motion, and to find where motion is missing. The first question is always whether the thing should animate at all. Deciding that it should not is a valid result.

Related files: ready-to-build code for common components is in `references/motion-recipes.md`, drag and swipe interactions follow `references/gestures.md`, and an audit of a whole app follows `references/motion-audit.md`.

## Decide in this order

**1. Should it animate?** By how often users see it:

| Frequency | Decision |
|---|---|
| 100+ times a day (keyboard shortcuts, command palette) | No animation |
| Tens of times a day (hover, list navigation) | Nearly imperceptible, or none |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare or first-time (onboarding, success, celebration) | Delight is allowed here |

Actions started from the keyboard never animate.

**2. What is it for?** Name one: feedback, spatial consistency, state indication, preventing a jarring change, explanation (marketing and onboarding only), or delight (rare tier only). If none fits, do not build it. Data the user is reading or acting on does not move for style.

**3. Which tool?** The cheapest that works:

| Need | Tool |
|---|---|
| Hover, press, color, a state toggled by a class or attribute | CSS transition |
| Entry on mount with no JavaScript state | CSS `@starting-style` |
| Predetermined motion that must stay smooth while the page loads | CSS animation |
| Programmatic control with CSS performance | Web Animations API (`element.animate()`) |
| Springs, layout animation, exit animation, gesture-driven values | The project's motion library, or Motion (motion.dev) when it has none |

When the task needs a component (a toast, drawer, command menu or dropdown), use the one from the project's UI library. Do not hand-roll it.

**4. Which properties?**

- Animate `transform` and `opacity` only. `clip-path` is also fine. `height` is tolerated for accordions.
- Never start from `scale(0)`. Start from `scale(0.9)` to `scale(0.97)` with `opacity: 0`.
- Popovers, dropdowns, menus and tooltips scale from their trigger (`transform-origin`). Modals stay centered.
- Prefer percentages in `translate()`: `translateY(100%)` moves an element by its own height.
- `scale()` also scales the element's children, which is what makes a press read as physical.
- `rotateX()` and `rotateY()` with `transform-style: preserve-3d` give flips, orbits and depth without JavaScript.
- In Motion (Framer Motion), the `x`, `y` and `scale` shorthands run on the main thread and drop frames under load. Use the full string: `animate={{ transform: "translateX(100px)" }}`.
- Do not drive a child's transform from a CSS variable on its parent. That recalculates styles for every child. Set `transform` on the element.

**5. Easing and duration.**

| Situation | Easing |
|---|---|
| Entering or exiting | ease-out |
| Moving or morphing on screen | ease-in-out |
| Hover or color change | ease |
| Constant motion (marquee, progress) | linear |

Never use `ease-in` on interface elements: it delays the moment the user is watching. The built-in curves are weak, so use these unless the project defines its own:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);
```

For a curve that is not here, take one from easing.dev or easings.co. Do not invent one.

| Element | Duration |
|---|---|
| Button press | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–500ms |

Interface animation stays under 300ms. Modals and drawers may take longer, up to the limit in the table. Speed changes how fast the app seems: a spinner that turns faster makes the same load feel shorter.

Use a spring for drag with momentum, for gestures the user can interrupt or reverse, and for decorative mouse tracking: `{ type: "spring", duration: 0.5, bounce: 0.2 }`. Keep bounce between 0.1 and 0.3, and reserve it for drag-to-dismiss and playful moments. For full physics control use `{ type: "spring", mass: 1, stiffness: 100, damping: 10 }`. For decorative mouse tracking, pass the value through `useSpring` so that it has momentum, because a value tied straight to the pointer looks artificial.

**6. Interruption and exit.**

- Anything triggered rapidly (toasts, toggles) uses transitions, which retarget from the current value. Keyframes restart from zero.
- An element exits the way it entered. A toast that slides in from the bottom leaves through the bottom.
- Timing is asymmetric where the user is deciding: slow on the deliberate phase (a hold-to-confirm press, 2s linear) and fast on the response (release, 200ms ease-out).
- Where `@starting-style` is not available, set a `data-mounted` attribute in an effect after the first render and transition on that.

**7. Reduced motion and hover gating** ship with the animation.

```css
@media (prefers-reduced-motion: reduce) {
  .element { animation: fade 0.2s ease; } /* keep opacity and color, drop movement */
}
@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); }
}
```

Reduced motion means fewer and gentler animations. Keep the transitions that help understanding and remove movement.

## Values by component

| Component | Motion |
|---|---|
| Button press | `:active { transform: scale(0.97) }` with `transition: transform 160ms var(--ease-out)` |
| Tooltip | `scale(0.97)` and opacity, 125ms `--ease-out`, origin at the trigger. Once one tooltip is open, the next ones open instantly |
| Dropdown, popover | `scale(0.95)` and opacity, 200ms `--ease-out`, origin at the trigger |
| Modal | `scale(0.96)` and opacity, 250ms `--ease-out`, origin at the center. The backdrop fades with it |
| Drawer, sheet | `translateY(100%)` to `0`, 500ms `--ease-drawer`. Dismiss on a flick: velocity above about 0.11 px/ms, whatever the distance |
| Toast | `@starting-style { opacity: 0; transform: translateY(100%) }` with `transition: 400ms ease`. Exits by the same edge |
| Accordion | `height` and opacity, 200ms `--ease-out`, to a measured height and never to `auto`. Keep it short: it costs layout on every frame |
| Tab indicator | Duplicate the tab list styled as active, clip the copy to the active tab with `clip-path`, and animate the clip: 250ms `--ease-in-out` |
| Hold to confirm | A colored overlay from `clip-path: inset(0 100% 0 0)` to `inset(0 0 0 0)`: 2s linear while pressed, 200ms `--ease-out` on release |
| List or grid entrance | `translateY(8px)` and opacity, 300ms `--ease-out`, 30–80ms stagger between items. Never block interaction during a stagger |
| Scroll reveal | Marketing pages only. `clip-path: inset(0 0 100% 0)` to `inset(0 0 0 0)`, 600ms `--ease-in-out`, once, when the element enters the viewport |
| Before and after slider | Two stacked images. Clip the top one with `clip-path: inset(0 50% 0 0)` and set the right inset from the drag position |
| Crossfade that looks like two objects | `filter: blur(2px)` and `opacity: 0.7` during the transition, 200ms. Keep blur under 20px, which is expensive in Safari |
| Drag | Capture the pointer when the drag starts, ignore extra touch points, and add rising resistance past a boundary in place of a hard stop |

Match the motion to the product's personality: a playful product can be bouncier, and a dashboard stays crisp and fast.

## Reviewing motion

Flag by default. A transition that works but feels sluggish, starts from the wrong origin, fires too often or drops frames is a regression. Report one table with a row per issue, then a verdict.

| Before | After | Why |
|---|---|---|
| `transition: all 300ms` | `transition: transform 200ms ease-out` | Name the properties; `all` animates unintended ones |
| `transform: scale(0)` | `transform: scale(0.95); opacity: 0` | Nothing appears from nothing |

Also flag: `ease-in` on an interface element, a weak built-in curve on a deliberate animation, an entrance that only fades with no starting transform, `transform-origin: center` on a popover anchored to a trigger, animation on a keyboard shortcut or an action used 100+ times a day, a duration over 300ms with no reason, keyframes on toasts or toggles, animated `width`, `height`, `margin`, `padding`, `top` or `left`, Motion `x`, `y` or `scale` props on motion that runs while the page is busy, a CSS variable on a parent that drives a child's transform, hover motion with no `(hover: hover)` gate, missing reduced-motion handling, the same timing for press and release on a hold interaction, and a group that appears all at once where a stagger belongs.

Prefer the earlier fix in this list: delete the animation, reduce it, fix the easing, fix the origin, make it interruptible, move it to `transform` and `opacity`, make the timing asymmetric, polish (blur for a crossfade, stagger for a group, a spring where the element should feel alive), then add reduced-motion and hover gating.

After the table, group any remaining comments by impact, highest first, and leave out empty groups: feel-breaking regressions, animations that should be removed or reduced, performance, interruptibility and timing, origin and cohesion, accessibility.

Close with **Block** or **Approve**, citing `file:line`. Block for a sluggish or comes-from-nowhere animation, motion on a keyboard or high-frequency action, `scale(0)` or `ease-in` on the interface, or a layout-property animation with an easy fix. Approve when none of those is present, durations and easing are within bounds, interruptibility is handled where it is needed and reduced motion is respected.

## Finding missing motion

This is a filter more than a finder: expect to reject most candidates. It reports and changes no code. Suggest at most 5 to 7 places for a whole app, fewer for one view, ordered by leverage.

Before sweeping, note the product's personality and a rough frequency map of its surfaces. A crisp dashboard earns fewer and subtler suggestions than a playful consumer app.

Each candidate has to pass four questions in order: frequency (step 1 above), purpose (step 2), speed (it works inside the duration budgets) and function (decoration on dense, functional UI hinders).

Where to look:

- **Missing feedback**: pressable elements with no `:active` state; destructive actions confirmed by a plain click.
- **Teleporting state**: content that swaps, appears or vanishes instantly; accordions that snap; list items added or removed with no transition.
- **No spatial story**: popovers and menus with no link to their trigger; surfaces that exit a different way than they entered.
- **Group entrances**: a grid that pops in at once on a page seen occasionally.
- **Gestures**: draggable elements that snap with no physics.
- **Flat rare moments**: first run, empty states, success and completion.

Useful searches: conditional renders with no transition (`{isOpen &&`, `display: none` toggles), `onClick` handlers on elements with no `:active` or transition styles, accordion markup, drag handlers, `.map(` renders of entering lists, and empty-state and success components.

Report three parts: a table of surviving suggestions (Location, Today, Purpose, Frequency, Suggested motion with exact values), a list of two to five rejected candidates with the question that rejected each, and one paragraph on how much motion this interface needs and which suggestion has the most leverage.

## After building an animation

Report the frequency tier and the named purpose, then the tool, properties, curve and duration in a line each. When the result depends on feel that code cannot settle (a crossfade, a spring's bounce), say so and name the check: play it at 2 to 5 times the duration, step through it frame by frame in the browser's animation inspector, and try gestures on a real phone.

In slow motion, check that colors cross over smoothly with no two states overlapping, that the easing does not start or stop abruptly, that the transform origin is right, and that properties animated together stay in sync. Look again the next day, when flaws missed during the work become visible.
