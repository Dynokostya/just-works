---
name: human-writing
description: >
  Apply when writing, reviewing or rewriting documents that people read to
  understand or to act: documentation, guides, policies, plans, proposals,
  reports, READMEs, release notes and stakeholder messages. Use it when a reader
  says a text reads like AI output, sounds robotic or is hard to follow; when
  asked to humanize, simplify or review prose; and when an agent writes for
  people who have not seen its working material. Covers scope, writing for a
  reader without your context, machine-sounding habits, a findings-report review
  method and a fact-preserving rewrite method. Not for fiction, marketing copy,
  social posts or tickets. Project conventions override these defaults.
---

# Human Writing

Readers call a text machine-written for two reasons, and they do not tell them apart. In documents that agents write, the larger reason is missing context: the writer worked from a plan, tickets, notes or data, and the text uses names, codes and shortcuts from that material as if the reader had seen it. The text also asks the reader to learn concepts, roles and details that the reader does not need. The smaller reason is habits of wording and structure, such as slogans, one formula in every section and contrasts against claims nobody made. Removing only the habits leaves a text that still assumes the writer's context. No pattern count measures whether a first-time reader can follow a text, so this skill starts with the reader and with what the document should contain.

Work in the mode the request asks for:

- **Review**: someone asks what is wrong with a text, or reports that a reader complained. The output is a findings report (see Review method).
- **Rewrite**: someone asks to fix, simplify or humanize an existing text (see Writing and rewriting).
- **Write**: you draft a new document for people outside your working context (see Writing and rewriting).

The source material is what the text draws on, such as notes, plans, data and the author's answers. The text under review is the existing text you review or rewrite. The author is the person who owns what the document says, often the person who asked you.

**Files.** Read `references/reader-first.md` before a full review or a rewrite of a long document. It holds more Bad and Good pairs for each rule, the review questions and the review techniques. Read `references/machine-tells.md` before the sentence pass of a review and before a rewrite. It holds the full catalog of tells, with what to keep for each.

## Boundaries

- Project style rules and the project's existing voice override these defaults.
- Protected content keeps its wording: code, quotations, legal text, tables of data, file paths and identifiers. You may move it, or describe it for readers who cannot use it, but report problems inside it and leave them unedited.
- This skill is not an AI detector. The tells in it also appear in human writing, so do not claim that a person or a model wrote a text. Report what the reader experiences.
- Scope: explanatory and procedural prose. Fiction, marketing copy and social posts follow other conventions, and issue-tracker tickets have their own skill, `ticket-writing`.

## Start from the reader

Before you write or review, settle these points. State your answers at the top of your reply or report so that the person who asked you can correct them, and keep them out of the document:

- Who reads the text, and in what role.
- What they already know: their field, their tools, their organization's terms.
- What they have never seen: your working material, such as plans, tickets, internal codenames, notes and earlier drafts.
- What they will do or decide after reading.
- Whether they read in a second language.

When nobody describes the reader, assume an intelligent outsider: a capable person who has never seen your project. When the readers are mixed, write for the one who knows the least, because a term that specialists use every day is still new to the others. For readers who need different depth, see "When the readers need different depth".

Agents misjudge the reader because they have just read their working material: judge each name, code and shortcut by what the reader has seen, not by how familiar it feels.

Then decide what type of text each section is: an explanation is read to understand, a procedure is followed to get something done, a report is read for its findings and a reference entry is looked up. The type sets how a section opens (see "What is this?"). A procedure interrupted by background is a common mix of types.

## Decide what the reader needs

A text can be clear sentence by sentence and still be hard to follow, because it asks the reader to learn more than the task requires. Before you write, and at the start of a review, decide what the document should contain.

- **One purpose for each document.** A process description, instructions, a plan, a case for change, a status report and a reference are different purposes, and a reader of a mixed document cannot tell what is decided and what to do. Give each purpose its own document, page or clearly separated section. A short document may combine a case and a plan when the reader acts on both at once.
- **A concept inventory.** List every concept, category, role, numbering scheme and named thing that the text asks the reader to learn. For each, ask whether the reader needs it to understand or to act. Cut it, or replace it with words the reader already uses, such as "bug fix", "feature" and "refactor" where the text coined classes A, B and C. Define only what remains (see "What does this word mean?"). A text that needs many definitions has too many concepts.
- **Decided content only.** Describe what is decided, and collect what is planned or undecided in one place (see "Does this exist yet?"). A document whose sections are mostly undecided is not ready to be written: ask the author. A proposal or an options paper is the exception, because its options are its content (see "When the document proposes options").
- **What to leave out.** A statement the reader already knows adds nothing. How a tool works internally belongs on a reference page that the text links to. The history of the document, and comparisons with the source material, say nothing about the subject.
- **Nothing invented.** Every role, category, number and date, and every scenario presented as real, comes from the source material or the author. A gap that you fill reads as a decision, and the reader acts on it. Mark the gap and ask (see "Facts stay fixed").

