# Machine tells: catalog, exceptions and over-corrections

A tell is a habit of wording or structure that makes readers suspect a text was generated. This file holds every entry, grouped by how much a single sighting proves. One sighting of a tell in the first group justifies an edit. A tell in the second group is a finding once you have checked that the document's genre does not call for it. A tell in the third group is a finding only when it recurs across the page or appears together with others. `SKILL.md` lists six of these tells as habits 1 to 6, the ones most common in documents that agents write, and each of those entries here gives its habit number. How common a tell is and how much one sighting proves are different measures: absolutes, for example, are common, but a single absolute proves little, so they belong to the third group.

Each entry gives the shape of the tell, the reason it bothers readers, the fix, and what to keep. Apply the "Keep" part before you record a finding, and list what you kept under "Left alone" in the report. Human writers produce these habits too. In one blind test, a quarter of the readers called a hand-written design document AI-written, so report what the reader experiences and leave authorship out of the report.

## One sighting justifies an edit

**1. Leftovers from chat, drafts and tools**
- Shape: a line addressed to the person who asked for the document, such as an offer of more help; a note about how the text was produced; an unfilled placeholder such as "[Your Name]" or "2025-XX-XX"; a tracking parameter in a link; a symbol left by a publishing tool.
- Why: it shows that nobody checked the text before it reached the reader.
- Fix: delete it. Fill a placeholder from the source material, or mark the gap.
- Keep: a caveat that changes what the reader should do; a template placeholder that is meant to stay; Markdown syntax in a format that renders it.

**2. Contrasts against claims nobody made** (habit 2)
- Shape: joined ("It is not X, it is Y"), split over two sentences ("This is not X. It is Y."), stacked ("Not X. Not Y. Just Z."), as a tail (", not Y"), reversed ("Y rather than X"), or clipped (", no guessing").
- Why: the rejected half names something nobody claimed, so that the real claim sounds larger.
- Fix: state the real claim. "The sample log is not paperwork. It records who handled each sample and when." becomes "The sample log records who handled each sample and when."
- Keep: a correction of a belief the reader actually holds; a pair in which both halves carry information, such as "Agents do not merge their changes; an engineer merges them"; a list of constraints, such as "no dependencies, no telemetry".

**3. Sayings and mirrored slogans** (habit 1)
- Shape: balanced clauses that read as a motto, often two short clauses joined by "and" or a semicolon; a claim of the form "X is the language of Y".
- Why: the symmetry does the work that content should do.
- Fix: state the rule that the saying compresses (who acts, when and with what result) from the source material, or mark the gap. Delete the saying when the next sentence already makes the claim, as in the pair in `SKILL.md`, and apply the test described there: imagine the sentence in a document on another subject.
- Keep: quotations, and idioms that the reader already uses.

**4. One-line closers and staged openers**
- Shape: a last line that restates its paragraph ("That distinction matters."); a run-up that delays the point ("Here is the thing:", "The catch?"); a topic sentence that describes the paragraph's role and leaves the point unsaid ("The number deserves context."); a section that opens by restating its heading and closes by summarizing itself.
- Why: the line makes the reader pause on a claim and adds nothing to it.
- Fix: delete it, and open on the point.
- Keep: a last sentence that adds a fact or a consequence.

**5. Arguing with no one**
- Shape: "This is not to say…", "To be clear,", "A tempting approach would be…", or a rebuttal of an objection that nobody raised.
- Why: it is usually left over from an earlier draft, and it makes the reader wonder who raised the objection.
- Fix: remove it, and keep any real claim it contains.
- Keep: an option that the reader would actually weigh.

## Strong in documents, after a genre check

**6. One point restated, one formula for every section** (habit 5)
- Shape: the same idea in the introduction, in each section and at the end, often as a new saying each time; every section closing on the same kind of line or the same moral; sibling sections built on the same skeleton whatever their content; equal length for sections of unequal difficulty.
- Why: a repeated skeleton shows that the structure came from a template. For a restated point, see "Can I trust the page?" in `SKILL.md`.
- Fix: make each point once, where it applies. Give a hard point, such as a hard decision, more space than a routine one, because readers judge which points are hard by the space each one gets. In place of a slot such as "If something goes wrong", state in one sentence what happens when the step fails, where the source material says, such as "The manager approves the claim. When it is not approved, it goes back to the employee."
- Keep: a fixed shape in procedures, reference pages, runbooks and other pages that readers scan, when each slot holds content that differs from one entry to the next; a short summary with the same fields at the top of each group of steps (see "When the document describes a process" in `SKILL.md`). Slots that read "None" or "Nobody", or repeat the entry's first sentence, come from a template and do not qualify: drop them.

