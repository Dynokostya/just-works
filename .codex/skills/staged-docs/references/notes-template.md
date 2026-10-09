Read this when you create NOTES.md or need to check its layout. The frontmatter is the state that a resumed session reads; the body holds the notes that the author and you keep.

## Template

Copy this into NOTES.md in the working folder and fill in the placeholders.

```markdown
---
skill: staged-docs
topic: "<topic>"
document: "<the document's folder or file, such as docs/ or report.md>"
stage: start
default_mode: step-by-step
current_piece: 0
waiting_for: "<what the last stop asked the author, in one line>"
round: 0
return_stage: ""
pieces: []
---

# Working notes: <topic>

The document does not publish these notes.

## Reader and purpose

## Sources

## Concept ledger

### The reader already knows

### Terms this document introduces (budget: <n>)

| Term | Meaning in one line | First used in |
|---|---|---|

### Roles

| Role | What it decides |
|---|---|

## Standing rules

## Checks

- `\[ASSUMPTION` an assumption mark is still in the text

## Decisions

## Assumptions

## Questions

## Deferred findings

## Parked

## Rounds
```

Once the structure is approved, each piece gets an entry under `pieces`, in the order of the document:

```yaml
pieces:
  - n: 1
    title: "Overview"
    file: docs/index.md
    diagram: true
    mode: step-by-step
    status: todo
```

## Frontmatter fields

- `skill`: always `staged-docs`; a resumed session finds the file by it.
- `topic`: the topic as the author gave it.
- `document`: the published document, a folder of Markdown files or one Markdown file, relative to the working folder.
- `stage`: `start`, `pieces`, `review`, `stakeholder`, `finish` or `done`.
- `default_mode`: `auto`, `step-by-step` or `author-led`; the mode for pieces added later and for "switch the rest".
- `current_piece`: the number of the piece in progress, or 0 when none is.
- `waiting_for`: one line saying what the last stop asked the author.
- `round`: the number of review and stakeholder rounds started; it goes up when a round's folder is created.
- `return_stage`: during a stakeholder round, the stage to go back to when the round closes; empty otherwise.
- `pieces`: for each piece, its number `n`, `title`, `file`, `diagram` (true or false), `mode` and `status`. SKILL.md says how numbers and order work when a piece is added later.

Piece status, in order: `todo` nothing yet; `sheet` the piece sheet is approved; `discussed` the substance is approved (author-led); `shaped` the diagram or outline is approved; `drafted` the text is written and shown, or, for an auto piece, written and waiting for the review; `done` approved by the author. Each status means the same in every mode. A step-by-step piece skips `sheet`, because its sheet is approved together with its first approved draft.

## Body sections

- **Reader and purpose**: who reads the document and what they do with it; the document's one purpose.
- **Sources**: one line per source: its path or link and what it covers.
- **Concept ledger**: what the reader already knows, the table of terms the document introduces, and the Roles table when the document describes decisions its readers make or wait for (leave the Roles table out otherwise). The Roles table lists each role that owns a decision in the document, with one line on what it decides; roles you proposed are defaults that each organization maps to its own people. Terms and roles together stay within the budget in the heading, because each role is one more thing the reader learns.
- **Standing rules**: the author's rules for this document, one per line, for example "The document uses US spelling." They override the skill's defaults.
- **Checks**: one list item per check, a Python regex in backticks followed by its reason, for example ``- `\b(?:colour|organisation)\b` the document uses US spelling``. Patterns are case-sensitive unless they start with `(?i)`, and `lint` does not match inside code blocks or inline code. The script reads the checks under the heading that starts with `## Checks`, and warns when it finds none. Keep the assumption-mark check.
- **Decisions**: `- D-<n> (<date>, <who>): <decision>.`, where `<who>` is `author`, or `<stakeholder> feedback` in a stakeholder round. The list is append-only; the only edit allowed to an old line is appending "Replaced by D-<m>.", and the new line ends with "Replaces D-<n>." Every rejected proposal gets a line `- D-<n> (<date>, <who>): Rejected <round-id> P-<id>: <what it proposed, and why not>.`, so that later rounds do not raise it again.
- **Assumptions**: `- A-<n> (piece <p>, open): <assumption>`, one line for each assumption mark (see Gaps in SKILL.md). Remove a line when its assumption is settled.
- **Questions**: `- Q-<n> (<piece p, or the stage>): <question> → <answer, or "open">`. A question with long options, such as the proposed structures, keeps them in an indented block under its line.
- **Deferred findings**: decision proposals that a review round held back to keep its list short, each with its round ID and what it proposes. The next review round or the finish stage shows them to the author.
- **Parked**: items the author chose to leave out of the document for now, each with its source.
- **Rounds**: `- R-<n> <round-id> (<date>): <n> proposals, <n> accepted (<n> by default), <n> rejected, <n> open.` For a stakeholder round on the apply-and-mark path: `- R-<n> <round-id> (<date>): <n> points, <n> agreed, <n> declined; <n> changes, <n> redone.`
