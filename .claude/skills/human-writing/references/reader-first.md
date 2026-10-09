# Rules for a reader who lacks your context: details and techniques

This file adds to `SKILL.md`: rules that apply less often, more Bad and Good pairs, the questions to ask during a review, and techniques for reading a text the way its reader will. Its sections use the titles and the order of `SKILL.md`, and each one adds detail to the rule or section of the same title there. Where a pair has a Known line, the Good version uses only what its Bad version or its Known line states.

## Decide what the reader needs

- **Signs of too many concepts.** Look for a glossary that the body depends on, categories coined with letters or numbers, a role or a duty for each step and a numbering scheme with several levels. Each of them asks the reader to learn something before they can follow the text.
- **Where each purpose goes.** A process description says what happens and in what order. Instructions say what the reader does. A project plan holds the dates, the schedule and the staffing. A case for change holds the reasons and the expected benefits. A status report says what is done and what is late, and a research report says what was found and how. A proposal holds the options and says who decides among them. Planned work goes in one place.
- **The reader's own categories.** When the reader's organization already has words for a set of categories, use them, even when a coined set looks tidier. A reader who meets a coined category has to learn it and then translate it back into the words used at work.
- **Obvious statements.** A sentence that the reader would accept without reading it, such as "careful reviews improve quality", costs reading time and changes nothing the reader does. Delete it.

Coined categories replaced with the ones the reader uses:

```
Known: the clinic sorts visits into first visits, follow-up visits and
       urgent visits, and each kind of visit has its own form.

Bad:   Each visit gets a code. Code V1 is a first appointment, V2 a
       return appointment and V3 an unplanned one. A V2 visit uses
       form 2.

Good:  Each kind of visit has its own form: one for first visits, one
       for follow-up visits and one for urgent visits.
```

## "What is this?"

- **Main point first.** Put the main point first in the page, in each section and in each paragraph. Many readers stop after the first lines, and the main point should reach them.
- **General before specific.** State the rule before its exceptions, and in instructions state the condition before the action, as in "If the check fails, open the log." A reader who meets an exception first has to read the passage again after reaching the rule.
- **Known before new.** Start a sentence with what the reader already has, and end it with the new point. Explain a prerequisite idea before the ideas that depend on it. The familiar part links each sentence to the one before it.
- **One purpose for each unit.** Give a paragraph one idea, and a section one purpose and one level of detail. In a procedure, say why the reader does a task before giving its steps. A unit that mixes purposes hides its point.
- **Sections that stand alone.** Many readers arrive at a section from a search or a link. Give each section a title and a first paragraph that provide the context it needs, and link to any earlier section that it depends on.
- **Tables for lookup.** Use a table so that the reader can look something up, and keep its cells short. When a cell needs more than a sentence or two, move its content to prose and keep the short answer in the table.

An explanation in the order a newcomer needs, with a literal word where a figurative one stood:

```
Bad:   The standard route is lean. Each change gets a tier, its risk
       level: tier 1 is small and bounded, tier 2 is a feature in an
       existing service, and tier 3 is new or cross-service. A tier 1
       change goes from story to plan to merge request.

Good:  Every change gets a tier that says how risky it is.
       - Tier 1 is a small change with clear limits.
       - Tier 2 is a feature in a service that already exists.
       - Tier 3 is a new service, or a change that touches several.
       A tier 1 change takes the standard route, which is also the
       simplest: a story, then a plan, then a merge request.
```

## "What does this word mean?"

- **Everyday words.** Use the everyday word, and keep a technical term only when the reader needs it, with a definition at first use. Readers complain about jargon more than about any other fault, and specialists also prefer plain words. Do not define a field's basic terms for readers who work in that field, because the definitions suggest that the text was not written for them.
- **No private meanings.** Do not give an ordinary word a special meaning, and do not coin new terms. If you have to, define the term at its first use, because readers forget a special meaning and fall back on the ordinary one.
- **When a project requires abbreviations.** Spell each one out at its first use on each page, and again in each section of a long document, because readers arrive at sections directly. Do not create an abbreviation for a term that appears only a few times. Do not expand one that the reader uses daily, such as API or URL, because spelling it out irritates that reader.
- **Shorthand.** Write "for example" and "that is" in place of the Latin abbreviations "e.g." and "i.e.", and avoid planning shorthand such as "TBD" and acronyms made from product names. Few readers know them, and second-language readers know them least.
- **Small words and clear pronouns.** Keep words such as "that", "the" and "then", and repeat a noun when a pronoun could point to two things. Second-language readers and translation tools depend on these words.
- **Literal phrasing.** Avoid idioms, phrasal verbs such as "carry out" or "find out", and references that depend on one culture, in headings as well as in text. Second-language readers and translation tools read them word by word.
- **A term list for long documents.** Keep a list of each concept and its one approved name, and check each draft against it. An agent that works on a document for hours tends to coin a second name for something that already has one, and then uses both names without connecting them.

