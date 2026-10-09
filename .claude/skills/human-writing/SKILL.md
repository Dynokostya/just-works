---
name: human-writing
description: >
  Apply when writing, reviewing or rewriting documents that people read to
  understand or to act: documentation, guides, manuals, policies, playbooks,
  plans, proposals, reports, READMEs, release notes and messages to
  stakeholders. Use it whenever a reader says a text reads like AI or LLM
  output, sounds robotic or is hard to follow; whenever someone asks to
  humanize, simplify, clean up or review prose; and whenever an agent writes
  for people who have not seen its working material, such as clients,
  executives, new colleagues or second-language readers. Covers deciding what
  a document includes (scope, concepts, roles, level of detail), writing for a
  reader who lacks your context (terms, abbreviations, internal codes, order
  of explanation, examples, status, headings), removing machine-sounding
  habits without creating new ones, a review method with a findings report,
  and a rewrite method that keeps facts fixed. Not for fiction, marketing
  copy, social posts or tickets. Project conventions override these defaults.
---

# Human Writing

Readers call a text machine-written for two different reasons, and they do not distinguish between them. In documents that agents write, the larger reason is missing context: the writer worked inside working material such as a plan, tickets, notes or data, and the text uses names, codes and shortcuts from that material as if the reader had seen it too. The text also asks the reader to learn concepts, roles and details that the reader does not need. The smaller reason is a set of habits in wording and structure, such as slogans, the same formula in every section and contrasts against claims nobody made. A cleanup that removes only the habits leaves a text that still assumes the writer's context, and the reader's complaint stays. Such a text can pass a pattern detector and still read as generated, because no pattern count measures whether a first-time reader can follow it. That is why this skill starts with the reader and with what the document should contain.

Work in the mode the request asks for:

- **Review**: someone asks what is wrong with a text, or reports that a reader complained. The output is a findings report (see Review method).
- **Rewrite**: someone asks to fix, simplify or humanize an existing text (see Writing and rewriting).
- **Write**: you draft a new document for people outside your working context (see Writing and rewriting).

In this skill, the source material is what the text draws on, such as notes, plans, data and the author's answers. The text under review is the existing text that you review or rewrite. The source file is the unrendered file behind a published page. The author is the person who owns what the document says, who is often the person who asked you.

**Files.** Read `references/reader-first.md` before a full review or a rewrite of a long document. It holds more detail and more Bad and Good pairs for each rule, the review questions and the review techniques. Read `references/machine-tells.md` before the sentence pass of a review and before a rewrite. It holds the full catalog of tells, with what to keep for each. `references/sources.md` lists the evidence behind the rules for people who maintain this skill, and you do not need it during a task.

## Boundaries

- Project style rules and the project's existing voice override these defaults.
- Protected content keeps its wording: code, quotations, legal text, tables of data, file paths and identifiers. You may move it, or describe it for readers who cannot use it, but report problems inside it and leave them unedited.
- This skill is not an AI detector. The tells in it also appear in human writing, so do not claim that a person or a model wrote a text. Report what the reader experiences.
- Scope: explanatory and procedural prose that people read to understand or to act. Fiction, marketing copy and social posts follow other conventions.
- Issue-tracker tickets have their own skill, `ticket-writing`.

## Start from the reader

Before you write or review, settle these points about the reader. State your answers at the top of your reply or report, so that the person who asked you can correct them, and keep them out of the document you write:

- Who reads the text, and in what role.
- What they already know: their field, their tools, their organization's terms.
- What they have never seen: your working material, such as plans, tickets, internal codenames, notes and earlier drafts.
- What they will do or decide after reading.
- Whether they read in a second language.

When nobody describes the reader, assume an intelligent outsider: a capable person who wants to understand and has never seen your project. When the readers are mixed, write for the one who knows the least about the subject, because a term or an abbreviation that the specialists use every day is still new to the other readers of the same page. When some readers need more detail than others, see "When the readers need different depth".

