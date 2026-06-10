---
name: fable-5-prompting
description: Apply when creating or editing prompts targeting Claude Fable 5 (model ID claude-fable-5). Covers effort-level selection, longer autonomous turns, brief-instruction steering, progress-claim grounding, action boundaries, parallel subagent orchestration, memory systems, early-stopping and context-budget mitigations, send-to-user tooling, reasoning-extraction refusal avoidance, and migration from Opus 4.8.
---

# Fable 5 Prompting

## When to Use

- Creating or editing system prompts targeting Claude Fable 5
- Designing long-running autonomous agents, harnesses, or subagent orchestration on Fable 5
- Migrating prompt text from Opus 4.8 or older Claude models
- Diagnosing refusals, fallbacks, early stopping, or fabricated progress reports on Fable 5

## Overview

Claude Fable 5 is Anthropic's most powerful model — a new tier above Opus (1M context, 128k max output, $10/$50 per MTok). It takes on problems previously too complex, long-running, or ambiguous for prior models, and is particularly effective at end-to-end work that takes a person hours, days, or weeks. Teams seeing the best outcomes apply it to their hardest unsolved problems; testing it only on simpler workloads undersells its capability range. It also performs reliably on straightforward tasks.

API surface matches Opus 4.7/4.8 (adaptive thinking only, no sampling parameters, no `budget_tokens`, no last-turn prefills) with one new breaking change: an explicit `thinking: {type: "disabled"}` returns a 400 — omit the `thinking` parameter entirely instead. The upstream guide covers Claude Fable 5 and Claude Mythos 5; this skill targets Fable 5 (`claude-fable-5`).

Capability improvements at this level are a prompt to re-evaluate which instructions, tools, and guardrails are still needed — skills and prompts developed for prior models are often too prescriptive for Fable 5 and can degrade output quality.

<context>
Key behavioral characteristics to design around:

- **Long-horizon autonomy**: Sustains productive output over extended periods — multi-day, goal-directed runs with strong instruction retention.
- **Longer turns by default**: Individual requests on hard tasks can run many minutes at higher effort; autonomous runs extend for hours. The largest shift teams encounter when migrating.
- **First-shot correctness**: Single-pass implementations of well-specified complex systems that previously took days of iteration.
- **Strong instruction following**: A brief instruction steers most behaviors — no need to enumerate each pattern by name.
- **Readier subagent dispatch**: Dispatches parallel subagents more readily than prior models; dependable at sustaining communication with long-running subagents and peer agents.
- **Stronger vision**: Interprets dense technical images, web apps, and screenshots with substantially higher accuracy, often using fewer output tokens; trained to use bash and crop tools on flipped, blurry, or noisy images.
- **Better code review and debugging**: Noticeably higher bug-finding recall than Opus 4.8 (outside safety-classifier domains), including search across codebases and repo history.
- **Navigates ambiguity**: Performs well on complex, multi-threaded requests when asked to determine next steps.
- **Memory leverage**: Performs particularly well when it can record lessons from previous runs and reference them.
- **Occasional unrequested actions**: Can draft an email no one asked for or create defensive git-branch backups — state boundaries explicitly.
- **Rare early stopping**: Deep into long sessions, can end a turn with a statement of intent without issuing the tool call, or ask permission it doesn't need.
- **Rare context-budget anxiety**: In very long sessions can suggest a new session or trim its own work — usually triggered by a visible remaining-token countdown.
- **Safety classifiers**: Targets offensive cybersecurity, biology/life sciences, and extraction of summarized thinking. Benign work in those areas may also trigger refusals.
</context>

## Effort Levels — Prompt Implications

Effort is the primary control for the intelligence/latency/cost trade-off on Fable 5. Lower effort settings still perform well and often exceed `xhigh` performance on prior models — re-baseline rather than carrying over old settings.