**7. Text about the document or its edits**
- Shape: "In this section, we will discuss…"; "The table below compares…"; "This function was changed to replace the old callback approach."; remarks about earlier drafts or about what a review asked for.
- Why: assistants write in the context of the edit they just made, and the reader never saw that edit.
- Fix: describe the subject as it is now.
- Keep: changelogs, release notes and migration guides, whose subject is the change; a convention the reader cannot infer, stated once; a note at the top of a section that it covers its subject only in part.

**8. Inflated significance and trailing riders**
- Shape: "marks a pivotal moment", "Despite these challenges", or a trailing clause such as ", ensuring consistency across teams".
- Why: the subject becomes less specific and more exaggerated at the same time.
- Fix: keep the fact. If the sentence still works without the inflating clause, delete the clause.
- Keep: a rider that the source material supports, such as a consequence it states.

**9. Vague attribution**
- Shape: "Experts agree", "Industry reports show", or one source presented as a consensus.
- Why: it claims an authority that nobody can check.
- Fix: name the study, report or person that the source material cites, or cut the claim.
- Keep: named, checkable sources. A missing citation alone is no tell.

**10. Invented labels**
- Shape: a coined name for a concept, such as "the supervision paradox" or "a coordination tax".
- Why: naming a concept does not explain it, and the reader has to guess what the label covers.
- Fix: describe the mechanism in words the reader already uses. Define the term only when the reader needs it again later (see "What does this word mean?" in `SKILL.md`).
- Keep: a defined term that is used consistently.

**11. Figurative verbs and forced metaphors**
- Shape: a figure chosen for its sound where a literal phrase exists, such as "where the delays actually live", "the Export button unlocks the full report", "earns its keep" or "the route is lean".
- Why: the figure replaces a direct statement, and its connotation brings in a claim that the source material did not make.
- Fix: state the literal property that the source material supports, or mark the gap where it never says what the figure means.
- Keep: technical senses, such as "gate", "pipeline" or "branch"; a metaphor that the passage explains.

**12. Announcers and framing shells** (habit 4)
- Shape: a sentence that only counts or previews what follows ("Three principles shape the design."); a shell that delays the claim ("The problem is that new staff get their badges late.", "What changed is the direction.").
- Why: the sentence previews structure and says nothing.
- Fix: start the list or the claim. "The problem is that new staff get their badges late." becomes "New staff get their badges late."
- Keep: a count of real, parallel items, such as numbered steps.

**13. Over-definition**
- Shape: an aside of the form "X, a short definition, does Y" at every mention, or definitions of terms that the reader uses daily.
- Why: it suggests that the writer never decided who the reader is, and it slows readers who know the term.
- Fix: cut a term that this reader does not need. Give a term that stays one definition, for this document's reader, in a sentence of its own (see "What does this word mean?" in `SKILL.md`).
- Keep: a definition that the reader needs, at first use.

## Weak alone: act on density or clusters

**14. Absolutes used for force** (habit 3)
- Shape: "never", "always", "every", "nobody", "the only way" or "all cases are handled", stated without a checked scope.
- Why: they claim a scope that the writer has not checked.
- Fix: state the real scope or the exception.
- Keep: true invariants, with their scope. A single absolute is normal, so act when they recur across the page.

**15. Uniform sentence and paragraph length**
- Shape: most sentences in a document fall in a narrow band of length, and most paragraphs have the same number of sentences.
- Why: the evenness reads as text produced by rule.
- Fix: let the content set the length of each sentence. Do not impose length bands, add rhetorical questions or chop sentences to create variety.
- Keep: steps, tables and reference entries, which are even by design.

**16. Repeated sentence openings and frames**
- Shape: consecutive sentences built on the same frame, such as "Annual leave is one type of absence. Sick leave is one type of absence."
- Why: the repetition comes from a rule, and the reader notices the pattern before the content.
- Fix: merge the sentences, or lead with the action. Do not ban the repeated word.
- Keep: numbered steps that share an imperative shape; real list content.

**17. Lists of three by default**
- Shape: three adjectives or nouns where the content has a different number, such as "affordable, flexible and sustainable"; a colon that leads into a triple.
- Why: three is a default rhythm, used whether or not the content has three parts.
- Fix: count the real items, and judge whether they are distinct. Cutting a list of four to three does not fix it.
- Keep: three real items.

**18. Abstractions doing human work** (habit 6)
- Shape: an abstraction as the subject of a human action, such as "The decision emerged after the offsite" or "the process decides".
- Why: the actor disappears, and the reader does not know who is responsible.
- Fix: name the actor that the source material names. When the document has a table of decisions, name the decision's owner from it. For any other action that the source material gives no role, describe the person by what they do, such as "the person who ran the survey". Do not invent a job title to fill the subject. When the source material does not say who acts or decides, mark the gap and ask the author. For a decision, you may suggest a default role (see "When the reader acts on decisions" in `SKILL.md`).
- Keep: literal system behavior, such as "the pipeline runs the tests", and ordinary personification.

