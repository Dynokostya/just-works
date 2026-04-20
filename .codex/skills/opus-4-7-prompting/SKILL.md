---
name: opus-4-7-prompting
description: Apply when creating or editing prompts targeting Opus 4.7. Covers literal instruction following, response length tuning, tool and subagent under-triggering, tone shifts, XML structure, design defaults, code review patterns, and migration from Opus 4.6.
---

# Opus 4.7 Prompting

## When to Use

- Creating or editing system prompts targeting Opus 4.7
- Steering response length, verbosity, and voice in prompts
- Tuning tool usage and subagent spawning
- Migrating prompt text from Opus 4.6 or older Claude models

## Overview

Opus 4.7 is Anthropic's most capable frontier model. It runs well on existing Opus 4.6 prompts out of the box, but several default behaviors shifted. Compared to 4.6, Opus 4.7 is more literal, more direct in tone, uses tools less often, spawns fewer subagents, and calibrates response length to task complexity. Prefilling is still not supported.

<context>
Key characteristics to design around:

- **More Literal**: Follows instructions exactly as written; does not silently generalize to related items. State scope explicitly.
- **Adaptive Length**: Shorter on simple lookups, longer on open-ended analysis. Tune if product depends on a fixed verbosity.
- **Lower Tool/Subagent Trigger Bar**: Prefers reasoning over tool calls and direct work over delegation. Prompt explicitly when you want more.
- **Direct, Opinionated Tone**: Less validation-forward, fewer emoji, more concise than 4.6's warmer default.
- **Native Progress Updates**: Produces higher-quality interim updates without scaffolding.
- **Strong Design Defaults**: Persistent house style on frontend work (cream background, serif display, terracotta accent).
- **Long-Horizon Reasoning**: Exceptional state tracking across extended interactions.
</context>

## General Principles

### Be Explicit with Instructions

Opus 4.7 interprets prompts literally. If you want behavior beyond the literal request, state it explicitly. The model will not infer unstated requirements or silently generalize an instruction from one item to the next.

```
Good: "Apply this formatting to every section, not just the first one."
Avoid: "Apply this formatting." (when multiple sections exist and generalization is implied)
```

### Add Context and Motivation

Explain WHY an instruction exists. A rule with a reason is followed more consistently than a bare directive.

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

### Prefer Positive Examples Over Negative Instructions

Positive examples showing the target behavior tend to be more effective than negative examples or "don't do X" instructions.

### Be Vigilant with Examples

Opus 4.7 pays close attention to every detail in your prompt, including examples. If an example contains an anti-pattern, the model may reproduce it. Every example should reflect exactly the behavior you want.

### Long-Horizon Reasoning

Opus 4.7 excels at tasks spanning many steps, files, or reasoning chains. Structure long tasks as sequences of verifiable milestones rather than monolithic instructions.

## Response Length and Verbosity

Opus 4.7 calibrates response length to task complexity rather than defaulting to a fixed verbosity. Simple lookups get shorter answers; open-ended analysis gets longer ones.

If your product depends on a specific style or verbosity, tune with prompts:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

For specific kinds of over-explanation, show a positive example of the target concision rather than listing what to avoid.

## Thinking

Opus 4.7 uses adaptive thinking -- it decides how deeply to reason based on task complexity. You can shape thinking behavior through prompt instructions.

### Discourage Over-Reflection

```
When deciding how to approach a problem, choose an approach and commit to it.
Avoid revisiting decisions unless you encounter new information that directly
contradicts your reasoning.
```

### Discourage Thinking on Simple Queries

```
Thinking adds latency and should only be used when it will meaningfully improve
answer quality -- typically for problems that require multi-step reasoning.
When in doubt, respond directly.
```

### Word Sensitivity

When thinking is disabled, the word "think" and its variants can inadvertently trigger internal reasoning. Use alternatives:

| Avoid | Use |
|-------|-----|
| "think about" | "consider" |
| "think through" | "evaluate" |
| "think carefully" | "analyze carefully" |
| "I think" | "I believe" |
| "think step by step" | "work through step by step" |

Note: explicitly documented for Opus 4.5; likely applies to 4.7 but not explicitly confirmed.

## Prompt Structure

### XML Tags

XML tags help Opus 4.7 distinguish between context, instructions, and output format. Use them where they add clarity; default to markdown headers and tables when those are sufficient.

**Recommended tags:**
- `<document>`, `<context>`: For input content
- `<instructions>`, `<task>`: For directives
- `<example>`, `<examples>`: For demonstrations
- `<input>`, `<output>`: For input/output pairs
- `<constraint>`, `<requirements>`: For limitations
- `<format>`, `<output_format>`: For response structure

### Long-Context Prompting

When prompts exceed 20k tokens:

