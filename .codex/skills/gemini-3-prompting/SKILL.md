---
name: gemini-3-prompting
description: Apply when creating or editing prompts targeting Gemini 3. Covers three-layer prompt organization, context-first pattern, constraint placement, thinking_level awareness, few-shot examples, persona conflicts, long-context grounding, prompt decomposition, and migration from Gemini 2.5.
---

# Gemini 3 Prompting

## When to Use

- Creating or editing system prompts targeting Gemini 3
- Writing few-shot examples for classification or extraction tasks
- Structuring long-context prompts with multiple sources
- Writing agentic instructions for Gemini 3 tool-use workflows
- Decomposing complex prompts into chainable sub-prompts
- Migrating prompt text from Gemini 2.5

## Overview

Gemini 3 responds best to direct, concise instructions. Verbose prompt engineering techniques from older models (Gemini 2.5 and earlier) cause over-analysis and degrade output quality. The model has native thinking capabilities controlled by a `thinking_level` parameter -- do not write manual chain-of-thought instructions.

<context>
Key characteristics to design around:

- **Conciseness Over Verbosity**: Direct prompts outperform over-specified ones. Remove filler instructions and meta-commentary.
- **Context-First Anchoring**: The model anchors reasoning on what it read most recently. Place source material before instructions.
- **End-Loaded Constraints**: Critical restrictions placed at the END of the prompt are followed most reliably.
- **Native Thinking**: The `thinking_level` parameter (high/low/medium/minimal) replaces manual CoT prompting -- do not write "Let's think step by step."
- **Temperature Stays at 1.0**: Lowering temperature causes looping and degraded reasoning. Write prompts assuming temperature=1.0.
- **Persona Adherence**: The model takes assigned personas seriously and may ignore other instructions to maintain persona. Review potential conflicts.
- **Default Directness**: Gemini 3 defaults to efficient, direct responses. Request conversational tone explicitly if needed.
</context>

## Core Prompt Structure

### Three-Layer Organization

Gemini 3 prompts perform best with a three-layer structure. Place critical constraints at the end -- the model weights final instructions most heavily.

**Layer 1 -- Context and source material:**
```
<context>
{{ source_documents }}
</context>
```

**Layer 2 -- Main task instructions:**
```
Based on the information above, {{ task_instruction }}.
```

**Layer 3 -- Negative, formatting, and quantitative constraints:**
```
Constraints:
- Respond in {{ output_format }} format.
- Do not include information from outside the provided context.
- Limit your response to {{ max_items }} items.
```

Full template:

```jinja
{# Three-layer Gemini 3 prompt #}
<context>
{{ context_data }}
</context>

{{ main_instruction }}

Constraints:
- Respond in {{ output_format }} format.
{% for constraint in constraints %}
- {{ constraint }}
{% endfor %}
```

### Context-First Principle

Place large context blocks (documents, data, conversation history) before your questions and instructions. Use bridging phrases to connect context to the task:

```
Based on the information above, ...
Using only the provided documents, ...
Given the context above, ...
Based on the entire document above, provide a comprehensive answer to: ...
```

The last phrasing is especially effective when synthesizing from multiple sources -- it anchors the model to the full input rather than just the most recent section.

### Conciseness

Remove filler that does not change model behavior:

```
Before: "I would like you to carefully analyze the following text and provide
         a detailed summary of the key points, making sure to capture all the
         important information."

After:  "Summarize the key points from the text above."
```

## Thinking and Reasoning

The `thinking_level` parameter controls how deeply the model reasons. It replaces manual chain-of-thought prompting entirely.

| Level | Availability | Use Case |
|-------|-------------|----------|
| `high` (default) | All models | Complex reasoning, analysis, math, multi-step problems |
| `low` | All models | Simple tasks where latency matters |
| `medium` | Flash only | Balanced approach for moderate complexity |
| `minimal` | Flash only | Chat, quick Q&A |

**Prompt implications:**

- Remove "Let's think step by step", "Think carefully", and similar CoT triggers from all prompts.
- If you need visible reasoning steps in the output (not just internal reasoning), request it explicitly:

```
Analyze this data. Show your reasoning step by step, then provide your final answer.
```

- For lower latency, combine `thinking_level: low` with the system instruction "think silently" -- this reduces visible reasoning overhead while keeping basic internal reasoning active.

## Constraint Writing

### Avoid Overly Broad Negatives

Broad negations like "do not infer" or "do not assume" cause the model to become overly conservative and refuse reasonable deductions.

```
Avoid:   "Do not infer any information."

Better:  "Use the provided additional information or context for deductions
          and avoid using outside knowledge."

Avoid:   "Never make assumptions."

Better:  "When the document does not address a topic, state that the
          information is not available rather than speculating."
```

### Grounding to Provided Context

When the model should not use training data, be explicit about the source of truth:

```
The provided context is the only source of truth for the current session.
Do not supplement answers with information from your training data.
If the context does not contain relevant information, say so.
```

