Applies when NOTES.md says `stage: finish`. This stage checks the document against every input and every decision, writes the opening summary when the structure has one, and closes the work.

1. **Reconcile with the inputs.** For each input (each older version, inputs/start.md, each inputs/piece-<n>.md and each feedback file), a fresh reader lists what in it did not make it into the document: one subagent per input if you can run subagents, otherwise one input after another. Give each reader the Decisions and Parked sections of NOTES.md, and have it leave out the points that a decision declined or that the author parked, because the author has already settled those. Points from early inputs get lost across many rounds, and only the author knows which of them still matter.

2. **Audit the decisions.** Check each D-n line that states what the document says: it is reflected in the document, parked or replaced. A line that rejects a proposal or declines a point is met when the text it rejected is absent, and a line about the work itself, such as the choice of a mode, needs no check. Check also that no assumption mark is left and that every question in NOTES.md is answered or parked, and list the Deferred findings.

   If the lists are empty, go on to step 4 without stopping. Otherwise: **Stop.** Set `waiting_for: "decisions on the reconciliation and audit lists"` in NOTES.md. Show the lists numbered: for each missing item, ask whether to add, park or drop it, with your recommendation; for each audit gap, ask the question that closes it; for each deferred finding, recommend whether to apply, park or drop it. End the turn with the menu.

3. **Apply the answers.** Write what the author chose to add or apply, following references/drafting.md; move parked items to Parked in NOTES.md; empty Deferred findings; and record each answer as a D-n line.

4. **Prepare the opening summary and the cuts.** If the approved structure has an opening summary, draft it now for the file the structure names, following references/drafting.md and with assumption marks, because a summary written earlier describes a document that has since changed. Then look for content repeated across pieces, and list each repeat with the one place where you would keep it. Apply neither yet: the author sees both at the next stop.

5. **Run the checks.** Run `python3 <skill>/scripts/proposals.py lint --notes NOTES.md <document>` and the project's own checks, such as a site build or a link check, and fix what they report.

   **Stop.** Set `waiting_for: "confirmation of the finished document"`. Show the summary draft with a question for each of its assumption marks, the repeats you would cut and the check results. Ask the author to approve them, whether to export the document and in what format, and, when the document is in a version-control repository, whether to commit or push. End the turn with the menu.

6. **Close.** Apply the summary and the cuts as the author approved them, with the summary's assumptions settled, and run `lint` again: it must be clean. If the author asked for an export: the skill has no export command, so use the project's exporter if it has one; otherwise produce the file yourself, such as a single HTML file, and check it: every piece is in it, and its tables, diagrams and links survived the conversion. Set `stage: done`. Commit or push only if the author said yes at the last stop, because a commit or a push is visible to others.

**Exit:** NOTES.md has `stage: done`; every D-n line that states what the document says is reflected in it, parked or replaced; Assumptions, Questions and Deferred findings hold nothing open; the last lint run is clean.