A term defined in a sentence of its own, from words the reader knows:

```
Known: a hotfix is a small, urgent fix that is released on its own,
       without waiting for the next planned release.

Bad:   A hotfix, a change outside the release train, goes straight to
       production.

Good:  A hotfix is a small, urgent fix that is released on its own,
       without waiting for the next planned release. A hotfix goes
       straight to production.
```

A tool described by what it does, with its name as detail for the readers who need it:

```
Known: Bandit and Gitleaks are security scanners. Bandit checks Python
       code for insecure patterns, and Gitleaks looks for passwords
       and keys that were committed by mistake. Both exist today.

Bad:   On every commit the pipeline runs Bandit and Gitleaks.

Good:  On every commit the pipeline runs two security scans. One
       checks the Python code for insecure patterns, and one looks
       for passwords and keys that were committed by mistake. The
       tools already exist: Bandit and Gitleaks.
```

## "What does this sentence claim?"

- **Required, optional or possible.** Word each statement so that it reads as required ("must"), optional ("can"), possible ("might") or plain fact. "Should" leaves the reader unsure whether a step is required.
- **Actor as subject, action as verb.** Write "The manager approves the claim" where the text said "Approval of the claim is performed by the manager." Abstract nouns and passives hide who has to act.
- **Sentences that have a verb.** A string of nouns, or a fragment with no verb, has to be decoded before it can be understood. Rewrite it as a sentence with a subject and a verb.

A statement whose force is unclear, fixed from the source material:

```
Known: a second signature is required for every payment over 5,000
       euros.

Bad:   Payments over 5,000 euros should have a second signature.
Good:  Every payment over 5,000 euros must have a second signature.
```

## "Why is this here?"

- **Navigation by role.** When a document needs routing by role, put it in the navigation, such as a contents page with links by task, and keep it out of the opening of the content. Routing by task works better than routing by audience, because readers often cannot place themselves in a list of roles, and role labels often come from internal jargon.

## "Is this real?"

- **One running example.** When a document walks through a process or a scenario, use one invented scenario for the whole document, such as a new receptionist's first week at a clinic. Introduce it once, near the start, and say that it is invented. A reader who arrives at a section from a link has not met the scenario and takes its details as real, so name it there in a few words. Other documents, such as reports and reference pages, may use several examples, or real cases that the source material gives.
- **Few example blocks.** Add an example block only where the shape of a result is not obvious from the text, such as the layout of a form. When every step has a block, the reader learns to skip them. Where the format allows, collapse a long example, so that a reader who knows the shape can pass it.
- **What a step produces.** Where the text describes steps, show an excerpt of what a step produces, such as a form, a schedule or a ticket. A log of a tool run shows how the tool worked, which belongs on the tool's reference page, and its hashes, timings and counts look like real data.
- **Values in examples.** Explain each specific value in an example, such as a date, an identifier or a duration, or replace it with a placeholder that is clearly not real, such as `<incident number>`. Unexplained values look like real data.

An example that shows what a step produces, taken from the running example:

```
Known: the running example is an invented new receptionist. The step
       "Prepare the first week" produces a schedule for the new
       employee. For the receptionist, it lists a badge and a tour on
       Monday, the privacy course on Tuesday and shifts with a buddy
       from Wednesday to Friday.

Bad:   Example output:
       [HR system] account created 09:14
       [HR system] badge 4471 issued, 3 courses assigned
       [HR system] finished in 6 minutes

Good:  For example, the first-week schedule for the new receptionist
       reads: "Monday: badge and tour. Tuesday: privacy course.
       Wednesday to Friday: shifts with your buddy."
```

## "Does this exist yet?"

