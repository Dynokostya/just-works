Applies when NOTES.md says `stage: review`, which is set when every piece is drafted. This stage runs one review round: four reviewers, a verifier, proposals the author decides on and the accepted changes applied.

1. **Open the round.** Increase `round` by one and, in the same step, create reviews/r<n>-review/ with a findings/ folder, where n is the new `round`.

2. **Run the four lenses**: reader, accuracy, consistency and completeness. Each runs in a fresh context, so that no reviewer is primed by the conversation that produced the drafts. Their prompts are in references/review-lenses.md. Each lens gets the document, NOTES.md (ledger, standing rules, decisions), the sources and, when it exists, sheets.md. If you can run subagents, run one per lens; each writes findings/<lens>.md and returns a short summary. Otherwise run the lenses one after another yourself, and write each findings file before starting the next lens.

3. **Verify.** A fresh verifier, a subagent when you can run one, checks each finding at its cited location with the verifier prompt in references/review-lenses.md, and answers real, false or unsure with evidence. Drop the false ones. Keep the unsure ones with `verdict: unsure`. Reviewers report some problems that the text already handles, and checking each finding at its location keeps the author's attention for the real ones.

4. **Triage** the findings in this conversation, by the triage rules in references/review-lenses.md, together with the Deferred findings in NOTES.md that still apply; remove from Deferred findings each one that becomes a proposal. You do this yourself because the reviewers did not see the conversation in which the author made the decisions.

5. **Write proposals.json** in reviews/r<n>-review/, following references/proposals.md. Run `python3 <skill>/scripts/proposals.py check reviews/r<n>-review`, fix every problem it reports, and run it again until it prints `OK`.

6. **Present the round.**
   - When the round covers auto pieces, open with them: the differences from the approved piece sheets, the open assumptions (numbered, each to confirm, change or cut) and the riskiest claims with their sources. Reading the full text is optional for the author. This order puts the parts most likely to be wrong in front of the author first.
   - For about 15 proposals or fewer, list them numbered in chat, each with its ID, one line on the change, the why and the recommended answer. The author answers in shorthand, such as "P-003 b, P-004 reject", and you write the author's choices file.
   - For more, start `python3 <skill>/scripts/proposals.py serve reviews/r<n>-review` in the background and give the address it prints. If the server cannot start (for example in a sandbox), run `python3 <skill>/scripts/proposals.py page reviews/r<n>-review`, give the path of the review.html it writes, and ask the author to send back the decisions.json that the page downloads. The page does not show the open assumptions, so list them in chat next to the link.
   - Ask the questions that triage logged under Questions for this round.

   **Stop.** Set `waiting_for: "decisions on the r<n>-review proposals"` in NOTES.md, ask the author to review and say when they are done, and end the turn with the menu.

7. **Apply the decisions.** Read the author's choices file. If the review server is running, stop it, so that no choice changes after it is applied.
   - Take the proposals with status `discuss` one at a time. For each: **Stop.** Set `waiting_for: "discussion of P-<id>"`, give your view and ask, and end the turn with the menu. Record the outcome in the author's choices file. When the discussion changes a proposal's wording, write the new text into proposals.json and run `check` again before you record the proposal as accepted.
   - If the author asks you to decide the remaining ones, run `apply --defaults`, which takes the recommended answer and leaves additions open. Otherwise run `apply`.
   - If any proposal is still open, such as an addition that `apply --defaults` left open: **Stop.** Set `waiting_for: "decisions on the open r<n>-review proposals"`, list them numbered with your recommendation for each, ask, and end the turn with the menu. Record the answers and run `apply` again.
   - Do by hand what the script lists under "Left for the agent": manual proposals, such as diagram changes, and skipped edits. An accepted option that keeps the text needs nothing; the script reports it as kept.
   - Settle the assumptions the author answered: a confirmed one loses its mark and gets a D-n line, a changed one is edited, a cut one is removed.
   - Record in NOTES.md a D-n line for each decision proposal (the option chosen) and for each rejected proposal, in the form `D-<n> (<date>, author): Rejected <round-id> P-<id>: <reason>.` with this round's ID, so that later rounds do not raise it again; a Rounds line with the counts (the format is in references/notes-template.md); and remove the settled assumptions from Assumptions.
   - Run `python3 <skill>/scripts/proposals.py lint --notes NOTES.md <document>` and fix what it reports, as the Lint rule in SKILL.md describes.

8. **Confirm.** Show a short summary of what changed. **Stop.** Set `waiting_for: "confirmation of the r<n>-review changes"`, ask the author to confirm and whether they have stakeholder feedback to bring, and end the turn with the menu. When the author confirms, set the auto pieces at `drafted` to `done`. If the author has feedback to bring, set `stage: stakeholder` and `return_stage: finish`; otherwise set `stage: finish`.

**Exit:** no proposal in the round has status `discuss`, and the author was asked about each one still open; every accepted proposal is applied; NOTES.md has the D-n lines and the Rounds line for this round, no settled assumption under Assumptions, every piece at `status: done`, and `stage` set to `stakeholder` or `finish`.