| Level | Prompt-authoring implication |
|-------|--------------|
| `max` | Available. Test for the most intelligence-demanding, latency-insensitive tasks; watch for overdeliberation on routine work. |
| `xhigh` | The most capability-sensitive workloads. Keep prompts lean — avoid prescribing reasoning steps. |
| `high` | Default for most tasks. Often produces excellent verification behavior and the most rigorous output. |
| `medium` | Routine work. Frequently matches or beats prior-model `xhigh`. |
| `low` | Routine, latency-sensitive work and a quicker, more interactive working style. |

Reduce effort if a task completes but takes longer than necessary, or if you want a quicker, more interactive working style.

On routine work at higher effort, Fable 5 can gather context and deliberate beyond what the task needs. To prevent unrequested tidying or refactoring at higher effort:

```
Don't add features, refactor, or introduce abstractions beyond what the task requires. A
bug fix doesn't need surrounding cleanup and a one-shot operation usually doesn't need a
helper. Don't design for hypothetical future requirements: do the simplest thing that
works well. Avoid premature abstraction and half-finished implementations. Don't add
error handling, fallbacks, or validation for scenarios that cannot happen. Trust
internal code and framework guarantees. Only validate at system boundaries (user input,
external APIs). Don't use feature flags or backwards-compatibility shims when you can
just change the code.
```

Source: https://platform.claude.com/docs/en/build-with-claude/effort

### Adaptive Thinking

Adaptive thinking is the only thinking mode. Set `thinking: {type: "adaptive"}` to enable; omit the parameter to run without thinking. Unlike Opus 4.7/4.8, an explicit `thinking: {type: "disabled"}` returns a 400 on Fable 5.

Thinking output is summarized-only: block text is empty by default; opt in with `thinking: {type: "adaptive", display: "summarized"}`. There is no full raw-thinking display.

**Never instruct the model to echo, transcribe, or explain its internal reasoning as response text.** That triggers the `reasoning_extraction` refusal category on Fable 5 and elevates fallbacks. If your application needs reasoning visibility, read the structured `thinking` blocks instead, and use a send-to-user tool to surface progress during long runs.

Source: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking

## Longer Turns by Default

Individual requests on hard tasks can run for many minutes at higher effort — especially when the task requires gathering context, building, and self-verifying — and autonomous runs can extend for hours. Before migrating: adjust client timeouts, enable streaming, update user-facing progress indicators, and consider restructuring harnesses to check on runs asynchronously (scheduled jobs) rather than blocking.

To keep Fable 5 from overplanning when a task is ambiguous:

```
When you have enough information to act, act. Do not re-derive facts already established
in the conversation, re-litigate a decision the user has already made, or narrate
options you will not pursue in user-facing messages. If you are weighing a choice, give
a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

## Strong Instruction Following

Instruction-following is improved enough that a brief instruction steers most behaviors — no need to enumerate each pattern. Example: when un-steered, Fable 5 can elaborate beyond what the task needs (surveying options it won't pursue, explaining root causes at length, heavily-structured PR descriptions, comments narrating the next line). A short brevity instruction is as effective as listing each pattern:

```
Lead with the outcome. Your first sentence after finishing should answer "what happened"
or "what did you find": the thing the user would ask for if they said "just give me the
TLDR." Supporting detail and reasoning come after. Being readable and being concise are
different things, and readability matters more.

