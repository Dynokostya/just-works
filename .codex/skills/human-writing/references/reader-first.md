# Rules for a reader who lacks your context: details and techniques

This file extends the seven rules in `SKILL.md` and does not repeat them. It adds the rules that apply less often, the Bad and Good pairs that did not fit in `SKILL.md`, the questions to ask during a review, and the techniques for reading a text the way its reader will. The sections follow the same reader questions as `SKILL.md`. In each pair, a Known line states what the source material says, and the Good version uses nothing else.

## "What is this?"

These rules extend rule 1.

- **Main point first.** Put the main point first in the page, in each section and in each paragraph. Many readers stop after the first lines, and the main point should reach them.
- **General before specific.** State the rule before its exceptions, and in instructions state the condition before the action, as in "If the check fails, open the log." A reader who meets an exception first has to read the passage again after reaching the rule.
- **Known before new.** Start a sentence with what the reader already has, and end it with the new point. Explain a prerequisite idea before the ideas that depend on it. The familiar part links each sentence to the one before it.
- **One job for each unit.** Give a paragraph one idea, and a section one purpose and one level of detail. In a procedure, say why the reader does a task before giving its steps. A unit that mixes purposes hides its point.
- **Sections that stand alone.** Many readers arrive at a section from a search or a link. Give each section a title and a first paragraph that provide the context it needs, and link to any earlier section that it depends on.

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

These rules extend rule 2.

- **Everyday words.** Use the everyday word, and keep a technical term only when the reader needs it, with a definition at first use. Readers complain about jargon more than about any other fault, and specialists also prefer plain words. Do not define a field's basic terms for readers who work in that field, because the definitions suggest that the text was not written for them.
- **No private meanings.** Do not give an ordinary word a special meaning, and do not coin new terms. If you have to, define the term where it is used, because readers forget a special meaning and fall back on the ordinary one.
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

## "What does this sentence claim?"

These rules extend rule 3.

- **Required, optional or possible.** Mark each statement as required ("must"), optional ("can"), possible ("might") or plain fact. "Should" leaves the reader unsure whether a step is required.
- **Actor as subject, action as verb.** Write "The tech lead reviews the plan" where the text said "A review of the plan is performed by the tech lead." Abstract nouns and passives hide who has to act.
- **Sentences that have a verb.** A string of nouns, or a fragment with no verb, has to be decoded before it can be understood. Rewrite it as a sentence with a subject and a verb.
- **"You" in a rewrite.** In a procedure, "you" for the person who does the steps is normal when the project's style allows it. In a rewrite, keep the source's choice, and do not add "you" where the source did not address the reader.

A statement whose force is unclear, fixed from the source:

```
Known: the review is required for every change that an agent makes.

Bad:   Engineers should review agent changes.
Good:  An engineer must review every change that an agent makes.
```

## "Why is this here?"

These rules extend rule 4.

- **Navigation by role.** When a document needs routing by role, put it in the navigation, such as a contents page with links by task, and keep it out of the opening of the content. Routing by task works better than routing by audience, because readers often cannot place themselves in a list of roles, and role labels often come from internal jargon.

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

A role that the reader's organization does not have:

```
Known: the person who maintains the team's rules writes each policy.
       The reader's company has no job with that name.

Bad:   The rules steward writes the policy.

Good:  The person who maintains the team's rules writes the policy.
       This is a role in the team, and the company has no job title
       for it.
```

## "Is this real?"

These rules extend rule 5.

- **Running examples.** Introduce a running example before you rely on it, and say that it is invented. A reader who arrives at a section from a link has not met the scenario, and takes its details as real.
- **Values in examples.** Explain each specific value in an example, such as a date, an identifier or a duration, or replace it with a placeholder that is clearly not real, such as `<incident number>`. Unexplained values look like real data.

## "Does this exist yet?"

These rules extend rule 6.

- **Words that go stale.** Avoid "new", "now", "currently" and "soon", which become wrong without anyone editing them. When timing matters, give a date.
- **Partial coverage.** If a section covers its subject only in part, say so at its top. Leave no empty headings.

## "Can I trust the page?"

These rules extend rule 7.

- **Headings with explained terms.** A heading uses the reader's words and no term that the page has not explained yet.
- **One version across documents.** Keep terms and formatting the same across the page and its companion documents. When two documents describe the same thing in different ways, readers suspect that neither is current.
- **Leftovers from publishing tools.** Documentation generators often add a symbol such as "¶" as the visible link of each heading's anchor, and it shows up when the page is copied, printed or converted. Raw markup, template placeholders and broken links are other leftovers. Check a copy in the format that the reader uses.

## Review questions

Ask these while you read as the reader. A question that the text leaves open at the point where the reader meets it is a finding.

For the page:

- What is this page, and what does the reader get from it? Does the first paragraph say so?
- What will the reader do or decide after reading, and does the page give them what they need for it?

For each section:

- What is the section about, in one short phrase? If that is hard to say, the section probably mixes purposes.
- Does the first sentence say what the subject is, and does the heading say what the section contains?
- Can a reader who arrives here from a link follow the section without the earlier ones?
- Does the reader know whether the thing exists, is planned or is unfinished?
- Does the section get space in proportion to how hard its decision is?

For each paragraph:

- What is it about, why does it matter, and how does the reader use it?
- If a sentence were deleted, would the reader lose information?

