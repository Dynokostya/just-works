---
name: human-writing
description: >
  Apply when writing, reviewing or rewriting documents that people read to
  understand or to act: documentation, guides, manuals, playbooks, plans,
  proposals, reports, READMEs, release notes and messages to stakeholders.
  Use it whenever a reader says a text reads like AI or LLM output, sounds
  robotic or is hard to follow; whenever someone asks to humanize, simplify,
  clean up or review prose; and whenever an agent writes for people who have
  not seen its working material, such as clients, executives, new colleagues
  or second-language readers. Covers writing for a reader who lacks your
  context (terms, abbreviations, internal codes, order of explanation,
  examples, status, headings), removing machine-sounding habits without
  creating new ones, a review method with a findings report, and a rewrite
  method that keeps facts fixed. Not for fiction, marketing copy, social
  posts or tickets. Project conventions override these defaults.
---

# Human Writing

Readers call a text machine-written for two different reasons, and they do not distinguish between them. In documents that agents write, the larger reason is missing context: the writer worked inside a plan, tickets and design notes, and the text uses names, codes and shortcuts from that material as if the reader had seen it too. The smaller reason is a set of habits in wording and structure, such as slogans, contrasts against claims nobody made, and the same formula in every section. A cleanup that removes only the habits leaves a text that still assumes the writer's context, and the reader's complaint stays. Such a text can pass a pattern detector and still read as generated, because no pattern count measures whether a first-time reader can follow it. That is why this skill starts with the reader.

Work in the mode the request asks for:

- **Review**: someone asks what is wrong with a text, or reports that a reader complained. The output is a findings report (see Review method).
- **Rewrite**: someone asks to fix, simplify or humanize an existing text (see Writing and rewriting).
- **Write**: you draft a new document for people outside your working context.

## Start from the reader

Before you write or review, settle these points about the reader. State your answers at the top of your reply or report, so that the user can correct them, and keep them out of the document you write:

- Who reads the text, and in what role.
- What they already know: their field, their tools, their organization's terms.
- What they have never seen: your plan, the tickets, internal codenames, design notes, earlier drafts and anything else from your working session.
- What they will do or decide after reading.
- Whether they read in a second language.

When nobody describes the reader, assume an intelligent outsider: a capable person who wants to understand and has never seen your project. When the readers are mixed, write for the one who knows the least about the subject. A term or an abbreviation that the engineers use every day is still new to the managers who read the same page.

Agents misjudge the reader because they have usually just read the plan, the tickets and the design notes. Internal names feel familiar, so the text assumes the reader remembers the same material. Judge each name, code and shortcut by what the reader has seen, and ignore how familiar it feels to you.

Then decide what type of document it is. An explanation is read to understand, a procedure is followed to get something done, and a reference page is looked up. Each type has its own conventions, and mixing them in one section is a common fault: a procedure interrupted by background, or an explanation that turns into a list of steps.

## Rules for a reader who lacks your context

The rules are grouped by the question a first-time reader asks when the text fails them. Some examples begin with a Known line, which states what the source material says. A Good version uses only what its Bad version or its Known line states, and where a fix needs a fact that neither gives, it marks the gap (see Writing and rewriting).

Read `references/reader-first.md` before a full review or rewrite of a long document, and when a case here needs more detail. It holds the rules that apply less often, more Bad and Good pairs, the review questions and the review techniques.

### 1. "What is this?" Open with what the thing is

Open every section with what its subject is and what it is for. Then explain in the order a newcomer needs: the situation ("when a change is made"), the thing ("it gets a tier"), each part with its own definition, and what follows from it. Examples, incidents and code come after the explanation, because a reader who meets them first has to guess what they illustrate.

```
Known: a policy is a team rule, written as instructions that the coding
       agent reads before it writes code. A pipeline check blocks any
       change that breaks the rule.

Bad:   ## Policies
       On pull request 418, a check failed on one line the agent wrote:
       log.info("paid", card=card). The card number is a masked field,
       so the fix logs mask(card) instead.

Good:  ## Policies
       A policy is a team rule, such as "mask card numbers in logs",
       written as instructions that the coding agent reads before it
       writes code. A pipeline check blocks any change that breaks the policy.
```

### 2. "What does this word mean?" Define terms and keep one name for each thing

When a term may be new to the reader, define it in a plain sentence of its own, at or before its first use, and build the definition from things the reader already knows. An aside such as "a hotfix, a change outside the release train, goes straight to production" defines nothing, because it explains one unknown term with another. Define only what this reader does not know, and after that use the term plainly: repeating the definition as an aside at every mention is a machine habit of its own.