- Place long documents near the top, above instructions and queries. Queries at the end can improve response quality noticeably.
- Wrap each document in `<document>` tags with `<source>` and `<document_content>` subtags.
- For long-document tasks, ask Claude to extract relevant quotes into `<quotes>` tags before answering -- grounds responses and cuts through noise.

### Prefilling Not Supported

Prefilling assistant responses is not supported in Opus 4.7 (returns a 400 error). Alternatives:

- **Format constraint**: Use Structured Outputs or prompt instructions. For JSON without preamble: "Respond with a JSON object. No preamble or explanation."
- **Continuation**: Move context to the user turn: "Your previous response was interrupted after: [last content]. Continue from there."
- **Preamble stripping**: Instruct directly ("Respond directly without preamble") or post-process.

## Behavioral Tuning

### Tool Use Triggering

Opus 4.7 uses tools less often than 4.6 and relies more on reasoning. This produces better results in most cases but can under-use tools when you want more tool calls.

If you want more tool use, state when and why explicitly:

```
Use the web search tool whenever the question involves current events, recent
product releases, or facts that may have changed since your training cutoff.
Describe your search strategy before calling the tool.
```

Keep language calm and conditional. Forceful phrasing needed for older models now causes overcorrection.

| Avoid | Use |
|-------|-----|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |

**Language replacements:**

| Aggressive Term | Equivalent |
|-----------------|------------|
| `CRITICAL` | Remove entirely |
| `You MUST` | State the instruction directly |
| `ALWAYS` | State the instruction directly |
| `NEVER` | `Don't` or state the positive alternative |
| `REQUIRED` | Remove entirely |
| `MANDATORY` | Remove or use `should` |
| `IMPORTANT:` | Remove the prefix, keep the instruction |

### Parallel Tool Calling

Opus 4.7 defaults to parallel tool calls when independent. To reinforce or tune:

```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between them,
make all of the independent tool calls in parallel. For example, when reading
3 files, run 3 tool calls in parallel. If some tool calls depend on previous
results to inform parameters, call them sequentially instead. Never use
placeholders or guess missing parameters.
</use_parallel_tool_calls>
```

### Subagent Spawning

Opus 4.7 spawns fewer subagents by default than 4.6. If your workflow benefits from subagents (parallel fan-out, isolated context, multi-file reads), prompt for it explicitly.

```xml
<subagent_guidance>
Do not spawn a subagent for work you can complete directly in a single response
(e.g., refactoring a function you can already see).

Spawn multiple subagents in the same turn when fanning out across items,
reading multiple files in parallel, or running independent workstreams.
</subagent_guidance>
```

### Over-Engineering Prevention

Opus 4.7 is capable enough to elaborate beyond what was asked. Scope boundaries prevent unrequested features, defensive code, or premature abstractions.

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

Opus 4.7's autonomy makes it important to distinguish reversible from irreversible actions explicitly.

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

### Tone and Writing Style

Opus 4.7 is more direct and opinionated than 4.6, with less validation-forward phrasing and fewer emoji. If your product relies on a warmer voice, re-tune style prompts against this baseline.

```
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```

### User-Facing Progress Updates

Opus 4.7 provides higher-quality interim updates during long agentic traces without scaffolding. Remove legacy instructions like "after every 3 tool calls, summarize progress." If the updates don't match your product's needs, describe the target format explicitly and include a positive example.

### Action vs Suggestion Steering

Opus 4.7 takes verbs literally. To default to implementation:

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