For each term, code, abbreviation and name:

- Does this reader know it? If not, is it explained where it first appears, in a sentence of its own?
- Does it keep one meaning on the page, and is the same thing always called by the same name?

For each example:

- Is it labelled as an example, and does it come after the general case?
- Does each date, number and identifier in it mean something to the reader?

For each claim:

- Who does what, to what, and under which condition?
- Is it required, optional, possible or a plain fact?
- Would a reader in a second language, reading word by word, get the right meaning?

## Review techniques

- **Read as a named reader.** Write down the reader's role, goal and what they already know, then read the whole text as that person and note each question they would ask. If the text has several kinds of reader, read it once as each, because a single imagined reader can make you narrow the document to that one person.
- **Read the headings and first sentences.** Read only the headings, then only the first sentence of each paragraph. Together they should give the whole argument in order, with no gaps and no repeated ideas.
- **Write a reverse outline.** Write the main idea of each paragraph as a short phrase. A paragraph whose idea does not fit a short phrase probably needs revision, and a column of near-identical phrases shows a repeated formula.
- **Sweep for terms and codes.** List every capitalized term, letter-and-digit code, abbreviation and product name in the order in which they first appear, in diagrams and tables as well as in the text, and note where each one is explained. A term explained after its first use, or never, is a finding. Treat any abbreviation, and any term that a reviewer asks about, as possible jargon.
- **Read each section alone.** Read each section as if you arrived from a search or a link, and check it against "Sections that stand alone" above.
- **Separate the types.** Ask of each section whether it helps the reader do something or understand something. A section that tries to do both mixes a procedure with an explanation, and should be split.
- **Test with a reader who has only the document.** Give the text to someone who has not seen the working material: a colleague, a new session, or a helper agent that starts with nothing but the document. Ask them to say in their own words what each section means, which terms are not explained, what the document assumes they already know, and what they would do next. Ask for a paraphrase, because readers often call a text clear and still misread a key term. Compare the paraphrase with what the text was meant to say.

## Sources

The rules on invented role titles, on the wording for unfinished sections, on labelling invented scenarios and on leftovers from publishing tools are this skill's own. No published guide states them, and each carries its reason where it appears.

- Google developer documentation style guide: https://developers.google.com/style/highlights
- Google Technical Writing courses: https://developers.google.com/tech-writing/one/words
- Federal Plain Language Guidelines, 2011 (archived): https://web.archive.org/web/20241231152827id_/https://www.plainlanguage.gov/media/FederalPLGuidelines.pdf
- European Commission, How to write clearly: https://op.europa.eu/en/publication-detail/-/publication/725b7eb0-d92e-11e5-8fea-01aa75ed71a1/language-en
- GOV.UK, Use clear language: https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/
- GOV.UK, Clear structure: https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-structure/
- Nielsen Norman Group, Technical jargon: https://www.nngroup.com/articles/technical-jargon/
- Nielsen Norman Group, Audience-based navigation: https://www.nngroup.com/articles/audience-based-navigation/
- Microsoft Writing Style Guide, Acronyms: https://learn.microsoft.com/en-us/style-guide/acronyms
- Microsoft Writing Style Guide, Final publishing review: https://learn.microsoft.com/en-us/style-guide/final-publishing-review
- digital.gov, Plain language style: https://digital.gov/guides/plain-language/writing/style/
- digital.gov, Paraphrase testing: https://digital.gov/guides/plain-language/test/paraphrase-testing/
- 18F, Abbreviations and acronyms: https://raw.githubusercontent.com/18F/guides/main/content/content-guide/our-style/abbreviations-and-acronyms.md
- Mailchimp, Writing for translation: https://styleguide.mailchimp.com/writing-for-translation/
- Write the Docs, Documentation principles: https://www.writethedocs.org/guide/writing/docs-principles/
- Diátaxis, The compass: https://diataxis.fr/compass/
- Mark Baker, 7 principles for designing help topics: https://blog.adobe.com/en/publish/2013/10/10/7-principles-for-designing-help-topics-in-the-age-of-the-web
- Gopen and Swan, The Science of Scientific Writing (quotations): https://www.win.tue.nl/~wstomv/quotes/science-of-scientific-writing.html
- Steven Pinker on the curse of knowledge, APS Observer: https://www.psychologicalscience.org/observer/the-curse-of-knowledge-pinker-describes-a-key-cause-of-bad-writing
- Caltech Hixon Writing Center, Revising with reverse outlines: https://writing.caltech.edu/documents/29881/Revising_with_Reverse_Outlines.pdf
- W3C, Making Content Usable: https://www.w3.org/TR/coga-usable/
- agent-style (name the reader): https://github.com/yzhao062/agent-style
- Matt Pocock's writing skills (ground each concept before use): https://github.com/mattpocock/skills
- SimpleEnglish (steps name their dependencies): https://github.com/AminBlg/SimpleEnglish
- doc-standards (document types, one approved term): https://github.com/JuanMarchetto/doc-standards-skill
- WRITING.md (define only what the reader needs): https://github.com/Anbeeld/WRITING.md
- doc-coauthoring (reader test in a fresh context): https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring
- avoid-ai-writing, issue 124 (two names for one thing): https://github.com/conorbronsdon/avoid-ai-writing/issues/124