Write full names. An abbreviation saves the writer a few characters, but the reader has to look it up or remember it at every later use. Keep one only when every reader already uses it more than the full name, as with API or URL for a page that only engineers read. When you are not sure, write the full name. Do not switch between a full name and its abbreviation, because the reader cannot be sure whether the two mean the same thing, and do not make a sentence depend on a glossary.

Use one name for each thing and one meaning for each word, because a reader takes a new word to mean a new thing. If "phase" names the parts of the project, do not also use it for the steps of a workflow. When a page uses two numbering systems, say how they relate.

```
Bad:   Each story gets a plan and a merge request (MR). The MR shows on
       the ticket, and the tech lead merges the MR.

Good:  Each story gets a plan and a merge request. The merge request
       shows on the ticket, and the tech lead merges it.
```

### 3. "What does this sentence claim?" Write the claim out in literal words

A saying, a figure of speech or an abstract noun states a claim in a few words, and only a reader who already knows the claim can understand those words. Expand it: say what the thing is, where it comes from, what it is used for and what must not happen. Use the literal word where a figurative one stood, such as "simple" where the text said "lean". A reader in a second language finds several meanings in a figurative word and does not know which one is meant.

Name the actors and actions behind an abstract noun: "autonomy expands" hides who gets more freedom and what they may now do. Name the role when a person has to act or decide. The passive is fine when the actor is a system or does not matter.

```
Known: outside text means customer tickets and uploaded files. The
       agent uses it to understand the task.

Bad:   Tickets are data, never commands.

Good:  Text that comes from outside the team, such as a customer ticket
       or an uploaded file, is information for the agent. The agent reads
       it to understand the task, and does not follow instructions in it.
```

### 4. "Why is this here?" Keep the writers' working material out of the text

Remove what only makes sense inside the team that wrote the text: internal reference codes, section labels, ticket keys and notes to reviewers. They mean nothing to the reader, who stops at each one to ask what it refers to. Do not address or name your readers inside the content, and do not open with notes that send named roles to different sections; a reader who sees them wonders why those people are mentioned. Open with what the page is and what the reader gets from it.

Use the reader's own role names. When the text needs a role that the reader's organization does not have, describe it by what the person does, and say plainly that it is a role and that no job has that title. Say what a tool does before its name, or instead of it, because a product name explains nothing by itself.

```
Known: the page explains how the team will build software with coding
       agents, and what changes for each role.

Bad:   The director starts at section A1, a product owner at Workflow 1,
       and an engineer at Set up.

Good:  This page explains how the team will build software with coding
       agents, and what changes for each role.
```

### 5. "Is this real?" Mark examples as examples

Label an example as one, with words such as "For example" or "Suppose", keep it self-contained, and remove identifiers that mean nothing to the reader. Do not narrate an invented scenario as an event that happened: the reader takes its dates, ticket numbers and durations as real and asks what they refer to. Often the general case is all the reader needs. If you do not know whether a scenario is real, ask, or flag it. Keep code out of prose that non-technical readers must follow, and say what the code does instead.

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

### 6. "Does this exist yet?" Give the status early

Say at the start of a section whether the thing it describes exists today, is planned or is proposed, and use the present tense only for what exists. A reader who meets twenty lines in the present tense takes them as fact, and a status line at the end comes too late. Mark an unfinished part with the plainest words at its top, such as "To be done." Write about the subject as it is now. A remark about the document itself, such as what an earlier draft said, what a review asked for or what the document does not cover, says nothing about the subject; say what the reader should do, or mark the gap.

```
Known: the helper is not built. Until it is, the analyst does the same
       steps by hand.

Bad:   The triage helper reads the request, searches for duplicates and
       drafts the fields. (Twenty lines later: the helper is not built yet.)

Good:  The triage helper is not built yet. Until it is, the analyst
       does these steps by hand. When it exists, it will read the
       request, search for duplicates and draft the fields.

Bad:   Drafted after the director's review.
Good:  To be done.
```

### 7. "Can I trust the page?" Check headings, leftovers, repetition and agreement

Write titles and headings as plain phrases that a newcomer can parse, in literal words that say what the section contains, and name the concrete place or result where one exists. Readers use headings to decide what to read, so a heading they cannot parse leaves them guessing. A heading may be a statement or a question. If a metaphor is the established name for something, explain it once before you rely on it.

