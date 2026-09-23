---
name: gemini-3-prompting
description: Apply when creating or editing prompts targeting the Gemini 3.x family (3.1 Pro, 3.5–3.8 Flash, 3.5 Flash-Lite). Covers prompt layering, thinking-level implications, determinism via instructions, few-shot, long context, tool and grounding instructions, agentic prompts, model picking, and migration from 3.0 and 2.5.
---

# Gemini 3.x Prompting

## When to Use

- Creating or editing system prompts targeting any Gemini 3.x model
- Picking a Gemini 3.x model for a prompt's workload
- Writing few-shot examples for classification or extraction tasks
- Structuring long-context prompts with multiple sources
- Writing agentic and tool-use instructions for Gemini 3.x workflows
- Decomposing complex prompts into chainable sub-prompts
- Migrating prompt text from Gemini 3 Flash Preview / 3.0 or Gemini 2.5

## Overview

Gemini 3.x responds best to direct, concise instructions. Verbose prompt engineering from Gemini 2.5 and earlier causes over-analysis and degrades output quality. Reasoning depth is set by the thinking level, not by prompt text -- keep prompts simple and let the level do the work. From 3.5 Flash onward the default level is `medium`, so prompts tuned under the old `high` default need re-testing.

<context>
Key characteristics to design around (sources: ai.google.dev/gemini-api/docs/prompting-strategies, ai.google.dev/gemini-api/docs/whats-new-gemini-3.5):

- **Conciseness Over Verbosity**: "Be concise in your input prompts. Gemini 3 responds best to direct, clear instructions." Remove filler.
- **Context Before Task**: "When providing large amounts of context (e.g., documents, code), supply all the context first. Place your specific instructions or questions at the very end of the prompt."
- **Constraints + Persona at the Beginning**: "Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt."
- **Native Thinking**: Levels `minimal` / `low` / `medium` / `high` set reasoning depth. Simplify heavy chain-of-thought scaffolding; a short "think very hard" cue is fine for heavy reasoning.
- **Determinism Through Instructions**: Sampling parameters are deprecated. Get consistent output from explicit rules in the system instruction plus a response schema.
- **Persona + Constraint Alignment**: Persona and other constraints belong together in the System Instruction. Ensure they do not contradict each other.
- **Default Directness**: "By default, Gemini 3 models provide direct and efficient answers." Request conversational tone explicitly if needed.
- **Few-Shot Recommended**: "Prompts without few-shot examples are likely to be less effective."
- **Reasoning Carries Forward**: From 3.5 Flash, reasoning from earlier turns carries into later turns -- long conversations can use more tokens than the same prompt did on 3.0.
</context>

## Model Picker

Behavioral fit, not specs. Thinking-level support is listed because it changes how "fast" prompts must be written.

| Model | Pick when | Thinking levels (default) |
|-------|-----------|---------------------------|
| 3.1 Pro | Deep reasoning, synthesis across many sources, high-stakes analysis | low / medium / high (high) |
| 3.8 Flash | Most capable Flash; hard agentic and coding work that benefits from step-by-step verification | low / medium / high (medium) |
| 3.7 Flash | Efficiency-first everyday work | low / medium / high (medium) |
| 3.6 Flash | General Flash work with fewer output tokens than 3.5 Flash | minimal / low / medium / high (medium) |
| 3.5 Flash | General Flash work | minimal / low / medium / high (medium) |
| 3.5 Flash-Lite | Sub-agents, routing, high-volume classification and extraction | minimal / low / medium / high (minimal) |

3.8 Flash verifies its own work heavily. Per Google: "the model takes smaller reasoning steps, calls tools iteratively, and verifies its work along the way. Not every workflow needs this level of verification. For everyday tasks, you can lower the reasoning effort to reduce token consumption. Alternatively, Gemini 3.7 Flash remains fully supported." (Source: ai.google.dev/gemini-api/docs/latest-model)

Older models still in use: 3.1 Flash-Lite (replacement: 3.5 Flash-Lite) and 3 Flash Preview (replacement: 3.6 Flash). 3 Pro Preview now resolves to 3.1 Pro.

## Core Prompt Structure

### System Instruction + Context + Task

Constraints, persona, and output format go FIRST (system instruction or prompt start); long context goes next; the specific question goes LAST.

```jinja
{# System Instruction -- behavioural rules, persona, output format #}
<role>{{ persona }}</role>
<constraints>
{% for constraint in behavioural_constraints %}
- {{ constraint }}
{% endfor %}
</constraints>
<output_format>{{ output_format }}</output_format>

{# User Prompt -- context first, specific task last #}
<context>
{{ context_data }}
</context>

<task>
Based on the information above, {{ specific_question }}.
</task>
```