- **Planned work in one place.** Keep one page or section for planned work, and list each planned item there with what will change when it exists. Elsewhere, describe what exists, and link to a planned item only where the reader needs to know that it is coming.
- **Undecided sections.** When most of a section is undecided, do not fill it with options or proposals that look like decisions. List the open questions for the author, and write the section when the answers exist. A document that proposes options is the exception (see "When the document proposes options").
- **Words that go stale.** Avoid "new", "now", "currently" and "soon", which become wrong without anyone editing them. When timing matters, give a date.
- **Partial coverage.** If a section covers its subject only in part, say so at its top. Leave no empty headings.

## "Can I trust the page?"

- **Headings with explained terms.** A heading uses the reader's words and no term that the page has not explained yet.
- **One version across documents.** Keep terms and formatting the same across the page and its companion documents. When two documents describe the same thing in different ways, readers suspect that neither is current.
- **Leftovers from publishing tools.** Documentation generators often add a symbol such as "¶" as the visible link of each heading's anchor, and it shows up when the page is copied, printed or converted. Raw markup, template placeholders and broken links are other leftovers. Check a copy in the format that the reader uses.

## Rules for some documents

### When the document is long

- **An overview that matches the sections.** Give each part of the overview, such as a box of a diagram or an item of a list, a section with the same name, in the same order. A reader who sees a name in the overview looks for a heading with that name, and a renamed or reordered section sends them searching.
- **Few cross-references.** A section that needs many references to other sections cannot be read alone. Move the fact the reader needs into the section, or merge the sections.

### When the document describes a process

- **Three levels of detail.** The overview shows the steps and how work flows between them, with no tool names and no roles. Each step has a section that says what happens, who decides, which tool does the work if a tool does, what it produces and where the result is kept. Each tool has a reference page that says how it works, such as its internal steps, its modes and its limits, and every mention of the tool in a step's section links to that page.
- **The home page of a process document.** It describes the process only: a sentence that says what the process is, the overview, the steps with the input and output of each and, where it helps, a table that shows which steps each kind of work goes through.

An overview of a process with no tool names or roles, in which each step is named by its action and states its output:

```
Known: clinic intake has four steps. Reception checks the patient in,
       and the patient is registered. A nurse assesses how urgent the
       visit is, and the patient gets an urgency level. A doctor sees
       the patient and writes a treatment plan. Reception books any
       follow-up visit. A reference page describes the booking system.

Bad:   1. Reception (receptionist; booking system): check-in, ID,
          insurance, form A
       2. Triage (nurse; urgency scale): see 2.1 to 2.6
       3. Consultation (doctor)
       4. Discharge (receptionist; booking system)

Good:  1. Check the patient in. Output: the patient is registered.
       2. Assess urgency. Output: the patient has an urgency level.
       3. See the doctor. Output: a treatment plan.
       4. Book the follow-up. Output: a follow-up visit, if one is needed.
```

### When the reader acts on decisions

- **What each role holds.** What a role holds matters more than how often it appears: a decision that the reader needs to know about, or a duty that nobody decided. A document that gives many roles invented duties is hard to follow, and a document that names no one leaves the reader unable to tell who makes each decision. Add the decisions and their owners, and add no other duties.
- **One place for many decisions.** When the document has many decisions, put the table of decisions, with what each role decides, in one place of its own, such as a page or a section that the steps link to.

Decision owners in one table, and named again at each decision:

```
Known: the employee's manager approves travel before it is booked and
       approves expenses up to 500 euros. The budget holder approves
       larger expenses. The finance director approves any exception to
       the policy, and the finance team approves each payment.

Bad:   Travel and expenses are approved, exceptions need approval and
       the payment goes out once it is signed off.

Good:  Decision                              Owner
       Approve travel before it is booked    The employee's manager
       Approve an expense up to 500 euros    The employee's manager
       Approve an expense over 500 euros     The budget holder
       Approve an exception to the policy    The finance director
       Approve the payment                   The finance team

       At the decision itself: "The budget holder approves the
       expense."
```

### When the readers need different depth

- **What each layer holds.** For readers who decide, the main text gives the outcome, who decides and the evidence the decision needs. Tool names, commands, file paths and configuration go into the detail layer. A reader who decides should be able to follow the main text with every details block closed.

### When the document proposes options

- **Options beside decided content.** In a document that also describes what is decided, keep the options in their own section, so that the reader can tell which statements are decided. Where the source material gives them, give each option the same kinds of information, such as what it changes and what it costs, so that the reader can compare the options.

