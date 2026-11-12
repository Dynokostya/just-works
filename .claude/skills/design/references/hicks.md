# Hick's law (Hick–Hyman)

Hick (1952); Hyman (1953). Information-theoretic choice reaction: time grows with the entropy of the choice set.

**Predicts:** decision time among *already-known, already-identified* alternatives, roughly logarithmic in *n* when alternatives are equally likely.

**Does not predict:** visual-search time, browsing, time to find an unfamiliar control, or "fewer items convert better." Liu, Gori, Rioul, Beaudouin-Lafon & Guiard (CHI 2020) argue the law is often misapplied in HCI; many log-looking curves are search or divide-and-conquer, not Hick.

## Formula

For *n* equally likely known responses:

```
RT = a + b × log2(n)
```

Hyman also uses entropy `H = −Σ p_i log2(p_i)` so unequal probabilities shrink H. The `log2(n+1)` form appears when "no stimulus" is a response; use `log2(n)` unless that applies.

*a*, *b* are fitted. Unfitted textbook slope is often ~0.15 s/bit. The unfitted intercept *a* is unknown — do not invent one. Report the **increment** `b × log2(n)` (e.g. `a + 0.24 s`) and label it **comparative**.

## When the formula applies

Apply Hick only when all of these hold:

- The options are visible (or recalled) and the user already knows what they are
- The user is *choosing*, not *searching* — they know the response set, as in Hick's lamp-and-key task
- Placement is stable enough that an expert can go to a remembered location

## When it does not (visual scanning / browsing)

First-time use of a menu, a nav, or a page of cards is **visual search**. Search through an unsorted or unfamiliar list is approximately **linear in *n***, not logarithmic.

Cockburn, Gutwin & Greenberg (CHI 2007), "A predictive model of menu performance": novices pay a linear search cost; experts who know item locations pay a logarithmic Hick–Hyman decision cost. Same menu, two curves.

If the step is browsing or first-time scanning:

- Skip the Hick RT number
- Write `Applied? no — visual search / browsing; time closer to linear in n (Cockburn et al. 2007)`
- Count *n* and the grouping (that is still useful); do not log-transform it

Landauer & Nachbar (1985) found log-like times for *hierarchical, ordered* touch menus (divide-and-conquer). That is not Hick either — do not relabel it as Hick.

## Effect size

Logarithmic growth means doubling *n* adds a constant, not a doubling of time. "Cut the menu from 16 to 8 to slash decision time" overstates the expert-Hick effect and ignores novice search. State which user you mean.

## Evidence

The choice set: screenshot or DOM list of the *n* options, and a one-line justification that they are known alternatives (or the reason Hick is skipped).
