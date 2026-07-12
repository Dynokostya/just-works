# Official GPT-5.6 guidance

Source of truth: OpenAI, “Model guidance: Using GPT-5.6”

- URL: https://developers.openai.com/api/docs/guides/latest-model
- Retrieved: 2026-07-10
- Treat this file as a compact snapshot. Verify the live official documentation before making claims about current model availability, parameters, prices, billing, or limits.

## Model and migration

- The `gpt-5.6` alias routes to `gpt-5.6-sol` in the documented release.
- `gpt-5.6-sol` targets flagship capability, `gpt-5.6-terra` balances capability and cost, and `gpt-5.6-luna` targets efficient high-volume workloads.
- Treat migration as a tuning pass, not merely a model-slug change.
- Start with the current GPT-5.5 or GPT-5.4 reasoning effort, then test the same setting and one level lower on representative tasks.
- Use the Responses API for reasoning, tool-calling, and multi-turn workflows.

## Prompt length

OpenAI reports that, in internal evaluations, replacing long explicit system prompts with minimal prompts improved scores by roughly 10–15%, reduced total tokens by 41–66%, and reduced cost by 33–67%.

The documented mechanism is not “shorter is always better.” The gains came from removing redundant instructions and examples, simplifying tool descriptions, exposing fewer irrelevant tools, and avoiding stale accumulated context. Add instructions only when evaluations reveal a specific gap.

## Brevity and structure

- GPT-5.6 is already biased toward shorter answers.
- Generic instructions such as “be concise,” “keep it short,” or “use minimal text” can cause the model to omit a complete requested artifact.
- Prefer prioritization: preserve required facts, decisions, caveats, and next steps; trim introductions, repetition, reassurance, and optional background first.
- Use lightweight task-specific structure rather than a global response template.
- Use concrete interpersonal guidance such as “be direct and tactful” instead of broad commands to be warm or empathetic.

## Autonomy and permissions

Define action boundaries compactly:

- Answer, explain, review, diagnose, or plan: inspect relevant material and report results; do not implement unless requested.
- Change, build, or fix: make requested in-scope local changes and run relevant non-destructive validation without asking first.
- Require confirmation for external writes, destructive actions, purchases, or material scope expansion.

Avoid repeating approval warnings throughout the prompt because repetition can trigger unnecessary permission checks.

## Reasoning effort and pro mode

Documented reasoning efforts: `none`, `low`, `medium`, `high`, `xhigh`, and `max`.

- `medium` is a balanced starting point.
- `low` is suitable for latency-sensitive work.
- Use higher levels only when measured quality gains justify them.
- Reserve `max` for the hardest quality-first workloads and compare it with `xhigh`.

Pro mode:

- Enable with `reasoning.mode: "pro"` on the selected GPT-5.6 model.
- Pro mode is not a separate model slug.
- Reasoning mode and reasoning effort are independent.
- Use pro mode when marginal quality or reliability materially affects a difficult, high-value outcome.
- Prefer standard mode for routine, latency-sensitive, or high-volume work.
- Prompt for the task, not the mode. Do not write “think harder,” “use pro mode,” or request multiple hidden candidate answers.

## Tools

- Expose only task-relevant tools.
- Keep tool descriptions concise and precise.
- Describe expected return fields, types, and error behavior when the model must route or process tool outputs.
- Use Programmatic Tool Calling for bounded processing such as filtering, joining, ranking, deduplication, aggregation, or validation.
- Do not select Programmatic Tool Calling merely because there are multiple calls. Prefer direct calls when intermediate outputs are small, each result affects the next decision, approval is required, or citations/native artifacts must be preserved.

## Evaluation

Benchmark on representative tasks and compare:

- Task success.
- Final-answer completeness.
- Required evidence.
- Total tokens.
- Latency.
- Cost.

Treat fewer calls, turns, or intermediate outputs as improvements only when the final user-visible result still meets the quality bar.
