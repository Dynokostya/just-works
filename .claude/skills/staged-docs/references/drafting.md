Read this before you write a piece sheet or draft any piece, in any mode. It holds the fields of a piece sheet, the diagram rules, the text rules and the self-check. Assumption marks are described under Gaps in SKILL.md.

## Piece sheet

A piece sheet lets the author approve what a piece will say before reading a draft of it. Write one for each auto or step-by-step piece in sheets.md, under the heading `Piece <n>: <title>`:

- **Purpose**: one line.
- **Input and output** (only for a piece that describes part of a process): what that part starts from and what it produces.
- **Key claims**: at most five, each with its source (file:line or a link) or "assumed".
- **New terms**: each one already in the concept ledger, or, in an auto piece, marked as an assumption.
- **Assumptions**: what you take as true without a source.

## Diagrams

A piece gets a diagram when its `diagram` flag in NOTES.md is true. These rules hold for every diagram:

- Draw it in Mermaid, unless the project uses another format.
- Keep it to about 12 boxes. Split a larger picture into an overview and one diagram for each part.
- Give it an accessible title and description where the format allows (`accTitle` and `accDescr` in Mermaid).
- Make the text and the diagram agree: every path, part or row that the text describes is in the diagram, and everything in the diagram is in the text.

An overview diagram of a process follows these rules as well (human-writing's rule "When the document describes a process"):

- It shows the flow only: no roles, no tool names and no technical detail. Who does what goes in the text.
- Each box is one piece, under the same name and in the same order.
- Name each box, and its piece, with an action phrase, such as "Check the claim", and write the state it leads to on the arrow that leaves it, such as "approved".
- Draw a decision as a diamond with labeled exits, and an approval as a diamond labeled "approved?" with "yes" and "no" exits and no role.

## Text

The human-writing skill applies in full. These of its rules come up most often when you draft a piece:

- Each section opens the way its type needs (human-writing's rule "What is this?"): an explanation with what the thing is, a procedure with its goal, a report or a findings section with its main finding. When the piece describes part of a process, its opening also gives the input and the output in one sentence.
- When the document describes decisions its readers make or wait for, the text names the owner role at each decision, from the Roles table in the concept ledger (human-writing's rule "When the reader acts on decisions"). A standing rule in NOTES.md, such as "a person approves", replaces this when the author chose one.
- When the readers need different depth, such as people who decide and people who carry out the work, follow human-writing's rule "When the readers need different depth".
- Examples are few, labeled as examples and collapsed where the format allows. Where the text describes a step, an example shows an excerpt of what the step produces and leaves out logs of tool runs. When the document walks through a process or a scenario, one running example goes through all of it (human-writing's rule "Is this real?").
- The text holds decided content only, and planned or open items go in one place, such as a section for planned work or NOTES.md (human-writing's rule "Does this exist yet?"). In a document that proposes options, such as a proposal or a plan with open choices, the options are the content: label each one as an option, and say who decides and by when (human-writing's rule "When the document proposes options").
- When the document describes a process, its parts carry no numbering scheme across pages, and they share a fixed template of slots only when the content differs from one step to the next (human-writing's rule "When the document describes a process", and its habit "The same point, formula or length throughout").

## Self-check before showing a draft

1. The piece uses only concepts the reader knows or the ledger introduces, and the author approved each new term; in an auto piece, a new term carries an assumption mark instead.
2. Every claim comes from the author, a decision or a named source, and anything else carries an assumption mark. Check the joins as well: a step you add to connect two stated steps, such as what happens after a wait or who acts next, is a claim too, and it is the kind of claim that is easiest to invent without noticing.
3. Ask "What does this piece add that the earlier ones did not?" and "If it were cut, what would break?" Cut any part that adds nothing and whose loss would break nothing.
4. The author's standing rules hold. When Python is available, run `python3 <skill>/scripts/proposals.py lint --notes NOTES.md <file>` and fix what it reports, as the Lint rule in SKILL.md describes.
