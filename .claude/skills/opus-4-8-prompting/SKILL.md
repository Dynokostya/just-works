---
name: opus-4-8-prompting
description: Apply when creating or editing prompts targeting Claude Opus 4.8 (model ID claude-opus-4-8). Covers effort-level recalibration, tool triggering improvements, mid-conversation system messages, literal instruction following, response-length calibration, subagent spawning, tone shifts, XML structure, design defaults, adaptive thinking, and migration from Opus 4.7. Do not apply to other Claude models — for Fable 5 use fable-5-prompting.
---

# Opus 4.8 Prompting

## When to Use

- Creating or editing system prompts targeting Opus 4.8
- Steering response length, verbosity, and voice in prompts
- Tuning tool usage and subagent spawning
- Migrating prompt text from Opus 4.7 or older Claude models

## Overview

Opus 4.8 is Anthropic's most capable generally available model (1M context, 128k max output). It builds on Opus 4.7 with no breaking API changes for code already running on 4.7. Key improvements: better tool triggering (fewer skipped calls), improved compaction recovery, fewer wasted thinking tokens, and mid-conversation system messages.

<context>
Key behavioral characteristics to design around:

- **More literal**: Follows instructions exactly as written; does not silently generalize. State scope explicitly. Particularly pronounced at `low` and `medium` effort.
- **Adaptive length**: Shorter on simple lookups, longer on open-ended analysis. Tune if your product depends on a fixed verbosity.
- **Improved tool triggering**: Less likely to skip tool calls the task requires vs 4.7, but still favors reasoning over tool calls. Raise effort or prompt explicitly for more tool use.
- **Direct, opinionated tone**: Less validation-forward, fewer emoji, more concise than 4.6's warmer default.
- **Native progress updates**: Produces higher-quality interim updates without scaffolding.
- **Strict effort respect**: Meaningfully stricter than 4.6, especially at low/medium — scopes work to what was asked.
- **Effort levels recalibrated**: Token allocation per level changed from 4.7 — `medium` allows more thinking, `high` allows less, `xhigh` substantially more. Re-baseline before adjusting.
- **Strong design defaults**: Persistent house style (cream/terracotta/Fraunces) on frontend work.
- **Long-horizon reasoning**: Exceptional state tracking across extended interactions, better compaction recovery than 4.7.
- **Mid-conversation system messages**: Can inject updated instructions after a user turn without restating the full system prompt.
</context>

## Effort Levels — Prompt Implications

On 4.8, the `effort` parameter controls reasoning depth. The default is `high` on all surfaces (API, Claude Code). Effort is more important for this model than any prior Opus — experiment with it actively. Effort levels are recalibrated from 4.7: re-baseline cost and latency before adjusting. Effort governs deliberation and tool-calling scope independently of whether the `thinking` parameter is enabled (see Adaptive Thinking below).

| Level | Prompt-authoring implication |
|-------|--------------|
| `max` | Deepest reasoning. Can deliver gains but may show diminishing returns or overthinking. Test for intelligence-demanding tasks. Keep prompts lean. |
| `xhigh` | Best setting for coding and agentic use cases. Same lean prompting style as `max` — avoid over-specifying reasoning steps. |
| `high` | Default. Balances token usage and intelligence. Minimum for most intelligence-sensitive use cases. |
| `medium` | Cost-sensitive. **Strict scope** — the model does not go "above and beyond". If you want extra steps, list them explicitly. Allows somewhat more thinking than 4.7's medium. |
| `low` | Short, scoped tasks and latency-sensitive workloads. Risk of under-thinking on complex prompts. Add targeted reasoning cues if the task is non-trivial. |

4.8 respects effort **strictly** at `low`/`medium`. If you see shallow reasoning on a complex task, raise effort rather than prompting around it. If you must keep effort low, add targeted guidance:

```
This task involves multi-step reasoning. Analyze the problem carefully step by step before responding.
```

Source: https://platform.claude.com/docs/en/build-with-claude/effort

### Adaptive Thinking — Prompt Behavior

On Opus 4.8, thinking is **off by default** — set `thinking: {type: "adaptive"}` explicitly to enable it. When enabled, the model decides per-turn whether to think based on task complexity. This reduces wasted thinking tokens compared to 4.7 at the same effort level.

**When adaptive thinking is on, do not add "show your reasoning" or "think step by step" — reasoning is already handled by the parameter.** Prescribing reasoning steps often underperforms a short cue like "think thoroughly."

Adaptive thinking is promptable. Large system prompts can over-trigger thinking on moderate queries; if you see that, add:

