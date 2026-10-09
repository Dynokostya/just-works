Read this before you write proposals.json or the author's choices file (decisions.json) for a review or stakeholder round, and for the commands of scripts/proposals.py. A proposal is one change to the document that the author accepts or rejects; the script checks proposals, shows them on the review page and applies the accepted ones.

## Fix or decision proposal

A fix corrects a problem that has one right answer, such as an undefined term, a wrong path or a sentence that contradicts a source. The author accepts or rejects it.

A decision proposal (`type: decision`) has several reasonable answers. Give it at least two options and recommend one, so the author can take the recommendation in one step. A finding that conflicts with a recorded decision (a D-n line in NOTES.md) becomes a decision proposal with "Keep D-<n>" as one option and `challenges: "D-<n>"`, because the author settled that point once and only the author can reopen it.

## proposals.json

The file sits in reviews/<round-id>/. The example below comes from a guide on how staff claim their expenses.

```json
{
  "round": "r1-review",
  "kind": "review",
  "root": "../..",
  "proposals": [
    {
      "id": "P-001",
      "type": "fix",
      "action": "change",
      "file": "docs/submit-a-claim.md",
      "old": "Then the claim goes through the gate.",
      "new": "Then the budget holder checks the claim and approves it before it is paid.",
      "why": "\"The gate\" is not explained anywhere, so the reader cannot tell what happens to the claim at this point.",
      "sources": ["docs/submit-a-claim.md:22", "inputs/piece-3.md"],
      "priority": "high",
      "group": "Terms",
      "lens": "reader",
      "verdict": "real"
    },
    {
      "id": "P-002",
      "type": "fix",
      "action": "add",
      "file": "docs/submit-a-claim.md",
      "anchor": "Attach the receipt to the claim.",
      "new": "\n\nIf the receipt is lost, attach a signed note with the date, the amount and the supplier.",
      "reader_question": "What do I do when I have lost the receipt?",
      "why": "A reader who has lost a receipt has no next step.",
      "sources": ["notes/expense-policy.md:8"],
      "priority": "medium",
      "group": "Gaps",
      "lens": "completeness",
      "verdict": "real"
    },
    {
      "id": "P-003",
      "type": "decision",
      "file": "docs/submit-a-claim.md",
      "old": "The employee's manager approves a claim over the limit.",
      "options": [
        {"id": "a", "label": "Keep D-4: the employee's manager approves a claim over the limit", "new": null},
        {"id": "b", "label": "The finance team approves a claim over the limit", "new": "The finance team approves each claim over the limit."}
      ],
      "recommended": "a",
      "challenges": "D-4",
      "why": "The expense policy says that the finance team approves claims over the limit, which D-4 does not mention.",
      "sources": ["NOTES.md D-4", "notes/expense-policy.md:14"],
      "priority": "high",
      "group": "Roles",
      "lens": "consistency",
      "verdict": "unsure"
    }
  ]
}
```

Top-level fields:

- `round`: the round ID, the name of the folder.
- `kind`: `review` or `stakeholder`.
- `root`: the folder that the `file` paths are relative to, given relative to the folder that holds proposals.json. From reviews/<round-id>/ to the working folder it is `../..`.

Proposal fields:

- `id`: `P-` and at least three digits, unique in the file.
- `type`: `fix` or `decision`.
- `action` (fixes only): `change` needs `old` and `new`; `remove` needs `old`; `add` needs `anchor`, `new` and `reader_question`, the question a reader asks that the new text answers.
- `options` (decision proposals only): at least two, each with `id` (a letter), `label` and `new`, the text that replaces `old`, or null for an option that keeps the text. `recommended` is one of the option IDs. When any option has a `new` text, `old` is required.
- Required on every proposal: `file`, `why`, `sources` (at least one, as file:line, a link or a NOTES.md decision such as `NOTES.md D-4`), `priority` and `lens` (`reader`, `accuracy`, `consistency`, `completeness` or `stakeholder`).
- Optional: `group` (default: the lens name); `verdict`, `real` (the default) or `unsure`, which the page shows as "Needs a check"; `challenges`, the ID of a decision the proposal reopens; `quote`, the stakeholder's words verbatim (stakeholder rounds); `manual`.
- `priority`: `high` when the reader gets lost or a claim is wrong, `medium` when the reader has to work, `low` for polish. The page collapses low-priority fixes into "N minor fixes".

## Writing proposals

