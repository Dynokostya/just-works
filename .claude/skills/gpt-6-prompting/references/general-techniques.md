# GPT-6 General Prompting Techniques

Layouts and templates for building a full GPT-6 prompt. The prompt layout, the retrieval budget, and the design constraints below are conventions this skill recommends; OpenAI has not published them as GPT-6 text. The Programmatic Tool Calling section follows OpenAI's guide.

## Contents

- Prompt layout
- Outcome-first prompting
- Tool routing
- Programmatic Tool Calling
- Retrieval budget
- Frontend and visual tasks

## Prompt layout

Keep each section short and add detail only where it changes behavior.

```
Role: [1-2 sentences: the model's function, context, and job]
# Personality: [writing choices and collaboration style: when to assume vs ask, how it checks work]
# Goal: [user-visible outcome]
# Success criteria: [what must be true before the final answer, including running and checking the result]
# Constraints: [policy, safety, business, evidence, side-effect limits]
# Tools: [which tools to use, when, and what not to use]
# Output: [format, writing style, and a quantitative length bound]
# Stop rules: [when to retry, fall back, abstain, ask, or stop]
```

## Outcome-first prompting

Describe what good looks like and let the model choose the path.

```
Resolve the customer's issue end to end.

Success means:
- the eligibility decision is made from available policy and account data
- any allowed action is completed before responding
- the final answer includes completed_actions, customer_message, and blockers
- if evidence is missing, ask for the smallest missing field
```

## Tool routing

- Expose only task-relevant tools. Each description states purpose, when to use it, key return fields, and error behavior in one or two sentences.
- State prerequisite retrieval when correctness depends on it: "Read the current config before proposing changes."
- On empty, partial, or suspiciously narrow results, require one or two fallbacks (alternate wording, broader filters, prerequisite lookup) before concluding "no results", and report what was tried.

## Programmatic Tool Calling

Source: https://developers.openai.com/api/docs/guides/latest-model (Programmatic Tool Calling section; GPT-6 supports the feature).

Use it for bounded workflows where code can process several tool results or large intermediate outputs and return a much smaller structured result: filtering, joining, ranking, deduplication, aggregation, validation. Multiple, parallel, or dependent calls alone do not justify it.

Prefer direct tool calls when one call is enough, intermediate outputs are small, each result may change the next decision, an action needs approval, or the final output must preserve citations or native artifacts.

When both routes are available, state which bounded stage uses Programmatic Tool Calling, which tools it may call, the exact output schema and required evidence, the concurrency, retry, and stopping limits, and which work stays direct. If both routes are needed, define one handoff and tell the model not to switch routes or repeat completed work. Test the program output and the final message separately, because correct records can still arrive with a required field or caveat missing.

```
<tool_orchestration>
Use Programmatic Tool Calling for [bounded stage] using only [eligible tools].
Run independent calls concurrently when safe. Use only documented tool input
and output fields.
Process and reduce the intermediate results, then emit exactly [output schema],
including the evidence needed for the final answer.
Stop when [condition] is met. Retry transient failures at most [R] times.
Do not repeat completed calls or perform side-effecting actions. If a required
result is still missing, return a clear structured failure.
Use direct tool calls for [semantic judgment, approval, or final validation].
</tool_orchestration>
```

## Retrieval budget

For search-enabled flows, define what needs support, what counts as sufficient evidence, and what to do when evidence is missing. Absence of evidence is not a factual "no".

```
<retrieval_budget>
Start with one broad search using short, discriminative keywords. If the top
results contain enough citable support for the core request, answer from them.

Search again only when: a required fact, parameter, owner, date, or ID is
missing; the user asked for exhaustive coverage or a comparison; a specific
document or artifact must be read; or the answer would otherwise contain an
important unsupported claim.

Do not search again to improve phrasing, add examples, or support wording that
can safely be made more generic.
</retrieval_budget>
```

Cite only sources retrieved in the current workflow, never invent citations, URLs, or IDs, and label inference separately from supported facts.

## Frontend and visual tasks

Constrain design work and do not script layout steps:

```
<design_constraints>
- Inspect and preserve the existing design system: tokens, components, patterns.
- Implement exactly what was requested, with no extra features or decorative UI.
- Preserve responsive behavior and expected states (loading, error, empty).
- Render and inspect the result before finalizing.
</design_constraints>
```

For a new design with no system, give a concrete direction (palette hex values, typeface, radii, spacing), or have the model propose three or four directions and build only the one chosen.
