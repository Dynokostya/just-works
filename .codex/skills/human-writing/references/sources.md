# Sources

This file lists the evidence behind the rules of this skill, for people who maintain it. You do not need it to write, review or rewrite a document.

## Rules for a reader who lacks your context

The rules in `SKILL.md` and `references/reader-first.md` draw on the published guides listed below. Several rules are this skill's own, and no published guide states them in this form: the concept inventory, naming the owner of each decision and creating no other duties, layers for readers who need different depth, describing only decided content, the three levels of detail in a process, example blocks that show what a step produces, and the rules on the wording for unfinished sections, on labeling invented scenarios and on leftovers from publishing tools. Each carries its reason where it appears.

These rules were first tuned on reviews of one kind of document, a description of a software delivery process that managers and engineers read. The rules that apply only to some documents keep their condition in their title for that reason, and the examples come from several kinds of document. Two comparisons from those reviews support rules whose reasons the skill states in general words:

- **Cut concepts before you define them.** Two documents covered the same subject. A rewrite of one of them defined each new term, nearly doubled in length and went from 1 defined term to 81, and readers still found it hard to follow. The other document covered more of the subject with 14 defined terms.
- **Name decision owners and create no other duties.** A process document that named a dozen job roles several hundred times, and gave them invented duties such as a champion and an owner for upkeep, was hard to follow. A document on the same subject that named nobody who approves was easy to follow, but an executive who reviewed it called the missing decision owners its most important gap. Its author added one page with the decisions and their owners, named the owner at each decision and added no other duties. Role mentions went from about one to about sixty across eight pages, far below the several hundred of the first document.

Published guides and skills:

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

## Machine tells

The catalog in `references/machine-tells.md` draws on these collections, tests and reports:

- avoid-ai-writing, version 3.36.0: https://github.com/conorbronsdon/avoid-ai-writing
- humanizer, versions 2.9.1 and 3.1.0: https://github.com/blader/humanizer
- stop-slop: https://github.com/hardikpandya/stop-slop
- tropes.fyi, "the writing whip": https://tropes.fyi
- Wikipedia, Signs of AI writing: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- vale-ai-tells (framing shells, mannered verbs, over-definition): https://github.com/tbhb/vale-ai-tells
- plain-writing-skill (slogans and catchy labels): https://github.com/docwriter-org/plain-writing-skill
- no-ai-slop (moving a sentence to another company as a test): https://github.com/petergyang/no-ai-slop
- stop-slop-refined (lazy extremes, visible gaps, additions where a draft compresses): https://github.com/odinfree/stop-slop-refined
- humanizer-stack (morals restated in each section, repeated skeletons): https://github.com/NulightJens/humanizer-stack
- edwinhu workflows (topic sentences about the paragraph, false positives, two-pass limit): https://github.com/edwinhu/workflows
- sepia (a list of findings before a rewrite): https://github.com/Nanako0129/sepia
- de-slop (hollow paragraphs marked and left unfilled): https://github.com/isatimur/de-slop
- WRITING.md (mechanical period substitution, structure for pages that readers scan): https://github.com/Anbeeld/WRITING.md
- talk-normal (bad examples in rules copied as templates): https://github.com/hexiecs/talk-normal/blob/main/regressions/rule-17-negation-frame.md
- SimpleEnglish evaluation of a skill with many rules: https://github.com/AminBlg/SimpleEnglish/blob/main/evals/results/WHY-USELESS-2026-09-02.md
- Michael Lynch, blind test of design documents written by AI and by people: https://refactoringenglish.com/blog/ai-vs-human-design-doc/
- Simon Willison, LLM cliché highlighter (runs of repeated sentence frames): https://tools.simonwillison.net/llm-cliche-highlighter
- Prompting guides for Claude Fable 5 and Fable 5.1 (readability over brevity, mannered prose): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 and https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
- User reports of over-correction: https://github.com/blader/humanizer/issues/146 and https://github.com/hardikpandya/stop-slop/issues/15