- **Exact text.** `old` and `anchor` must each occur exactly once in the file. Copy them from the file character for character, including punctuation and Markdown, and include enough words to make them unique, usually the whole sentence. Two proposals in one file must not overlap; when two findings touch the same sentence, make them one proposal.
- **Added text.** The text goes in right after the anchor. For a new paragraph, start the `new` text with `\n\n` and choose an anchor that ends its paragraph, such as the paragraph's last sentence; `check` reports an anchor that does not. Without `\n\n`, the text is inserted inside the paragraph. Keep it to the smallest text that answers the reader question.
- **Why.** One or two sentences, in plain words, on what goes wrong for the reader without the change. The author reads it on the page next to the change.
- **Groups.** Give fixes of one kind the same group, for example "Terms" or "Diagram labels", so that "Accept all fixes in a group" accepts a set the author can judge as one. That button leaves out additions and fixes marked "Needs a check", which the author decides one by one. Keep a fix that needs its own judgment out of a routine group.
- **Manual changes.** Set `manual: true` when the change is not one exact replacement, such as a diagram layout change or the same edit in several places. Point `old` and `new` at the first place, so the page can show the change, and list the other places in `why`. You apply manual proposals by hand after the author accepts them; `apply` skips them.

## The author's choices file

decisions.json sits next to proposals.json and is keyed by proposal ID. The served review page writes it. You write it yourself when the author answers in chat, and the decisions.json that the standalone page downloads takes the place of this file.

```json
{
  "P-001": {"status": "accepted", "option": null, "note": "", "at": "2026-10-09T14:03:11", "applied": false},
  "P-003": {"status": "accepted", "option": "a", "note": "keep it general", "at": "2026-10-09T14:04:02", "applied": false}
}
```

- `status`: `open`, `accepted`, `rejected`, `discuss` or `default`. For a decision proposal, `accepted` means the option in `option` was chosen. Only `apply --defaults` writes `default`, which means the recommended answer was taken because the author asked you to decide; an addition never gets `default`.
- `option`: the chosen option's ID for a decision proposal, otherwise null.
- `note`: the author's comment, or an empty string.
- `at`: local time of the choice, as `yyyy-mm-ddThh:mm:ss`.
- `applied`: false until the change is in the document. `apply` sets it, also for an accepted option that keeps the text, which it reports as kept; set it yourself after a manual change.

## Commands

Run each command from the working folder as `python3 <skill>/scripts/proposals.py <command>`; `--help` describes every command. The exit code is 0 on success, 1 when problems are found, and 2 for a usage error.

```
check ROUND_DIR [--notes PATH]                validate proposals.json and run the NOTES.md checks over every new text
lint --notes PATH FILE_OR_DIR...              run the NOTES.md checks over Markdown files
serve ROUND_DIR [--port 8770]                 serve the review page; choices are saved to decisions.json
serve --doc PATH...                           serve a read-only preview of the document
page ROUND_DIR [--out PATH]                   write a standalone review.html that keeps choices in the browser
apply ROUND_DIR [--defaults] [--dry-run]      apply accepted proposals and list what is left for you
snapshot ROUND_DIR --doc PATH...              copy the document's Markdown files into ROUND_DIR/base/
changes ROUND_DIR --doc PATH... [--out PATH]  write a read-only page of the changes since the snapshot
```

`check` reports a check match only when a proposal's new text has more matches than the text it replaces, so a proposal may edit a sentence that keeps an open assumption mark. `serve` keeps running until it is stopped, so start it in the background; once a proposal is applied, the page refuses to change its choice. `apply --dry-run` prints the changes as a diff and writes nothing. Running `apply` again changes nothing that is already applied, even after an interrupted run, because it records each change as soon as it makes it.

`snapshot` and `changes` serve the apply-and-mark path of a stakeholder round (stages/stakeholder.md), and neither needs git. Run `snapshot` before the first edit of the round; it refuses to run when ROUND_DIR/base/ already exists, so a snapshot is never overwritten. Both commands store each file's path relative to the folder they run in, so run them from a folder that holds the document, with ROUND_DIR and the `--doc` paths written from there: the working folder, or its parent when the working folder is a subfolder beside the document. `changes` compares the current files with base/ and writes ROUND_DIR/changes.html: the changed files in full, with new text in yellow, removed text struck through and an ID such as C-12 on each change for the author to quote. It keeps the IDs in ROUND_DIR/changes-ids.json, so a change keeps its ID when `changes` runs again.