This is particularly important for hypothetical scenarios, fictional settings, or domain-specific data that contradicts general knowledge.

### Quantitative Constraints

Gemini 3 follows quantitative constraints reliably. Use them instead of vague qualifiers:

```
Avoid:   "Keep it short."
Better:  "Respond in 2-3 sentences."

Avoid:   "List some examples."
Better:  "List exactly 5 examples."
```

## Few-Shot Examples

Few-shot examples remain effective for classification, extraction, and formatting tasks. The model reproduces patterns it sees -- every example should reflect exactly the behavior you want.

- Include 2-5 diverse examples demonstrating the desired pattern
- Use consistent semantic prefixes (Input:, Output:)
- Show correct patterns only, not anti-patterns
- Place examples before the final input (context-first principle)

```jinja
{% for example in few_shot_examples %}
Input: {{ example.input }}
Output: {{ example.output }}

{% endfor %}
Input: {{ current_input }}
Output:
```

For classification with structured output:

```jinja
Classify each message into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
Message: {{ example.message }}
Category: {{ example.category }}
Confidence: {{ example.confidence }}

{% endfor %}
Message: {{ input_message }}
Category:
```

## Persona and Tone

### Persona Conflicts

Gemini 3 takes assigned personas seriously and may prioritize persona adherence over other instructions. Before assigning a persona, check for conflicts:

```
{# Potential conflict: persona says "be friendly" but constraints say "be terse" #}
You are a friendly customer support agent.
...
Respond in 1-2 words only.

{# Resolution: align persona with constraints #}
You are a concise customer support agent who values brevity.
...
Respond in 1-2 words only.
```

Review potential conflicts between the persona description and:
- Output length constraints
- Tone requirements elsewhere in the prompt
- Domain restrictions (e.g., a "creative writer" persona asked to stick to facts)

### Conversational Tone

Gemini 3 defaults to direct, efficient responses. If you need a warmer or more conversational tone, request it explicitly:

```
Explain this as a friendly, talkative assistant. Use casual language
and occasional humor where appropriate.
```

Without this, responses will be professional and to-the-point.

## Long-Context and Multi-Source

### Multi-Source Synthesis

When the prompt includes multiple documents or data sources, anchor the model to the full input:

```jinja
<document id="1">
{{ document_1 }}
</document>

<document id="2">
{{ document_2 }}
</document>

{% if documents|length > 2 %}
{% for doc in documents[2:] %}
<document id="{{ loop.index + 2 }}">
{{ doc }}
</document>

{% endfor %}
{% endif %}

Based on the entire set of documents above, provide a comprehensive answer
to the following question. Reference specific documents by ID when citing
information.

Question: {{ question }}
```

### Knowledge Cutoff Declaration

When the model needs to be aware of its knowledge boundaries, include the cutoff in system instructions:

```
Your knowledge cutoff date is January 2025. For events or information
after this date, rely only on the provided context.
```

### Grounding Hypothetical Scenarios

For fictional, counterfactual, or simulation-based prompts, establish the context as the sole source of truth:

```
You are operating in a simulated environment. The provided context describes
the current state of this environment. Treat it as the only source of truth.
Do not reference real-world information that contradicts the simulation state.
```

## Prompt Decomposition

### Breaking Complex Prompts

When a single prompt tries to do too much, split it into focused sub-prompts and chain outputs:

```
{# Instead of one massive prompt, decompose into stages #}

Stage 1 -- Extract:
"Extract all dates, names, and monetary amounts from the contract above.
Respond in JSON format."

Stage 2 -- Analyze (receives Stage 1 output):
"Given the extracted data above, identify any clauses where the effective
date is more than 90 days from the signing date."

Stage 3 -- Summarize (receives Stage 2 output):
"Summarize the flagged clauses in plain language for a non-legal audience."
```

### Two-Step Verification Pattern

When the model might lack information or the context might not contain what you need, split into verification then generation:

```
First, check if the document above contains information about {{ topic }}.
If it does, answer the following question based on that information:
{{ question }}
If the document does not contain relevant information, state that clearly
instead of answering from general knowledge.
```

This prevents the model from silently falling back to training data when the context is incomplete.

### Parallel Decomposition

For tasks that can be answered independently, structure sub-prompts for parallel execution and aggregation:

```jinja
{# Run these as parallel calls, then aggregate #}
{% for section in document_sections %}
Prompt {{ loop.index }}:
"Summarize the following section in 2-3 sentences:
{{ section }}"
{% endfor %}

Aggregation prompt:
"Given the section summaries above, write a unified executive summary
in one paragraph."
```

## Agentic Prompts

For Gemini 3 in agentic workflows with tool access:

```jinja
Agent Instructions:
- When encountering ambiguity, ask for clarification rather than assuming.
- Before taking state-changing actions, explain what will change and why.
- When multiple approaches exist, evaluate trade-offs before choosing.
- For routine tool execution, proceed without narration.
- For planning and complex decisions, explain your reasoning.
```

Key considerations:

