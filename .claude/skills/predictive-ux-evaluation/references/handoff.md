# Hand-off to real humans

Load this when writing the **For real humans** table and when assigning **severity**.

## Severity (task completion only)

Required on every synthesized finding. Not a conversion claim.

| Level | Meaning |
|-------|---------|
| **Blocker** | A first-time user is predicted to be unable to complete the task, with no visible alternative |
| **Major** | Predicted to fail the task, or its central part, on the intended path; recovery needs exploring beyond the start screen |
| **Minor** | A detour, stall, or wrong turn with a visible way back |

A `weak yes` is still a failure story. Severity is how far that story is from completing the task, not how sure you are. Keep grades (`no` / `weak yes`) on the walkthrough rows; put severity only on synthesized findings.

## Sample size *n* (conventions, not power)

Use these unless the user names a number. Say they are conventions.

| Method | n | Source of the convention |
|--------|---|--------------------------|
| Five-second test / first-click / unmoderated recall | 20–30 per viewport | Common unmoderated panel size for a first-impression item |
| Moderated think-aloud / task walk | 5–8 per viewport | Discount usability (Nielsen) |
| Timed expert trials to check KLM | 8–12 after 3 practice runs per path | Enough for a median and a spread; not a power calc |
| Pointing study to fit Fitts *a*, *b* | ≥ 12, ISO 9241-411 style | Device-level fit, not a page preference test |
| First-fixation / heatmap | ~39 | Pernice & Nielsen 2009, for a stable heatmap |
| Single-device engineering check (e.g. iOS status-bar tap) | 1 device | Mechanism, not a user sample |

One row in the hand-off table can reuse the same sessions (`same 5–8`). Eye-tracking subsets sit inside the larger recall sample.

Do not treat these as proof of conversion, preference, or emotion. They only confirm or refute a named prediction from this pass.
