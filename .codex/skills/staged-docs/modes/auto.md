Applies to pieces whose mode is `auto`: you draft them from the topic and the sources, after the author approves the piece sheets of all auto pieces at one stop.

1. **Piece sheets.** Set `current_piece` to the first auto piece at `status: todo`. Write a piece sheet to sheets.md for every auto piece at `status: todo`; the fields are in references/drafting.md. If an answer from the author would change a sheet, ask at most one numbered list of such questions.

   **Stop.** Set `waiting_for: "approval of the piece sheets for the auto pieces"` in NOTES.md. Show the sheets and any questions, ask the author to approve or edit them, and end the turn with the menu. This is the only stop before the auto pieces are drafted, because a person who first sees a finished draft is anchored by it and checks it less carefully than a short sheet of claims.

   When the author approves the sheets, set those pieces to `status: sheet` and go on with the next unfinished piece.

2. **Draft** each auto piece when its turn comes: the shape first (a diagram, or an outline), then the text, following references/drafting.md, and run the self-check. Write only what the approved sheet and the sources support, and give anything else an assumption mark. A term that is not in the concept ledger also gets an assumption mark, and you list it under Assumptions for the review stage instead of adding it to the ledger, because no stop comes before the review where the author could approve it. Set the piece to `status: drafted` as soon as it is written, so that a lost session resumes at the right piece.

   Do not stop between auto pieces. When the next unfinished piece is also auto, draft it in the same turn. When it is step-by-step or author-led, read its mode file, and say at that piece's first stop which auto pieces are drafted and waiting for the review.

3. **Hand over to the review.** When no unfinished piece is left, set `stage: review` and read stages/review.md. The review shows the author the auto pieces first, starting with what differs from the sheets and what is assumed.

**Exit:** every auto piece has `status: drafted`, its sheet in sheets.md, and each of its assumption marks listed under Assumptions in NOTES.md.
