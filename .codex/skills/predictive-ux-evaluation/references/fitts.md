# Fitts's law

Fitts, "The information capacity of the human motor system" (*J. Exp. Psychol.*, 1954). HCI standard form: Shannon formulation, MacKenzie (1992). Measurement protocol: Soukoreff & MacKenzie, "Towards a standard for pointing device evaluation" (*IJHCS*, 2004); ISO 9241-9 / 9241-411.

**Predicts:** time to acquire a target as a function of distance and size. Relative ranking of targets is the reliable output when *a*, *b* are not fitted to this device.

**Does not predict:** whether the user will look for the target (walkthrough Q1–Q3), error rate without IDe, preference, or conversion.

## Formula

Shannon / MacKenzie (use this):

```
ID = log2(D / W + 1)     // bits
MT = a + b × ID          // seconds
```

Original Fitts used `log2(2D / W)`. Do not mix formulations in one table.

- **D** — Euclidean distance from movement start to target centre, in px (same unit as W).
- **W** — target width along the approach axis. Use `min(width, height)` of the **interactive hit area**, not the painted box. `getBoundingClientRect` on the element misses a hit target grown by `::before` / padding / an invisible inset. If paint and hit disagree, measure by `elementFromPoint` (or a tap/click just outside the paint) and record both.
- **a**, **b** — empirically fitted intercept and slope.

## Constants

| Source | a (s) | b (s/bit) | Use |
|--------|-------|-----------|-----|
| Unfitted textbook (common teaching defaults) | 0.050 | 0.150 | Comparative ranking only. Label every MT **unfitted**. Do not put this MT into a KLM sum |
| Locally fitted | from a pointing study on this device | Absolute MT for that device; only then may KLM replace P with this MT |

Never present unfitted MT as a stopwatch prediction. Rank ("primary CTA is 2.1× harder than the previous control") is the claim the law supports without a local fit.

Touch: Fitts still applies. Without a touch fit, reuse the mouse textbook *a*, *b* and label the row **ranking only, mouse constants on touch**. Finger W is the *effective* hit area (often smaller than the painted button if padding is not in the hit box).

## Measuring a web UI

1. **Start point (default, so two runs match):**
   - First target of a task: **viewport centre** `(innerWidth/2, innerHeight/2)` in CSS px. Desktop mouse and phone use that same rule on their own viewport.
   - Later targets: centre of the previous target in the path.
   - Record the origin on the first-target row if you ever override it.
2. End point: centre of the hit box.
3. Screenshot the screen; record `selector`, `width`, `height`, `x`, `y`. On animated surfaces, record t since load.
4. Edges and corners: screen-edge targets have effectively infinite W in the constrained dimension (Accot & Zhai / MacKenzie edge effect). Note it; do not treat a 1-px-tall menu bar at the screen edge as W = 1 if it is edge-docked.
5. **Hover-grown target:** W is the hit box **at the moment of the click** (after hover zoom). Note the rest size if it differs.
6. **Moving target:** static Fitts is a lower bound. Record speed (px/s) and say the ID understates the chase.

## Report columns

`Target | W (px) | D (px) | ID (bits) | Predicted MT | a, b source | Evidence`

## Evidence

DOM rects or screenshot with measured px. CSS `file:line` is extra, not a substitute for the rendered size.