### Bridging Context to Task

"Anchor the model's reasoning by starting your question with a phrase like, "Based on the preceding information..."" (Source: ai.google.dev/gemini-api/docs/prompting-strategies). Equivalents: "Based on the information above, ...", "Using only the provided documents, ...". For multi-source synthesis, "Based on the entire document above, provide a comprehensive answer to: ..." anchors the model to the full input rather than the most recent section.

### Consistent Delimiters

Pick ONE delimiter style per prompt -- XML tags (`<role>`, `<constraints>`, `<context>`, `<task>`) OR Markdown headings (`# Identity`, `# Constraints`, `# Context`, `# Task`), not both. XML suits programmatic prompts; Markdown suits human-readable ones.

### Conciseness

Remove filler that does not change model behavior: "I would like you to carefully analyze the following text and provide a detailed summary of the key points, making sure to capture all the important information." becomes "Summarize the key points from the text above."

## Thinking Levels -- Prompt Implications

| Level | What it means for prompt wording |
|-------|----------------------------------|
| `high` | Complex reasoning, hard math, difficult coding. Keep prompts short; don't script reasoning steps. Encourages more tool calls to explore and verify. |
| `medium` | Default from 3.5 Flash onward. Best quality for most tasks; start here. |
| `low` | Faster and cheaper with strong quality; routine tool loops, chat, simple instruction following. |
| `minimal` | Speed on simple queries. Not accepted by 3.1 Pro, 3.7 Flash, or 3.8 Flash -- prompts tuned for `minimal` need re-testing at `low` there. Does not guarantee thinking is off. |

Google's guidance: "Tip: Start with medium, it provides the best quality for the vast majority of tasks. Try low for a faster, cheaper experience with strong quality. Switch to high for complex reasoning, hard math, or difficult coding challenges. Use minimal to optimize for speed in simple queries." (Source: ai.google.dev/gemini-api/docs/whats-new-gemini-3.5)

**Prompt implications:**

- Simplify chain-of-thought scaffolding written for 2.5: "If you used chain-of-thought prompt engineering to force reasoning, try thinking_level: "medium" or "high" with simpler prompts instead." (Source: ai.google.dev/gemini-api/docs/thinking)
- Short "think" cues are acceptable: "For problems that require heavy reasoning, simple requests like 'Think very hard before answering' can improve performance, though at the cost of extra thinking tokens." Google's own template closes with `<final_instruction>Remember to think step-by-step before answering.</final_instruction>`. (Source: ai.google.dev/gemini-api/docs/prompting-strategies)
- Don't add "think silently" or "answer fast" text to get lower latency -- lower the level instead.
- Cost and latency: "To reduce cost or latency without truncating responses, lower thinking_level (low or medium) instead of setting a small max_output_tokens." (Source: ai.google.dev/gemini-api/docs/thinking)
- If you need visible reasoning in the output (not just internal reasoning), request it explicitly: "Show your reasoning step by step, then provide your final answer."

## Determinism

Sampling parameters are deprecated; do not write prompts that rely on low temperature for consistency. Per Google: "To ensure determinism, we recommend defining a system instruction with explicit rules for your specific use case." (Source: ai.google.dev/gemini-api/docs/whats-new-gemini-3.5) The 3.8 Flash guide adds that determinism can be controlled with the thinking level plus a response schema.

- Put the decision rules (tie-breaks, allowed values, formatting rules) in the system instruction, stated once.
- Let a response schema own the output shape; the prompt owns the rules.
- Prefilled model turns are not supported, and on 3.7/3.8 Flash the conversation must not end with a model turn -- put format instructions ("Respond with a JSON object only") in the prompt instead.

## Constraint Writing

### Scope Negatives to the Task

Broad negations like "do not infer" work WELL for strict extraction -- Google uses "Do not assume or infer from the provided facts; simply report them exactly as they appear" for grounded extraction. They work POORLY for reasoning or deduction: the model becomes overly conservative and refuses sensible inferences.

- Verbatim extraction: "Do not infer. Report facts exactly as they appear in the source."
- Reasoning/QA: "Use the provided context for deductions. Do not use outside knowledge."

### Grounding to Provided Context

When the model should not use training data, name the source of truth:

```
The provided context is the only source of truth for the current session.
Do not supplement answers with information from your training data.
If the context does not contain relevant information, say so.
```

