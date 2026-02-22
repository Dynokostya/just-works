---
name: claude-opus-4-6-prompting
description: Apply when creating or editing prompts targeting Claude Opus 4.6. Covers adaptive thinking, XML tag structure, language softening, behavioral tuning, over-engineering prevention, tool overtriggering mitigation, and prompt migration.
---

# Claude Opus 4.6 Prompting

## When to Use

- Creating or editing system prompts targeting Claude Opus 4.6
- Tuning tool usage, autonomy, and safety guardrails in prompts
- Adjusting prompt language to match Opus 4.6's sensitivity
- Migrating prompt text from older Claude models

## Overview

Claude Opus 4.6 is Anthropic's most capable frontier model. It is more responsive to system prompts, more autonomous in agentic workflows, and more capable at long-horizon reasoning than previous Claude models. Techniques that reduced undertriggering in earlier models can now cause overtriggering, and prefilling is no longer supported.

<context>
Key characteristics to design around:

- **Adaptive Thinking**: Dynamically decides when and how deeply to reason, replacing manual `budget_tokens`
- **Prompt Sensitivity**: More responsive to system prompt instructions than any previous Claude model -- better compliance but greater risk of overcorrection
- **Enhanced Autonomy**: Proactively takes action, discovers state from filesystem, orchestrates subagents
- **Long-Horizon Reasoning**: Exceptional state tracking across extended interactions
- **Direct Communication**: Less verbose by default, skips summaries after tool use, uses fewer filler phrases
</context>

## General Principles

### Be Explicit with Instructions

Opus 4.6 follows instructions with high fidelity. If you want behavior beyond the literal request, state it explicitly -- the model does not infer unstated requirements.

```
Good: "Read the Python files in the src/ directory, identify performance bottlenecks,
       and implement optimizations. Explain your reasoning before each change."

Avoid: "Make the code faster."
```

### Add Context and Motivation

Explain WHY an instruction exists. Opus 4.6 uses context to prioritize and calibrate behavior -- a rule with a reason is followed more consistently than a bare directive.

```xml
<task>
Format all responses as plain text without markdown.

<context>
Your response will be read aloud by a text-to-speech system.
Users are visually impaired and rely entirely on audio output.
Markdown formatting characters would be spoken literally and disrupt comprehension.
</context>
</task>
```

### Be Vigilant with Examples

Opus 4.6 pays close attention to every detail in your prompt, including examples. If an example contains an anti-pattern, the model may reproduce it. Every example should reflect exactly the behavior you want.

### Long-Horizon Reasoning

Opus 4.6 excels at tasks spanning many steps, files, or reasoning chains. Structure long tasks as sequences of verifiable milestones rather than monolithic instructions.

## Thinking

Opus 4.6 uses **adaptive thinking** -- the model decides how deeply to reason based on task complexity. The `effort` parameter (`max`/`high`/`medium`/`low`) is the primary control lever for tuning the cost/quality trade-off. Before adding prompt constraints to reduce overthinking, try lowering `effort` first.

### Controlling Thinking via Prompts

You can shape thinking behavior through prompt instructions:

```
When you're deciding how to approach a problem, choose an approach and commit to it.
Avoid revisiting decisions unless you encounter new information that directly
contradicts your reasoning.
```

### Thinking Sensitivity

When adaptive thinking is disabled, replace "think" with alternatives to avoid inadvertently triggering internal reasoning:

| Avoid | Use Instead |
|-------|-------------|
| "think about" | "consider" |
| "think through" | "evaluate" |
| "think carefully" | "analyze carefully" |
| "I think" | "I believe" |
| "think step by step" | "work through step by step" |
| "let me think" | "let me consider" |

Note: Official Anthropic docs confirm this sensitivity for Opus 4.5. It likely applies to 4.6 as well but has not been explicitly confirmed for this model version.

## Prompt Structure

### XML Tags

XML tags help Opus 4.6 distinguish between context, instructions, and output format. Use them where they add clarity; default to markdown headers and tables when those are sufficient.