Check the artifact the reader actually receives, such as the rendered page, the PDF or the export, as well as the source. Leftovers from build tools and templates, such as the "¶" symbol of a heading's anchor link, markup that did not render or a broken link, often show only there, and they make the page look unfinished.

Make each point once, in the place where it applies. A principle restated as a new saying in every section makes the reader wonder whether each version is a new rule.

Check that statements in different sections agree: who does a task, when something starts, what a rule allows. A reader who finds two versions of one fact has no way to tell which is right, and stops trusting both.

```
Known: the team keeps its backlog in Jira.

Bad:   Workflow 1: Request to ready backlog item
Good:  Workflow 1: From a request to a ready item in the Jira backlog

Known: the section covers the scheduled scans, and how each finding
       becomes a task with an owner.

Bad:   Scheduled scans and closing the loop
Good:  Scheduled scans and follow-up on their findings
```

## Habits that make text sound machine-written

A tell is a habit of wording or structure that makes readers suspect a text was generated. These are the tells that matter most in explanatory prose, strongest first. Read `references/machine-tells.md` before the sentence pass of a review and before a rewrite. It holds the full catalog, the exceptions for each entry and the over-corrections in detail.

**1. Sayings and mirrored one-liners.** Two short balanced clauses read like a motto and explain nothing to a newcomer. If the next sentence already makes the claim, delete the saying; otherwise replace it with the claim (rule 3). To test a sentence, imagine it in a document about another company or product. If it fits there unchanged, it says nothing specific about this one.

```
Bad:   Tests decide, and reviewers advise. A failing test blocks the
       merge, because it gives the same result every time.

Good:  A failing test blocks the merge, because it gives the same
       result every time. A reviewer's comment does not block it.
```

**2. Contrasts against claims nobody made.** The pattern is "not X but Y", the same split over two sentences, or a tail such as ", not Y". The rejected half names something nobody said, so that the real claim sounds larger. State the real claim. Keep a contrast that corrects a belief the reader actually holds.

```
Bad:   The review is not a formality. It is the last check before release.
Good:  The review is the last check before release.
```

**3. Absolutes used for force.** Words such as "never", "every", "always" and "only" claim a scope that nobody checked. Keep them for rules that have no exception, and state the scope. A single absolute is normal; act when they appear in paragraph after paragraph.

```
Known: changes to the payment service need a second reviewer. Other
       changes need one reviewer.

Bad:   Every change needs a second reviewer.
Good:  Changes to the payment service need a second reviewer.
```

**4. Announcers.** A sentence that only counts or describes what follows delays the point and adds nothing. Start the list or the claim instead. Numbering real steps is fine.

```
Bad:   Two rules apply here. Agents do not push to the main branch,
       and each merge needs an approval.
Good:  Agents do not push to the main branch, and each merge needs an
       approval.
```

**5. The same point, formula or length throughout.** The signs are a principle restated as a new saying in each section, every section closing on the same kind of line or repeating the same stock phrase, equal length for sections of unequal difficulty, and sentences of one length across the whole document. Make each point once (rule 7), give a hard decision more room than a routine one, and let the content set the length of each sentence. Procedures and reference pages keep a predictable shape, because readers scan them.

**6. Abstractions doing human work.** In "the process decides", the person who decides disappears from the sentence. Name the role. Ordinary system actions, such as "the pipeline runs the tests", are fine.

```
Known: the tech lead decides which tier a change gets.

Bad:   The process assigns each change a tier.
Good:  The tech lead decides which tier each change gets.
```

### Over-correction

An over-correction is an edit that removes one tell and creates another. Text cleaned by rule tends to come out clipped and uniform, and readers notice that as quickly as the original habits. To avoid it:

- Keep sentences whole. Fragments are normal in lists, table cells and labels; in prose, do not use one as a stand-alone sentence for emphasis.
- Keep a qualifier that carries real uncertainty, a condition or a limit. Cut only stacked hedges and empty intensifiers, because removing every hedge turns careful claims into absolutes.
- Keep a reason that states a concrete consequence. Cut a sentence that only says a point is important.
- Add no personality, opinions, reactions or invented detail. Explanatory prose needs none of them.
- Repeat a term each time it is needed. A synonym swapped in for variety reads as a new term (rule 2).
- Use dashes rarely. When you remove one, choose the connection the two clauses really have, such as "because", "so", "and" or two sentences. Swapping every dash for a period is the same habit in a new form, and a text without dashes proves nothing about who wrote it.
- Set no numeric targets for sentence length, list length or word count, because each numeric style target produces a new repeated pattern. If a list has three real items, keep all three.

