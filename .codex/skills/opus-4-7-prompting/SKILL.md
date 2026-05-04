---
name: opus-4-7-prompting
description: Apply when creating or editing prompts targeting Claude Opus 4.7 (model ID claude-opus-4-7). Covers literal instruction following, response-length calibration, tool and subagent under-triggering, tone shifts, XML structure, design defaults, code review patterns, adaptive thinking behavior, effort-level prompt implications (max/xhigh/high/medium/low), and migration from Opus 4.6.
---

# Opus 4.7 Prompting

## When to Use

- Creating or editing system prompts targeting Opus 4.7
- Steering response length, verbosity, and voice in prompts
- Tuning tool usage and subagent spawning
- Migrating prompt text from Opus 4.6 or older Claude models

## Overview

Opus 4.7 is Anthropic's most capable generally available model (1M context, 128k max output). Existing Opus 4.6 prompts generally carry forward, but several default behaviors shifted — prompts need re-tuning for tone, verbosity, tool-triggering, and scope. Note: on 4.7, sampling parameters (`temperature`, `top_p`, `top_k`) at non-default values are rejected; prompts that rely on `temperature=0` determinism need different strategies (e.g., Structured Outputs for shape constraints).

<context>
Key behavioral characteristics to design around:

- **More literal**: Follows instructions exactly as written; does not silently generalize. State scope explicitly. Particularly pronounced at `low` and `medium` effort.
- **Adaptive length**: Shorter on simple lookups, longer on open-ended analysis. Tune if your product depends on a fixed verbosity.
- **Lower tool/subagent trigger bar**: Prefers reasoning over tool calls and direct work over delegation. Raising effort to `high` or `xhigh` increases tool use; prompt explicitly for more.
- **Direct, opinionated tone**: Less validation-forward, fewer emoji, more concise than 4.6's warmer default.
- **Native progress updates**: Produces higher-quality interim updates without scaffolding.
- **Strict effort respect**: Meaningfully stricter than 4.6, especially at low/medium — scopes work to what was asked.
- **Strong design defaults**: Persistent house style (cream/terracotta/Fraunces) on frontend work.
- **Long-horizon reasoning**: Exceptional state tracking across extended interactions and context windows.
</context>

## Effort Levels — Prompt Implications

On 4.7, the `effort` parameter controls reasoning depth and has a big influence on how your prompt should be written. Target effort `max` on Opus 4.7 when you want the deepest reasoning; it is the recommended default for new deployments. The levels and what they mean for prompt authoring:

| Level | Prompt-authoring implication |
|-------|--------------|
| `max` | Deepest reasoning. You can keep prompts lean — 4.7 fills gaps with reasoning. Prescribing step-by-step plans here often underperforms a short "think thoroughly" cue. |
| `xhigh` (new) | Strong alternative for coding and agentic workloads. Same prompting style as `max` — avoid over-specifying reasoning steps. |
| `high` | Minimum for most intelligence-sensitive use cases. Prompts can still be lean; add scope hints where you previously needed them. |
| `medium` | Cost-sensitive. **Strict scope** — the model does not go "above and beyond". If you want extra steps, list them explicitly. |
| `low` | Short, scoped tasks. Risk of under-thinking on complex prompts. Add targeted reasoning cues if the task is non-trivial. |

4.7 respects effort **strictly** at `low`/`medium`, unlike 4.6 which tended to elaborate. If you see shallow reasoning on a complex task, raise effort rather than prompting around it. If you must keep effort low, add targeted guidance:

```
This task involves multi-step reasoning. Work through the problem carefully before responding.
```

Source: https://platform.claude.com/docs/en/build-with-claude/effort#recommended-effort-levels-for-claude-opus-4-7

### Adaptive Thinking — Prompt Behavior

On Opus 4.7, adaptive thinking is the only supported thinking mode. When it is enabled, the model decides how deeply to reason based on task complexity. **When adaptive thinking is on, do not add "show your reasoning" or "think step by step" to your prompt — reasoning is already handled by the parameter.** Prescribing reasoning steps often underperforms a simple cue like "think thoroughly."

Adaptive thinking is promptable. Large system prompts can over-trigger thinking on moderate queries; if you see that, add:

```
Thinking adds latency and should only be used when it will meaningfully improve
answer quality — typically for problems that require multi-step reasoning.
When in doubt, respond directly.
```

Source: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking#tuning-thinking-behavior

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

### Examples Are Load-Bearing

Positive examples outperform "don't do X" instructions. Every example is a pattern the model may reproduce — if an example contains an anti-pattern, it leaks into the output. Be precise.

### Long-Horizon Reasoning

