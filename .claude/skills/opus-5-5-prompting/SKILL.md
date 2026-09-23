---
name: opus-5-prompting
description: Apply when creating or editing prompts targeting Claude Opus 5 (model ID claude-opus-5). Covers response and deliverable length, progress narration, over-verification removal, subagent damping, self-correction narration, scope constraints, effort-level implications, code review harnesses, XML structure, long-context patterns, and migration from Opus 4.8. Do not apply to other Claude models — for Fable 5 use fable-5-prompting.
---

# Opus 5 Prompting

## When to Use

- Creating or editing system prompts targeting Opus 5
- Steering response length, deliverable length, and narration cadence
- Damping subagent spawning and self-verification
- Migrating prompt text from Opus 4.8 or older Claude models

## Overview

Opus 5 is Anthropic's model for complex agentic coding and enterprise work. It performs well out of the box on existing Opus 4.8 prompts — the changes below are tuning, not repair. Most of the tuning removes instructions that earlier models needed and Opus 5 does not.

<context>
Key behavioral characteristics to design around:

- **Longer by default**: Visible responses and files written to disk both run longer than on 4.8. Effort does not reliably shorten them — prompt for length explicitly.
- **Narrates more**: Announces what it is about to do during agentic work; per-message output in agentic sessions is longer than prior models'.
- **Self-verifying**: Checks and fixes its own work without being told to. Carried-over verification instructions cause over-verification.
- **Delegates readily**: Spawns subagents more eagerly than 4.8 — the opposite tuning direction from 4.8, which under-used them.
- **Expands scope**: Adds steps that weren't requested and applies its own judgment about what the task should be.
- **Narrates corrections**: Flags corrections to its own earlier statements more than prior models.
- **Effort converts to quality**: Turns additional effort into better results more reliably than any earlier Opus. `low` and `medium` hold quality at a fraction of the tokens.
- **Completes tasks**: Finishes multi-file features and refactors without leaving stubs or placeholders. Performs best given the full specification up front and left to run.
- **Thinks by default**: Reasoning is handled at the parameter level, so prompts should not prescribe it.
- **Consistent across long context**: Instruction following, tool calling, and reasoning stay consistent throughout a 1M-token window.
</context>

## Effort Levels — Prompt Implications

The default is `high`. If you carried an effort setting over from an earlier model, re-baseline it — the ladder is re-anchored from 4.8, where `xhigh` was the recommended coding default.

| Level | Prompt-authoring implication |
|-------|--------------|
| `max` | Deepest reasoning. Test where capability matters more than cost. Can overthink simpler tasks. Keep prompts lean. |
| `xhigh` | Demanding coding and agentic work. Same lean prompting style as `max` — avoid over-specifying reasoning steps. |
| `high` | Default. The right starting point for most workloads. |
| `medium` | Primary cost and latency control. Use liberally wherever quality holds. |
| `low` | Strong quality at a fraction of the tokens. Suitable for subagents, short scoped tasks, and high-volume work. Still viable for code review — accuracy holds at lower effort. |

Two things effort does **not** do:

- **It does not shorten visible responses.** Lowering effort reduces thinking volume, not output length. Prompt for length instead — see Response Length below.
- **It does not substitute for tools on vision tasks.** Giving the model tools to crop, analyze, and visually verify is a more cost-effective lever than raising effort.

Because thinking is on by default, **do not add "show your reasoning" or "think step by step"** — a short cue outperforms a hand-written reasoning plan.

## Response Length and Verbosity

Default user-facing responses run longer than on prior Opus models. A short conciseness instruction is effective:

```
Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested.
```

In a long system prompt, pair the instruction with a short reminder near the end:

```xml
<tone_preference>
Keep outputs reasonably concise.
</tone_preference>
```

### Written Deliverable Length

Separate from conversational verbosity: reports, Markdown documents, and summaries written to disk run long. If your product ships Claude-authored documents, calibrate explicitly:

```
Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.
```

### User-Facing Progress Updates

Opus 5 narrates readily during agentic work. Describe the cadence and shape you want rather than listing what to avoid:

