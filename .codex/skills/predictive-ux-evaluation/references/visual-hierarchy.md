# Visual hierarchy / first fixation

**Predicts:** a ranking of where gaze is *likely* to go first, either from a named computational saliency model or from an explicit heuristic. Task (what the user is trying to do) often overrides bottom-up saliency — Yarbus (1967).

**Does not predict:** what the user will click, conversion, preference, or emotion. A first-look ranking is not a walkthrough Q2 answer by itself; Q2 still needs the control to be the one that serves the goal.

## Name the method on every pass

| Method | When you may use it | Label in the report |
|--------|---------------------|---------------------|
| **Itti & Koch (2001)** computational saliency (and descendants: GBVS, etc.) | You actually ran the model on a screenshot | `model (Itti–Koch)` or the exact variant |
| **DeepGaze II / III** (Kümmerer et al.) | You actually ran it | `model (DeepGaze II)` / `III` |
| **Heuristic ranking** | Default. No saliency model available | `heuristic` |

If no validated model ran, the ranking is **heuristic**. Do not imply eyetracking. If a local DeepGaze or Itti–Koch tool is available, run it and label the method; do not stall the pass to install one. F-pattern / Z-pattern (Nielsen 2006 and later popularizations) are observations on specific page types, not a general law — cite them only as a heuristic, for pages that resemble those stimuli.

## Heuristic ranking (default)

Score only elements in the first viewport of the task screen. Rank by these cues. Faces outrank equally large non-face objects.

1. **Faces / people** — photographs of faces attract early fixations independently of low-level saliency (Cerf, Harel, Einhäuser & Koch 2008). On a page of portraits they dominate. Still a heuristic here unless a face-aware model (e.g. DeepGaze) ran.
2. **Contrast** against the immediate background (luminance and chromatic)
3. **Size** of the painted element (not the hit target — that's Fitts)
4. **Position** — centre and top-left of the viewport attract more first looks on typical web pages; this is a prior, not a law
5. **Isolation** — a singleton in an otherwise uniform field (von Restorff-ish; still a heuristic here)
6. **Motion / flicker** if present (preattentive; also a banner-blindness risk)

Write the rank with the winning cues, e.g. "1. grid portraits — faces, 29% of the viewport, top edge at centre."

**When cues disagree** (size on the grid, motion on a strip): do not force a total order. Put them in one band (`1–2`) and say which cue favoured which. A later rank can still be a singleton.

**Behind a veil or blur** (modal backdrop, `filter: blur`): do not count those faces or that motion as the face/motion cue. Label them faint or skip them. The ranking is of what is actually lookable.

## Task modulation

For a goal-directed task, boost elements whose labels match the walkthrough goal (top-down). A huge decorative image can win a bottom-up model and still lose a task-weighted ranking. State which ranking you are reporting if you compute both.

## Evidence

Screenshot of the first viewport; for heuristic rows, the measured font-size / contrast / bounding box. For a model, the saliency map or the model's top-*k* coordinates plus the screenshot.
