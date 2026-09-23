# KLM / GOMS

Card, Moran, and Newell, *The Psychology of Human-Computer Interaction* (1983); KLM encoding rules ibid. GOMS family survey: John & Kieras, "The GOMS family of user interface analysis techniques" (*ACM ToCHI*, 1996). Famous field check: Gray, John & Atwood, Project Ernestine (1993) — CPM-GOMS predicted expert operator time.

**Predicts:** execution time of a practiced expert on an error-free path.

**Does not predict:** first-use time, error rate, learning time, or whether the user will choose this path (that is the walkthrough).

## Which variant

Default to **KLM** (Keystroke-Level Model): one method, operator counts, a sum. Use fuller **CMN-GOMS / NGOMSL** only when the task has competing methods and you need selection rules. **CPM-GOMS** (parallel cognitive/perceptual/motor) is out of scope unless the user asks.

## Encoding `KLM-web-1`

Every KLM table states `encoding: KLM-web-1`. The operator times in this file *are* that encoding. Changing a constant or adding an operator requires `KLM-web-2` and a line in the changelog below.

| ID | Skill vintage | Difference |
|----|---------------|------------|
| **KLM-web-0** | First published skill | Phone typing used **K = 0.28**; scroll had no time (unquantified `SCROLL`) |
| **KLM-web-1** | This file | **P_tap** 1.10, **K_soft** 0.50, **SCROLL_W** 0.10 / notch, **SCROLL_F** 0.70 |

A prior report with no encoding id is `KLM-web-0`. To compare times across skill versions, re-sum the old operator string with this file's table (`references/verify.md`). Never treat `5.48 s` vs `6.80 s` as a page change when the string went from `6K` to `6K_soft`.

## Operators and times (KLM)

Physical + mental + system. Times from Card, Moran & Newell (1983):

| Op | Meaning | Time (s) |
|----|---------|----------|
| **K** | Keystroke (including modifier as its own K) | 0.28 default (average non-secretary, ~40 wpm). 0.12 good typist; 0.20 skilled; 0.50 random letters; 1.20 unfamiliar keyboard |
| **P** | Point at a display target (mouse, includes the click in original KLM) | 1.10 |
| **H** | Home hand between keyboard and mouse | 0.40 |
| **D** | Draw *n* segments of total length *l* | 0.9*n* + 0.16*l* — rare on web |
| **M** | Mental preparation | 1.35 |
| **R(*t*)** | System response the user waits for | *t* (0 if the UI is ready before the next operator) |

Optional later operator (not in original six): **B** mouse-button press or release, 0.10 s (click = BB = 0.20). If you use B, P is movement only. If you stay with original KLM, P includes the click. Pick one encoding and apply it to every path you compare.

### P and Fitts

Keep **P = 1.10 s** (or **P_tap** below) inside every `T_execute` sum. Unfitted Fitts MTs are ranking-only (`fitts.md`); substituting them would put a comparative number inside an absolute sum.

Substitute Fitts for P **only** when *a* and *b* were fitted on this device in this session. Say so on the KLM row.

## Touch and scroll (labelled extensions)

Not in Card, Moran & Newell. Use them so two runs encode the same way; keep the `EXTENSION` tag on the operator string.

| Op | Meaning | Time (s) | Notes |
|----|---------|----------|-------|
| **P_tap** | Point-and-tap, finger already on glass | 1.10 | Reuses mouse P. Not a fitted tap time. No **H** between taps |
| **K_soft** | One character on a known soft keyboard | 0.50 | Card's "random letters" as the closest original operator. Physical **K** stays 0.28 |
| **SCROLL_W** | One mouse-wheel notch (~100 px of content) | 0.10 | Assumed, for comparability (same order as K/B). Count notches from measured distance / 100; report the count |
| **SCROLL_F** | One expert touch flick covering the remaining distance | 0.70 | Assumed, for comparability. One gesture, not a notch train. **R** extra if momentum is still settling |

A sum that includes any of these is an extension estimate. Example: `M P_tap SCROLL_F R(1.15)`.

## M placement (Card, Moran & Newell)

Start with physical operators + R only. Then:

- **Rule 0.** Insert M before every K / K_soft that is not part of an argument string (typed text/numbers). Insert M before every P / P_tap that selects a *command* (not an argument).
- **Rule 1.** Drop M if the following operator was fully anticipated by the operator before it (e.g. PMK → PK when the click is the obvious next motor act).
- **Rule 2.** A string of MKs that is one cognitive unit (a command name) keeps only the first M.
- **Rule 3.** Drop M before a redundant terminator K.
- **Rule 4.** Drop M before a K that terminates a *constant* string (command name); keep M before a K that terminates a *variable* string (an argument the user just composed).

Consistency of M placement across alternatives matters more than the exact count. Report the operator string, not only the sum.

## Web encoding notes

- Click a button (original KLM, hand already on mouse): `M P` or `P` after Rule 1. With B: `M P BB`.
- Tap (phone): `M P_tap`.
- Type *n* characters into a focused field: `nK` (desktop) or `n K_soft` (phone), plus M before the first key if the content is composed.
- Switch mouse ↔ keyboard: `H`. No H between taps.
- Wheel to a location: `SCROLL_W × n` with n measured. Flick: `SCROLL_F`. Do not hide scroll inside P.

## Once-shown surfaces

A first-visit modal, cookie gate, or age wall is not a practiced expert path. Still encode the motor operators, and label the row **motor floor, unpracticed surface**. Do not treat that T as comparable to a practiced expert path.

## Report

`T_execute = Σ operator times`. Label: **predicted expert, error-free execution time**. Header: `encoding: KLM-web-1`. State the operator string (so it can be re-summed later), K / K_soft, P vs P_tap, every EXTENSION operator, and the **browser + version** beside every measured **R**. P in the sum is 1.10 s unless a fitted Fitts MT was substituted.

## Evidence

Operator string mapped to the path; each P/K target cited to DOM or `file:line`.