```
Thinking adds latency and should only be used when it will meaningfully improve
answer quality — typically for problems that require multi-step reasoning.
When in doubt, respond directly.
```

If running hard workloads at `medium` and seeing under-thinking, raise effort first. If you need finer control, prompt for it directly.

When running at `max` or `xhigh` effort, set a large max output token budget (start at 64k) so the model has room to think and act across subagents and tool calls.

Source: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking

## General Principles

### Be Explicit with Instructions

Opus 4.8 interprets prompts literally. If you want behavior beyond the literal request, state it explicitly. The model will not infer unstated requirements or silently generalize an instruction from one item to the next.

```
Good: "Apply this formatting to every section, not just the first one."
Avoid: "Apply this formatting." (when multiple sections exist and generalization is implied)
```

### Add Context and Motivation

Explain WHY an instruction exists. A rule with a reason ("format as plain text — the response is read aloud by a text-to-speech system") is followed more consistently than a bare directive.

### Examples Are Load-Bearing

Positive examples outperform "don't do X" instructions — every example is a pattern the model may reproduce, so keep examples precise and free of anti-patterns.

### Long-Horizon Reasoning

Opus 4.8 excels at tasks spanning many steps, files, or reasoning chains. It handles compaction recovery better than 4.7 — fewer derailments after context compaction. Structure long tasks as sequences of verifiable milestones rather than monolithic instructions.

## Response Length and Verbosity

Opus 4.8 calibrates response length to task complexity rather than defaulting to a fixed verbosity. Simple lookups get shorter answers; open-ended analysis gets longer ones.

If your product depends on a specific style or verbosity, tune with prompts:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

For specific kinds of over-explanation, show a positive example of the target concision rather than listing what to avoid.

### Controlling Output Format

Four techniques in order of effectiveness:

1. **Tell Claude what to do, not what not to do** — "compose your response of smoothly flowing prose paragraphs" beats "do not use markdown in your response".
2. **Use XML format indicators** — "Write the prose sections of your response in `<smoothly_flowing_prose_paragraphs>` tags."
3. **Match prompt style to output style** — removing markdown from your prompt reduces markdown in the output.
4. **Use detailed prompts for formatting preferences.**