Agents misjudge the reader because they have usually just read their working material. Internal names feel familiar, so the text assumes the reader remembers the same material. Judge each name, code and shortcut by what the reader has seen, and ignore how familiar it feels to you.

Then decide what type of text each section is. An explanation is read to understand, a procedure is followed to get something done, a report is read for its findings and a reference entry is looked up. The type sets the form of a section, including how it opens (see "What is this?"), and mixing types in one section is a common fault: a procedure interrupted by background, or an explanation that turns into a list of steps. The purpose of the whole document is a separate question, which the next section answers.

## Decide what the reader needs

A text can be clear sentence by sentence and still be hard to follow, because it asks the reader to learn more than the task requires. Before you write, and at the start of a review, decide what the document should contain.

- **One purpose for each document.** The purposes that most often get mixed are a description of a process or a system, instructions for a task, a plan with dates and staffing, a case for why something should change, a status or research report and a reference. A reader of a document that mixes them cannot tell what is decided and what to do. Give each purpose its own document, page or clearly separated section. A short document may combine a case and a plan when the reader acts on both at once.
- **A concept inventory.** List every concept, category, role, numbering scheme and named thing that the text asks the reader to learn. For each one, ask whether the reader needs it to understand the text or to act on it. Cut it, or replace it with words and categories that the reader already uses, such as "bug fix", "feature" and "refactor" where the text coined classes A, B and C. Define only what remains (see "What does this word mean?"). Each definition costs the reader effort, so a definition is the fallback for a concept that cannot be cut, and a text that needs many definitions has too many concepts.
- **Decided content only.** Describe what is decided, and collect what is planned or undecided in one place (see "Does this exist yet?"). A document whose sections are mostly undecided is not ready to be written: ask the author. A proposal or an options paper is the exception, because its options are its content (see "When the document proposes options").
- **What to leave out.** A statement that the reader already knows adds nothing. How a tool works internally belongs on a reference page or in an appendix that the text links to. The history of the document, and comparisons with the source material it came from, say nothing about the subject.
- **Nothing invented.** Every role, category, number and date, and every scenario presented as real, comes from the source material or from the author. A gap that you fill reads as a decision, and the reader acts on it. Mark the gap and ask the author (see "Facts stay fixed" under Writing and rewriting).

## Rules for a reader who lacks your context

Each rule answers a question that a reader asks when the text fails that reader. Apply a rule where the document raises its question, and skip it where it does not: a document with no decisions for its reader needs no owners, a short page needs no overview and a report needs no diagram. The examples show one way to answer each question, so choose the form that fits the document. The rules in this section apply to most documents. The rules under "Rules for some documents" apply only when the condition in their title holds. In a report, refer to a rule by its title, such as "What is this?".

Some examples begin with a Known line, which states what the source material says. A Good version uses only what its Bad version or its Known line states, and where a fix needs a fact that neither gives, it marks the gap (see "Facts stay fixed" under Writing and rewriting).

### "What is this?" Open each section with what it gives the reader

What a section opens with depends on its type. An explanation opens with what its subject is and what it is for. A procedure opens with the goal that the reader reaches by following it. A report or a findings section opens with its main finding. Then explain in the order a newcomer needs: the situation ("when a change is made"), the thing ("it gets a tier"), each part with its own definition and what follows from it. Examples, anecdotes and code come after the explanation, because a reader who meets them first has to guess what they illustrate.

```
Known: in a six-week pilot in two clinics, the new check-in form cut
       the average wait at check-in from 25 to 12 minutes in both.

Bad:   ## Results
       The pilot ran in two clinics for six weeks. Waiting times were
       recorded at check-in, and staff were interviewed at the end.

Good:  ## Results
       The new check-in form cut the average wait at check-in from 25
       to 12 minutes in both pilot clinics.
```

### "What does this word mean?" Define the terms that remain, and keep one name for each thing

First ask whether the reader needs the term at all, and cut or replace it if not (see "Decide what the reader needs"). When a term that remains may be new to the reader, define it in a plain sentence of its own, at or before its first use, and build the definition from things the reader already knows. An aside such as "a hotfix, a change outside the release train, goes straight to production" defines nothing, because it explains one unknown term with another. Define only what this reader does not know, and after that use the term plainly: repeating the definition as an aside at every mention is a machine habit of its own.