Opus 4.7 is less prone to hallucinations but can still speculate about unread code:

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific
file, read the file before answering. Investigate and read relevant files before
answering questions about the codebase.
</investigate_before_answering>
```

### Temporary File Cleanup

Opus 4.7 may create scratch files during iteration. Add cleanup instructions if undesirable:

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

### LaTeX Output Defaults

Opus 4.7 defaults to LaTeX for mathematical expressions. Opt out if your rendering target does not support it:

```
When presenting mathematical expressions, use plain text notation rather than
LaTeX. For example, write "x^2 + 3x + 1" instead of "$x^2 + 3x + 1$".
```

## Specialized Scenarios

### Code Review Harnesses

Opus 4.7 follows filtering instructions more faithfully than 4.6. Prompts like "only report high-severity issues" or "be conservative" cause it to investigate thoroughly, find bugs, and then drop findings below the stated bar. This reads as lower recall even though underlying bug-finding ability improved.

Prompt for coverage at the finding stage, filter separately:

```
Report every issue you find, including ones you are uncertain about or consider
low-severity. Do not filter for importance or confidence at this stage -- a separate
verification step will do that. Your goal here is coverage: it is better to surface
a finding that later gets filtered out than to silently drop a real bug. For each
finding, include your confidence level and an estimated severity so a downstream
filter can rank them.
```

If self-filtering in a single pass is required, be concrete about the bar:

```
Report any bugs that could cause incorrect behavior, a test failure, or a misleading
result; only omit nits like pure style or naming preferences.
```

### Interactive Coding Products

In interactive, multi-turn coding sessions, Opus 4.7 reasons more after user turns than in autonomous single-turn setups. To maximize performance and efficiency:

- Specify the task, intent, and relevant constraints upfront in the first user turn
- Reduce required human interactions (add auto modes where safe)
- Avoid progressively conveying ambiguous prompts over many user turns

### Frontend Design

Opus 4.7 has strong default design instincts and a persistent house style: warm cream backgrounds (~#F4F1EA), serif display type (Georgia, Fraunces, Playfair), italic word-accents, terracotta/amber accent. This reads well for editorial and hospitality briefs but feels off for dashboards, dev tools, fintech, healthcare, or enterprise apps.

Generic negatives ("don't use cream", "make it minimal") shift the model to a different fixed palette rather than producing variety. Two approaches work:

**1. Specify a concrete alternative.** The model follows explicit specs precisely:

```
Visual direction: cold monochrome, pale silver-gray deepening into blue-gray and
near-black. Palette: #E9ECEC, #C9D2D4, #8C9A9E, #44545B, #11171B. Typography:
square, angular sans-serif with wide letter spacing. 4px corner radius across
cards, buttons, inputs. Generous margins.
```

**2. Have the model propose options before building.** Breaks the default and gives the user control; produces real variety across runs.

```
Before building, propose 4 distinct visual directions tailored to this brief
(each as: bg hex / accent hex / typeface -- one-line rationale). Ask the user
to pick one, then implement only that direction.
```

Opus 4.7 requires less prompting than earlier models to avoid generic "AI slop" aesthetics. A short snippet works:

```xml
<frontend_aesthetics>
Avoid generic AI-generated aesthetics: overused fonts (Inter, Roboto, Arial,
system fonts), cliched color schemes (purple gradients on white or dark),
predictable layouts, cookie-cutter components. Use distinctive fonts, cohesive
color themes, and purposeful animations for micro-interactions.
</frontend_aesthetics>
```

### Research and Information Gathering

For complex research tasks:

```
Search for this information in a structured way. As you gather data, develop several
competing hypotheses. Track your confidence levels in your progress notes to improve
calibration. Regularly self-critique your approach and plan. Update a hypothesis
tree or research notes file to persist information and provide transparency. Break
down this complex research task systematically.
```

## Prompt Migration Checklist

### From any older Claude (4.6 or earlier)

- [ ] Replace CRITICAL, MUST, ALWAYS, NEVER, REQUIRED with calm, direct equivalents
- [ ] Remove prefilled assistant responses; use Structured Outputs or prompt instructions
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy")
- [ ] Remove explicit think-tool instructions ("use the think tool to plan")
- [ ] Remove compensatory over-prompting added for older models
- [ ] Replace "think" with "consider", "evaluate", "analyze" if adaptive thinking is disabled
- [ ] Add safety guardrails for destructive/irreversible actions
- [ ] Add scope constraints to prevent over-engineering
- [ ] Add LaTeX opt-out if rendering target does not support LaTeX

### From Opus 4.6 specifically

- [ ] State scope explicitly where you previously relied on generalization ("apply to every X, not just first")
- [ ] Add verbosity guidance if product depends on a fixed response length
- [ ] Flip subagent prompts from "limit use" to "encourage when appropriate" -- 4.7 defaults to under-use
- [ ] Encourage tool use explicitly where under-triggering matters (search, file reads)
- [ ] Re-tune voice prompts if you need a warmer tone -- 4.7 defaults more direct
- [ ] Remove "summarize every N tool calls" scaffolding -- native updates are better
- [ ] For code review harnesses: shift to "coverage at finding stage, filter separately"
- [ ] For frontend work: specify concrete palettes or have model propose options (avoid generic negatives)

## Anti-Patterns

- **Aggressive emphasis**: `CRITICAL: You MUST ALWAYS...` overcorrects. Use direct, calm instructions.
- **Anti-laziness prompts**: "Be thorough", "think carefully", "do not be lazy" amplify proactive behavior.
- **Assuming generalization**: Opus 4.7 applies instructions literally to what you named. State full scope.
- **Negative-only style direction**: "Don't use purple gradients" shifts to another fixed alternative rather than producing variety. Use positive examples or concrete specs.
- **Suggesting instead of acting**: If you want implementation, say "change" or "implement", not "suggest changes". The model takes verbs literally.
- **Conflicting instructions**: "Be concise but also very detailed" -- pick one or separate by context.
- **Ambiguous examples**: Every example is a pattern the model may reproduce. Be precise.
- **Overloaded prompts**: Break large requests into phases.
- **Over-prompting for default behavior**: Remove instructions for things 4.7 does by default (interim summaries, balanced tool use, scope discipline).

## Reference

- Official Claude Prompting Best Practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