## Review questions

Ask these while you read as the reader. A question that the text leaves open at the point where the reader meets it is a finding. Skip a group whose condition the document does not meet.

For the page:

- What is this page, and what does the reader get from it? Does the first paragraph say so?
- What will the reader do or decide after reading, and does the page give them what they need for it?
- Which purpose does the page serve (see "Where each purpose goes")? If it serves more than one, which parts belong in another document or a separate section?
- Which concepts, categories, roles, numbering schemes and named things does the page ask the reader to learn? Does the reader need each one to understand or to act, and could the reader's own words replace it?
- Does each role that the page names come from the source material or the author? Is any duty one that nobody decided?
- Where are the planned and undecided items? Are they in one place, and does the rest of the page describe only what is decided?

For a long document:

- Is there an overview before the parts, in a form that fits the document?
- Does each part of the overview have a section with the same name, in the same order?
- Does the page refer to other parts by name, and can each section be read without many cross-references?

For a process:

- Does the overview show the steps without tool names or roles?
- Is each step named with an action phrase, with the state it leads to in its output line or on the diagram arrow? Do the states give their plain meaning instead of the tool's event name?
- Does each section open with its input and output, and say which tool does the work if any, what it produces and where the result is kept? Does it link to the tool's reference page for how the tool works?

When the reader acts on decisions:

- Does each decision name its owner at the point where the reader meets it?
- Do the role names come from the source material, the author or the reader's own field?

When the readers need different depth:

- Can the main text be followed without the details?

For a document that proposes options:

- Is each option labeled as an option, and does the page say who decides and by when?

For each section:

- What is the section about, in one short phrase? If that is hard to say, the section probably mixes purposes.
- Does the opening fit the type of the section, and does the heading say what the section contains?
- Can a reader who arrives here from a link follow the section without the earlier ones?
- Does the reader know whether the thing exists, is planned or is unfinished?
- Does the section get space in proportion to how hard its subject is?

For each paragraph:

- What is it about, why does it matter and how does the reader use it?
- If a sentence were deleted, would the reader lose information?

For each term, code, abbreviation and name:

- Does this reader know it? If not, is it explained where it first appears, in a sentence of its own?
- Does it keep one meaning on the page, and is the same thing always called by the same name?

For each example:

- Is it labeled as an example, and does it come after the general case?
- Does each date, number and identifier in it mean something to the reader?
- Does the reader need this block, or is the shape of the result clear from the text?
- If it illustrates a step, does it show what the step produces or a log of a tool run? When the document has a running example, does the example come from it?

For each table:

- Does the reader use it to look something up, and are its cells short? Which cells need to become prose?

For each claim:

- Who does what, to what and under which condition?
- Is it required, optional, possible or a plain fact?
- Would a reader in a second language, reading word by word, get the right meaning?

## Review techniques

These add to the passes in the Review method of `SKILL.md`.

- **Read as each kind of reader.** Write down the reader's role, goal and what they already know, then read the whole text as that person and note each question they would ask. If the text has several kinds of reader, read it once as each, because a single imagined reader can make you narrow the document to that one person.
- **Write a reverse outline.** Write the main idea of each paragraph as a short phrase. A paragraph whose idea does not fit a short phrase probably needs revision, and a column of near-identical phrases shows a repeated formula.
- **Put the concept inventory in order.** List the items of the concept inventory in the order in which they first appear, in diagrams and tables as well as in the text, including capitalized terms, letter-and-digit codes, abbreviations and product names. Note where each one is explained. A term that stays and is explained after its first use, or never, is a finding. Treat any abbreviation, and any term that a reviewer asks about, as possible jargon. In a rewrite, compare the inventories of the text under review and the result: a longer list means that the rewrite added concepts.
- **Read each section alone.** Read each section as if you arrived from a search or a link, and check it against "Sections that stand alone" above.
- **Separate the types.** Ask of each section whether it helps the reader do something or understand something. A section that tries to do both mixes a procedure with an explanation, and should be split. Then note the purpose each section serves. Sections with different purposes belong in different documents or clearly separated sections.
- **Ask for a paraphrase.** When you test the text with a reader who has only the document (see Review method in `SKILL.md`), ask them to say in their own words what each section means. Readers often call a text clear and still misread a key term. Compare the paraphrase with what the text was meant to say.
