# Verification mode

Load this when the user points at a **prior report** from this skill (or asks to re-run, verify, or mark findings resolved).

A verification pass is the same methods on the same tasks, plus a status for every prior finding and a time comparison that splits **encoding change** from **page change**.

## Inputs

- The prior report path
- The current artifact (same product, possibly a later build)
- The prior task list, reused unless a new surface exists (add it as a new task; do not silently drop an old one)

## Status vocabulary

Use only these, in the Status column:

| Status | Meaning |
|--------|---------|
| **resolved** | The predicted failure is gone on the current artifact |
| **partly resolved** | Some of the predicted failure is gone; the rest is still there |
| **still open** | The same failure is still there |
| **still open, kept by decision** | Still there, and a recorded product decision owns it |
| **not re-tested** | This pass did not re-walk that step |

Every status row needs evidence on the current artifact.

## Times across skill versions

Do not compare two `T_execute` numbers from different encodings as if the page moved.

1. Read the prior row's **operator string** and its **encoding** (`KLM-web-0`, `KLM-web-1`, …). If the prior report has no encoding, treat it as `KLM-web-0`.
2. Re-sum that string with **this** file's current encoding (`klm-goms.md`) → `T_reencoded`.
3. Encode the path on the current page → `T_now`.
4. Report:

| Task | Path | Prior T | Prior encoding | T_reencoded | T_now | Δ encoding | Δ page |
|------|------|---------|----------------|-------------|-------|------------|--------|

- **Δ encoding** = `T_reencoded − prior T`. Same operators, new constants. Example: `6K` at 0.28 s → `6 K_soft` at 0.50 s is encoding, not the page.
- **Δ page** = `T_now − T_reencoded`. Operator string or measured R changed.
- If the prior string is missing, say so and skip the split. Do not invent operators to make the old sum.

Fitts IDs compare only when W, D, origin, and *a*, *b* source match. If any of those changed in the skill, recompute the prior row with current rules and label it **recomputed**.

## Order of the report

Run the live evaluation first (lane → first look), then:

```
## Verification of [prior report]
Prior encoding: …
This encoding: KLM-web-1

### Finding status
| Finding | Prior severity | Status | Evidence |

### Time comparison
| Task | Path | Prior T | Prior encoding | T_reencoded | T_now | Δ encoding | Δ page |
```

New failure points from this pass get ordinary findings (`V-…` or the next free prefix). Do not fold them into a status row.

## Independence

Do not read sibling reviews that were not this skill's prior report. The prior predictive report and the current artifact are the inputs.
