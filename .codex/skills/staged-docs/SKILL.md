---
name: staged-docs
description: Builds a document for people together with its author, piece by piece from an approved structure, such as a guide, process description, plan, proposal, report or README. Each piece is written in one of three modes, from agent-drafted to author-led, with review rounds decided in chat or on a local page. Use when the author starts it explicitly with a topic, for a document of one or more Markdown files. Not for one-shot documents, single-section edits or documentation generated from code.
disable-model-invocation: true
compatibility: Runs in Claude Code or OpenAI Codex, on a document written as one or more Markdown files. Drafts and reviews follow the human-writing skill, installed alongside. The review page needs Python 3.10 or later (standard library only), a browser and network access to cdn.jsdelivr.net, from which it loads its rendering libraries.
---

# Staged docs

This skill builds a document together with its author. The document is one that people read to understand or to act, such as a guide, a plan or a report, written as one or more Markdown files. The author approves a structure first. A piece is one part of that structure: usually one file, or one section when the document is a single file. Each piece is written in one of three modes, and the document then goes through review rounds before it is finished.

- **auto**: you draft the piece from the topic and the sources, after the author approves its piece sheet (a short list of what the piece will say) at one stop that covers all auto pieces.
- **step-by-step**: you draft the piece, and the author comments on the diagram, when the piece has one, and then on the text.
- **author-led**: the author gives their view of the piece first, and you shape it into a diagram or an outline, and then text, without adding claims of your own.

## Start or resume

NOTES.md holds the state of the work in its frontmatter, and it is the only record of where the work stands. It lives in the working folder, the one folder that holds all the working files (see Working files). Draft files can be ahead of what the author approved, so do not infer progress from them.

1. Look for a NOTES.md whose frontmatter has `skill: staged-docs`: in the current folder, its `notes-*/` subfolders and its parent folders, and in any folder the author names.
2. If none is found, or the author's message names a topic that none of them covers, read stages/start.md and begin. If several are found and the message does not say which one to continue, ask.
3. Otherwise read the frontmatter of the NOTES.md for this topic and report the state in one line: the topic, the stage and what the last stop asked (`waiting_for`); in `stage: pieces` also piece n of N with its title and mode, and in other stages the round. Then wait for the author to confirm. When the author's message already says to continue, or answers `waiting_for`, report the line and go on in the same turn.
4. Go on with the file that the table under "What to read when" names for the stage. In the review and stakeholder stages, resume at the step that `waiting_for` names, and do not repeat a step whose files exist. If a folder reviews/r<round>-* exists, that round is open: continue it rather than opening another.

## Rules at every stage