For a state or an event that a tool names, give the reader's meaning first and the tool's term after it, as in "the change is integrated but not yet released: its merge request is merged", and keep one name for the state after that. Say what a tool does before its name, or instead of it, because a product name explains nothing by itself.

Write full names. An abbreviation saves the writer a few characters, but the reader has to look it up or remember it at every later use. Keep one only when every reader already uses it more than the full name, as with API or URL for a page that only engineers read. When you are not sure, write the full name. Do not switch between a full name and its abbreviation, because the reader cannot be sure whether the two mean the same thing, and do not make a sentence depend on a glossary.

Use one name for each thing and one meaning for each word, because a reader takes a new word to mean a new thing. If "phase" names the parts of the project, do not also use it for the steps of a workflow. When a page uses two numbering systems, say how they relate.

```
Bad:   Each expense claim (EC) needs receipts. Your EC goes to your
       line manager, who approves the EC.

Good:  Each expense claim needs receipts. Your expense claim goes to
       your line manager, who approves it.
```

### "What does this sentence claim?" Write the claim out in literal words

A saying, a figure of speech or an abstract noun states a claim in a few words, and only a reader who already knows the claim can understand those words. Expand it: say what the thing is, where it comes from, what it is used for and what must not happen. Use the literal word where a figurative one stood, such as "simple" where the text said "lean". A reader in a second language finds several meanings in a figurative word and does not know which one is meant.

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

Remove what only makes sense inside the team that wrote the text: internal reference codes, section labels, ticket keys and notes to reviewers. They mean nothing to the reader, who stops at each one to ask what it refers to. Open with what the page is and what the reader gets from it. Do not route readers by role inside the content, as in "Engineers start at section 3", because a reader who sees such a note wonders why those people are mentioned. Routing belongs in the navigation. Addressing the reader as "you" is normal in a procedure, for the person who does its steps. A document written in layers may open with a short note on how to read it (see "When the readers need different depth").

```
Known: the guide explains the first week for new staff in every
       department, and what to bring on the first day.

Bad:   Sales staff start at section B2, warehouse staff at C1, and
       managers at the appendix.

Good:  This guide explains what happens in your first week, and what
       to bring on your first day.
```

### "Is this real?" Label examples as examples

Label an example as one, with words such as "For example" or "Suppose", keep it self-contained, and remove identifiers that mean nothing to the reader. An invented scenario is fine when it is labeled as an example. Do not narrate it as an event that happened, and do not add invented counts, hashes or metrics, because the reader takes an example's dates, numbers and durations as real and asks what they refer to. Often the general case is all the reader needs. If you do not know whether a scenario is real, ask the author or mark the gap.

Add an example block only where the shape of a result is not obvious. When a document walks through a process or a scenario, use one running example for the whole document, introduced once. Where the text describes a step, show an excerpt of what it produces, such as a form, a letter or a ticket, and leave out logs of tool runs. Keep code out of prose that non-technical readers must follow, and say what the code does instead.

```
Known: after an incident, the on-call engineer restores the service.
       The cause is recorded as a bug, and each follow-up action
       becomes a task with an owner.

Bad:   On March 3, login failed for some users, incident OPS-311. On-call
       restored service in 41 minutes. The cause became bug OPS-305.

Good:  When an incident happens, the on-call engineer restores the
       service first. The cause is then recorded as a bug, and each
       follow-up action becomes a task with an owner.
```

### "Does this exist yet?" Describe what is decided, and give the status once

Describe what is decided, and use the present tense only for what exists. Collect planned and undecided items in one place, such as a section for planned work, and give the status once, at the place where the reader needs it. A status in every section, such as "to be decided" or a status column in every table, makes the reader check each line for whether it is real. When a planned item has to appear in the body, say so at its start: a reader who meets twenty lines in the present tense takes them as fact, and a status line at the end comes too late. Label an unfinished part with the plainest words at its top, such as "To be done." A section that is mostly undecided is not ready to be written: ask the author for the decisions.