```
Before your first tool call, say in one sentence what you're about to do. While working, give a brief update only when you find something important or change direction. When you finish, lead with the outcome: your first sentence should answer "what happened" or "what did you find," with supporting detail after it for readers who want it.
```

The same lever tunes narration up. Positive examples of the target style outperform prohibitions.

### Controlling Output Format

Four techniques in order of effectiveness:

1. **Tell Claude what to do, not what not to do** — "compose your response of smoothly flowing prose paragraphs" beats "do not use markdown in your response".
2. **Use XML format indicators** — "Write the prose sections of your response in `<smoothly_flowing_prose_paragraphs>` tags."
3. **Match prompt style to output style** — removing markdown from your prompt reduces markdown in the output.
4. **Use detailed prompts for formatting preferences.**

For over-formatted responses (bullet-soup, unnecessary bold), add an `<avoid_excessive_markdown_and_bullet_points>` block: write long-form content in clear, flowing prose; reserve markdown primarily for inline code, code blocks, and simple headings (###); use lists only for truly discrete items or when the user explicitly requests a list or ranking.

## Task Scope and Over-Verification

**Remove verification instructions carried over from earlier models.** Opus 5 verifies its own work unprompted. Instructions like "include a final verification step for any non-trivial task", "use a subagent to verify", "double-check your answer", or "re-verify before responding" compound with native behavior and burn tokens with no quality gain. The same applies to legacy harness scaffolding that adds separate verification steps.

Opus 5 also expands the scope of narrow tasks. Constrain explicitly:

```
Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it. Finish the whole task, and stop short of actions that are clearly beyond what was asked.
```

For code-level over-engineering, the scope-constraint block still applies:

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

## Self-Correction

Opus 5 catches and fixes its own mistakes well without prompting — avoid instructing re-checks it already performs.

It also narrates corrections to earlier statements more than prior models, which reads poorly in user-facing products:

```
Only correct an earlier statement when the error would change the user's code, conclusions, or decisions. State corrections plainly and briefly, then continue the task. For slips that change nothing for the user, make the fix and move on without noting it.
```

## Behavioral Tuning

### Controlling Subagent Spawning

Opus 5 delegates more readily than prior models. Delegation pays off on genuinely independent, sizeable tracks of work; it multiplies cost and time on small tasks. Give explicit criteria, or cap spawn counts in the harness.

```xml
<subagent_guidance>
Delegate to a subagent only for large tasks that are genuinely independent and
parallelizable, such as a wide multi-file investigation. Do not delegate work you can
finish yourself in a handful of tool calls, and do not use subagents to verify or
double-check your own work. If one subagent can complete the task, use one rather than
several, and keep spawn counts low.
</subagent_guidance>
```

Multi-agent coordination itself is strong — writer-verifier patterns work well and agents rarely overwrite each other's work. The problem is volume, not quality.

### Tool Use Triggering

Keep language calm and conditional. Forceful phrasing needed for older models causes overcorrection:

| Avoid | Use |
|-------|-----|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |

Drop these markers from prompts: `CRITICAL`, `You MUST`, `ALWAYS`, `NEVER`, `REQUIRED`, `MANDATORY`, `IMPORTANT:`. Prefer direct statements or `should`; replace `NEVER` with `Don't` or the positive alternative.

### Parallel Tool Calling

Opus 5 defaults to parallel tool calls when independent. To reinforce to ~100%:

```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between them,
make all of the independent tool calls in parallel. For example, when reading
3 files, run 3 tool calls in parallel. If some tool calls depend on previous
results to inform parameters, call them sequentially instead. Never use
placeholders or guess missing parameters.
</use_parallel_tool_calls>
```

### Balancing Autonomy and Safety

Distinguish reversible from irreversible actions explicitly.

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

### Action vs Suggestion Steering

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

Opus 5 is less prone to hallucination but can still speculate about unread code:

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

LaTeX opt-out (Opus models default to LaTeX for math): "Use plain text notation rather than LaTeX. For example, write 'x^2 + 3x + 1' instead of '$x^2 + 3x + 1$'."

## Prompt Structure

### XML Tags

XML tags help Claude parse prompts that mix instructions, context, examples, and variable inputs.

**Principles:**
- Use consistent, descriptive tag names across your prompts.
- Nest when content has natural hierarchy (`<documents>` -> `<document index="n">` -> `<document_content>` + `<source>`).
- Prefer expressive interfaces (tool parameter design, schemas, rubrics) over usage examples — on Claude 5-generation models, examples constrain exploration. Where examples are needed to pin an output format, wrap them in `<examples>` with each in `<example>`; 3-5 precise ones.

**Commonly used in Anthropic's own examples:** `<documents>`/`<document>` (with `<source>`, `<document_content>`), `<context>`, `<instructions>`, `<task>`, `<examples>`/`<example>` (with `<input>`, `<output>`), `<format>`, `<output_format>`, `<quotes>`, and named behavioral-steering tags (`<use_parallel_tool_calls>`, `<default_to_action>`, `<do_not_act_before_instructions>`, `<investigate_before_answering>`, `<frontend_aesthetics>`, `<avoid_excessive_markdown_and_bullet_points>`, `<scope_constraints>`, `<action_safety>`, `<subagent_guidance>`, `<tone_preference>`).

Default to markdown headers and tables where they are sufficient; reach for XML when you need unambiguous separation or when an instruction has a natural name.

### Long-Context Prompting

Instruction following and tool calling stay consistent across the full window. When prompts exceed 20k tokens:

- **Put long documents at the top, query at the end.** Queries-last improves response quality by up to 30% in Anthropic's tests, especially with multi-document inputs.
- **Wrap each document** in `<document index="n">` with `<source>` and `<document_content>` subtags; wrap the collection in `<documents>`.
- **Ground in quotes** for long-document tasks: ask Claude to extract relevant quotes into `<quotes>` before answering, then reason from there.

### Context Awareness

Claude tracks its remaining token budget. If your harness compacts context or writes to external files, prevent premature wrap-up:

```
Your context window will be automatically compacted as it approaches its limit,
allowing you to continue working from where you left off. Do not stop tasks early
due to token budget concerns. As you approach your budget, save progress to memory
before the context refreshes. Never artificially stop a task early regardless of
the context remaining.
```

### Prefilling Not Supported

Assistant-message prefill on the last turn is rejected on Claude 4.6 models and later. Replacement phrasings:

- **Force JSON/YAML shape**: Use Structured Outputs. For simple cases: "Respond with a JSON object only. No preamble or explanation."
- **Strip preambles** ("Here is the..."): "Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc."
- **Continue after interruption**: Move the continuation into the user turn: "Your previous response was interrupted and ended with [previous_response]. Continue from where you left off."
- **Role consistency reminders**: Inject them into the user turn, or use a mid-conversation system message.

## Specialized Scenarios

### Code Review Harnesses

Opus 5 reviews with high precision and recall — real bugs at a high rate per pass, with additional findings mostly real rather than false positives. Accuracy holds at lower effort, which supports a fast `low`/`medium` pass at review time and a thorough `xhigh` pass later.

Qualitative filters backfire. "Only report high-severity issues" or "be conservative" are followed literally and drop real findings. Prompt for coverage, filter separately:

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

### Interactive Coding Products

Opus 5 performs best given the complete task specification up front and left to run.

- **Specify task, intent, and constraints in the first user turn.** A well-specified first turn pays off more than progressive clarification across many turns.
- **Avoid ambiguous prompts conveyed incrementally** — this pattern hurts efficiency and sometimes quality.
- **Match effort to difficulty rather than defaulting high.** Single-turn edits show a smaller gap from prior models; `low` and `medium` hold quality there.

### Vision

Strong on chart, document, and diagram understanding, and on UI and frontend visual replication.

- **Re-validate vision workarounds** tuned for prior models — coordinate-scaling hacks, resolution caveats, and defensive framing may no longer be needed.
- **Give the model tools** to iteratively analyze, crop, and visually verify: "If you need pixel-level detail from part of an image, call the crop tool to zoom into that region first, then analyze the crop."
- **Ask for a visual verification loop** on replication tasks: render, screenshot, compare against the target, iterate.

### Office and Document Tasks

Opus 5 generates and edits complex multi-sheet spreadsheets with non-trivial formulas, and produces well-structured slide decks. Supply the specific styles, templates, or house formats it should follow — it follows explicit specs precisely, and the deliverable-length calibration above applies here too.

### Long-Running Agents and Memory

When a memory tool is in play, give domain-specific guidance (what to record, what to read) rather than re-explaining the tool:

- "Before starting work, view /memories to load any prior progress."
- "Update /memories/progress.md when you finish a feature; record assumptions that may need verifying later."

For multi-session work, use the initializer/subsequent-session pattern: the first session writes a progress log, feature checklist, and startup script; subsequent sessions read memory before starting, work on one feature at a time, and update memory before ending. Constrain file-path parameters ("Only access paths under /memories") — path traversal is a known concern.

### Frontend Design

Without guidance, models converge on generic "AI slop" patterns. Anthropic's current snippet is model-neutral:

```xml
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter,
Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients
on white or dark backgrounds), predictable layouts and component patterns, and
cookie-cutter design that lacks context-specific character. Use unique fonts,
cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

*(This canonical snippet is the documented exception to the no-NEVER guidance in Tool Use Triggering above.)*

Generic negatives ("don't use cream", "make it minimal") shift the model to another fixed palette rather than producing variety. Two approaches work: specify a concrete alternative (palette hexes, typeface, radius, spacing), or have the model propose 3-4 distinct visual directions and implement only the one the user picks.

Opus 4.8 had a documented house style with a fixed palette and typeface set. No equivalent default is documented for Opus 5 — if you carried palette-specific counter-prompting over from a 4.8 prompt, re-baseline it against actual output before keeping it.

### Structured Outputs

Structured Outputs enforces shape at the schema level — the prompt should state intent and let the schema handle the shape.

- **Do not embed JSON templates or shape instructions in the prompt** when a schema is in play. Duplication confuses the model.
- **Keep the prompt focused on task intent**: "Extract the customer's contact info from the message below." The schema lists the fields.
- **Structured Outputs is incompatible with citations** — don't pair a strict schema with a request for inline citations.

### Security Framing

Opus 5 runs cybersecurity safety classifiers. Legitimate security work can be refused where the purpose is ambiguous.

- **State the defensive or authorized purpose explicitly**: "You are assisting an authorized security engineer performing an internal pen test..."
- **Don't rely on prompt injection or roleplay** to bypass the safeguard.

### Running with Thinking Disabled

Thinking can only be disabled at `high` effort or below. Where it is disabled, two artifacts can appear in visible output. The primary mitigation for both is to keep thinking enabled and control cost with lower effort instead — thinking on at `low` effort outperforms thinking off at similar cost.

**Tool calls as text.** The model occasionally writes a tool call into user-facing text instead of emitting a structured tool call. The turn completes, the call never runs, and in agentic loops the leaked text stays in history and affects later turns. Most common on tool-heavy workloads such as search.

**Internal XML tags in output.** The model can emit `<thinking>` or other internal tags into its visible response. If your system prompt contains a rule instructing the model not to think or not to reason, remove it — that increases tag leakage.

For prompts that must run with thinking disabled, one combined instruction mitigates both:

```
When you use a tool, you may say a brief sentence first. If no tool can express what the user asked for, say so instead of guessing. Do not include internal or system XML tags in your response.
```

Instructions that call out thinking tags by name are less effective than the general form — avoid naming them specifically.

## Prompt Migration Checklist

### From Opus 4.8

- [ ] Add explicit conciseness guidance — responses and written files both run longer, and lowering effort does not shorten them.
- [ ] Add written-deliverable length calibration if your product ships Claude-authored documents.
- [ ] Add narration-cadence guidance for agentic products — Opus 5 announces its intentions more often.
- [ ] **Remove** verification and self-check instructions ("include a final verification step", "use a subagent to verify", "double-check your answer"). They cause over-verification.
- [ ] Flip subagent prompts from "encourage when appropriate" to explicit delegation criteria or hard caps — 4.8 under-used subagents, Opus 5 over-uses them.
- [ ] Add scope constraints for narrow tasks.
- [ ] Add correction-narration limits for user-facing products.
- [ ] Remove "think step by step" and hand-written reasoning plans — thinking is on by default and handled at the parameter level.
- [ ] Re-baseline effort per route rather than carrying over 4.8's `xhigh`-for-coding default; `low` and `medium` are the primary cost controls.
- [ ] Re-validate vision workarounds tuned for prior models; prefer giving crop/analysis tools over raising effort.
- [ ] Re-baseline frontend counter-prompting — the 4.8 house-style palette is not documented for Opus 5.
- [ ] Rightsize context: convert worst-case guardrails to principles, state each instruction once across system prompt / tool descriptions / CLAUDE.md, and move detail into selectively loaded skills. Anthropic removed over 80% of Claude Code's system prompt for Claude 5-generation models with no measured eval loss; `/doctor` in Claude Code rightsizes CLAUDE.md and skills.

### From Opus 4.7 or older

Apply these first, then the 4.8 -> 5 steps above:

- [ ] Replace CRITICAL/MUST/ALWAYS/NEVER/REQUIRED/MANDATORY with calm, direct equivalents.
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy") and explicit think-tool instructions.
- [ ] Remove manual "step 1, 2, 3" reasoning plans.
- [ ] Replace prefill-based shape enforcement with Structured Outputs or "respond with JSON only".
- [ ] Remove "summarize every N tool calls" scaffolding — native updates are better.
- [ ] Add safety guardrails for destructive/irreversible actions.
- [ ] Add LaTeX opt-out if your rendering target doesn't support it.
- [ ] Add explicit defensive-purpose framing to legitimate security prompts.

## Anti-Patterns

- **Carried-over verification instructions** — Opus 5 verifies natively; "double-check", "add a verification step", and "use a subagent to verify" all compound and waste tokens.
- **Subagent encouragement carried from 4.8** — 4.8 under-used subagents and needed a push. Opus 5 needs a cap.
- **Relying on effort to shorten responses** — effort controls thinking volume, not visible length. Prompt for length.
- **Aggressive emphasis** (CRITICAL: You MUST ALWAYS...) — overcorrects. Use direct, calm instructions.
- **Anti-laziness prompts** ("be thorough", "think carefully", "do not be lazy") — amplify already-proactive behavior.
- **Qualitative code-review filters** ("only high-severity", "be conservative") — followed literally; real findings get dropped. Prompt for coverage and filter separately.
- **Turning thinking off to save cost** — thinking on at `low` effort outperforms thinking off at similar cost, and avoids tool-call-as-text and XML-tag leakage.
- **Rules telling the model not to think or reason** — increase internal-tag leakage when thinking is disabled.
- **Naming `<thinking>` tags in mitigation instructions** — the general "no internal XML tags" form works better.
- **Prescriptive reasoning plans** — hand-written step plans underperform a short cue.
- **Negative-only style direction** ("Don't use purple gradients") — shifts to a different fixed alternative. Use positive specs or propose-options patterns.
- **Suggesting instead of acting** — Opus 5 takes verbs literally. Say "change" or "implement", not "suggest changes".
- **Conflicting instructions** ("concise but very detailed") — pick one or separate by context.
- **Ambiguous examples** — every example is a pattern the model may reproduce. Be precise.
- **Duplicating structured-output shape in the prompt** — with a schema in place, state intent only.
- **Repeating an instruction across system prompt, tool descriptions, and CLAUDE.md** — Claude 5-generation models internalize an instruction stated once; consolidate it where it belongs (usually the tool description).

## Reference

- Prompting Opus 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- What's new in Opus 5: https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5
- Migration guide: https://platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-from-claude-opus-4-8-to-claude-opus-5
- Context engineering for Claude 5-generation models: https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