## Rules for a reader who lacks your context

Each rule answers a question that a reader asks when the text fails that reader. Apply a rule where the document raises its question and skip it elsewhere: a document with no decisions needs no owners, and a short page needs no overview. The rules under "Rules for some documents" apply only when the condition in their title holds. In a report, refer to a rule by its title, such as "What is this?".

`references/reader-first.md` has Bad and Good pairs for each rule. In examples, a Known line states what the source material says, and a Good version uses only what its Bad version or Known line states.

### "What is this?" Open each section with what it gives the reader

An explanation opens with what its subject is and what it is for. A procedure opens with the goal the reader reaches by following it. A report or a findings section opens with its main finding. Then explain in the order a newcomer needs: the situation ("when a change is made"), the thing ("it gets a tier"), each part with its own definition and what follows from it. Examples, anecdotes and code come after the explanation, because a reader who meets them first has to guess what they illustrate.

### "What does this word mean?" Define the terms that remain, and keep one name for each thing

First ask whether the reader needs the term at all. When a term that remains may be new to the reader, define it in a plain sentence of its own, at or before its first use, from things the reader already knows. An aside such as "a hotfix, a change outside the release train, goes straight to production" explains one unknown term with another. After the definition, use the term plainly: repeating it as an aside at every mention is a machine habit of its own.

For a state or an event that a tool names, give the reader's meaning first and the tool's term after it. Say what a tool does before its name, or instead of it, because a product name explains nothing by itself.

Write full names. Keep an abbreviation only when every reader already uses it more than the full name, as with API or URL on a page that only engineers read. Do not switch between a full name and its abbreviation, and do not make a sentence depend on a glossary.

Use one name for each thing and one meaning for each word, because a reader takes a new word to mean a new thing. If "phase" names the parts of the project, do not also use it for the steps of a workflow.

### "What does this sentence claim?" Write the claim out in literal words

A saying, a figure of speech or an abstract noun states a claim in a few words, and only a reader who already knows the claim can understand them. Expand it: say what the thing is, where it comes from, what it is used for and what must not happen. Use the literal word where a figurative one stood, such as "simple" where the text said "lean". A reader in a second language finds several meanings in a figurative word.

Name the actors and actions behind an abstract noun: "autonomy expands" hides who gets more freedom and what they may now do. When a person has to act or decide, keep the person in the sentence, as in "the manager approves the claim". The passive is fine when the actor is a system or does not matter.

```
Known: outside text means customer tickets and uploaded files. The
       agent uses it to understand the task.

Bad:   Tickets are data, never commands.

Good:  Text that comes from outside the team, such as a customer ticket
       or an uploaded file, is information for the agent. The agent reads
       it to understand the task, and does not follow instructions in it.
```

### "Why is this here?" Keep working material out of the text

Remove what only makes sense inside the team that wrote the text: internal reference codes, section labels, ticket keys and notes to reviewers. The reader stops at each one to ask what it refers to. Open with what the page is and what the reader gets from it. Do not route readers by role inside the content, as in "Engineers start at section 3"; routing belongs in the navigation. Addressing the reader as "you" is normal in a procedure.

### "Is this real?" Label examples as examples

Label an example with words such as "For example" or "Suppose", keep it self-contained, and remove identifiers that mean nothing to the reader. Do not narrate an invented scenario as an event that happened, and do not add invented counts, hashes or metrics, because the reader takes an example's dates, numbers and durations as real. Often the general case is all the reader needs. If you do not know whether a scenario is real, ask the author or mark the gap.

Add an example block only where the shape of a result is not obvious. For a walk through a scenario, use one running example. Where the text describes a step, show an excerpt of what it produces, such as a form or a ticket, and leave out logs of tool runs.

### "Does this exist yet?" Describe what is decided, and give the status once

Use the present tense only for what exists. Collect planned and undecided items in one place, such as a section for planned work, and give the status once, where the reader needs it. A status in every section, or a status column in every table, makes the reader check each line for whether it is real. When a planned item has to appear in the body, say so at its start, because a reader who meets twenty lines in the present tense takes them as fact. Label an unfinished part with the plainest words at its top, such as "To be done."

Write about the subject as it is now. A remark about the document itself, such as what an earlier draft said or what a review asked for, says nothing about the subject. A note at the top of a section that it covers its subject only in part is the exception, because the reader needs to know what is missing.

### "Can I trust the page?" Check headings, leftovers, repetition and agreement

