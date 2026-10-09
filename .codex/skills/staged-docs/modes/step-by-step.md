Applies to pieces whose mode is `step-by-step`: you draft the piece, and the author comments on the diagram, when the piece has one, and on the text.

For the current piece:

1. **Sheet.** Write the piece sheet to sheets.md (the fields are in references/drafting.md). Do not stop for it: the author sees it on top of the first draft shown for the piece, and approving that draft approves the sheet too. The status therefore skips `sheet` in this mode.

2. **Shape.** Draft the diagram, or an outline when the piece has no diagram, following references/drafting.md.

   For a piece with a diagram: **Stop.** Set `waiting_for: "approval of the diagram for piece <n>"` in NOTES.md. Show the sheet and then the diagram, ask for comments or approval, and end the turn with the menu. When the author approves, set `status: shaped`.

   For a piece without a diagram, go on to the text in the same turn; the outline gets no stop of its own.

3. **Text.** Draft the text from the shape and the sheet, run the self-check, and set `status: drafted`.

   **Stop.** Set `waiting_for: "approval of the text for piece <n>"`. Show the text, with the sheet on top when there was no diagram stop, and ask about each assumption mark left in the piece. Ask for comments or approval, and end the turn with the menu. When the author approves the text and no assumption mark is left, set `status: done`.

4. **Contested piece.** If the author's comments rewrite the substance of the piece and not only its wording, offer to switch it to author-led, where the author states the substance before anything is drafted.

**Exit:** the piece has `status: done`; its file holds no assumption mark; each assumption the author confirmed is a D-n line in NOTES.md. Then go on with the next unfinished piece, or set `stage: review` when none is left.