**Recommended tags:**
- `<document>`, `<context>`: For input content
- `<instructions>`, `<task>`: For directives
- `<example>`, `<examples>`: For demonstrations
- `<input>`, `<output>`: For input/output pairs
- `<constraint>`, `<requirements>`: For limitations
- `<format>`, `<output_format>`: For response structure

### Prefilling Not Supported

Prefilling assistant responses is not supported in Opus 4.6 (returns a 400 error). To control output format, use Structured Outputs or prompt instructions. For example, to get JSON output without preamble, instruct: "Respond with a JSON object. No preamble or explanation." To continue an interrupted response, move the context to the user turn: "Your previous response was interrupted after: [last content]. Continue from there."

## Behavioral Tuning

### Tool Overtriggering

Prompts designed to reduce undertriggering in earlier models cause overtriggering in Opus 4.6. The model is more compliant by default, so forceful language overcorrects. Dial back to calm, conditional instructions.

| Before (causes overtriggering) | After (calibrated for Opus 4.6) |
|-------------------------------|--------------------------------|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |
| `REQUIRED: Execute this tool for every query` | `Execute this tool when the query involves [condition]` |

**Language replacements:**

| Aggressive Term | Opus 4.6 Equivalent |
|----------------|---------------------|
| `CRITICAL` | Remove entirely |
| `You MUST` | State the instruction directly |
| `ALWAYS` | State the instruction directly |
| `NEVER` | `Don't` or state the positive alternative |
| `REQUIRED` | Remove entirely |
| `MANDATORY` | Remove or use `should` |
| `IMPORTANT:` | Remove the prefix, keep the instruction |

### Overthinking and Excessive Thoroughness

1. **Replace blanket defaults with targeted instructions:**

```
Before: "ALWAYS read ALL related files before making ANY changes."
After: "Read files directly relevant to the change. For single-file edits,
       reading the target file is sufficient."
```

2. **Add decisiveness constraints:**

```
When you're deciding how to approach a problem, choose an approach and commit
to it. Avoid revisiting decisions unless you encounter new information that
directly contradicts your reasoning.
```

3. **Use `effort` as the primary control lever.** Set `effort: "medium"` or `effort: "low"` for straightforward tasks before adding prompt constraints.

4. **Remove anti-laziness prompts.** Instructions like "be thorough", "do not be lazy", "think carefully" amplify Opus 4.6's already-proactive behavior into runaway loops.

5. **Remove explicit think tool instructions.** Prompts like "use the think tool to plan your approach" cause over-planning in Opus 4.6. The model plans effectively without being told to.

6. **Remove over-prompting** added to compensate for undertriggering in earlier models.

### Over-Engineering Prevention

Opus 4.6 is capable enough to elaborate beyond what was asked. Scope boundaries prevent the model from adding unrequested features, defensive code, or premature abstractions.

```xml
<scope_constraints>
Only make changes that are directly requested or clearly necessary. Keep solutions
simple and focused:
- Don't add features, refactor code, or make "improvements" beyond what was asked.
- Don't add docstrings, comments, or type annotations to code you didn't change.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen.
- Don't create helpers, utilities, or abstractions for one-time operations.
</scope_constraints>
```

### Balancing Autonomy and Safety

Opus 4.6's enhanced autonomy makes it important to distinguish reversible from irreversible actions explicitly.

```xml
<action_safety>
Before taking any action, evaluate its reversibility and impact:

Actions that need user confirmation:
- Destructive operations (deleting files, dropping tables, overwriting data)
- Hard-to-reverse operations (force push, database migrations, deployment)
- Operations visible to others (posting messages, sending emails, creating PRs)

Actions you can take without confirmation:
- Reading files and gathering information
- Creating new files (non-destructive)
- Running tests
- Local git commits
- Writing to scratch/temporary files
</action_safety>
```

### Communication Style