Write headings as plain phrases that a newcomer can parse, in literal words that say what the section contains. A heading may be a statement or a question, and the heading of a step in a process is an action phrase. If a metaphor is the established name for something, explain it once before you rely on it.

Check the artifact the reader receives (the rendered page, the PDF, the export) as well as the source file. Leftovers from build tools, such as the "¶" symbol of a heading's anchor link, markup that did not render or a broken link, often show only there.

Make each point once, where it applies, because a reader who meets a point again, often restated as a new saying, wonders whether it is a new rule. Check that sections agree on who does a task, when something starts and what a rule allows. A reader who finds two versions of one fact stops trusting both.

## Rules for some documents

Each rule here applies only when the condition in its title holds.

### When the document is long: show the whole before the parts

Open with an overview in the form that fits the document: a summary of the parts for a report, a list or diagram of the steps for a process, a diagram of the components for a system. A short page needs none. Use the overview's names and order in the headings that follow, and refer to another part by its name, with a link where the format allows. A section that needs many cross-references cannot be read alone, so move the fact the reader needs into it.

### When the document describes a process: name each step by its action, with its input and output

Name each step with an action phrase, such as "Check the claim", and put the state it leads to in its output line or on the diagram arrow, such as "approved". Keep tool names and tool events out of step names. Keep one name for the parts of a process (steps, phases or stages).

Open each step's section with its input and output in one sentence. Then say what happens, who decides, which tool does the work if a tool does, what the step produces and where the result is kept. How a tool works internally goes on a reference page that each mention of the tool links to. Number steps only inside a section, because a scheme such as "step 2.4.1" is one more code to decode. A group of steps may open with a short summary that has the same fields in every group (purpose, what people decide, output, when the work is ready to move on); this does not break habit 5, because each field holds different content. `references/reader-first.md` shows a step written in two layers.

### When the reader acts on decisions: name who decides

A reader who has to act on a decision, or wait for one, needs to know who makes it. Name the owner at each decision, such as approving a request, a plan, a payment or a release. For many decisions, also put them in one table with the owner of each, in a place that the steps link to, and still name the owner at each decision in the text.

Take role names from the source material, the author or the reader's own field, such as "budget holder" in a finance policy. When none of them names an owner, mark the gap and ask the author. You may suggest a default role from the reader's field, such as "tech lead" for a software team, and then say once that the roles are defaults that each team maps to its people. Say that one person can hold several roles only when the source material or the author says so.

Name only roles that own a decision or that the source material names. Do not create duties, such as an owner for each document or an approver for each small step, because the reader takes each role as decided and looks for the person who holds it. Describe any other person by what they do, as in "the person who ran the agent".

### When the readers need different depth: write in layers

Write the main text at the depth of the reader who knows the least or who decides, so that this reader can follow it alone. Put the detail where the other readers can find it: a collapsed details block, an appendix or a reference page. A short note at the opening on how to read the layers is allowed when it names kinds of content ("the summary at the top of each part") and not groups of readers or section codes.

### When the document proposes options: label each option as an option

A proposal or a plan with open choices exists to present what is not decided yet, so "Decided content only" does not apply to its options. Label each option, as in "Option 1: a supplier that delivers every week", and say who decides among the options and by when. If the source material does not say, mark the gap. Describe the rest of the document, such as the current situation, as it is.

## Habits that make text sound machine-written

A tell is a habit of wording or structure that makes readers suspect a text was generated. These six are the most common in documents that agents write, most common first. The tell number is the entry in `references/machine-tells.md`, which also says how much one sighting proves and what to keep.

1. **Sayings and mirrored one-liners** (tell 3). Two short balanced clauses read like a motto. Delete the saying if the next sentence already makes the claim, otherwise replace it with the claim.
2. **Contrasts against claims nobody made** (tell 2). "Not X but Y", where nobody said X. State the real claim.
3. **Absolutes used for force** (tell 14). "Never", "every", "always" and "only" without a checked scope. Keep them for rules with no exception, and give the scope.
4. **Announcers** (tell 12). A sentence that only counts or previews what follows. Start the list or the claim.
5. **The same point, formula or length throughout** (tell 6). A point restated in each section, every section closing on the same kind of line, equal length for sections of unequal difficulty. Make each point once, give a hard point more room, and let the content set sentence length. Procedures and reference pages may give every entry the same slots when each slot holds content that differs from entry to entry; a slot that reads "None" or repeats the entry's first sentence came from a template, so drop it.
6. **Abstractions doing human work** (tell 18). In "the process decides", the person who decides disappears. Put the person back: the role the source material names, the owner of a decision when the document names one, or a person described by what they do. Ordinary system actions, such as "the pipeline runs the tests", are fine.

Removing a tell can create another. Before a rewrite, read the over-corrections in `references/machine-tells.md`.