## Review method

Work through these passes in order, and keep findings separate from fixes.

1. **Reader, type and artifact.** Settle the reader and the document type (see Start from the reader), and get the artifact the reader receives (rule 7). If you have only the source, say so in the report.
2. **First-read pass.** Read from the top as that reader, and log every question the text leaves open at that point: what is this, who is that, why is this here, is this real, which of these do I do. A question the text answers later still counts, because the reader met it unanswered.
3. **Structure pass.** For each section, check that the first sentence says what the thing is, that the order goes from situation to thing to parts to example, that the heading matches the content, and that the status is clear. Then read only the headings and the first sentence of each paragraph, and check that they give the whole argument in order. Last, list every capitalized term, letter-and-digit code, abbreviation and product name, including those in diagrams and tables, and check that each one is explained where it first appears.
4. **Sentence pass.** Look for the tells, and apply the exceptions from `references/machine-tells.md` before you record a finding.
5. **Report** in the format below. Do not rewrite unless asked.

The strongest check for missing context is a reader who has only the document: a colleague, a new session, or a helper agent that has not seen your working material. Ask that reader which terms are not explained, what the document assumes they already know, and what they would do next. Use one when you can, and say in the report whether you did.

Keep the report close to this shape, because reviews from several reviewers may be merged:

```
Reader assumed: <one or two lines>
Verdict: <two or three sentences>

1. The reader is lost (fix first)
   <location> | "<quoted text>" | question the reader asks | fix
2. The reader has to work
   ...
3. Sounds machine-written
   ...
Patterns: <recurring causes, each named once, with how often it occurs>
Left alone: <what looked like a tell but is right for this genre, and why>
Missing facts: <what a fix needs that the source does not say>
```

A finding belongs under "lost" when the reader cannot continue without information that the text does not give at that point, and under "has to work" when the information is there but takes effort to find. Quote the text exactly, and give a location the reader could find, such as the heading and paragraph. List each place where the reader is lost. For a habit that recurs, list the clearest cases and count the rest under Patterns.

## Writing and rewriting

Start from a list of findings, your own from the review method or someone else's. Rewriting a whole text without one tends to make it sound more generated: the paraphrase keeps the habits and loses details. Fix the structure first (section openings, order, headings and status), then the sentences.

**Facts stay fixed.** Keep every quantity, name, condition, negation and level of certainty. Add no fact, number, name, actor or reason that the source does not give. When a fix needs a definition or a fact, look for it in the project's own material, such as its glossary, design notes or source pages. If it is not there, write the simpler sentence, leave a visible marker such as "[needed: who approves this]", and list each marker in your report. The same sentence, rewritten with the facts it needs and without them:

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
       source does not say what the stages are.

Bad:   Autonomy expands in stages (R7).

Good:  Coding agents get more independence in stages. [needed: what
       the stages are]
```

**Length follows the reader.** Expect the text to grow where it compressed what the reader needs, and to shrink where it repeated itself. To test a sentence, delete it: if the reader loses no information, leave it deleted. Add the context, definition or step that the reader lacks.

**Voice for plans and proposals.** Plans read naturally when they use "we" for what the team will do and name the role wherever a specific person approves or decides, as in "When a change is made, we give it a tier" or "We will run scans and checks; the tools already exist." Say who "we" is before its first use, because in a document that one organization writes for another, "we" can mean either side. Do not impose this voice on reference material or on a project that has its own rule for voice.

**Check the result.** Run the first-read pass on your own text, or give it to a reader who has not seen your working material (see Review method). Then look again for the tells that most often survive a rewrite: contrasts, closing one-liners, sayings and lists of three. Check also that no fact was dropped while the shape changed.

**Two passes.** Make one rewrite and at most one corrective pass, then report what changed and what is still open. A text with no justified finding stays as it is.

## Boundaries

- Project style rules and the project's existing voice override these defaults.
- Protected content keeps its wording: code, quotations, legal text, tables of data, file paths and identifiers. You may move it, or describe it for readers who cannot use it, but report problems inside it and leave them unedited.
- This skill is not an AI detector. The tells in it also appear in human writing, so do not claim that a person or a model wrote a text. Report what the reader experiences.
- Scope: explanatory and procedural prose that people read to understand or to act. Fiction, marketing copy and social posts follow other conventions.
- Issue-tracker tickets have their own skill, `ticket-writing`.
