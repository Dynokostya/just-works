---
name: design
description: >
  Design work on a web interface. Use when asked to prototype a UI piece or
  show several options for it; to evaluate a UI, prototype or flow for
  first-time-user failures, expert task time, target size and distance, choice
  time or where the eye goes first ("cognitive walkthrough", "KLM", "Fitts",
  "usability inspection", "will users find this", "how long will this task
  take"), or to verify or re-run a prior evaluation report; to build, review,
  suggest or audit animation and motion, including drag, swipe and sheet
  gestures; to name a motion effect from a loose description ("what's it
  called when"); to review typography and visual hierarchy; or when a web app
  feels wrong on a phone. Does not predict conversion, preference or emotion.
---

# Design

Design work on a web interface comes in five jobs. The request decides which one runs. Load the reference for that job.

| Job | Use it to | Reference |
|---|---|---|
| Prototype | Build several different versions of one UI piece behind a picker, then promote the one the user chooses | `references/prototype.md` |
| Evaluate | Predict where a first-time user fails and how long a practiced user takes, by inspection | `references/evaluate.md` |
| Motion | Build an animation, review existing motion, or find where motion is missing | `references/motion.md` |
| Visual polish | Review or improve typography, hierarchy, materials and clarity | `references/foundations.md` |
| Mobile feel | Fix what makes a web app feel like a website on a phone | `references/mobile-feel.md` |

Load these as well when the job reaches them:

| Need | Reference |
|---|---|
| Ready-to-build animation code for common components | `references/motion-recipes.md` |
| Drag, swipe, sheets, springs and momentum | `references/gestures.md` |
| A prioritized motion audit of a whole app, with plans other agents can execute | `references/motion-audit.md` |
| The name of a motion effect from a loose description | `references/motion-vocabulary.md` |
| A library for a UI task when the project has not chosen one | `references/libraries.md` |

Rules for every job:

- Use the project's own tokens: colors, radii, spacing, fonts, and easing and duration variables. Extend them. A parallel set is a defect.
- Whatever a job builds also meets `references/motion.md` and `references/foundations.md`. Load both when the job writes interface code.
- When a result depends on something code cannot settle, such as how an animation feels or how a page behaves on a real phone, say so and name the check.