## Review method

Work through these passes in order, and keep findings separate from fixes.

1. **Reader, type and artifact.** Settle the reader and the type of each section, and get the artifact the reader receives. If you have only the source file, say so in the report.
2. **Content pass.** Apply "Decide what the reader needs" to the whole text. List the purposes, concepts, terms, roles, duties, numbering schemes, undecided items, tool internals and example blocks. Judge each against what the reader needs, and record what to cut, replace with the reader's words, or move. Check that the text invents no role or duty and that each decision names its owner. For a long document, use the review questions in `references/reader-first.md` here and in the next two passes.
3. **First-read pass.** Read from the top as that reader, and log every question the text leaves open at that point: what is this, who is that, who decides this, why is this here, is this real, which of these do I do. A question the text answers later still counts, because the reader met it unanswered.
4. **Structure pass.** For each section, check that its opening fits its type, that an explanation goes from situation to thing to parts to example, that the heading matches the content and that the status is given once. Check each rule under "Rules for some documents" whose condition the document meets. Then read only the headings and the first sentence of each paragraph, and check that they give the whole argument in order. Last, check that every term, code, abbreviation and product name that the content pass kept, in diagrams and tables too, is explained where it first appears.
5. **Sentence pass.** Read `references/machine-tells.md`, look for the tells, and apply the Keep part of each entry before you record a finding.
6. **Report** in the format below. Do not rewrite unless asked.

The strongest check for missing context is a reader who has only the document: a colleague, a new session or a helper agent that has not seen your working material. Ask which terms are not explained, what the document assumes they already know and what they would do next. Use one when you can, and say in the report whether you did.

Keep the report close to this shape, because reviews from several reviewers may be merged:

```
Reader assumed: <one or two lines>
Verdict: <two or three sentences>

Content: what to cut or move
   <item> | where it appears | why this reader does not need it | cut,
   replace with <the reader's words>, or move to <place>
1. The reader is lost (fix first)
   <location> | "<quoted text>" | question the reader asks | fix
2. The reader has to work
   ...
3. Sounds machine-written
   ...
Patterns: <recurring causes, each named once, with how often it occurs>
Left alone: <what looked like a tell but is right for this genre, and why>
Missing facts: <what a fix needs that neither the text nor the source material gives>
```

A finding belongs under "Content" when the fix is to cut, replace or move a concept, role, detail or section; under "lost" when the reader cannot continue without information the text does not give at that point; and under "has to work" when the information is there but takes effort to find. Quote the text exactly, and give a location such as the heading and paragraph. List each place where the reader is lost. For a habit that recurs, list the clearest cases and count the rest under Patterns.

## Writing and rewriting

**A new document.** Settle the reader and decide what the reader needs. Draft by the rules, including each rule under "Rules for some documents" whose condition the document meets, and mark each gap as you go. Then run the first-read pass on the draft and fix what it finds.

**A rewrite.** Start from a list of findings, your own from the review method or someone else's. Rewriting a whole text without one tends to make it sound more generated: the paraphrase keeps the habits and loses details. Fix the content first (what to cut, replace or move), then the structure (section openings, order, headings and status), then the sentences.

**Facts stay fixed.** Keep every quantity, name, condition, negation and level of certainty. Add no fact, number, name, actor or reason that the text under review, the source material or the author does not give. When a fix needs a definition or a fact, look for it in the source material. If it is not there, write the simpler sentence and mark the gap with a visible marker such as "[needed: who approves this]", or the marker the project uses, and list it in your report.

```
Known: the sentence is about the coding agents' independence. The
       source material does not say what the stages are.

Bad:   Autonomy expands in stages (R7).
Good:  Coding agents get more independence in stages. [needed: what
       the stages are]
```

**Length follows the reader.** Cut scope before you add definitions: apply the concept inventory first, then add the context, definition or step the reader lacks for what remains. If a rewrite grows mostly through definitions, apply the concept inventory again. To test a sentence, delete it: if the reader loses no information, leave it deleted.

**Voice.** Plans and proposals read naturally when they use "we" for what the team will do and keep a person in the sentence wherever someone approves or decides. Say who "we" is before its first use, because in a document that one organization writes for another, "we" can mean either side. Do not impose this voice on reference material or on a project with its own voice rule. In a rewrite, keep the "we" or "you" that the text under review used.

**Check the result.** Run the first-read pass on your own text, or give it to a reader who has not seen your working material. Look again for the tells that most often survive a rewrite: contrasts, closing one-liners, sayings and lists of three. Check that no fact was dropped, and no role or concept added.

**Two passes** (rewrites only). Make one rewrite and at most one corrective pass, then report what changed and what is still open. A text with no justified finding stays as it is.