- **Stops.** Stop at every stop the current file names. At a stop, first write the state to NOTES.md (`stage`, `current_piece`, the piece's `status`, `waiting_for`), save the drafts, and log each numbered question you ask as a Q-n line under Questions; then ask, then end the turn with the menu described below. Writing first lets a lost session resume at this stop, and ending the turn keeps the work from running ahead of an answer it depends on. Record each answer on its Q-n line when it comes.
- **Approval.** A reply approves only what was shown at that stop, because the author has not seen the rest. When the author comments or asks for changes instead of approving or confirming, revise and stop again until they approve.
- **Gaps.** Put ` [ASSUMPTION A-<n>]` after every claim that you inferred and did not take from the author, a decision or a named source, and list A-<n> under Assumptions in NOTES.md, numbering assumptions across the whole document, so that the author can find and settle each guess. A fact that is missing, rather than inferred, becomes a numbered question. Do not use human-writing's "[needed: …]" marker here, because the checks and the finish audit look only for assumption marks and questions. In step-by-step and author-led pieces, settle every mark before the piece is approved: confirm it (remove the mark and record a D-n line), change the claim, or cut it. In auto pieces the marks stay until the review.
- **Author-led pieces.** Add no claims of your own. What you cannot take from the author's words or a named source becomes a numbered question or an assumption mark, because the author decides the substance of these pieces and an invented claim would read as theirs.
- **Questions.** Number them and ask about five at a time. Ask only what changes the structure or a key claim and can be answered now, and do not ask what you can look up, because each question costs the author time. Give a question that has options a recommended answer, so that "yes" accepts it. Ask about facts only the author knows, such as how their team works, as an open question, because a suggested answer would put your guess in their mouth. The author may answer in shorthand, such as "1 yes, 2 b". Use a structured question tool only when the host offers one; otherwise ask in plain numbered text.
- **Terms.** A new term or role needs the author's approval and goes into the concept ledger, the list in NOTES.md of what the reader already knows and what the document introduces. The ledger is the record of human-writing's concept inventory and serves as its term list, so the skill uses only the name "concept ledger". The document stays within the ledger's budget for terms and roles, because each term is one more thing the reader must learn, and a document that defines dozens of terms stays hard to follow however clear each definition is.
- **Writing.** Every draft follows the human-writing skill. If it is not installed, say so once and continue with the rules in these files.
- **Drafting.** Draft pieces in order, in this conversation, because each piece builds on the decisions made before it. Use subagents only for review work (the review lenses, the verifier, the reconciliation at the finish) and for reading large sources, each in a fresh context. After the author has commented three times on a piece with no real change, ask what can be removed, because circling usually means the piece holds more than it needs.
- **Applying changes.** Apply only what the author accepted: the proposals they accepted, or, on the apply-and-mark path of a stakeholder round, the points they agreed to in the discussion, which they then check in a marked copy. Do not apply an addition as a default answer (`apply --defaults`), because an addition puts claims in the document that the author has not read.
- **Lint.** `lint` reports every assumption mark. While an assumption is open, its match is expected, so do not remove an open mark to make lint pass; fix every other match. At the finish stage, lint must be clean.
- **The author's rules.** The standing rules that the author recorded in NOTES.md override the defaults in these files and in the human-writing skill.

## Ending a stop

End every stop with a one-line menu that says what comes next and how to go on. For example: "Reply with comments, or approve. Next: piece 3, 'Approve the budget', step-by-step. To switch mode, say 'switch piece 3 to author-led' or 'switch the rest to auto'." When you run in Codex, add "In Codex, start your reply with $staged-docs.", because Codex drops a skill between turns unless the message names it again.

## What to read when

Read a file when its stage is reached, not before, so that instructions for later stages do not crowd out the current ones.

| When | Read |
|---|---|
| No NOTES.md yet, or `stage: start` | stages/start.md |
| `stage: pieces` | the mode file of the current piece: modes/auto.md, modes/step-by-step.md or modes/author-led.md |
| Before writing a piece sheet or drafting a piece | references/drafting.md (piece sheets, diagram and text rules, self-check) |
| `stage: review` | stages/review.md, and references/review-lenses.md and references/proposals.md when it names them |
| `stage: stakeholder` | stages/stakeholder.md, which offers two paths (apply-and-mark, or proposals), and references/proposals.md for the proposals and the `snapshot` and `changes` commands |
| `stage: finish` | stages/finish.md |
| `stage: done` | nothing; say the document is finished. New stakeholder feedback starts stages/stakeholder.md |
| Creating NOTES.md or checking its layout | references/notes-template.md |
| Writing proposals.json or the author's choices file, or running the script | references/proposals.md |

## Working through the pieces

In `stage: pieces`, while any auto piece still has `status: todo`, start with the piece sheets in modes/auto.md, because one stop covers all auto pieces. Otherwise work on `current_piece`. A piece is finished at `status: done`, or at `drafted` for an auto piece. The next piece is always the lowest-numbered unfinished piece: set `current_piece` to it and read its mode file. When no unfinished piece is left, set `stage: review`.

Once the structure is approved, adding, removing, splitting or moving a piece is a stop, because the structure shapes every piece. Piece numbers never change: a piece added later gets the next unused number, and its place in the `pieces` list sets its place in the document.

`default_mode` is the mode for pieces added later and for "switch the rest". When the author switches a piece's mode, change its `mode` in NOTES.md and map its status, because the modes pass through different steps:

- to auto: a piece whose piece sheet the author has not approved goes back to `todo` (a step-by-step piece's sheet is approved together with the first draft of it that the author approves);
- to author-led: a piece goes back to `todo` unless it is `discussed` or later (`shaped`, `drafted` or `done`);
- to step-by-step: the status stays.

Then continue with the new mode file from the first step the piece has not done.

## Working files

All working files live in the working folder, chosen at the start. For a document in a folder, the default is the folder that holds it (for docs/, the project root), so that the published document does not include the working files. For a single-file document, it is the folder that holds the file. If that folder already has a NOTES.md without `skill: staged-docs`, or one for another topic, do not touch it: make a subfolder named after the topic, such as `notes-<slug>/`, the working folder, and tell the author. Paths in NOTES.md and in these files are relative to the working folder.

```
NOTES.md                             state (frontmatter) and the author's notes (body)
inputs/start.md                      context the author pasted at the start, verbatim
inputs/piece-<n>.md                  the author's words for piece n, verbatim, in dated entries
sheets.md                            piece sheets for auto and step-by-step pieces
feedback/<yyyy-mm-dd>-<round-id>.md  stakeholder feedback, verbatim
reviews/<round-id>/                  one folder per round: proposals.json, decisions.json,
                                     findings/<lens>.md, review.html; discussion.md in a
                                     stakeholder round; on the apply-and-mark path, base/,
                                     changes.html and changes-ids.json until the round closes
```

A round is one review round or one stakeholder round. Its ID is `r<n>-review` or `r<n>-<stakeholder>` (for example `r2-legal`), where n is the `round` value in NOTES.md, and `round` goes up by one only when a round's folder is created.

Three records share the word "decision". A decision is a D-n line under Decisions in NOTES.md: a point the author settled, which later rounds respect. A decision proposal is a proposal with `type: decision`, where the author chooses between options. The author's choices file is decisions.json in a round folder, which holds the author's answer to each proposal.

## Tools and files

- **Subagents.** Where these files use subagents and the host can run them, give each one a self-contained task in a fresh context. Otherwise do the same work yourself, one task after another, and write each result to its file before starting the next.
- **Script.** `scripts/proposals.py` checks proposals, lints the document against the checks in NOTES.md, serves the review page and applies accepted changes. For the apply-and-mark path of a stakeholder round, it also takes a snapshot of the document (`snapshot`) and writes a marked copy of the changes since that snapshot (`changes`). Run it from the working folder as `python3 <skill>/scripts/proposals.py <command>`, where `<skill>` is the folder that holds this SKILL.md. In commands, `<document>` stands for the `document` path in NOTES.md, together with any piece file outside it. `assets/review.html` is the page template that the script fills. The commands are in references/proposals.md.