Opus 4.7 excels at tasks spanning many steps, files, or reasoning chains. Structure long tasks as sequences of verifiable milestones rather than monolithic instructions.

## Response Length and Verbosity

Opus 4.7 calibrates response length to task complexity rather than defaulting to a fixed verbosity. Simple lookups get shorter answers; open-ended analysis gets longer ones.

If your product depends on a specific style or verbosity, tune with prompts:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

For specific kinds of over-explanation, show a positive example of the target concision rather than listing what to avoid.

### Controlling Output Format

Four techniques in order of effectiveness (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#control-the-format-of-responses):

1. **Tell Claude what to do, not what not to do.**
   Instead of: "Do not use markdown in your response"
   Try: "Your response should be composed of smoothly flowing prose paragraphs."

2. **Use XML format indicators.**
   "Write the prose sections of your response in `<smoothly_flowing_prose_paragraphs>` tags."

3. **Match prompt style to output style.**
   Removing markdown from your prompt reduces markdown in the output.

4. **Use detailed prompts for formatting preferences.**

For reducing over-formatted responses (bullet-soup, unnecessary bold):

```xml
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form
content, write in clear, flowing prose using complete paragraphs and sentences. Use
standard paragraph breaks for organization and reserve markdown primarily for
`inline code`, code blocks (```...```), and simple headings (###).

DO NOT use ordered lists (1. ...) or unordered lists (*) unless a) you're presenting
truly discrete items where a list format is the best option, or b) the user explicitly
requests a list or ranking.

Instead of listing items with bullets or numbers, incorporate them naturally into
sentences.
</avoid_excessive_markdown_and_bullet_points>
```

For post-tool-call summaries (4.7 may skip them):

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

**Word sensitivity.** When adaptive thinking is off, the word "think" and its variants can inadvertently trigger internal reasoning. Large/complex system prompts can also over-trigger adaptive thinking (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#calibrating-effort-and-thinking-depth). Prefer neutral alternatives:

| Avoid | Use |
|-------|-----|
| "think about" | "consider" |
| "think through" | "evaluate" |
| "think carefully" | "analyze carefully" |
| "I think" | "I believe" |
| "think step by step" | "work through step by step" |

## Prompt Structure

### XML Tags

XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#structure-prompts-with-xml-tags).

**Principles:**
- Use consistent, descriptive tag names across your prompts.
- Nest when content has natural hierarchy (`<documents>` → `<document index="n">` → `<document_content>` + `<source>`).
- Wrap multiple examples in `<examples>` with each in `<example>`; 3–5 examples is Anthropic's recommended range.

**Commonly used in Anthropic's own examples:**
- Input content: `<document>`, `<documents>`, `<document_content>`, `<source>`, `<context>`
- Directives and constraints: `<instructions>`, `<task>`, `<requirements>`, `<constraint>`
- Demonstrations: `<example>`, `<examples>`, `<input>`, `<output>`
- Output shape: `<format>`, `<output_format>`, `<answer>`
- Long-context grounding: `<quotes>`, `<info>`
- Reasoning in few-shot examples: `<thinking>`
- Behavioral steering (4.7-specific): `<use_parallel_tool_calls>`, `<default_to_action>`, `<do_not_act_before_instructions>`, `<investigate_before_answering>`, `<frontend_aesthetics>`, `<avoid_excessive_markdown_and_bullet_points>`, `<scope_constraints>`, `<action_safety>`

Default to markdown headers and tables where they are sufficient; reach for XML when you need unambiguous separation or when an instruction has a natural name.

### Long-Context Prompting

When prompts exceed 20k tokens (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#long-context-prompting):

- **Put long documents at the top, query at the end.** Queries-last improves response quality by up to 30% in Anthropic's tests, especially with multi-document inputs.
- **Wrap each document** in `<document index="n">` with `<source>` and `<document_content>` subtags; wrap the collection in `<documents>`.
- **Ground in quotes** for long-document tasks: ask Claude to extract relevant quotes into `<quotes>` before answering, then reason from there. Cuts through noise and reduces fabrication.

Skeleton:

```xml
<documents>
  <document index="1">
    <source>annual_report_2023.pdf</source>
    <document_content>{{ANNUAL_REPORT}}</document_content>
  </document>
</documents>

Analyze the document above. {{ question }}
```

4.7 has a 1M context window at standard pricing. The new tokenizer consumes up to ~35% more tokens per unit of text vs 4.6 — budget longer prompts accordingly (https://platform.claude.com/docs/en/about-claude/models/migration-guide#updated-token-counting).

### Context Awareness

Claude 4.6/4.5 tracks its remaining token budget explicitly; 4.7 is not named in docs but assume similar. If your agent harness compacts context or writes to external files, prevent premature wrap-up:

```
Your context window will be automatically compacted as it approaches its limit,
allowing you to continue working from where you left off. Do not stop tasks early
due to token budget concerns. As you approach your budget, save progress to memory
before the context refreshes. Never artificially stop a task early regardless of
the context remaining.
```

### Prefilling Not Supported

Assistant-message prefill on the last turn is rejected starting with Opus 4.6. Replacement phrasings for prompts that used to rely on it:

- **Force JSON/YAML shape**: Use Structured Outputs (see below). For simple cases: `"Respond with a JSON object only. No preamble or explanation."`
- **Strip preambles** ("Here is the..."): `"Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc."`
- **Continue after interruption**: Move the continuation into the user turn: `"Your previous response was interrupted and ended with [previous_response]. Continue from where you left off."`
- **Role consistency reminders**: Inject them into the user turn, or expose them as a tool the model can call.

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#migrating-away-from-prefilled-responses

## Behavioral Tuning

### Tool Use Triggering

Opus 4.7 uses tools less often than 4.6 and relies more on reasoning. If you want more tool use, state when and why explicitly:

```
Use the web search tool whenever the question involves current events, recent
product releases, or facts that may have changed since your training cutoff.
Describe your search strategy before calling the tool.
```

Keep language calm and conditional — forceful phrasing needed for older models now causes overcorrection:

| Avoid | Use |
|-------|-----|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |

Drop these aggressive markers from prompts: `CRITICAL`, `You MUST`, `ALWAYS`, `NEVER`, `REQUIRED`, `MANDATORY`, `IMPORTANT:`. Prefer direct statements or `should`; replace `NEVER` with `Don't` or the positive alternative.

**Effort first, then prompt guidance.** Raising effort to `high`/`xhigh`/`max` also increases tool use. Try the effort lever before adding prompt scaffolding; then add when-and-why conditions.

(Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#tool-use-triggering)

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

Opus 4.7 spawns fewer subagents by default than 4.6. If your workflow benefits from subagents (parallel fan-out, isolated context, multi-file reads), prompt for it explicitly. Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#controlling-subagent-spawning

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

### Tone, Voice, and Progress Updates

4.7 is more direct and opinionated than 4.6 — less validation-forward, fewer emoji. For warmer voice: `"Use a warm, collaborative tone. Acknowledge the user's framing before answering."`

Native interim updates during long agentic traces are already high-quality — remove legacy scaffolding like "after every 3 tool calls, summarize progress." If updates don't match your product's needs, describe the target format explicitly with a positive example.

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

### Temporary Files, Test Gaming, LaTeX

Scratch-file cleanup: `"If you create any temporary files for iteration, remove them at the end of the task."`

Test hard-coding prevention: `"Write a general-purpose solution. Do not hard-code values or create solutions that only work for specific test inputs. If tests are incorrect, inform me rather than working around them."`

LaTeX opt-out (4.7 defaults to LaTeX for math): `"Use plain text notation rather than LaTeX. For example, write 'x^2 + 3x + 1' instead of '$x^2 + 3x + 1$'."`

## Specialized Scenarios

### Code Review Harnesses

4.7 follows filtering instructions more faithfully than 4.6. "Only report high-severity issues" or "be conservative" causes it to find bugs then drop findings below the bar — reads as lower recall.

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

### Interactive Coding Products

Interactive multi-turn sessions cost more tokens than autonomous single-turn agents — 4.7 reasons more after user turns. That improves long-horizon coherence and instruction following, at token cost. Prompt-authoring implications:

- **Specify task, intent, and constraints upfront** in the first user turn. A well-specified first turn pays off more on 4.7 than on prior models.
- **Avoid ambiguous prompts conveyed progressively** across many turns — this pattern hurts efficiency and sometimes quality.
- **Favor auto modes** in prompts where safe — reduce required human interactions.

### Frontend Design

Opus 4.7 has a persistent house style: warm cream (~#F4F1EA), serifs (Georgia, Fraunces, Playfair), italic accents, terracotta/amber. Reads well for editorial and hospitality briefs; feels off for dashboards, dev tools, fintech, healthcare, enterprise.

Generic negatives ("don't use cream", "make it minimal") shift to another fixed palette rather than producing variety. Two approaches work:

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

4.7 requires less prompting than earlier models to avoid generic "AI slop". A short snippet works:

```xml
<frontend_aesthetics>
Avoid generic AI-generated aesthetics: overused fonts (Inter, Roboto, Arial,
system fonts), cliched color schemes (purple gradients on white or dark),
predictable layouts, cookie-cutter components. Use distinctive fonts, cohesive
color themes, and purposeful animations for micro-interactions.
</frontend_aesthetics>
```

If you've carried over a lengthy 4.6-era frontend snippet, try the minimal `<frontend_aesthetics>` block above alone first; re-baseline against current output. (Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#design-and-frontend-defaults)

### Research and Information Gathering

For complex research tasks:

```
Search for this information in a structured way. As you gather data, develop several
competing hypotheses. Track your confidence levels in your progress notes to improve
calibration. Regularly self-critique your approach and plan. Update a hypothesis
tree or research notes file to persist information and provide transparency. Break
down this complex research task systematically.
```

### Structured Outputs

When you need JSON or a strict shape, Structured Outputs enforces it at the API level — the prompt should state intent and let the schema handle the shape.

Prompt-authoring implications:

- **Do not embed JSON templates or shape instructions in the prompt** when a structured-output schema is in play. The schema guarantees the shape; the prompt defines the task. Duplication confuses the model.
- **Keep the prompt focused on task intent**: "Extract the customer's contact info from the message below." The schema lists the fields.
- **Do not prefill `{` to force JSON** — prefill is rejected on 4.7. If you previously relied on that pattern, move to Structured Outputs or a direct instruction: "Respond with a JSON object only. No preamble or explanation."
- **Structured Outputs is incompatible with citations** — if your prompt asks for inline citations, don't pair it with a strict schema.

Source: https://platform.claude.com/docs/en/build-with-claude/structured-outputs

### Task Budgets — Prompting Implications

Task Budgets (beta) give the model an advisory token budget across a full agentic loop; it sees a running countdown and paces accordingly. Prompt-authoring implications:

- **Budget-aware prompts can skip scaffolding** like "work efficiently" or "don't get stuck" — the budget itself paces the model.
- **Budgets below 20k tokens are rejected and budgets that are clearly insufficient for the task cause 4.7 to refuse or stop early.** If you're prompting for a large job, state the scope plainly rather than relying on the budget to keep the model focused.
- **Instruct the model to finish gracefully** if your task benefits from end-of-budget summaries: `"As the task budget nears depletion, finalize and summarize progress rather than starting new subtasks."`
- **Don't layer a `task_budget` onto open-ended research prompts** where quality matters more than speed — let the model run without the countdown.

Source: https://platform.claude.com/docs/en/build-with-claude/task-budgets

### Memory Tool and Long-Running Agents

4.7 is meaningfully better at writing and using file-system-based memory than 4.6. When a memory tool is in play, prompts should give domain-specific guidance (what to record, what to read) rather than re-explaining the tool — Anthropic's built-in memory system prompt already covers tool usage.

Useful phrasings:

- `"Before starting work, view /memories to load any prior progress."`
- `"Update /memories/progress.md when you finish a feature; record assumptions that may need verifying later."`

For multi-session software development, use the initializer/subsequent-session pattern: first session writes a progress log, feature checklist, and startup script; subsequent sessions read memory before starting, work on one feature at a time, update memory before ending.

Path-safety: constrain file-path parameters in the prompt ("Only access paths under `/memories`") — path-traversal is a known concern.

Source: https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool

### High-Resolution Image Support

4.7 supports images up to 2576px / 3.75MP (up from 1568px / 1.15MP on 4.6), and model-emitted coordinates are 1:1 with actual image pixels.

Prompt-authoring implications:

- **Remove any "scale coordinates by X" instructions** from prompts carried over from 4.6 — 4.7 reports coordinates in actual pixel space.
- **For pointing / bounding-box / chart-transcription tasks**, you can ask for precise pixel coordinates without scaling caveats.
- **If your harness exposes a crop tool**, tell the model to crop into regions before detailed inspection: `"If you need pixel-level detail from part of an image, call the crop tool to zoom into that region first, then analyze the crop."` Anthropic's cookbook reports consistent uplift from this pattern (https://platform.claude.com/cookbook/multimodal-crop-tool).
- **Image-heavy prompts consume up to ~3x more tokens per full-res image** vs 4.6 — factor this into your context budgeting when you size prompts.

Source: https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-7#high-resolution-image-support

### Cybersecurity Safeguards

New on 4.7: a real-time safeguard layer for cybersecurity topics. Requests involving prohibited or high-risk cyber topics may lead to refusals that didn't happen on 4.6 (`stop_reason: "refusal"`). Source: https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-7#behavior-changes

Prompt-authoring implications:

- **Legitimate security prompts (pen testing, vulnerability research, red teaming)** may now be refused where 4.6 would comply. Consider applying to the Cyber Verification Program for reduced restrictions: https://claude.com/form/cyber-use-case
- **Framing matters.** Be explicit about the defensive/legitimate purpose in the prompt when it's ambiguous ("You are assisting an authorized security engineer performing an internal pen test..."). This is the same guidance as 4.6 but more load-bearing on 4.7.
- **Don't rely on prompt injection or roleplay** to bypass the safeguard — 4.7 is less susceptible.

## Prompt Migration Checklist

### From any older Claude

- [ ] Replace CRITICAL/MUST/ALWAYS/NEVER/REQUIRED/MANDATORY with calm, direct equivalents.
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy").
- [ ] Remove explicit think-tool instructions and compensatory over-prompting for older models.
- [ ] Replace "think" with "consider"/"evaluate"/"analyze" if adaptive thinking is off.
- [ ] Add safety guardrails for destructive/irreversible actions.
- [ ] Add scope constraints to prevent over-engineering.
- [ ] Add LaTeX opt-out if rendering target does not support it.

### From Opus 4.6 specifically

- [ ] State scope explicitly where you previously relied on generalization ("every X, not just the first").
- [ ] Add verbosity guidance if product depends on a fixed response length.
- [ ] Flip subagent prompts from "limit use" to "encourage when appropriate" — 4.7 under-uses.
- [ ] Encourage tool use explicitly where under-triggering matters (raise effort first, then add prompt guidance).
- [ ] Re-tune voice prompts for a warmer tone — 4.7 defaults more direct.
- [ ] Remove "summarize every N tool calls" scaffolding — native updates are better.
- [ ] Code review: shift to coverage-at-finding-stage or state the bar concretely.
- [ ] Frontend: specify concrete palettes or have model propose options; try the minimal `<frontend_aesthetics>` snippet first.
- [ ] Replace prefill-based shape enforcement with Structured Outputs or `"respond with JSON only"`.
- [ ] Remove manual "step 1, 2, 3" reasoning plans — a short cue works better with adaptive thinking.
- [ ] Drop "scale coordinates" phrasing from image prompts — 4.7 reports 1:1 pixel coordinates.
- [ ] Add explicit defensive-purpose framing to legitimate-security prompts that now refuse; apply to the Cyber Verification Program if needed.

Sources: https://platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-to-claude-opus-4-7, https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-7

## Anti-Patterns

- **Aggressive emphasis** (`CRITICAL: You MUST ALWAYS...`) — overcorrects. Use direct, calm instructions.
- **Anti-laziness prompts** ("be thorough", "think carefully", "do not be lazy") — amplify proactive behavior.
- **Assuming generalization** — 4.7 applies instructions literally to what you named. State full scope.
- **Prescriptive reasoning plans when adaptive thinking is on** — hand-written "step 1, 2, 3" plans often underperform a short "think thoroughly" cue.
- **Prompting around low effort** — if reasoning is shallow at `low`/`medium`, raise effort rather than adding "think carefully".
- **Negative-only style direction** ("Don't use purple gradients") — shifts to a different fixed alternative. Use positive specs or propose-options patterns.
- **Suggesting instead of acting** — 4.7 takes verbs literally. Say "change" or "implement", not "suggest changes".
- **Qualitative code-review filters** ("only high-severity", "be conservative") — 4.7 follows them faithfully and drops findings. Prompt for coverage and filter separately, or state the bar concretely.
- **Conflicting instructions** ("concise but very detailed") — pick one or separate by context.
- **Ambiguous examples** — every example is a pattern the model may reproduce. Be precise.
- **Overloaded prompts** — break large requests into phases.
- **Over-prompting defaults** — remove instructions for what 4.7 does natively (interim summaries, parallel tool calls when independent, scope discipline).
- **Duplicating structured-output shape in the prompt** — with a schema in place, state intent only; don't repeat the shape.
- **"Think" sensitivity ignored** — when thinking is off at the parameter level, "think" variants can inadvertently trigger reasoning. Prefer "consider", "evaluate", "analyze".

## Reference

- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- What's new in 4.7: https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-7
- Migration guide: https://platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-to-claude-opus-4-7
- Adaptive thinking: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking
- Effort parameter: https://platform.claude.com/docs/en/build-with-claude/effort#recommended-effort-levels-for-claude-opus-4-7
- Task budgets: https://platform.claude.com/docs/en/build-with-claude/task-budgets
- Structured outputs: https://platform.claude.com/docs/en/build-with-claude/structured-outputs
- Memory tool: https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool
- Models overview: https://platform.claude.com/docs/en/about-claude/models/overview