Write about the subject as it is now. A remark about the document itself, such as what an earlier draft said or what a review asked for, says nothing about the subject: say what the reader should do, or mark the gap. A note at the top of a section that it covers its subject only in part is the exception, because the reader needs to know what is missing.

```
Known: the online booking system is not built. Until it is, staff book
       meeting rooms by email to the front desk. The policy has a
       section on planned changes.

Bad:   Staff book meeting rooms in the online booking system. (Twenty
       lines later: the booking system is not available yet.)

Good:  Staff book meeting rooms by email to the front desk. (In the
       section on planned changes: an online booking system that will
       replace the email.)

Known: the section is a placeholder, and nobody has written it.

Bad:   Drafted after the director's review.
Good:  To be done.
```

### "Can I trust the page?" Check headings, leftovers, repetition and agreement

Write titles and headings as plain phrases that a newcomer can parse, in literal words that say what the section contains, and name the concrete place or result where one exists. Readers use headings to decide what to read, so a heading they cannot parse leaves them guessing. A heading may be a statement or a question, and the heading of a step in a process is an action phrase (see "When the document describes a process"). If a metaphor is the established name for something, explain it once before you rely on it.

Check the artifact the reader actually receives, such as the rendered page, the PDF or the export, as well as the source file. Leftovers from build tools and templates, such as the "¶" symbol of a heading's anchor link, markup that did not render or a broken link, often show only there, and they make the page look unfinished.

Make each point once, in the place where it applies, because a reader who meets a point again, often restated as a new saying, wonders whether each version is a new rule.

Check that statements in different sections agree: who does a task, when something starts, what a rule allows. A reader who finds two versions of one fact has no way to tell which is right, and stops trusting both.

```
Known: the section covers how the team turns a request into an item
       in its backlog that is ready for work.

Bad:   Workflow 1: Request to ready backlog item
Good:  Turn a request into a backlog item that is ready for work

Known: the section covers how the clinic records patient complaints,
       and how each complaint gets an answer.

Bad:   Complaints and closing the loop
Good:  Record and answer patient complaints
```

## Rules for some documents

Each rule here applies only when the condition in its title holds. A document can meet several of these conditions, or none.

### When the document is long: show the whole before the parts

A reader of a long document needs to see its parts, and how they fit together, before reading any one of them. Open with an overview in the form that fits the document: a summary of the parts for a report, a list or a diagram of the steps for a process or a diagram of the components for a system. A short page needs none. Use the overview's names and order in the headings that follow, because a reader who sees a name in the overview looks for a heading with that name. Refer to another part by its name, with a link where the format allows. A section that needs many cross-references cannot be read alone, so move the fact the reader needs into it.

### When the document describes a process: name each step by its action, with its input and output

This skill calls the parts of a process steps. A document may call them phases or stages, and keeps one name for them. Name each step with an action phrase, such as "Check the claim" or "Review the change", and put the state that the step leads to in its output line or on the diagram arrow, such as "approved" or "ready for review". Keep the name of a tool or of a tool's event out of a step's name, and give each state its plain meaning (see "What does this word mean?").

Open each step's section with its input and output in one sentence or line. Then say what happens, who decides (see "When the reader acts on decisions"), which tool does the work if a tool does, what the step produces and where the result is kept. How a tool works internally goes on a reference page or in an appendix that each mention of the tool links to. A numbering scheme such as "step 2.4.1" is one more code for the reader to decode, so number steps only inside a section, where the reader follows them in order.

When the steps fall into a few larger groups, each group may open with a short summary that has the same fields in every group: its purpose, what the people and tools do, what people decide, its output and when the work is ready to move on. This does not break habit 5 (tell 6), because each field holds different content and the summary comes once for each group.

The example below shows one step of a process, written in layers for two kinds of reader (see "When the readers need different depth"):