For reducing over-formatted responses (bullet-soup, unnecessary bold), add an
`<avoid_excessive_markdown_and_bullet_points>` block: write long-form content in
clear, flowing prose; reserve markdown primarily for inline code, code blocks, and
simple headings (###); use lists only for truly discrete items or when the user
explicitly requests a list or ranking — otherwise incorporate items into sentences.

For post-tool-call summaries (4.8 may skip them):

```
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

## Thinking — Prompt Tuning

Reasoning depth is controlled at the parameter level (see Effort Levels above). Use these snippets to shape *when* Claude thinks, not *how deeply*.

**Discourage over-reflection:**

```
When deciding how to approach a problem, choose an approach and commit to it.
Avoid revisiting decisions unless you encounter new information that directly
contradicts your reasoning.
```

**Word sensitivity.** When adaptive thinking is off, the word "think" and its variants can inadvertently trigger internal reasoning. Large/complex system prompts can also over-trigger adaptive thinking. Prefer neutral alternatives:

| Avoid | Use |
|-------|-----|
| "think about" | "consider" |
| "think through" | "evaluate" |
| "think carefully" | "analyze carefully" |
| "I think" | "I believe" |
| "think step by step" | "work through step by step" |

## Prompt Structure

### XML Tags

XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs.

**Principles:**
- Use consistent, descriptive tag names across your prompts.
- Nest when content has natural hierarchy (`<documents>` -> `<document index="n">` -> `<document_content>` + `<source>`).
- Wrap multiple examples in `<examples>` with each in `<example>`; 3-5 examples is Anthropic's recommended range.

**Commonly used in Anthropic's own examples:** `<documents>`/`<document>` (with `<source>`, `<document_content>`), `<context>`, `<instructions>`, `<task>`, `<examples>`/`<example>` (with `<input>`, `<output>`), `<format>`, `<output_format>`, `<quotes>`, `<thinking>` (in few-shot demos), and named behavioral-steering tags (`<use_parallel_tool_calls>`, `<default_to_action>`, `<do_not_act_before_instructions>`, `<investigate_before_answering>`, `<frontend_aesthetics>`, `<avoid_excessive_markdown_and_bullet_points>`, `<scope_constraints>`, `<action_safety>`).

Default to markdown headers and tables where they are sufficient; reach for XML when you need unambiguous separation or when an instruction has a natural name.

### Long-Context Prompting

When prompts exceed 20k tokens:

- **Put long documents at the top, query at the end.** Queries-last improves response quality by up to 30% in Anthropic's tests, especially with multi-document inputs.
- **Wrap each document** in `<document index="n">` with `<source>` and `<document_content>` subtags; wrap the collection in `<documents>`.
- **Ground in quotes** for long-document tasks: ask Claude to extract relevant quotes into `<quotes>` before answering, then reason from there. Cuts through noise and reduces fabrication.

4.8 has a 1M context window at standard pricing (no long-context premium, no beta header). The tokenizer (same as 4.7) consumes up to ~35% more tokens per unit of text vs 4.6 — budget longer prompts accordingly.

### Mid-Conversation System Messages (New in 4.8)

Opus 4.8 accepts `role: "system"` messages immediately after a user turn in the `messages` array. This lets you inject updated instructions mid-conversation without restating the full system prompt, preserving prompt cache hits on earlier turns.

Use cases:
- Updating tool permissions or constraints mid-loop in agentic systems
- Injecting domain context discovered after initial prompt construction
- Reducing input cost on long-running conversations

Earlier models (including 4.7) reject `role: "system"` in messages with a 400 error. If you maintain backward-compatible code paths, gate this on model version.

Source: https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages

### Context Awareness

Claude tracks its remaining token budget. If your agent harness compacts context or writes to external files, prevent premature wrap-up:

```
Your context window will be automatically compacted as it approaches its limit,
allowing you to continue working from where you left off. Do not stop tasks early
due to token budget concerns. As you approach your budget, save progress to memory
before the context refreshes. Never artificially stop a task early regardless of
the context remaining.
```

4.8 has improved compaction recovery — long agentic traces stay on task with fewer derailments after compaction than 4.7.

### Prefilling Not Supported

Assistant-message prefill on the last turn is rejected starting with Opus 4.6. Replacement phrasings for prompts that used to rely on it:

- **Force JSON/YAML shape**: Use Structured Outputs. For simple cases: "Respond with a JSON object only. No preamble or explanation."
- **Strip preambles** ("Here is the..."): "Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc."
- **Continue after interruption**: Move the continuation into the user turn: "Your previous response was interrupted and ended with [previous_response]. Continue from where you left off."
- **Role consistency reminders**: Inject them into the user turn, or use a mid-conversation system message.

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#migrating-away-from-prefilled-responses

## Behavioral Tuning

### Tool Use Triggering

Opus 4.8 improves on 4.7's tool triggering — fewer cases of skipping a tool call the task requires. However, it still favors reasoning over tool calls in many situations.

If you want more tool use:
1. **Raise effort first** — `high`/`xhigh` show substantially more tool usage in agentic search and coding.
2. **Then add prompt guidance** — state when and why to use tools explicitly:

```
Use the web search tool whenever the question involves current events, recent
product releases, or facts that may have changed since your training cutoff.
Describe your search strategy before calling the tool.
```

Keep language calm and conditional — forceful phrasing needed for older models causes overcorrection:

| Avoid | Use |
|-------|-----|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |

Drop these aggressive markers from prompts: `CRITICAL`, `You MUST`, `ALWAYS`, `NEVER`, `REQUIRED`, `MANDATORY`, `IMPORTANT:`. Prefer direct statements or `should`; replace `NEVER` with `Don't` or the positive alternative.

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#tool-use-triggering

### Parallel Tool Calling

Opus 4.8 defaults to parallel tool calls when independent. Has a high success rate without prompting, but to reinforce to ~100%:

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

Opus 4.8 spawns fewer subagents by default than 4.6. If your workflow benefits from subagents (parallel fan-out, isolated context, multi-file reads), prompt for it explicitly.

```xml
<subagent_guidance>
Do not spawn a subagent for work you can complete directly in a single response
(e.g., refactoring a function you can already see).

Spawn multiple subagents in the same turn when fanning out across items,
reading multiple files in parallel, or running independent workstreams.
</subagent_guidance>
```

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#controlling-subagent-spawning

### Over-Engineering Prevention

Opus 4.8 is capable enough to elaborate beyond what was asked. Scope boundaries prevent unrequested features, defensive code, or premature abstractions.

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

Opus 4.8's autonomy makes it important to distinguish reversible from irreversible actions explicitly.

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

### Tone, Voice, and Progress Updates

4.8 is more direct and opinionated than 4.6 — less validation-forward, fewer emoji. For warmer voice: "Use a warm, collaborative tone. Acknowledge the user's framing before answering."

Native interim updates during long agentic traces are higher-quality on 4.8 than prior models — remove legacy scaffolding like "after every 3 tool calls, summarize progress." If updates don't match your product's needs, describe the target format explicitly with a positive example.

### Action vs Suggestion Steering

Opus 4.8 takes verbs literally. To default to implementation:

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

Opus 4.8 is less prone to hallucinations but can still speculate about unread code:

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific
file, read the file before answering. Investigate and read relevant files before
answering questions about the codebase.
</investigate_before_answering>
```

### Temporary Files, Test Gaming, LaTeX

Scratch-file cleanup: "If you create any temporary files for iteration, remove them at the end of the task."

Test hard-coding prevention: "Write a general-purpose solution. Do not hard-code values or create solutions that only work for specific test inputs. If tests are incorrect, inform me rather than working around them."

LaTeX opt-out (4.8 defaults to LaTeX for math): "Use plain text notation rather than LaTeX. For example, write 'x^2 + 3x + 1' instead of '$x^2 + 3x + 1$'."

## Specialized Scenarios

### Code Review Harnesses

4.8 is meaningfully better at finding bugs than prior models (higher recall and precision). However, if your harness says "only report high-severity issues" or "be conservative", 4.8 follows that instruction faithfully — it may find bugs then drop findings below the bar.

Prompt for coverage at the finding stage, filter separately:

```
Report every issue you find, including ones you are uncertain about or consider
low-severity. Do not filter for importance or confidence at this stage — a separate
verification step will do that. For each finding, include your confidence level
and an estimated severity so a downstream filter can rank them.
```

If single-pass self-filtering is required, state the bar concretely:

```
Report any bugs that could cause incorrect behavior, a test failure, or a misleading
result; only omit nits like pure style or naming preferences.
```

### Frontend Design

Opus 4.8 has a persistent house style: warm cream (~#F4F1EA), serifs (Georgia, Fraunces, Playfair), italic accents, terracotta/amber. Reads well for editorial and hospitality briefs; feels off for dashboards, dev tools, fintech, healthcare, enterprise.

4.8 requires less frontend design prompting than earlier models to avoid generic "AI slop". Generic negatives ("don't use cream", "make it minimal") shift to another fixed palette rather than producing variety. Two approaches work:

**Specify a concrete alternative** — the model follows explicit specs precisely:

```
Visual direction: cold monochrome, pale silver-gray deepening into blue-gray and
near-black. Palette: #E9ECEC, #C9D2D4, #8C9A9E, #44545B, #11171B. Typography:
square, angular sans-serif with wide letter spacing. 4px corner radius across
cards, buttons, inputs. Generous margins.
```

**Have the model propose options** — breaks the default, gives the user control:

```
Before building, propose 4 distinct visual directions tailored to this brief
(each as: bg hex / accent hex / typeface -- one-line rationale). Ask the user
to pick one, then implement only that direction.
```

A minimal prompt snippet works well on 4.8:

*(This canonical snippet is the documented exception to the no-NEVER guidance in Tool Use Triggering above.)*

```xml
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter,
Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients
on white or dark backgrounds), predictable layouts and component patterns, and
cookie-cutter design that lacks context-specific character. Use unique fonts,
cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