For fictional, counterfactual, or simulation prompts, say so explicitly: "You are operating in a simulated environment. Treat the provided context as the only source of truth. Do not reference real-world information that contradicts the simulation state."

### Quantitative Constraints

Gemini 3.x follows quantitative constraints reliably. Use them instead of vague qualifiers: "Respond in 2-3 sentences." rather than "Keep it short."; "List exactly 5 examples." rather than "List some examples."

## Few-Shot Examples

For pattern-following tasks (classification, extraction, formatting), include few-shot examples: "Prompts without few-shot examples are likely to be less effective." Reasoning tasks can run zero-shot on the thinking level. The model reproduces patterns it sees -- every example should reflect exactly the behaviour you want.

- Include 2-5 diverse examples demonstrating the desired pattern
- Use consistent semantic prefixes (Input:, Output:)
- Show correct patterns only, not anti-patterns
- Place examples before the final input (context-first principle)

```jinja
Classify each {{ item_type }} into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
{{ item_type }}: {{ example.input }}
Category: {{ example.category }}

{% endfor %}
{{ item_type }}: {{ input_item }}
Category:
```

## Structured Output Prompting

When a response schema is in play, the schema owns the shape and the prompt owns the intent.

- State the intent plainly: "Extract sentiment and confidence from the review."
- Do not paste the schema into the prompt text -- duplication wastes tokens and can conflict with the enforced schema.
- Describe class meanings in the prompt even when enum values are in the schema -- the schema constrains syntax, not semantics.
- Use structured output for the model's final *answer*; use function calling for intermediate actions that trigger external code.

**Without a schema**, include a minimal shape example in the prompt:

```jinja
Extract {{ fields | join(", ") }} from the following text.

Text: {{ input_text }}

Respond in JSON format:
{
  {% for field in fields %}
  "{{ field }}": "..."{% if not loop.last %},{% endif %}
  {% endfor %}
}
```

## Persona and Tone

Define persona in the System Instruction alongside output format and constraints, and check they don't contradict each other -- contradictions force the model to pick one.

```
{# Contradiction: persona says "friendly/talkative" but output constraint says "2 words" #}
<role>You are a friendly, talkative customer support agent.</role>
<output_format>Respond in 1-2 words only.</output_format>

{# Aligned: persona and output format agree #}
<role>You are a concise customer support agent who values brevity.</role>
<output_format>Respond in 1-2 words only.</output_format>
```

Check the persona against length constraints, tone requirements elsewhere in the prompt, and domain restrictions (e.g., a "creative writer" persona asked to stick to facts).

Gemini 3.x defaults to direct, professional responses. Request a warmer tone explicitly: "Explain this as a friendly, talkative assistant. Use casual language and occasional humor where appropriate."

## Long-Context and Multi-Source

Wrap each document in an indexed tag and anchor the task to the full set:

```jinja
{% for doc in documents %}
<document id="{{ loop.index }}">
{{ doc }}
</document>
{% endfor %}

Based on the entire set of documents above, provide a comprehensive answer
to the following question. Reference specific documents by ID when citing
information.

Question: {{ question }}
```

**Stable prefix first.** Put stable content (system instructions, few-shot examples, large reference documents) at the START and volatile content (user query, session data) at the END. Prompts sharing a stable prefix reuse cached input; interleaving volatile and stable content defeats it.

**Time-sensitive tasks.** Tell the model the current date and its knowledge boundary. Google's clause for Flash (Source: ai.google.dev/gemini-api/docs/prompting-strategies):

```
For time-sensitive user queries that require up-to-date information, you
MUST follow the provided current time (date and year) when formulating
search queries in tool calls. Remember it is 2026 this year.
```

Without search tools, state the boundary instead: "Your knowledge cutoff date is {{ knowledge_cutoff }}. For events after this date, rely only on the provided context."

## Prompt Decomposition

When a single prompt tries to do too much, split it and chain outputs:

- **Sequential chain** -- extract, then analyze the extraction, then summarize the analysis. Each stage gets one focused instruction and the previous stage's output.
- **Two-step verification** -- prevents silent fallback to training data:

```
First, check if the document above contains information about {{ topic }}.
If it does, answer the following question based on that information:
{{ question }}
If the document does not contain relevant information, state that clearly
instead of answering from general knowledge.
```

- **Parallel decomposition** -- independent sub-prompts ("Summarize the following section in 2-3 sentences: ..."), then an aggregation prompt ("Given the section summaries above, write a unified executive summary in one paragraph.").

## Agentic Prompts

