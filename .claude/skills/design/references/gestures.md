# Gestures

Use this file for anything the user drags, swipes, flicks or throws: sheets, drawers, carousels, sliders, dismissible cards. An interface feels fluid when it behaves like a physical object: it responds at once, moves continuously, carries momentum, resists at its limits and can be redirected in mid-motion. The rules come from Apple's guidance on fluid interfaces.

## Respond immediately

- Show feedback on pointer-down. Waiting for the click or the release reads as lag.
- Look for delay on the input path: debounces, artificial timers, waits for a transition to finish, the 300ms tap delay. Remove whatever is not essential.
- During a drag, a slider move or a sheet pull, update the element 1:1 with the pointer for the whole gesture. Animating only when the gesture ends is too late.

## Track the pointer 1:1

- The element stays under the finger at the point where it was grabbed. Snapping its center to the pointer breaks the illusion.
- Use Pointer Events with `setPointerCapture`, so that tracking continues when the pointer leaves the element.
- Keep a short history of positions and timestamps from the last few `pointermove` events. The release velocity comes from it.

```js
el.addEventListener('pointerdown', (e) => {
  el.setPointerCapture(e.pointerId);
  const grabOffset = e.clientY - el.getBoundingClientRect().top;
  // track position and timestamp history for velocity
});
```

## Keep every animation interruptible

The user can grab a moving element at any moment and reverse it. A closing sheet that is grabbed again follows the finger. It does not finish closing first.

- Never lock out input during a transition.
- Start each new animation from the value on screen now, never from the target of the previous one. Starting from the target makes the element jump.
- CSS transitions and keyframes cannot be grabbed and reversed smoothly, so gesture-driven motion uses springs, which start from the current value and velocity.
- When a gesture reverses, carry the velocity through the change of target. Replacing one animation with another at the reversal creates a visible stop.
- Animate X and Y with separate springs. One spring on a 2D distance falls out of sync when the two velocities differ.

## Springs

A spring has no fixed duration. Two parameters describe it:

- **Damping ratio** controls overshoot. `1.0` settles with no bounce. Below `1.0` it overshoots, and lower means bouncier.
- **Response** is how quickly the value approaches the target, in seconds. Lower is snappier.

Start most interface motion at damping `1.0`. Add bounce (damping about `0.8`) only when the gesture itself carried momentum: a flick, a throw, a drag release. Overshoot on a menu that faded in feels wrong, and overshoot on a card that was flicked feels right.

| Interaction | Damping | Response |
|---|---|---|
| Move or reposition | 1.0 | 0.4 |
| Rotation | 0.8 | 0.4 |
| Drawer or sheet | 0.8 | 0.3 |

In Motion, the `bounce` and `duration` options map closely to damping and response:

```js
import { animate } from 'motion';

animate(el, { y: 0 }, { type: 'spring', bounce: 0, duration: 0.4 });        // no overshoot
animate(el, { y: target }, { type: 'spring', bounce: 0.2, duration: 0.4 }); // after a flick
```

## Hand off the velocity

When the gesture ends, the animation continues at the finger's velocity, so that dragging and animating look like one motion. Pass the release velocity as the spring's initial velocity. Motion takes it in pixels per second (`velocity`). An API that wants relative velocity gets `gestureVelocity / (targetValue - currentValue)`: an element at `y=50` heading to `y=150` with the finger moving at 50 px/s starts at `0.5`.

## Project the momentum

Choose the snap target from where the gesture is going, not from where it was released. Project the resting position from the release velocity, then snap to the target nearest that point. This is what makes a flick throw the element.

```js
// decelerationRate: 0.998 for a normal scroll feel, 0.99 for snappier
function project(initialVelocity /* px/s */, decelerationRate = 0.998) {
  return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
}

const projectedEndpoint = currentPosition + project(releaseVelocity);
const target = nearestSnapPoint(projectedEndpoint);
animateSpringTo(target, { velocity: releaseVelocity });
```

Decide between committing and reversing from the sign of the velocity at release, not from the position.

For dismissal alone, a simpler test works: dismiss when the distance passes a threshold or when `Math.abs(distance) / elapsedMs` exceeds about `0.11`.

## Resist at the boundary

Past an edge, the element follows the finger less and less. A hard stop looks frozen, and rising resistance says that there is nothing more here.

```js
function rubberband(overshoot, dimension, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
}
```

## Keep paths consistent

- An element leaves by the path it entered. A panel that slides in from the right dismisses to the right.
- A menu, popover or sheet grows from the element that opened it (`transform-origin` at the trigger).
- The frames in between point at the outcome: a panel grows toward the finger that opened it.

## Recognizing the gesture

- A tap highlights on touch-down and commits on touch-up. Allow about 10px of slack around the target, and let the user cancel by dragging away.
- A drag commits to a direction after about 10px of movement, then tracks 1:1.
- Detect every plausible gesture from the first movement and cancel the losers once the intent is clear. Events that report only a finished swipe throw away the tracking needed for feedback.
- Double-tap detection delays every single tap. Pay that cost only where double-tap exists.
- After the drag begins, ignore additional touch points, or the element jumps when the user switches fingers.

## Smoothness

- Animate `transform` and `opacity`, driven by `requestAnimationFrame` or a spring library, and add `will-change` where motion is about to start.
- Set `transform` on the dragged element directly. A CSS variable on the parent recalculates styles for every child.
- For very fast motion, a slight blur or stretch reads better than a sharp streak.

## Sound and haptics

When motion is paired with sound or haptics, three rules hold. The cause is obvious: feedback fires on the event that caused it, such as the toggle flipping or the item snapping home. The visual, the sound and the haptic land on the same frame. Feedback is kept for moments that matter (success, error, commit, snap), because constant feedback teaches people to ignore it.

## Reduced motion

With `prefers-reduced-motion: reduce`, replace slides, springs and parallax with short opacity cross-fades and drop overshoot. Keep the feedback itself.