```
Known: the readers are employees and the finance team. The manager's
       check starts from a submitted expense claim and ends with the
       claim approved or returned to the employee. The employee's
       manager checks the receipts and decides. In the finance system,
       the claim is form EX-2, and it waits in the manager's queue for
       up to five days.

Bad:   ## Step 2.3: Approval
       Input: see step 2.2. Form EX-2 waits in the manager's queue for
       up to five days, and then the system escalates it.

Good:  ## Check the claim
       Input: a submitted expense claim. Output: the claim, approved or
       returned to the employee.
       The employee's manager checks the receipts and decides.
       Details (collapsed): in the finance system, the claim is form
       EX-2, and it waits in the manager's queue for up to five days.
```

### When the reader acts on decisions: name who decides

A reader who has to act on a decision, or wait for one, needs to know who makes it. Name the owner at each decision, such as approving a request, a plan, a payment or a release. For a few decisions, a sentence at each decision is enough. For many, also put them in one table with the owner of each, in a place that the steps link to, and still name the owner at each decision in the text.

Take the role names from the source material, from the author or from the reader's own field, such as "budget holder" in a finance policy. When none of them names an owner, mark the gap and ask the author. You may suggest a default role from the reader's field, such as "tech lead" or "release manager" for a software team, and then say once that the roles are defaults that each team maps to its people. Say that one person can hold several roles only when the source material or the author says so.

Name only roles that own a decision or that the source material names. Do not create duties, such as an owner for each document, a champion or an approver for each small step, because the reader takes each role as decided and looks for the person who holds it. Each role is also one more concept to learn, so count the roles in the concept inventory. Describe any other person by what they do, as in "the person who ran the agent".

### When the readers need different depth: write in layers

When some readers need only the main points and others need the detail, such as people who decide and people who do the work, write the main text at the depth of the reader who knows the least or who decides, so that this reader can follow it alone. Put the detail where the other readers can find it: a collapsed details block, an appendix or a reference page. A short note at the opening on how to read the layers is allowed, because it names kinds of content and not groups of readers. The note names the layers, such as "the summary at the top of each part" and "the details under each step", and uses no section codes. The example under "When the document describes a process" shows a step written in two layers.

### When the document proposes options: label each option as an option

A proposal, an options paper or a plan with open choices exists to present what is not decided yet. Its options are its content, so "Decided content only" does not apply to them. Label each option as an option, as in "Option 1: a supplier that delivers every week", and say who decides among the options and by when. If the source material does not say, mark the gap. Describe the rest of the document, such as the current situation, as it is.

## Habits that make text sound machine-written

A tell is a habit of wording or structure that makes readers suspect a text was generated. These six are the tells most common in documents that agents write, most common first. The tell number after each title is its entry in `references/machine-tells.md`, which also says how much one sighting proves and what to keep.

**1. Sayings and mirrored one-liners** (tell 3). Two short balanced clauses read like a motto and explain nothing to a newcomer. If the next sentence already makes the claim, delete the saying. Otherwise replace it with the claim (see "What does this sentence claim?"). To test a sentence, imagine it in a document on another subject, such as another organization or product. If it fits there unchanged, it says nothing specific about this one.

```
Bad:   Tests decide, and reviewers advise. A failing test blocks the
       merge, because it gives the same result every time.

Good:  A failing test blocks the merge, because it gives the same
       result every time. A reviewer's comment does not block it.
```

**2. Contrasts against claims nobody made** (tell 2). The pattern is "not X but Y", the same split over two sentences or a tail such as ", not Y". The rejected half names something nobody said, so that the real claim sounds larger. State the real claim. Keep a contrast that corrects a belief the reader actually holds.

```
Bad:   The deadline is not a suggestion. Claims filed more than 30 days
       after the expense are not paid.
Good:  Claims filed more than 30 days after the expense are not paid.
```

**3. Absolutes used for force** (tell 14). Words such as "never", "every", "always" and "only" claim a scope that nobody checked. Keep them for rules that have no exception, and give the scope of those rules. Elsewhere, replace the absolute with the real scope. A single absolute is normal, so act when they appear in paragraph after paragraph.