**19. Avoiding "is" and "has"**
- Shape: "serves as", "stands as", "boasts" or "features" where "is" or "has" would do.
- Why: an inflated verb stands in for a plain relation.
- Fix: write "is", "are" or "has".
- Keep: a verb that adds meaning. Human scholarship uses "serves as" often, so act only on clusters.

**20. Hollow intensifiers**
- Shape: "a real improvement", "genuinely", "truly", "quietly".
- Why: "real" implies an unnamed fake version, and the others add emphasis without information.
- Fix: delete them.
- Keep: a named contrast, such as "actual revenue, from paying customers and not from grants".

**21. Hedge stacks**
- Shape: "could potentially", "may eventually", "might possibly".
- Why: the qualifiers repair an overstatement and report no real doubt.
- Fix: keep the one qualifier that carries the real uncertainty of the text under review.
- Keep: a single hedge, a statement of scope, a safety notice, and any caveat that changes what the reader will do.

**22. Bold and heading habits**
- Shape: bold on every key term; a bold label that repeats each bullet; Title Case headings; headings written for effect.
- Why: the formatting was applied by rule, and it gives every item the same weight.
- Fix: write sentence-case headings that say what the section holds, and keep bold for the few words that a reader must not miss.
- Keep: bold terms in a list of terms and definitions.

**23. Dashes**
- Shape: em dashes that join clauses throughout a text.
- Why: a dash lets the writer skip deciding how two clauses relate.
- Fix: use dashes rarely. Choose the connection the clauses have ("because", "so", "and"), or use a period, comma, colon or parentheses.
- Keep: dashes in code, paths and URLs. A text without dashes proves nothing about who wrote it.

## Over-corrections to avoid

An over-correction is an edit that removes one tell and creates another. Readers notice these as quickly as the original habits.

- **Clipped sentences.** Whole sentences chopped into fragments to sound brisk. Readers describe the result as rushed, and cleanup tools produce it often enough that it has become a tell of its own. Vary length by writing different sentences, and keep each sentence whole.
- **Added voice.** First person, opinions, reactions or confessions that the text under review lacks. Technical text stays neutral and plain. In a rewrite, keep the choice of "we" or "you" that the text under review made (see Voice in `SKILL.md`).
- **Invented specifics.** A number, name, date, quotation or example added to sound concrete. A fabricated specific is worse than the vague wording it replaced. Mark the gap.
- **Invented actors.** A "you", a team, a job title or a system component added as the subject of a sentence that had none. Name only the actors that the source material or the author gives, including the owners in the document's table of decisions when it has one, and mark the gap where a decision has no owner.
- **Invented contrasts.** A foil, a crowd or a rejected option added to make a point sound sharper. A foil that neither the text under review nor the source material contains is a new claim.
- **Hedges stripped into absolutes.** "Most teams struggle with alignment" turned into "Teams struggle with alignment." Do not raise the confidence of the text under review.
- **Synonym swaps.** Synonyms rotated to avoid repetition, or one listed word replaced by another listed word, such as "lean into" by "embrace". Repeat the term, and use the plain word.
- **Mechanical dash removal.** Every dash turned into a period. Choose the connection the clauses have. A dash count near zero after a cleanup is a sign of over-editing.
- **Numeric targets.** Caps on sentence length, quotas for list length and formulas for varied rhythm. Skills that had such targets later removed them, because each one produced a new repeated pattern. Let the structure follow the content.
- **Lists as an escape.** Prose turned into bullets because list items seem exempt from the rules. Use lists for separate items, and keep reasoning in sentences.
- **Cut reasons.** A "because" clause deleted although it states a concrete consequence. Cut only sentences that call a point important without saying why.
- **Bans on working technical terms.** A technical term removed because it appears on a list of AI words. In developer documentation, "robust", "ecosystem" and "leverage" in its technical sense are normal.
- **Over-polishing.** Text with no justified finding rewritten anyway. Removing every irregularity can push human writing toward the uniform profile of generated text, so text with no justified finding comes back unchanged.

## Signs that point to a human writer, and signs that prove nothing

Use these to keep false findings out of a review, and to fill the "Left alone" part of the report.

Signs that often point to a human writer: simple phrases with "there is" and "it has"; plain verbs, such as "used" where generated text tends to write "utilized"; definite statements; ordinary hedges and mild intensifiers, such as "perhaps" or "tends to"; an isolated wordy phrase, such as "in order to"; text written before November 2022; a writer who can explain their choices; and, in personal writing, odd specific detail, mixed feelings and real asides.

Signs that prove nothing on their own: perfect grammar; a mix of casual and formal registers; bland or formal prose; transition words; content without sources; dashes; curly quotes; a single short emphatic sentence.
