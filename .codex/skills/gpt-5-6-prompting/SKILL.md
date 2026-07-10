---
name: gpt-5-6-prompting
description: create, migrate, audit, and debug prompts for the gpt-5.6 model family. use when a user wants to rewrite a legacy system prompt, reduce prompt bloat, design task instructions or tool descriptions, choose reasoning effort or pro mode, define autonomy and approval boundaries, or build an evaluation plan for a gpt-5.6 migration. also use when a prompt becomes too terse, over-explores, repeats validation, asks unnecessary permission questions, misuses tools, or omits required output after instructions such as "be concise."
---

# GPT-5.6 Prompting

## Purpose

Produce the smallest prompt that reliably satisfies the task. Preserve requirements that affect correctness, safety, permissions, evidence, or output compatibility; remove legacy ceremony that merely restates behavior GPT-5.6 already performs.

Treat prompt optimization as an evaluation-driven tuning pass, not a model-name replacement or a contest to delete the most words.

## Workflow

1. Classify the request:
   - **Create**: turn a goal or rough notes into a GPT-5.6 prompt.
   - **Migrate**: rewrite an existing prompt from another model or an older harness.
   - **Audit**: identify contradictions, duplication, over-constraint, missing boundaries, or likely failure modes.
   - **Configure**: recommend model, reasoning effort, reasoning mode, reasoning context, and tool exposure.
   - **Evaluate**: define representative cases and measurable acceptance criteria.

2. Extract the behavioral contract before editing:
   - Goal and user-visible outcome.
   - Relevant context and source material.
   - Non-negotiable constraints, safety rules, and domain rules.
   - Required evidence, verification, or citations.
   - Autonomy, approval, write, and destructive-action boundaries.
   - Available tools and when each tool should be used.
   - Success criteria and output format.

3. Remove instructions that do not change the behavioral contract:
   - Inflated expert personas without a product requirement.
   - Repeated goals, warnings, prohibitions, or formatting rules.
   - Generic commands to be intelligent, careful, thorough, honest, or to think harder.
   - Generic brevity commands such as “be concise,” “keep it short,” or “use minimal text.”
   - Requests to enable pro mode, expose hidden reasoning, or simulate internal reasoning settings inside the prompt.
   - Exhaustive step-by-step methods when only the outcome and constraints matter.
   - Examples that duplicate rules instead of resolving a demonstrated ambiguity.
   - Global response templates applied to unrelated tasks.
   - Tools and verbose tool descriptions irrelevant to the current task.

4. Preserve or add instructions when they materially control behavior:
   - Exact schemas, compatibility requirements, or downstream parsing constraints.
   - Product-specific style, terminology, audience, or compliance language.
   - Evidence requirements and definitions of acceptable sources.
   - Permission boundaries and confirmation requirements for external writes, destructive actions, purchases, or scope expansion.
   - Tool-selection rules that distinguish direct calls from bounded programmatic processing.
   - Retry, concurrency, stopping, and failure-reporting limits when tools are involved.
   - Acceptance criteria that can be checked on representative tasks.

5. Rewrite using this lightweight order when applicable:

```text
Goal
[Describe the required outcome.]

Context
[Include only facts the model needs to perform the task.]

Requirements
[State correctness, evidence, safety, and domain constraints.]

Actions and tools
[Define authorized actions, approval boundaries, relevant tools, and stopping rules.]

Success criteria
[State what a correct result must contain or accomplish.]

Output
[Specify only the task-specific structure or machine-readable schema required.]
```

Do not force every heading into simple prompts. A direct paragraph or short list is often better.

6. Validate the rewrite:
   - Every remaining instruction should change correctness, safety, permissions, evidence, or output compatibility.
   - Remove contradictions and duplicated constraints.
   - Prefer positive prioritization over generic compression. For example: “Keep all required findings and caveats; trim introductions, repetition, and optional background first.”
   - Keep task-specific structure lightweight.
   - Expose only relevant tools and keep descriptions precise about inputs, outputs, and errors.
   - Do not sacrifice a complete requested artifact merely to reduce tokens.
   - Do not claim improvement without an evaluation or clearly label it as a recommendation.

## Runtime recommendations

When recommending current GPT-5.6 API settings or making claims about official guidance, verify the live official OpenAI documentation when web access is available, because model aliases, parameters, and billing can change.

Apply these defaults unless the workload indicates otherwise:

- Preserve the current reasoning effort as the migration baseline, then test one level lower.
- Use `low` for latency-sensitive work, `medium` as a balanced starting point, and higher efforts only when representative evaluations show a meaningful gain.
- Recommend `reasoning.mode: "pro"` only for difficult, high-value work where marginal reliability matters more than latency and token usage.
- Configure pro mode in the API request, never by telling the model to “use pro mode” or “think harder” in the prompt.
- Treat reasoning mode and reasoning effort as independent settings.
- Use persisted reasoning only when prior goals, assumptions, and decisions remain relevant.
- Use Programmatic Tool Calling only for bounded filtering, joining, ranking, deduplication, aggregation, or validation with a known output schema. Keep judgment-dependent steps as direct model/tool interaction.

## Output patterns

### Create

Return:

1. **Recommended prompt**: ready to paste.
2. **Assumptions**: only unresolved assumptions that materially affect behavior.
3. **Runtime suggestion**: only when model settings or tools are relevant.

### Migrate

Return:

1. **Verdict**: the main problem with the existing prompt.
2. **Optimized prompt**: ready to paste, preserving necessary placeholders and variables.
3. **Material changes**: explain only consequential removals, additions, or semantic changes.
4. **Runtime recommendation**: model family member, reasoning settings, context, and tool exposure when relevant.
5. **Evaluation plan**: include for production prompts or when the user asks whether the rewrite is better.

### Audit

Return findings in severity order. For each finding, identify the exact instruction, explain the likely failure mode, and give the smallest corrective change. Provide a full rewritten prompt when the user asks for a usable replacement.

### Evaluate

Compare the original and candidate prompt on representative tasks. Measure:

- Task success and required-field completeness.
- Factual or evidence correctness.
- Policy and permission compliance.
- Tool-selection consistency.
- Total input/output tokens and accumulated context.
- Latency and cost.
- Unnecessary calls, repeated validation, and permission checks.

Prefer the smallest prompt that meets the same quality bar. Fewer tokens or calls are not improvements when the final answer becomes incomplete.