```
Known: staff who handle patient records take the privacy course in
       their first week. Other staff take it within three months.

Bad:   Every new employee takes the privacy course in the first week.
Good:  Staff who handle patient records take the privacy course in
       their first week.
```

**4. Announcers** (tell 12). A sentence that only counts or describes what follows delays the point and adds nothing. Start the list or the claim instead. Numbering real steps is fine.

```
Bad:   Two steps come first. Copy settings.example to settings, and
       fill in the name of your database.
Good:  First, copy settings.example to settings, and fill in the name
       of your database.
```

**5. The same point, formula or length throughout** (tell 6). The signs are a point restated in each section, often as a new saying, every section closing on the same kind of line or repeating the same stock phrase, equal length for sections of unequal difficulty and sentences of one length across the whole document. Make each point once (see "Can I trust the page?"), give a hard point, such as a hard decision, more room than a routine one, and let the content set the length of each sentence. Procedures and reference pages may give every entry the same slots, because readers scan them, when each slot holds content that differs from one entry to the next. A slot that reads "None" or "Nobody", or repeats the entry's first sentence, shows that a template set the shape: drop it.

**6. Abstractions doing human work** (tell 18). In "the process decides", the person who decides disappears from the sentence. Put the person back: the role that the source material names, the owner of a decision when the document names one (see "When the reader acts on decisions"), or else a person described by what they do. Ordinary system actions, such as "the pipeline runs the tests", are fine.

```
Known: the charge nurse decides which patients are seen first.

Bad:   Triage determines who is seen first.
Good:  The charge nurse decides who is seen first.
```

### Over-correction

An over-correction is an edit that removes one tell and creates another. Text cleaned by rule tends to come out clipped and uniform, and readers notice that as quickly as the original habits. To avoid it:

- Keep sentences whole. Fragments are normal in lists, table cells and labels. In prose, do not use one as a stand-alone sentence for emphasis.
- Keep a qualifier that carries real uncertainty, a condition or a limit. Cut only stacked hedges and empty intensifiers, because removing every hedge turns careful claims into absolutes.
- Keep a reason that states a concrete consequence. Cut a sentence that only says a point is important.
- Add no personality, opinions, reactions or invented detail. Explanatory prose needs none of them.
- Repeat a term each time it is needed. A synonym swapped in for variety reads as a new term (see "What does this word mean?").
- Use dashes rarely. When you remove one, choose the connection the two clauses really have, such as "because", "so", "and" or two sentences. Swapping every dash for a period is the same habit in a new form, and a text without dashes proves nothing about who wrote it.
- Set no numeric targets for sentence length, list length or word count, because each numeric style target produces a new repeated pattern. If a list has three real items, keep all three.

## Review method

Work through these passes in order, and keep findings separate from fixes.

1. **Reader, type and artifact.** Settle the reader and the type of each section (see Start from the reader), and get the artifact the reader receives (see "Can I trust the page?"). If you have only the source file, say so in the report.
2. **Content pass.** Apply "Decide what the reader needs" to the whole text. List the purposes the document serves, the concepts and terms it asks the reader to learn, the roles and duties it names, any numbering scheme, the undecided items, any passage that describes how a tool works internally and the example blocks. Judge each against what the reader needs, and record what to cut, replace with the reader's words, or move elsewhere. Check that the text invents no role or duty that the source material does not give and, when the reader acts on decisions, that each decision names its owner. For a long document, use the review questions in `references/reader-first.md` here and in the next two passes.
3. **First-read pass.** Read from the top as that reader, and log every question the text leaves open at that point: what is this, who is that, who decides this, why is this here, is this real, which of these do I do. A question the text answers later still counts, because the reader met it unanswered.
4. **Structure pass.** For each section, check that its opening fits its type (see "What is this?"), that an explanation goes from situation to thing to parts to example, that the heading matches the content and that the status is given once. Check each rule under "Rules for some documents" whose condition the document meets: that the main text of a layered document can be followed without its details, that a long document's overview matches its headings in name and order and that the steps of a process are named by their actions and open with their input and output. Then read only the headings and the first sentence of each paragraph, and check that they give the whole argument in order. Last, check that each term, code, abbreviation and product name that the content pass kept, including those in diagrams and tables, is explained where it first appears.
5. **Sentence pass.** Read `references/machine-tells.md`, look for the tells, and apply the Keep part of each entry before you record a finding.
6. **Report** in the format below. Do not rewrite unless asked.

