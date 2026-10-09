Applies to pieces whose mode is `author-led`: the author gives their view of the piece first, and you shape it into a diagram or an outline, and then text, without adding claims of your own.

For the current piece:

1. **Ask for the view.** When the author's message already gives their view of this piece, go straight to step 2. Otherwise: **Stop.** Set `waiting_for: "the author's view of piece <n>"` in NOTES.md, ask the author for their view of the piece as an open question, and end the turn with the menu. The author may dictate at length and in any language. Names of people, places and products can arrive misheard, so confirm with the author each name that looks wrong.

2. **Save it verbatim.** Before you do anything else with the author's words, append them unchanged to inputs/piece-<n>.md as an entry headed with the date. Do the same with each later answer that adds to the substance of this piece; a bare instruction such as "continue" or "approved" is not substance. These words are the source that every claim in the piece traces back to.

3. **Discuss.** Restate the view as a short list, keeping what the author said apart from what you infer. Point out where it conflicts with the sources, citing the location, or with common practice in the field. Disagree where you have grounds: the author wants conflicts named, and agreement for its own sake hides them. Ask the numbered questions, and end with "Anything else for this piece?"

   **Stop.** Set `waiting_for: "approval of the substance of piece <n>"` and end the turn with the menu. Repeat steps 2 and 3 until the author approves the substance. Record each decision as a D-n line in NOTES.md, then set `status: discussed`.

4. **Shape.** Draft the diagram, or an outline when the piece has no diagram, from the approved substance only, following references/drafting.md.

   **Stop.** Set `waiting_for: "approval of the diagram for piece <n>"` (or of the outline). Show it, ask for comments or approval, and end the turn with the menu. When the author approves, set `status: shaped`.

5. **Text.** Draft the text from inputs/piece-<n>.md, the decisions and the approved shape. Where something is missing, ask a numbered question instead of writing text to fill the gap. A gap is anything the reader needs from this piece that neither the author's words nor the sources say, such as who does a step or how a choice between options is made. Leaving a gap out of the text is right, and asking about it is what lets the author fill it. Run the self-check, and check also that every claim traces to the author's words, a decision or a named source. Set `status: drafted`.

   **Stop.** Set `waiting_for: "approval of the text for piece <n>"`. Show the text and ask for comments or approval. If there are real gaps, add "What is missing in this piece?" with a short list of questions, as a last check for what the discussion skipped. End the turn with the menu. When the author approves the text and no assumption mark is left in the piece, set `status: done`.

**Exit:** the piece has `status: done`; inputs/piece-<n>.md holds the author's words; each decision is a D-n line in NOTES.md; the piece's file holds no assumption mark. Then go on with the next unfinished piece, or set `stage: review` when none is left.
