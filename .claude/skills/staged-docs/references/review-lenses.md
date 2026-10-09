Read this at the review stage. It holds the prompts for the four reviewers (lenses) and the verifier, and the rules for triage. A reviewer in a fresh context sees nothing but its prompt, so each prompt below is complete once you fill in the paths.

## Shared part of every lens prompt

Send each reviewer this part, followed by the part for its lens. Leave out the line on the piece sheets when sheets.md does not exist.

```
You are reviewing a document written for people. You have not seen the conversation
that produced it.

Inputs:
- The document: <paths>
- NOTES.md: <path>. It holds the concept ledger (what the reader knows, the terms the
  document may introduce and, if the document describes decisions, the roles that own
  them), the author's standing rules and the decisions. Lines under Decisions that
  contain "Rejected" record proposals the author already rejected.
- The sources the document draws on: <paths>
- The piece sheets: <path to sheets.md>

The standing rules in NOTES.md override the defaults of the human-writing skill, so do
not report what a standing rule allows, and do not raise again what the author rejected.
Report only what would mislead or stop a reader, or break a rule stated in NOTES.md.
There is no minimum number of findings, and an empty report is a valid result.
Do not edit the document or any other input.

Write your findings to <round folder>/findings/<lens>.md, one block per finding:
- Location: file:line
- Text: the exact text, quoted
- Problem: what goes wrong for the reader
- Source: the file:line or link that shows the problem, or "none"
Then reply with a summary of at most five lines: the number of findings and the
most serious ones.
```

## Lens: reader

```
Lens: reader. Read the document as a reader who has only the document. If you can read
the human-writing skill (<path to its SKILL.md>), work through the passes of its review
method, but write each finding in the block format above instead of that skill's report
format, and include findings that the text sounds machine-written. If you cannot read
it, read from the top as a newcomer and log every question the text leaves open at the
point where it arises.
In either case, then write 5 to 10 questions that a real reader of this document would
ask, and answer each from the document alone. Check your answers against NOTES.md and
the sources, and report each question the document cannot answer or answers wrongly.
```

## Lens: accuracy

```
Lens: accuracy. Split the text into atomic claims, one fact each, and check each claim
against its source: the material the document describes, the sources and the links.
Report claims that no source supports, claims that a source contradicts, and
connections between facts that no source makes.
```

## Lens: consistency

```
Lens: consistency. Check every diagram against the text: every path or part the text
describes is in the diagram, and the diagram shows nothing the text leaves out. If the
document has an overview diagram of a process, check also that every box has a piece
with the same name, in the same order. Check the terms against the concept ledger:
terms used without a definition, two names for one thing and more terms and roles than
the budget allows. If the document describes decisions its readers make or wait for,
check that each decision names the role that owns it, and that the role matches the
Roles table in the ledger. Check numbers and names that differ between pieces. Check
the text against the decisions and the standing rules in NOTES.md, including the rules
that no check pattern covers.
```

## Lens: completeness

```
Lens: completeness. Compare the document with every input: the older versions, the
author's inputs in inputs/, the notes, and the stakeholder feedback in feedback/. If you
can search the web, compare it also with common practice for documents of this kind.
Report what the reader needs and the document lacks. An addition has a higher bar than
other findings: for each one, name the question a reader would ask that it answers, and
propose the smallest text that answers it.
```

## Verifier prompt

Run one fresh verifier over all findings, or several for a long list.

```
You check review findings against the document. For each finding, read the cited
location and the sources it names, and answer real, false or unsure, with one line of
evidence (a file:line or a quote). A finding is false when the text answers it at or
before the point where the reader meets it, when the source does not say what the
finding claims, when a standing rule in <path to NOTES.md> allows what it reports, or
when it repeats a proposal the author rejected (the lines under Decisions in that file
that contain "Rejected"). Do not edit any file. Findings: <paths to the findings files>
```

## Triage

Triage happens in the main conversation, because only you saw the conversation in which the author made the decisions. The author tends to accept proposals in large batches, so what reaches the page is mostly what gets applied; filtering before the page matters more than the buttons on it.

- Merge findings that share a root cause into one proposal.
- Set each priority yourself, by the meanings in references/proposals.md; the reviewers' sense of severity lacks the context.
- Split decision proposals from fixes, as references/proposals.md describes.
- An addition names the reader question it answers. In an author-led piece, turn an addition into a numbered question to the author, logged under Questions in NOTES.md and asked when you present the round, because you add no claims to those pieces.
- Keep about 20 decision proposals per round at most, the ones with the highest priority. List the rest under Deferred findings in NOTES.md, which the next review round or the finish stage shows the author; Parked holds only what the author chose to leave out. Low-priority fixes can come in any number, because the page collapses them.
- Set no quota of findings in either direction: an empty round is fine.
