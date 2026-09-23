---
name: predictive-ux-evaluation
description: >
  Predictive (model-based) UX evaluation of web UIs and HTML prototypes using
  cognitive walkthrough, KLM/GOMS, Fitts's law, Hick's law, and visual-hierarchy
  / first-fixation analysis. Use whenever the user asks to evaluate a UI,
  prototype, flow, or HTML mock for first-time-user failures, expert task time,
  target size and distance, choice time, or where the eye goes first — including
  "cognitive walkthrough", "KLM", "GOMS", "Fitts", "Hick", "predictive UX",
  "model-based evaluation", "usability inspection", "will users find this",
  "how long will this task take", "verify the last UX pass", "mark findings
  resolved", or "/predictive-ux-evaluation". Produces a fit verdict, a task
  list, predicted failure points, task-time estimates, and a target table, each
  finding cited to a screenshot, DOM measurement, or file:line. Re-running a
  prior report adds resolved/open status and splits encoding change from page
  change. Does not predict conversion, preference, or emotion.
---

# Predictive UX Evaluation

Inspection methods that predict *where a first-time user fails* and *how long a practiced expert takes*. They do not predict conversion, preference, or emotion. Run the lane check before any method. Hand every pass to a real-user study.

## The lane (checked before anything runs)

**These methods can usefully predict** — the answer lives in the artifact's structure:

- First-time-user failure points at a named step (cognitive walkthrough), including whether the first screen *carries the cues* for a stated comprehension
- Expert, error-free task time on a named path (KLM / GOMS)
- Relative target-acquisition time from size and distance (Fitts's law)
- Decision time among already-known, labelled alternatives (Hick–Hyman), with the visual-search limit stated
- Likely first-look ranking under a *named* heuristic or a *named* saliency model

**These methods cannot establish** — refuse, and name the human method instead:

- Conversion, purchase intent, or "which variant wins"
- Whether visitors will actually understand the product, or feel it is for them (five-second test, interview)
- Preference, delight, trust, or any felt quality
- What people will actually do, pay, or remember
- Launch or investment validation

Mixed questions: answer the in-lane part; refuse the rest in the same report. Do not invent success-rate percentages, conversion lifts, or emotion scores. A walkthrough produces failure stories, not "% of users will fail."

## Required inputs

Ask only for what is missing:

- **Artifact** — live URL, HTML prototype, screenshots of a flow, or source files
- **Tasks** — user goal, start state, success criterion. Comprehension ("what is this?") is a valid task: success is a statement, not a click. If omitted, infer 1–3 primary tasks from the artifact and state the inference
- **User assumption** — first-time (walkthrough) and/or practiced expert (KLM). Default: both
- **Arrival context** (optional) — search title/snippet or referrer. Default: words on screen only
- **Pointer** — mouse or touch. Default: mouse on desktop, touch on a mobile viewport
- **Prior report** (optional) — a previous pass from this skill. If present, this is a verification run: load `references/verify.md`

## Method (when the lane check passes)

Load a reference only when that method runs.

1. **Fit check.** Write the verdict. Stop if the whole question is out of lane.
2. **Measure the artifact.** Prefer a browser: screenshot each task screen; `getBoundingClientRect()` on every control the task uses. From source only: `file:line` plus computed size/position if the layout is determinate. Invented pixels are not evidence. On an animated surface, record time since load. If the run cannot write a screenshot, DOM plus the reproducing action is enough.
3. **Cognitive walkthrough** on each first-time-user task, including comprehension tasks with no click. Load `references/cognitive-walkthrough.md`. Four questions at every step; `no` / `weak yes` are failure points. Walk the reverse of toggles and overlay dismiss.
4. **KLM / GOMS** on each expert *motor* path. Load `references/klm-goms.md`. Header `encoding: KLM-web-1`. Operator string + sum. P in the sum is 1.10 s (or P_tap); do not fold unfitted Fitts MT into it. Skip KLM on comprehension tasks. Record browser + version next to every measured R.
5. **Fitts** on every pointing target in those paths. Load `references/fitts.md`. First-target D from the **viewport centre**. Table: size, distance, ID, predicted MT. Rank targets; unfitted *a*, *b* stay comparative.
6. **Hick** only where the user chooses among already-visible, already-understood options. Load `references/hicks.md`. If the user must scan or browse, say so and skip the log formula.
7. **Visual hierarchy / first fixation.** Load `references/visual-hierarchy.md`. Name the model (Itti–Koch, DeepGaze, …) if one actually ran; otherwise label the ranking **heuristic**.
8. **Hand off.** Load `references/handoff.md`. Severity on synthesized findings; *n* from that table.
9. **Verify** if a prior report was given. Load `references/verify.md`. Status every prior finding; split Δ encoding from Δ page.

## Output contract

Use this structure. Every finding carries evidence: a screenshot path, a DOM measurement (`selector`, `w×h`, `x,y`), or `file:line`.

```
# Predictive UX evaluation: [artifact]
PREDICTIVE MODEL, NOT USER EVIDENCE
encoding: KLM-web-1
Arrival: [snippet / unknown]
Users: first-time […]; expert […]

## Lane check
[question] → in-lane | out-of-lane (human method: …)

## Task list
| ID | Goal | Start | Success | Methods run |

## Predicted failure points (cognitive walkthrough)
| Task | Step | Q | Grade (no / weak yes / not evaluable) | Failure story | Evidence |

## Task-time estimates (KLM / GOMS)
encoding: KLM-web-1
| Task | Path | Operator string | Predicted expert time | Assumptions | Evidence |
(P in the sum is 1.10 s or P_tap unless a fitted Fitts MT is named. Browser + version next to measured R.)

## Target table (Fitts)
First-target origin: viewport centre unless a row notes otherwise.
| Task | Target | W (px) | D (px) | ID (bits) | Predicted MT | a, b source | Evidence |

## Choice time (Hick–Hyman), if applicable
| Task | Step | n | Applied? | Predicted RT or reason skipped | Evidence |

## First look
Method: heuristic | model ([name])
| Rank | Element | Why | Evidence |

## Findings
| ID | Severity (blocker / major / minor) | Method + step | Prediction | Evidence |

## Verification of [prior report]   ← only if a prior report was given
| Finding | Prior severity | Status | Evidence |
| Task | Path | Prior T | Prior encoding | T_reencoded | T_now | Δ encoding | Δ page |

## For real humans
[prediction → method → n → what confirms/refutes]
```

Keep `PREDICTIVE MODEL, NOT USER EVIDENCE` on the line under the H1 and on each findings table.

## Quality checks

- Lane check ran first; out-of-lane asks were refused with a named human method
- Comprehension tasks were walked with Q2/Q3; Q4 is n/a; KLM/Fitts/Hick were skipped
- Gates/modals were walked in visual order (read then press); Q1 is not assumed yes on a dismiss-and-go heading
- Every failure point names the step, the question (Q1–Q4), and a grade
- Toggles, overlays, and one label-invited wrong path were walked
- KLM header is `encoding: KLM-web-1`; operator strings are recorded; P in the sum is not an unfitted Fitts MT
- Fitts first-target D uses the viewport centre; W is the hit area, not only the painted box
- Hick is skipped (with reason) when the step is visual search or browsing
- First-look names the method, includes faces when lookable, and skips faces behind a blur/veil
- Synthesized findings have severity from `handoff.md`
- Every finding has a screenshot, DOM measurement, or file:line
- If a prior report was given: verification table and Δ encoding / Δ page split are present
- The report ends in a real-user hand-off with *n* from `handoff.md`
- No conversion, preference, or emotion claims