The strongest check for missing context is a reader who has only the document: a colleague, a new session or a helper agent that has not seen your working material. Ask that reader which terms are not explained, what the document assumes they already know and what they would do next. Use one when you can, and say in the report whether you did.

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

A finding belongs under "Content" when the fix is to cut, replace or move a concept, role, detail or section. A finding belongs under "lost" when the reader cannot continue without information that the text does not give at that point, and under "has to work" when the information is there but takes effort to find. Quote the text exactly, and give a location that the person who reads the report could find, such as the heading and paragraph. List each place where the reader is lost. For a habit that recurs, list the clearest cases and count the rest under Patterns.

## Writing and rewriting

**A new document.** Settle the reader (see Start from the reader) and decide what the reader needs. Then draft by the rules, including each rule under "Rules for some documents" whose condition the document meets, and mark each gap as you go (see "Facts stay fixed"). Last, run the first-read pass of the Review method on the draft, and fix what it finds.

**A rewrite** (rewrites only). Start from a list of findings, your own from the review method or someone else's. Rewriting a whole text without one tends to make it sound more generated: the paraphrase keeps the habits and loses details. Fix the content first (what to cut, replace or move), then the structure (section openings, order, headings and status), then the sentences.

**Facts stay fixed.** Keep every quantity, name, condition, negation and level of certainty. Add no fact, number, name, actor or reason that the text under review, the source material or the author does not give. When a fix needs a definition or a fact, look for it in the source material, such as a glossary, notes or other pages. If it is not there, write the simpler sentence and mark the gap. To mark a gap, leave a visible marker such as "[needed: who approves this]", or the marker that the project uses, and list it in your report. The same sentence, rewritten with the facts it needs and without them:

```
Known: there are three steps. First an engineer watches every agent
       session. Then agents run in the pipeline with read-only access.
       Last, agents may push branches by themselves.

Bad:   Autonomy expands in stages (R7).

Good:  Agents start under supervision and get more independence in
       three steps.
       1. At first, an engineer watches every agent session.
       2. Next, agents may run in the pipeline with read-only access.
       3. Later, agents may push branches by themselves.

Known: the sentence is about the coding agents' independence. The
       source material does not say what the stages are.

Bad:   Autonomy expands in stages (R7).

Good:  Coding agents get more independence in stages. [needed: what
       the stages are]
```

**Length follows the reader.** Cut scope before you add definitions: apply the concept inventory first (see "Decide what the reader needs"), then add the context, definition or step that the reader lacks for what remains. The text grows where it compressed what the reader needs, and shrinks where it repeated itself or carried what the reader does not need. If a rewrite grows mostly through definitions or detail the reader could do without, apply the concept inventory again. To test a sentence, delete it: if the reader loses no information, leave it deleted.

**Voice.** Plans and proposals read naturally when they use "we" for what the team will do and keep a person in the sentence wherever someone approves or decides, as in "When a change is made, we give it a tier" or "We will run scans and checks; the tools already exist." Say who "we" is before its first use, because in a document that one organization writes for another, "we" can mean either side. Do not impose this voice on reference material or on a project that has its own rule for voice. In a rewrite, keep the choice of "we" or "you" that the text under review made.

**Check the result.** Run the first-read pass on your own text, or give it to a reader who has not seen your working material (see Review method). Then look again for the tells that most often survive a rewrite: contrasts, closing one-liners, sayings and lists of three. Check also that no fact was dropped, and no role or concept added, while the shape changed.

**Two passes** (rewrites only). Make one rewrite and at most one corrective pass, then report what changed and what is still open. A text with no justified finding stays as it is.