- Use `thinking_level: high` for planning and complex decisions, `low` for routine tool execution.
- Specify when to assume vs. request clarification -- without guidance, the model tends to assume.
- Distinguish exploratory actions (safe to take) from state-changing actions (explain first).
- Let the model's native thinking handle task decomposition; avoid over-prescribing steps.

## Common Patterns

### Classification Task

```jinja
Classify the following {{ item_type }} into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
{{ item_type }}: {{ example.input }}
Category: {{ example.category }}

{% endfor %}

{{ item_type }}: {{ input_item }}
Category:
```

### Extraction Task

```jinja
Extract {{ fields | join(", ") }} from the following text.

Text: {{ input_text }}

Respond in JSON format:
{
  {% for field in fields %}
  "{{ field }}": "..."{% if not loop.last %},{% endif %}
  {% endfor %}
}

JSON:
```

### Reasoning Task

Set `thinking_level: high` and keep the prompt simple:

```jinja
{{ question }}

Provide your analysis and final answer.
```

If you need visible reasoning in the output:

```jinja
{{ question }}

Show your reasoning step by step, then provide your final answer.
```

### Tool-Augmented Task

```jinja
You have access to the following tools:
{% for tool in tools %}
- {{ tool.name }}: {{ tool.description }}
{% endfor %}

{{ task_description }}

Respond in JSON format:
{
  "answer": "...",
  "sources": ["..."],
  "confidence": 0.0-1.0
}
```

## Iteration Techniques

When a prompt is not producing the desired output, try these approaches in order:

1. **Rephrase differently**: Use different wording for the same instruction. Gemini 3 can respond differently to semantically equivalent phrasings.

2. **Reorder content**: Move the most important instruction to the end of the prompt (end-loaded constraints are weighted more heavily).

3. **Switch to an analogous task**: If "summarize this document" gives poor results, try "extract the 5 most important points from this document" -- a related but differently framed task.

4. **Add or remove examples**: If the model is over-fitting to examples, reduce to 2. If it is under-performing, add examples that cover edge cases.

5. **Adjust constraint specificity**: Replace vague constraints with quantitative ones, or loosen overly tight constraints that prevent good output.

6. **Decompose**: If iteration is not converging, the prompt may be too complex. Split into sub-prompts (see Prompt Decomposition section).

## Migration from Gemini 2.5

Prompt-level changes when migrating from Gemini 2.5 to Gemini 3:

- [ ] Remove manual CoT instructions ("Let's think step by step", "Think carefully before answering") -- set the `thinking_level` parameter instead
- [ ] Remove `temperature` overrides below 1.0 -- Gemini 3 requires temperature=1.0
- [ ] Simplify verbose prompts -- Gemini 3 handles concise instructions better than over-specified ones
- [ ] Move critical constraints to the end of the prompt (three-layer pattern)
- [ ] Replace broad negatives ("do not infer") with specific alternatives
- [ ] Test persona instructions for conflicts with other constraints
- [ ] Remove image segmentation instructions (not supported in Gemini 3)

## Anti-Patterns

- **Manual chain-of-thought**: "Let's think step by step" degrades output when `thinking_level` is active. Remove it.
- **Temperature below 1.0**: Causes looping and degraded reasoning. Always use 1.0.
- **Broad negatives**: "Do not infer" or "Never assume" makes the model refuse reasonable deductions. Use specific alternatives.
- **Persona-constraint conflicts**: A "friendly, verbose" persona with a "respond in 2 words" constraint. The model will prioritize persona.
- **Context after instructions**: Placing source material after the question weakens grounding. Context goes first.
- **Mixed delimiter styles**: Using both XML tags and triple backticks for structural sections in the same prompt. Pick one style.
- **Over-specified prompts**: Long meta-instructions about how to approach the task. Keep prompts focused on what to do, not how to think.
- **Anti-pattern examples**: Showing the model what NOT to do. It reproduces patterns it sees, including bad ones.
- **Missing output format**: Not specifying expected response structure (JSON, list, table). Always define the format.

## Quality Checklist

- [ ] Instructions are concise and direct (no verbose meta-instructions)
- [ ] Three-layer structure: context, then instructions, then constraints at the end
- [ ] Context is placed before questions/instructions
- [ ] Response format is explicitly defined
- [ ] Few-shot examples are included where appropriate (2-5 examples)
- [ ] Examples show only correct patterns, not anti-patterns
- [ ] No manual CoT instructions ("think step by step") -- use `thinking_level` parameter
- [ ] No temperature overrides below 1.0
- [ ] Negative constraints are specific, not broad ("use provided context" instead of "do not infer")
- [ ] Persona instructions do not conflict with other constraints
- [ ] Grounding instructions are included when context should override training data
- [ ] Complex prompts are decomposed into chainable sub-prompts where needed

## Reference

- Official Gemini 3 Documentation: https://ai.google.dev/gemini-api/docs/gemini-3
- Gemini Prompting Guide: https://ai.google.dev/gemini-api/docs/prompting-strategies
