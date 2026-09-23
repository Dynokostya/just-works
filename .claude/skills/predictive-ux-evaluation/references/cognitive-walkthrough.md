# Cognitive walkthrough

Wharton, Rieman, Lewis, and Polson, "The cognitive walkthrough method: A practitioner's guide" (in Nielsen & Mack, *Usability Inspection Methods*, 1994). Grounded in CE+ exploratory learning (Polson, Lewis, Rieman, Wharton 1992).

**Predicts:** first-time / untrained user failure points on a specific task. Learnability, not expert efficiency. Also: whether the *cues on the first screen* could support a stated comprehension (see below).

**Does not predict:** expert time (use KLM), conversion, preference, how many people will fail, or whether visitors will actually understand / feel the product is for them (five-second test, interview).

## Preconditions

- A named user (what they already know; default: first-time with the domain vocabulary on the screen and nothing else)
- Optional **arrival context**: search title/snippet, ad, or referrer. Record it when known; the default still ignores it
- A task with start state and success criterion
- For action tasks: the correct action sequence the design intends (the happy path), plus the reverse of every toggle and the dismiss of every overlay the path opens

## Comprehension tasks (no motor action)

"Work out what this is" has no click. Do not skip it and do not invent a fake click.

- Success is a **statement** the visitor could make from the current screen ("I can chat with these characters"), not a feeling.
- Walk a single read step. **Q1** is usually yes if that is why they came. **Q2:** are the cues that would support the statement perceptible? **Q3:** do those cues mean that statement, or a different product? **Q4:** n/a — no action, no feedback. Put `n/a` in the grade column for Q4; do not force a yes/no.
- Do not run KLM, Fitts, or Hick. Do run first-look.
- Whether they *will* understand, or whether it is *for them*, stays out of lane.

## Mixed tasks (read then press on one surface)

A cookie / age / consent modal often holds the product statement *and* the exits. Walk it as two steps in **visual order**, not as a pure read or a pure click.

- If the heading frames a dismiss-and-move-on goal ("We use cookies"), **Q1** for reading the lower block is not automatically yes. The visitor came to get past the gate. Grade Q1 for the product statement as `weak yes` unless the heading prompts that reading.
- If the exits sit **above** the statement, Q2 for the statement is: will they notice it *before* they press? A press that closes the surface is the finding, not a later Q4.
- Q4 for the statement is `n/a` if they never have to act on those words. The failure lives on the read step (Q1/Q2).

## The four questions (every action)

Ask these in order. A credible "no" is a **failure story** — a hypothesis about why a real first-time user would stall or take the wrong action.

**Q1. Will the user try to produce whatever effect this action has?**
Does the user even form the goal this step requires? Hidden prerequisites, surprising subgoals, and designer-only decompositions fail here.

**Q2. Will the user notice that the correct action is available?**
Is the control perceptible in the current view (not "would they recognize it" — that is Q3). Off-screen, below the fold, icon-only in a crowded toolbar, collapsed behind a menu the user has no reason to open: Q2.

**Q3. Will the user associate the correct action with the effect they are trying to achieve?**
Once the control is seen, do its label, icon, and affordance mean *this produces that*? Jargon, identical-looking buttons, and "Submit" for a non-obvious side effect fail here.

**Q4. If the correct action is performed, will the user see that progress is being made toward the goal?**
Is feedback prompt, visible, and interpretable enough to continue? Silent success, delayed toasts, and state changes that don't mention the goal fail here.

Use this wording in the report (`Q1`…`Q4`). Paraphrase in the failure story, not in the question column.

**Grade** every answered question: `yes` | `weak yes` | `no` | `n/a` | `not evaluable`. Only `no` and `weak yes` become failure-point rows. `not evaluable` is for a step whose next surface is a stub (toast, missing screen); put it in its own row so the gap is visible.

## How to walk

1. Write the intended action list as atomic, observable steps (one click, one field, one key decision). For comprehension, one read step (above). For a gate/modal, read then press in visual order (mixed task).
2. For each **toggle, filter, or overlay** the path uses, walk the reverse too: press the set control again; dismiss the overlay. That is how a second click that undoes the filter, or a close that throws away the query, shows up as Q4.
3. Also walk **one wrong path the labels invite** (the same word as the goal on a different control: rail "Chats" when the goal is start a chat).
4. For each step, answer Q1–Q4 from the cues actually on screen at that moment. Quote the label or cite the screenshot / DOM.
5. Record only `no` / `weak yes` as failure points. A `yes` needs no row. `not evaluable` gets a row with no failure story.
6. Do not skip a step because "users will figure it out." That is the claim under test.

Streamlined two-question variants (Spencer 2000) are a different method. This skill uses the 1994 four.

## Evidence

Each row cites at least one of: screenshot of the step, DOM of the control (`selector`, `w×h`, `x,y`), or `file:line`. When the run cannot write a screenshot, DOM plus the URL or action that reproduces the state is enough. On an animated surface, record time since load.