If you have carried over a lengthy 4.6-era frontend snippet, try the minimal frontend_aesthetics block alone first; re-baseline against current output.

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#design-and-frontend-defaults

### Research and Information Gathering

For complex research tasks, prompt for structured investigation: develop competing hypotheses, track confidence levels in progress notes, self-critique the approach regularly, and persist findings to a hypothesis tree or research notes file.

### Structured Outputs

When you need JSON or a strict shape, Structured Outputs enforces it at the API level — the prompt should state intent and let the schema handle the shape.

Prompt-authoring implications:

- **Do not embed JSON templates or shape instructions in the prompt** when a structured-output schema is in play. The schema guarantees the shape; the prompt defines the task. Duplication confuses the model.
- **Keep the prompt focused on task intent**: "Extract the customer's contact info from the message below." The schema lists the fields.
- **Do not prefill { to force JSON** — prefill is rejected on 4.8. If you previously relied on that pattern, move to Structured Outputs or a direct instruction: "Respond with a JSON object only. No preamble or explanation."
- **Structured Outputs is incompatible with citations** — if your prompt asks for inline citations, don't pair it with a strict schema.

Source: https://platform.claude.com/docs/en/build-with-claude/structured-outputs

See [references/specialized-scenarios.md](references/specialized-scenarios.md) for the remaining specialized scenarios: interactive coding products, task budgets, the memory tool, high-resolution image support, computer use, cybersecurity safeguards, and fast mode.

## Prompt Migration Checklist

### From Opus 4.7

- [ ] Update model name from `claude-opus-4-7` to `claude-opus-4-8`.
- [ ] Re-evaluate your `effort` setting. The default is `high`; for coding/agentic work, set `xhigh` explicitly. Effort levels are recalibrated — re-baseline cost and latency.
- [ ] Remove any context-window beta header. The 1M context window is the default.
- [ ] Consider using mid-conversation system messages to preserve prompt cache hits on long conversations instead of rebuilding full message history.
- [ ] Verify stop-reason handling reads `stop_details` on refusals (now publicly documented).
- [ ] If you had aggressive tool-use prompting to work around 4.7's tool-skipping, test without it — 4.8 triggers better. Keep prompt guidance for explicit "when and why" conditions.
- [ ] If you had defensive prompting around compaction recovery, test without it — 4.8 handles compaction better.

### From Opus 4.6 or older

Apply the 4.7 migration steps first, then the 4.7->4.8 steps above:

- [ ] Replace CRITICAL/MUST/ALWAYS/NEVER/REQUIRED/MANDATORY with calm, direct equivalents.
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy"), explicit think-tool instructions, and compensatory over-prompting for older models.
- [ ] Replace "think" with "consider"/"evaluate"/"analyze" if adaptive thinking is off; remove manual "step 1, 2, 3" reasoning plans — a short cue works better with adaptive thinking.
- [ ] Add safety guardrails for destructive/irreversible actions and scope constraints to prevent over-engineering.
- [ ] Add LaTeX opt-out if rendering target does not support it.
- [ ] State scope explicitly where you previously relied on generalization; add verbosity guidance if product depends on a fixed response length.
- [ ] Flip subagent prompts from "limit use" to "encourage when appropriate" — 4.8 under-uses.
- [ ] Re-tune voice prompts for a warmer tone — 4.8 defaults more direct.
- [ ] Remove "summarize every N tool calls" scaffolding — native updates are better.
- [ ] Code review: shift to coverage-at-finding-stage or state the bar concretely.
- [ ] Frontend: specify concrete palettes or have model propose options.
- [ ] Replace prefill-based shape enforcement with Structured Outputs or "respond with JSON only".
- [ ] Drop "scale coordinates" phrasing from image prompts (4.8 reports 1:1 pixel coordinates); add explicit defensive-purpose framing to legitimate-security prompts that now refuse.
- [ ] Switch from extended thinking (budget_tokens) to adaptive thinking + effort; remove sampling parameters (temperature, top_p, top_k) — rejected on 4.8.

## Anti-Patterns

- **Aggressive emphasis** (CRITICAL: You MUST ALWAYS...) — overcorrects. Use direct, calm instructions.
- **Anti-laziness prompts** ("be thorough", "think carefully", "do not be lazy") — amplify proactive behavior.
- **Assuming generalization** — 4.8 applies instructions literally to what you named. State full scope.
- **Prescriptive reasoning plans when adaptive thinking is on** — hand-written "step 1, 2, 3" plans often underperform a short "think thoroughly" cue.
- **Prompting around low effort** — if reasoning is shallow at low/medium, raise effort rather than adding "think carefully".
- **Negative-only style direction** ("Don't use purple gradients") — shifts to a different fixed alternative. Use positive specs or propose-options patterns.
- **Suggesting instead of acting** — 4.8 takes verbs literally. Say "change" or "implement", not "suggest changes".
- **Qualitative code-review filters** ("only high-severity", "be conservative") — 4.8 follows them faithfully and drops findings. Prompt for coverage and filter separately, or state the bar concretely.
- **Conflicting instructions** ("concise but very detailed") — pick one or separate by context.
- **Ambiguous examples** — every example is a pattern the model may reproduce. Be precise.
- **Overloaded prompts** — break large requests into phases.
- **Over-prompting defaults** — remove instructions for what 4.8 does natively (interim summaries, parallel tool calls when independent, scope discipline).
- **Duplicating structured-output shape in the prompt** — with a schema in place, state intent only; don't repeat the shape.
- **"Think" sensitivity ignored** — when thinking is off at the parameter level, "think" variants can inadvertently trigger reasoning. Prefer "consider", "evaluate", "analyze".
- **Aggressive tool-use prompting carried from 4.7** — 4.8 triggers better; over-prompting now causes overcorrection.

## Reference

- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- What's new in 4.8: https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-8
- Migration guide: https://platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-from-claude-opus-47
- Adaptive thinking: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking
- Effort parameter: https://platform.claude.com/docs/en/build-with-claude/effort
- Structured outputs: https://platform.claude.com/docs/en/build-with-claude/structured-outputs
- Mid-conversation system messages: https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages
- Models overview: https://platform.claude.com/docs/en/about-claude/models/overview
