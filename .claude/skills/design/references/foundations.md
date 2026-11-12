# Visual foundations

These rules apply to everything the design skill builds, and they are the checklist for a request to review or improve how a screen looks. They come from Apple's design guidance.

## Typography

- Letter spacing depends on size. Large display text takes negative tracking (about `-0.02em`), body text stays near `0`, and small text takes slightly positive tracking. One `letter-spacing` value for every size is wrong somewhere.
- Line height runs opposite to size: tight on large headings (about 1.05), looser on body copy (about 1.5), and tighter again in dense, information-heavy UI.
- Build hierarchy from weight, size and line height together. Emphasize with weight, which adds presence without taking space.
- Size spacing in `rem` or `em` so that the layout scales with the user's text size.
- Start from the system font and replace it only for a reason.

```css
.display {
  font-size: clamp(2rem, 5vw, 4rem);
  line-height: 1.05;
  letter-spacing: -0.02em;
  font-optical-sizing: auto;
}
```

## Clarity

- Simplicity means the core purpose stands out. Hiding everything behind one menu looks minimal and is harder to use. Order, spacing and contrast make the most important thing the most visible. Show the common path first and advanced options one level deeper.
- Every screen answers four questions: where am I, where can I go, what is here, and how do I get out.
- Place a control near what it affects. A control that needs a label to explain what it changes has a weak mapping.
- Things that look the same behave the same and sit in the same place.
- Name navigation items for their contents ("Progress", "Library"), not with umbrella words ("Home").

## Feedback

- Feedback comes in four kinds: status, completion, warning and error. Confirm meaningful actions, show ongoing status, warn before a problem, and validate inline, not on submit.
- Offer undo for slips. Keep confirmation dialogs for destructive, irreversible actions, because overuse trains people to click through.
- Every spacing, timing and alignment value is a choice you can defend. Misaligned icons and layouts that break at another size read as carelessness.

## Principles

- **Purpose.** Decide what not to build. Every feature spends the user's time, attention and trust.
- **Responsibility.** Ask for data at the moment it is needed, and only for what is needed. Anticipate misuse and harm, and add previews, confirmations or disclaimers where the risk is real.
- **Familiarity.** Build on what people already know. Break a familiar pattern only when testing shows the new one is better.
- **Flexibility.** Adapt to the platform, the situation and the full range of abilities. When no single layout fits everyone, let people rearrange controls and hide what they do not use.
- **Delight.** It results from getting the rest right. Decide the emotion the product should leave (calm, confident, excited) and reinforce it in every decision.

## Materials and depth

Translucent surfaces form a floating layer that gives structure without taking focus. On the web, build them with `backdrop-filter`.

- Navigation bars, toolbars and sheets are translucent layers over content that scrolls underneath, not opaque bars that take a fixed strip.
- Material weight encodes hierarchy. Heavier, darker materials separate structural regions such as sidebars, and lighter ones draw attention to interactive elements. Never stack one light translucent surface on another, because legibility collapses.
- Bigger surfaces read as thicker: a stronger blur and a deeper shadow than small chips get.
- A modal task dims the background with a scrim. A parallel panel that does not block uses translucency and offset, with no scrim.
- Text over a blurred surface needs more contrast and slightly more weight than flat gray. Put color on a solid layer.
- Where content meets floating chrome, fade with a small blur or gradient mask in place of a 1px divider.
- A glass surface enters by animating blur radius and scale together, not opacity alone.

```css
.toolbar {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(255, 255, 255, 0.4);
}
```

## Accessibility preferences

- `prefers-reduced-transparency: reduce`: raise the background opacity and drop the blur.
- `prefers-contrast: more`: near-solid backgrounds with a defined, contrasting border.
- `prefers-reduced-motion: reduce`: see `references/motion.md`.
- Avoid moving backgrounds that fill the viewport, slow looping oscillation and abrupt brightness jumps. Ease the change between dark and light themes.

```css
@media (prefers-reduced-transparency: reduce) {
  .toolbar { background: white; backdrop-filter: none; }
}
```

## Component craft

- Good defaults matter more than options. Most people never customize, so the default easing, timing and look have to be right.
- Keep adoption cheap: a component mounted once and a plain function call beat hooks, context and setup.
- Handle edge cases where the user never sees them: pause toast timers while the tab is hidden, fill the gaps between stacked toasts so that hover is not lost, capture the pointer during a drag.
- A component's easing, duration and look match each other and the product.

## Process

- Prototype interactively (`references/prototype.md`). A working prototype shows what static designs hide and sets the bar for the final build.
- Design interaction and visuals together. Motion is not a layer added after the pixels.
- Test with real people in a real context, and review the result again with fresh eyes.

## Reviewing a screen

Report one row per issue, with the location as `file:line`, what is there now, the change, and the rule above that it breaks. Order the rows by how much each one hides the screen's main purpose.
