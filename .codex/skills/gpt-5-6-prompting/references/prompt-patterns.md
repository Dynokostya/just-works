# GPT-5.6 prompt patterns

## 1. Minimal task prompt

```text
Goal
Determine whether [proposal] should proceed.

Context
[Only the facts and materials required for the decision.]

Requirements
Evaluate [criteria]. Distinguish verified facts from assumptions. Cite the evidence used. Do not invent unavailable measurements.

Success criteria
Give a clear go/no-go verdict, the decisive reasons, material uncertainty, and the smallest next test that would change the decision.

Output
Verdict, evidence, risks, recommendation.
```

Use this for analysis, research, and decision support. Remove headings when a compact paragraph communicates the same contract.

## 2. Legacy prompt migration example

### Before

```text
You are a world-class senior expert. Think step by step and be extremely thorough but concise. Never hallucinate. Double-check everything multiple times. Do not stop until the task is perfectly complete. Always use all available tools. Ask permission before doing anything. Return a detailed answer but use minimal text.

Analyze the attached migration plan and identify risks.
```

### After

```text
Review the attached migration plan for failure modes that could cause data loss or extended downtime.

For each finding, cite the relevant plan step, estimate impact and likelihood, and recommend a specific mitigation. Distinguish confirmed risks from assumptions. Return the five most important risks in severity order.

Inspect the provided material without asking first. Do not modify files or external systems.
```

Why it is better:

- Replaces generic expertise and hidden-reasoning commands with a measurable outcome.
- Removes contradictory “extremely thorough” and “minimal text” instructions.
- Replaces “use all tools” with the actual authorization boundary.
- Defines evidence, ranking, and completeness.

## 3. Replace generic brevity

Avoid:

```text
Be concise. Keep it short. Use minimal text.
```

Prefer:

```text
Lead with the conclusion. Keep all required findings, evidence, caveats, and next steps. Trim introductions, repetition, generic reassurance, and optional background first.
```

## 4. Compact action policy

```text
For requests to answer, explain, review, diagnose, or plan, inspect relevant materials and report the result. Do not implement changes unless requested.

For requests to change, build, or fix, make the requested in-scope local changes and run relevant non-destructive validation without asking first.

Require confirmation for external writes, destructive actions, purchases, or material scope expansion.
```

Adapt this policy to the actual environment. Delete branches the workflow cannot perform.

## 5. Tool description pattern

```text
Tool: lookup_order
Use when an order id is available and current order status is required.
Input: order_id string.
Returns: status enum, updated_at ISO timestamp, shipment object or null, error_code or null.
Do not call for product discovery or customer identity lookup.
```

Document behavior that affects routing. Do not explain obvious implementation details.

## 6. Production migration evaluation

Build a representative set containing:

- Routine happy paths.
- Ambiguous inputs.
- Missing-data cases.
- Long-context cases.
- Tool failures and empty results.
- Requests near permission boundaries.
- Cases where the complete output is longer than the model's default response.

For original and candidate prompts, record:

```text
case_id
success (0/1)
required_fields_present (0/1)
evidence_correct (0/1)
permission_compliant (0/1)
tool_route_correct (0/1)
input_tokens
output_tokens
latency_ms
cost
unnecessary_tool_calls
repeated_validation_count
```

Adopt the candidate only when quality is non-inferior on critical cases and the efficiency gain is meaningful. Do not average away failures on safety, permissions, or required output fields.

## 7. Runtime recommendation pattern

```text
Model: [sol/terra/luna, after verifying current official availability]
Reasoning effort: [baseline and candidate]
Reasoning mode: [standard/pro]
Reasoning context: [auto/current_turn/all_turns]
Tools exposed: [only relevant tools]
Evaluation: [representative task set and acceptance threshold]
```

Explain each non-default choice in one sentence. Do not recommend the maximum setting merely because it exists.