The way to keep output short is to be selective about what you include (drop details
that don't change what the reader would do next), not to compress the writing into
fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

Same for checkpoint behavior in long-running workflows — no need to enumerate every case:

```
Pause for the user only when the work genuinely requires them: a destructive or
irreversible action, a real scope change, or input that only they can provide. If you
hit one of these, ask and end the turn, rather than ending on a promise.
```

### Give the Reason, Not Only the Request

Fable 5 performs better when it understands the intent behind a request: context lets it connect the task to relevant information rather than inferring intent on its own. Especially valuable for long-running agents drawing on multiple workstreams:

```
I'm working on [the larger task] for [who it's for]. They need [what the output
enables]. With that in mind: [request].
```

### State the Boundaries

Fable 5 can occasionally take unrequested actions (drafting an email when none was asked for, creating defensive git-branch backups). Define explicit constraints:

```
When the user is describing a problem, asking a question, or thinking out loud rather
than requesting a change, the deliverable is your assessment. Report your findings and
stop. Don't apply a fix until they ask for one. Before running a command that changes
system state (restarts, deletes, config edits), check that the evidence actually
supports that specific action. A signal that pattern-matches to a known failure may have
a different cause.
```

## Long Autonomous Runs

### Ground Progress Claims

On long autonomous runs, instruct Fable 5 to audit progress against actual tool results. In Anthropic's testing this nearly eliminated fabricated status reports, even on tasks designed to elicit them:

```
Before reporting progress, audit each claim against a tool result from this session.
Only report work you can point to evidence for; if something is not yet verified, say so
explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step
was skipped, say that; when something is done and verified, state it plainly without
hedging.
```

### Rare Early Stopping

Deep into a long session, Fable 5 can occasionally end a turn with a text-only statement of intent ("I'll now run X") without issuing the tool call, or pause to ask permission when it already has enough to proceed. A "continue" or "go ahead and do it end to end" suffices. Pair with the checkpoint instruction above to define when pausing is appropriate. For autonomous pipelines, add a system reminder:

```
You are operating autonomously. The user is not watching in real time and cannot answer
questions mid-task, so asking "Want me to…?" or "Shall I…?" will block the work. For
reversible actions that follow from the original request, proceed without asking.
Offering follow-ups after the task is done is fine; asking permission after already
discussing with the user before doing the work is not. Before ending your turn, check
your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or
a promise about work you have not done ("I'll…", "let me know when…"), do that work now
with tool calls. End your turn only when the task is complete or you are blocked on
input only the user can provide.
```

### Rare Context-Budget Concern

In very long sessions, Fable 5 can suggest a new session, offer to summarize and hand off, or trim its own work — most often when the harness shows a remaining-token countdown. Avoid surfacing explicit context-budget counts where possible. If the harness must show them:

```
You have ample context remaining. Do not stop, summarize, or suggest a new session on
account of context limits. Continue the work.
```

### Construct a Memory System

Fable 5 performs particularly well when it can record lessons from previous runs and reference them. Provide a place to write notes — as simple as a Markdown file:

```
Store one lesson per file with a one-line summary at the top. Record corrections and
confirmed approaches alike, including why they mattered. Don't save what the repo or
chat history already records; update an existing note rather than creating a duplicate;
delete notes that turn out to be wrong.
```

To bootstrap the memory system from existing history:

```
Reflect on the previous sessions we've had together. Use subagents to identify core
themes and lessons, and store them in [X]. Make sure you know to reference [X] for
future use.
```

### Explicit Self-Verification

Make self-verification explicit in long-run prompts. Separate, fresh-context verifier subagents tend to outperform self-critique:

```
Establish a method for checking your own work at an interval of [X] as you build. Run
this every [X interval], verifying your work with subagents against the specification.
```

## Parallel Subagents

Fable 5 dispatches parallel subagents more readily than prior models — the opposite tuning direction from Opus 4.8, which under-used them. Use subagents frequently, provide explicit guidance about when delegation is appropriate, and prefer asynchronous communication between orchestrator and subagents over blocking until each returns. Long-lived subagents that keep context across subtasks save time and cost through cache reads and avoid bottlenecking on the slowest subagent.

```
Delegate independent subtasks to subagents and keep working while they run. Intervene
if a subagent goes off track or is missing relevant context.
```

## Communicating with the User

### Readability in Extended Sessions

In extended or agentic conversations (many tool calls, large working context), Fable 5 can produce text that's hard to follow: dense arrow-chain shorthand, deep implementation detail, references to thinking the user never saw, overly technical phrasing. A communication-style addendum mitigates this:

```
Terse shorthand is fine between tool calls (that's you thinking out loud, and brevity
there is good). Your final summary is different: it's for a reader who didn't see any of
that.

If you've been working for a while without the user watching (overnight, across many
tool calls, since they last spoke), your final message is their first look at any of it.
Write it as a re-grounding, not a continuation of your working thread: the outcome
first, then the one or two things you need from them, each explained as if new. The
vocabulary you built up while working is yours, not theirs; leave it behind unless you
re-introduce it.

When you write the summary at the end, drop the working shorthand. Write complete
sentences. Spell out terms. Don't use arrow chains, hyphen-stacked compounds, or labels
you made up earlier. When you mention files, commits, flags, or other identifiers, give
each one its own plain-language clause. Open with the outcome: one sentence on what
happened or what you found. Then the supporting detail. If you have to choose between
short and clear, choose clear.
```

### Create a Send-to-User Tool

For long, asynchronous agents, give the agent a way to surface a message the user must see exactly as written, without ending its turn: a deliverable (generated code snippet, drafted message), a progress update with specific numbers, or a direct reply to a mid-loop question. Render the tool input directly in your UI and return a simple acknowledgement. Tool inputs are never summarized, so content arrives intact.

```json
{
  "name": "send_to_user",
  "description": "Display a message directly to the user. Use this for progress updates, partial results, or content the user must see exactly as written before the task finishes.",
  "input_schema": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "The content to display to the user."
      }
    },
    "required": ["message"]
  }
}
```

Add this tool whenever your UX depends on delivering content or direct user interactions verbatim mid-task. For agents that only narrate routine progress, the model's own summaries are typically adequate.

## Carried-Over Fundamentals

Cross-model practices that still apply on Fable 5 — condensed; full treatment in the prompting best-practices doc and `opus-4-8-prompting`:

- **Explicit instructions with motivation.** State scope explicitly; a rule with a reason is followed more consistently.
- **XML tags** for unambiguous separation of instructions, context, examples, and inputs. 3-5 precise examples; every example is a pattern the model may reproduce.
- **Long context**: documents at the top, query at the end; ground answers in extracted quotes.
- **Calm tool language.** `Use this tool when...` — not `CRITICAL: You MUST...`. Aggressive markers overcorrect.
- **No prefills.** Last-assistant-turn prefill returns 400. Use Structured Outputs or "Respond with a JSON object only. No preamble or explanation."
- **Structured Outputs own the shape; the prompt owns the intent.** Don't duplicate schema shape in prompt text.
- **No sampling parameters.** `temperature`/`top_p`/`top_k` return 400 — steer variance through prompting.

Because instruction following is stronger, much of this scaffolding can shrink. Review carried-over prompts and remove instructions where default behavior is already better.

## Safety Classifiers and Refusals

Fable 5 runs safety classifiers targeting offensive cybersecurity techniques (building exploits, malware, attack tooling), biology and life sciences content (lab methods, molecular mechanisms), and extraction of the model's summarized thinking. Benign cybersecurity work and beneficial life sciences tasks may also trigger these safeguards. Fable 5 is not intended for offensive cybersecurity or biology/life-sciences work; requests in those domains can return `stop_reason: "refusal"`.

Prompt-authoring implications:

- **Configure fallback.** To re-route declined requests automatically, configure server-side or client-side fallback to Claude Opus 4.8.
- **Audit for reasoning-echo instructions.** Prompts, skills, or harness instructions telling the model to echo or explain its internal reasoning as response text trigger the `reasoning_extraction` refusal category and elevate fallbacks. Read structured `thinking` blocks instead.
- **Frame legitimate security work explicitly** when purpose is ambiguous; expect more refusals in classifier domains than on Opus 4.8.

Source: https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback

## Recommended Scaffolding Changes

- **Start at the top of your difficulty range.** Pick a task harder than what you'd assign to prior models; have Fable 5 scope it, ask clarifying questions, and execute.
- **Make self-verification explicit in long-run prompts** with fresh-context verifier subagents (see Explicit Self-Verification above).
- **Refactor existing prompts and skills.** Skills developed for prior models are often too prescriptive for Fable 5 and can degrade output quality. Remove older instructions if default performance is better. Fable 5 also updates skills on the fly based on what it learns from the task at hand.
- **Don't instruct Claude to reproduce its reasoning in the response** — triggers `reasoning_extraction` refusals.
- **Create a send-to-user tool** for long, asynchronous agents.

## Prompt Migration Checklist

### From Opus 4.8

- [ ] Update model name from `claude-opus-4-8` to `claude-fable-5`.
- [ ] Remove any explicit `thinking: {type: "disabled"}` — returns 400 on Fable 5; omit the parameter instead.
- [ ] Adjust client timeouts, streaming, and user-facing progress indicators for longer turns; consider async run-checking (scheduled jobs) over blocking.
- [ ] Audit prompts, skills, and harness instructions for echo/transcribe/show-your-reasoning language — refusal risk on Fable 5.
- [ ] Strip over-prescriptive instructions carried from prior models; re-baseline against default behavior before re-adding.
- [ ] Flip subagent guidance from "encourage spawning" (4.8 under-used) to "calibrate when delegation is appropriate" (Fable 5 dispatches readily); prefer async orchestration and long-lived subagents.
- [ ] Add a progress-audit instruction to long-run prompts (eliminates fabricated status reports).
- [ ] Add boundary and autonomy instructions for agents (unrequested actions, early stopping).
- [ ] Hide remaining-token countdowns from the model, or add the ample-context reassurance.
- [ ] Re-baseline `effort` per route: `high` default, `xhigh` for capability-sensitive work; `medium`/`low` now viable for routine work (often ≥ prior-model `xhigh`).
- [ ] Configure refusal fallback to Opus 4.8 for workloads near classifier domains.
- [ ] Add a send-to-user tool for long async agents whose UX needs verbatim mid-task delivery.
- [ ] Keep: calm tool language, Structured Outputs over prefills, no sampling parameters.

### From Opus 4.7 or older

Apply the migration checklists in `opus-4-8-prompting` first (adaptive thinking, sampling-parameter removal, prefill replacement, aggressive-language softening), then the Fable 5 steps above.

## Anti-Patterns

- **Testing only on simple workloads** — undersells the capability range. Start at the top of your difficulty range.
- **Enumerating every behavior** — a brief instruction steers as effectively as listing each pattern by name.
- **Carrying over prescriptive legacy skills** — instructions tuned for prior models degrade Fable 5 output. Remove and re-baseline.
- **Show-your-reasoning instructions** — trigger `reasoning_extraction` refusals and fallbacks. Read `thinking` blocks instead.
- **Surfacing token countdowns** — triggers premature wrap-up, handoff offers, and self-trimming in long sessions.
- **Blocking on each subagent** — prefer async communication and long-lived subagents; blocking bottlenecks on the slowest one.
- **Treating an intent-statement stop as failure** — a rare late-session quirk; "continue" or "go ahead and do it end to end" suffices.
- **Requests without intent** — Fable 5 connects tasks to relevant information when told why; bare requests force it to infer intent.
- **Unconstrained working shorthand in final summaries** — add the readability addendum for extended/agentic sessions.
- **Explicit `thinking: {type: "disabled"}`** — 400s on Fable 5 (accepted on Opus 4.7/4.8). Omit the parameter.
- **Prompting offensive-security or bio workloads** — classifier domains; expect refusals, route elsewhere.

## Reference

- Prompting Claude Fable 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- Introducing Claude Fable 5 and Claude Mythos 5: https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5
- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Effort parameter: https://platform.claude.com/docs/en/build-with-claude/effort
- Adaptive thinking: https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking
- Refusals and fallback: https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback
- Models overview: https://platform.claude.com/docs/en/about-claude/models/overview
