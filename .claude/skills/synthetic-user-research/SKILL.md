---
name: synthetic-user-research
description: "Use AI personas for early-stage research signal within a narrow scope. Use when asked to run synthetic user testing, simulate user reactions with AI personas, pretest a survey or message before fielding it, or decide whether synthetic research is appropriate. Produces a fit verdict, a persona-panel design grounded in real data, findings labelled synthetic, and a follow-up plan with real humans. Not a substitute for discovery interviews."
---

# Synthetic User Research

AI personas are useful in a narrow lane of questions and misleading outside it. A synthetic panel can catch comprehension failures, confusing flows and survey defects before real participants are spent on them. It cannot tell you what people will pay for, feel or do. This skill checks that the question is in the lane, then runs the method. Sometimes the result is "no, here is the human study to run instead".

## The lane (checked before anything runs)

**Synthetic methods can probe** questions whose answer lives in the artifact, not in people's feelings:
- **Comprehension**: is this copy, onboarding or explanation understandable, and where does a reader stumble?
- **Instrument defects**: leading questions, double-barrelled items and missing answer options, found before a survey is fielded.
- **Information architecture**: can someone with a goal find the thing, and where does the navigation mislead?
- **Message differentiation**: do these three positionings read as different?
- **Edge cases**: which user situations did the design forget? Personas serve as brainstorming here, not as evidence.

**Synthetic methods cannot establish** the following, so refuse these questions and say why:
- Willingness to pay, purchase intent or price sensitivity. Models have no budget and agree too readily.
- Emotional response, delight or trust. A model's simulated feeling carries no information.
- Unknown needs. Personas recombine known data, and discovery is about what is not yet known.
- Behavior. What people say they would do is already unreliable, and a model's guess at it is worse.
- Validation of a launch or investment decision. Synthetic output is not evidence of demand.

## Required inputs

Ask for these if they are not provided:
- **The research question.** Run the lane check first and give the verdict before choosing a method.
- **Real data to ground the personas**: interview notes, support tickets, reviews, analytics segments. With no real data there is no panel, because ungrounded personas only repeat the model's stereotypes.
- **The artifact under test**: the copy, flow, survey or navigation.
- **The decision this feeds and its stakes.** Higher stakes narrow the lane.

## Method (when the lane check passes)

1. **Build personas from data, with sources.** Each persona cites where it comes from, for example "from the 14 churn interviews: SMB admin, low technical confidence, evaluates in under 10 minutes". Use 4 to 6 personas that span the real segment axes, including at least one hostile or low-attention profile, because synthetic panels skew cooperative unless you force otherwise.
2. **Counter the agreeableness.** Instruct each persona to struggle where its profile would struggle. Ask for failure ("where do you stop reading? what would make you give up?") and not for opinions ("do you like this?"). Never ask satisfaction or intent questions, since those are the ones models answer most fluently and least truthfully.
3. **Run tasks on the actual artifact.** Give the persona the artifact and a goal. Record where it misreads, stalls or takes the wrong path, and quote the artifact in every finding.
4. **Compare across personas and runs.** A stumble that appears for 4 of 6 personas and in repeated runs is a signal. A single eloquent complaint is not.
5. **Label every output and hand off.** Mark the output SYNTHETIC at the top and on each finding. Convert findings into fixes to the artifact (cheap, do now) and hypotheses for the human study. The follow-up plan names the method, the sample size and what would confirm or refute each hypothesis.

## Output format

### Synthetic research pass: [artifact] (SYNTHETIC SIGNAL, NOT USER EVIDENCE)

**Lane check:** [question] → [in the lane / out of the lane, with the human method to use instead]

**Panel:** [persona → grounded in → key traits], with the source of each persona.

**Findings** (each labelled synthetic)
| # | Finding | Artifact evidence (quoted) | Personas affected | Confidence |
|---|---|---|---|---|

**Fixes now:** [artifact changes the pass justifies: comprehension, navigation and survey defects]

**For real humans:** [hypothesis → method → n → what confirms or refutes it]. The synthetic pass produces sharper questions, not answers.

## Quality checks

- [ ] The lane check ran first, and out-of-lane questions were refused with the alternative named
- [ ] Every persona cites the real data it is built from
- [ ] The panel includes hostile or low-attention profiles
- [ ] No finding reports simulated emotion, intent or willingness to pay
- [ ] The SYNTHETIC label appears on each finding, so it survives copy-paste
- [ ] The human follow-up plan exists

## Anti-patterns

- Running synthetic "validation" for a launch or investment decision. This presents a model's agreeableness as evidence.
- Building personas from guesses or market-report archetypes. Personas built that way repeat the stereotypes behind them.
- Asking personas how they feel or what they would pay. The fluent answer is the unreliable one.
- Reporting synthetic findings in the same register as real research. A stakeholder who cannot tell the difference was not told clearly enough.
- Letting a synthetic pass replace the discovery interview it was meant to prepare. It comes before human research, never instead of it.