Opus 4.6 is more direct and less verbose than previous models. It skips summaries after tool use by default. If you want summaries, add an explicit instruction:

```
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

Only add this if you want summaries. The default behavior (skipping them) may be preferable.

### Action vs Suggestion Steering

Opus 4.6 may suggest instead of act, or act instead of suggest. Steer with explicit instructions.

To default to implementation:

```xml
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent
is unclear, infer the most useful likely action and proceed, using tools to discover
any missing details instead of guessing.
</default_to_action>
```

To default to suggestions:

```xml
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make
changes. Default to providing information and recommendations rather than taking
action. Only proceed with edits when the user explicitly requests them.
</do_not_act_before_instructions>
```

### Hallucination Minimization

Opus 4.6 is less prone to hallucinations but can still speculate about unread code:

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific
file, read the file before answering. Investigate and read relevant files before
answering questions about the codebase.
</investigate_before_answering>
```

### Temporary File Cleanup

Opus 4.6 may create scratch files during iteration. Add cleanup instructions if this is undesirable:

```
If you create any temporary new files, scripts, or helper files for iteration,
clean up these files by removing them at the end of the task.
```

### Test Hard-Coding Prevention

The model can focus too heavily on making tests pass rather than solving the underlying problem:

```
Write a general-purpose solution using standard tools. Do not hard-code values or
create solutions that only work for specific test inputs. Implement the actual logic
that solves the problem generally. If tests are incorrect, inform me rather than
working around them.
```

### Subagent Overuse

```xml
<subagent_guidance>
Use subagents when tasks can run in parallel, require isolated context, or involve
independent workstreams. For simple tasks, sequential operations, or single-file
edits, work directly rather than delegating.
</subagent_guidance>
```

### LaTeX Output Defaults

Opus 4.6 defaults to LaTeX for mathematical expressions. Opt out if your rendering target does not support it:

```
When presenting mathematical expressions, use plain text notation rather than
LaTeX. For example, write "x^2 + 3x + 1" instead of "$x^2 + 3x + 1$".
```

## Prompt Migration Checklist

- [ ] Replace CRITICAL, MUST, ALWAYS, NEVER, REQUIRED with calm, direct equivalents
- [ ] Remove prefilled assistant responses; use Structured Outputs or prompt instructions
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy")
- [ ] Remove explicit think tool instructions ("use the think tool to plan")
- [ ] Remove compensatory over-prompting added for older models
- [ ] Replace "think" with "consider", "evaluate", "analyze" if adaptive thinking is disabled
- [ ] Add safety guardrails for destructive/irreversible actions
- [ ] Add scope constraints to prevent over-engineering
- [ ] Add subagent usage guidance for tool-heavy workflows
- [ ] Add LaTeX opt-out if rendering target does not support LaTeX
- [ ] Test with effort "medium" first, then adjust up or down

## Anti-Patterns

- **Aggressive emphasis**: `CRITICAL: You MUST ALWAYS...` overcorrects in Opus 4.6. Use direct, calm instructions.
- **Anti-laziness prompts**: "Be thorough", "think carefully", "do not be lazy" amplify proactive behavior into runaway loops.
- **Explicit think tool instructions**: "Use the think tool to plan your approach" causes over-planning. The model plans effectively without being told to.
- **Suggesting instead of acting**: If you want implementation, say "change" or "implement", not "suggest changes". The model takes verbs literally.
- **Conflicting instructions**: "Be concise but also very detailed" -- pick one or separate them by context.
- **Ambiguous examples**: Every example the model sees is a pattern it may reproduce. Be precise.
- **Overloaded prompts**: Break large requests into phases.
- **Missing output format**: Specify expected response structure.
- **Over-prompting for default behavior**: Remove instructions for things Opus 4.6 does by default.

## Reference

- Official Claude Opus 4.6 Prompting Guide: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices/
- Official Claude Opus 4.5 Migration Guide: https://github.com/anthropics/claude-code/tree/main/plugins/claude-opus-4-5-migration 