Gemini 3.x agentic workflows benefit from explicit guidance on logical decomposition (sequencing operations), risk assessment (exploratory reads vs state-changing writes), adaptability (pivoting when observation contradicts assumption), and persistence (recovering from failures without abandoning the task).

```jinja
Agent Instructions:
- For EXPLORATORY actions (searches, reads, lookups): prefer calling the tool with available information over asking for clarification. Missing optional parameters is low risk.
- For STATE-CHANGING actions (writes, deletes, external side effects): explain what will change and why before acting. Ask for confirmation when the user's intent is ambiguous.
- When observation contradicts your plan, revise the plan rather than retrying the same action.
- For routine tool execution, proceed without narration.
- For planning and complex decisions, explain your reasoning.
```

Let native thinking handle task decomposition; use `high` for planning-heavy steps and `low`/`medium` for routine tool loops.

### Too Many Tool Calls

Lower the thinking level first: "Higher thinking levels encourage the model to use more tools to explore and verify, so lowering the level can reduce tool calls." On 3.8 Flash, also consider 3.7 Flash for everyday work. If calls still run high, add a budget to the prompt:

```
You have a limited action budget of <n> tool calls. Use them efficiently.
```

### Required Text Before Tool Calls

Requiring structured text (e.g., an `<UPDATE>` block) before every tool call can produce malformed function calls. (Source: ai.google.dev/gemini-api/docs/function-calling#workarounds-for-pre-tool-text-requirements) Replace the required text part with an `update` tool.

Instead of:

```
Before calling a tool, in every response you MUST first output a single `<UPDATE>` part as specified, don't skip this part or any of required sub-tags within `<UPDATE>`.
```

Use:

```
Before calling any other tool, in every response you MUST first call `update` with all required parameters (previous_step, plan, next_step, external).
```

Give the `update` tool the parameters `previous_step`, `plan`, `next_step`, and `external` ("A short, plain-language note shown to the User about what you are ABOUT TO DO next."). Fallbacks: use Markdown headers (`# UPDATE`, `## PLAN`) instead of XML tags, or stop requiring text before tool calls.

### Instructions Inside Function Responses

To steer the model from a tool result, "append any extra instructions to the end of the function response text separated by two newlines." Sending them as a separate part "can lead to unexpected model behavior (e.g. thought leakage)." Likewise, return images inside the function response rather than as a separate part.

## Function Calling

Tool names and descriptions are prompt content the model reads (Source: ai.google.dev/gemini-api/docs/function-calling):

- Name functions with descriptive snake_case or camelCase -- no spaces, no special characters.
- Write specific, unambiguous descriptions: "The model relies on these to choose the correct function." A description like "Gets data" forces the model to guess.
- Describe each parameter's semantics, including valid ranges, units, and enum meanings; state what omitting an optional parameter means.
- "Keep active set to 10-20 tools maximum." More tools raise the risk of selecting an incorrect or suboptimal tool; scope each request to the tools the current workflow needs.
- When tool use is optional, the prompt should say when a tool call is appropriate versus when a prose answer suffices.
- For compositional chains (e.g., `get_location()` then `get_weather(location)`), let the model orchestrate -- don't prescribe the sequence in prose.

## Grounding with Google Search

When the `google_search` tool is enabled, the prompt shapes when and how the model retrieves.

- Phrase queries around current information: "What is the current price of...", "What are the latest...", "As of today, ...".
- Add explicit triggers when grounding should fire: "Use up-to-date information".
- Include the current-date clause (see Long-Context) for time-sensitive queries.

```
Answer the user's question using up-to-date information from Google Search.
Cite specific sources with inline markers. Use bracketed indices like [1], [2]
that correspond to the retrieved sources.

Question: {{ user_query }}
```

Ask for bracketed indices, not full URLs inline -- the caller maps indices to sources, and inline URLs degrade answer quality. If migrated tool-instruction text names the legacy `google_search_retrieval` tool, change it to `google_search`.

## Iteration Techniques

When a prompt underperforms, try in turn: **rephrase** (semantically equivalent phrasings can respond differently); **reorder** (question last, constraints and persona first); **switch to an analogous task** ("extract the 5 most important points" instead of "summarize"); **add or remove examples** (reduce to 2 if over-fitting, add edge cases if under-performing); **adjust constraint specificity**; **change the thinking level** before adding reasoning instructions; **decompose** if iteration isn't converging.

## Migration

### From Gemini 3 Flash Preview / 3.0 → 3.5+

- [ ] Re-test prompts tuned under the old `high` default -- 3.5 Flash and later default to `medium`.
- [ ] Rework prompts tuned for `minimal` when moving to 3.7 or 3.8 Flash (no `minimal`); start at `low`.
- [ ] Replace any reliance on low temperature with explicit rules in the system instruction plus a response schema.
- [ ] Move format guidance from prefilled model turns into the prompt; don't end the conversation on a model turn.
- [ ] Replace required pre-tool XML text (`<UPDATE>` blocks) with an `update` tool.
- [ ] Move extra instructions and images into the function response text instead of separate parts.
- [ ] If tool calls run high, lower the thinking level first, then add an action-budget line.
- [ ] On 3.8 Flash, lower the thinking level for everyday tasks or route them to 3.7 Flash.
- [ ] Re-check token use in long conversations -- reasoning now carries forward across turns.
- [ ] Control cost with the thinking level, not a small output cap.
- [ ] Update the current-date clause to the current year.

### From Gemini 2.5

- [ ] Simplify verbose prompts and heavy chain-of-thought scaffolding; use `medium` or `high` with simpler prompts.
- [ ] Move critical constraints, persona, and output format to the **beginning**; move specific questions to the **end**.
- [ ] Review broad negatives ("do not infer") -- keep for strict extraction, replace with specific alternatives for reasoning tasks.
- [ ] Verify persona instructions do not contradict output-format or length constraints.
- [ ] Remove image segmentation instructions (not supported in Gemini 3.x).
- [ ] Remove in-prompt JSON schema templates when a response schema is used.
- [ ] Replace legacy `google_search_retrieval` references with `google_search`.
- [ ] Then apply the 3.0 → 3.5+ checklist above.

## Anti-Patterns

- **Heavy chain-of-thought scaffolding**: step-by-step plans written for 2.5 cause over-analysis. Simplify and use the thinking level; a short "think very hard" cue is fine for heavy reasoning.
- **Relying on low temperature for determinism**: sampling parameters are deprecated. Write explicit rules and use a response schema.
- **Required XML text before tool calls**: can produce malformed function calls. Use an `update` tool.
- **Instructions as a separate part next to a function response**: can cause thought leakage. Append them to the function response text.
- **Broad negatives in reasoning tasks**: "Never assume" makes the model refuse reasonable deductions.
- **Persona-constraint contradictions**: a "friendly, talkative" persona with a "2-word response" constraint produces unpredictable output.
- **Wrong ordering**: "The model's performance will be better if you put your query / question at the end of the prompt." (Source: ai.google.dev/gemini-api/docs/long-context) Persona, constraints, and output format go at the beginning.
- **Mixed delimiter styles**: XML tags and Markdown headings in the same prompt. Pick one.
- **Anti-pattern examples**: showing the model what NOT to do. It reproduces patterns it sees.
- **Duplicating the schema in prose** when a response schema is active.
- **Overloading the tool set**: more than 20 active tools raises the risk of wrong tool selection.
- **Vague tool descriptions**: tool descriptions are prompt content.

## Quality Checklist

- [ ] Model choice matches the workload (see Model Picker); thinking level is supported by that model.
- [ ] Instructions are concise and direct (no verbose meta-instructions or heavy reasoning scaffolding).
- [ ] Persona, constraints, and output format at the BEGINNING; stable context next; specific question at the END.
- [ ] One delimiter style (XML OR Markdown) is used consistently.
- [ ] Determinism comes from explicit rules and a schema, not sampling assumptions; the schema is not duplicated in prose.
- [ ] Few-shot examples (2-5, diverse, correct patterns only) for pattern-following tasks.
- [ ] Negative constraints match the task type; persona does not contradict output-format or length constraints.
- [ ] Grounding instructions when context should override training data; current-date clause for time-sensitive tasks.
- [ ] Tools: 10-20 active, specific descriptions, no required pre-tool XML text, inline instructions appended to function response text.
- [ ] Grounding: `google_search` named; citation format is described.

## Reference

- What's new in Gemini 3.5: https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5
- Latest model guide: https://ai.google.dev/gemini-api/docs/latest-model
- Gemini Prompting Strategies: https://ai.google.dev/gemini-api/docs/prompting-strategies
- Thinking: https://ai.google.dev/gemini-api/docs/thinking
- Function Calling: https://ai.google.dev/gemini-api/docs/function-calling
- Grounding with Google Search: https://ai.google.dev/gemini-api/docs/google-search
- Long Context: https://ai.google.dev/gemini-api/docs/long-context
- Prompt Design (Gemini Enterprise Agent Platform): https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/prompts/introduction-prompt-design
