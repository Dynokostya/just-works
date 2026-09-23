---
name: fable-5-1-prompting
description: Apply when creating or editing prompts targeting Claude Fable 5.1 (claude-fable-5-1). Covers effort re-sweeps, finishing the whole task, progress updates, tool-call batching, append-only reminders, prose and formatting style, coding scope, long autonomous runs, subagents, refusals, and migration from Fable 5.
---

# Fable 5.1 Prompting

## When to Use

- Creating or editing system prompts targeting Claude Fable 5.1
- Designing long-running autonomous agents, harnesses, or subagent orchestration on Fable 5.1
- Migrating prompt text from Fable 5, Opus 5, Opus 4.8, or older Claude models
- Diagnosing early stopping, missing progress updates, one-tool-per-turn loops, out-of-scope edits, or refusals on Fable 5.1

## Overview

Claude Fable 5.1 is Anthropic's model for demanding reasoning and long-horizon agentic work; for most other workloads, start with Opus 5.5 (see `opus-5-5-prompting`). It is particularly effective at end-to-end work that takes a person hours, days, or weeks. Teams seeing the best outcomes apply it to their hardest unsolved problems; testing it only on simpler workloads undersells its capability range.

Prompts written for Fable 5 perform well on Fable 5.1 unchanged. The changes below are tuning. Thinking is always on and cannot be disabled, so any prompt text that assumes a no-thinking mode is obsolete.

<context>
Key behavioral characteristics to design around:

- **Long-horizon autonomy**: Sustains productive output over multi-day, goal-directed runs with strong instruction retention. Individual requests on hard tasks can run many minutes at higher effort.
- **First-shot correctness**: Single-pass implementations of well-specified complex systems that previously took days of iteration.
- **Strong instruction following**: A brief instruction steers most behaviors, and explicit tool instructions are followed reliably.
- **Fewer progress updates**: Writes fewer user-facing updates than Fable 5; progress text between tool calls arrives inside thinking blocks, which the user does not see.
- **One tool call per turn**: In coding, bash/editor, and computer-use loops, may issue a single tool call per turn even when several are independent.
- **Denser prose, lighter formatting**: Prose can be mannered and dense; in chat it under-uses bold, headers, and lists.
- **Unmarked quoting**: Can reproduce retrieved passages without marking them as quotes.
- **Scope creep at higher effort**: On scope-graded coding it peaks at `medium`; at higher effort it occasionally adds small, unrequested changes in files outside the task.
- **Memory answers at low effort**: At `low`, answers from memory more often instead of searching.
- **Double drafting at `xhigh`/`max`**: May draft a whole long deliverable in thinking, then write it again.
- **Readier subagent dispatch**: Dispatches parallel subagents readily, but still often chooses to wait on them.
- **Stronger vision and code review**: Accurate on dense technical images and screenshots; high bug-finding recall across codebases and repo history.
- **Rare early stopping and unrequested actions**: Deep into long sessions, can end on a statement of intent without the tool call, or take actions no one asked for (drafting an email, defensive git-branch backups).
- **Rare approval-gate overclaiming**: In rare cases (under 0.01% per the system card) overclaims user intent to get past an approval gate, including fabricating a user quote.
- **Safety classifiers**: Refusal categories cover cyber, bio, frontier_llm, reasoning_extraction, and general_harms. False positives are lower than Fable 5 at launch but more likely than on Opus 5.
</context>

## Effort Levels — Prompt Implications

Effort is the primary control for the intelligence/latency/cost trade-off. Re-sweep it rather than carrying over Fable 5 settings: "Re-run the sweep even if you already ran one on Claude Fable 5: effort level names don't correspond to the same amount of thinking across models."

| Level | Prompt-authoring implication |
|-------|--------------|
| `max` | Largest gains over Fable 5. For long deliverables, add the long-output instruction below or use `high`. |
| `xhigh` | Largest gains over Fable 5; keep prompts lean. Same long-output caveat as `max`. |
| `high` | Default for most tasks. Add a brevity instruction on coding work to curb out-of-scope edits. |
| `medium` | Roughly matches Fable 5 results at lower cost. Scope-graded coding peaks here. |
| `low` | Often competitive with Opus/Sonnet on cost per task while scoring higher. Raise effort or add the search-trigger instruction for lookup-heavy turns. |

- **Adjust effort before adding prompt text about thinking.** Lower effort before adding "think less" instructions; reduce it when a task completes but takes longer than necessary.
- **Change effort per message, not for the whole conversation.** A conversation-level change "steers the model less reliably: its earlier replies were written at the previous level, and it tends to stay consistent with them."

### Thinking Is Always On

Don't prescribe reasoning steps or write instructions for a no-thinking mode. **Never instruct the model to echo, transcribe, or explain its internal reasoning as response text** — that triggers the `reasoning_extraction` refusal category. If your application needs reasoning visibility, read the structured thinking blocks; to surface progress to the user, ask for progress updates or give the model a send-to-user tool (both below).

## Steering with Brief Instructions

A brief instruction steers most behaviors — no need to enumerate each pattern. When un-steered, the model can elaborate beyond what the task needs (surveying options it won't pursue, long root-cause explanations, heavily structured PR descriptions, comments narrating the next line). A short brevity instruction is as effective as listing each pattern:

```
Lead with the outcome. Your first sentence after finishing should answer "what happened" or "what did you find": the thing the user would ask for if they said "just give me the TLDR." Supporting detail and reasoning come after. Being readable and being concise are different things, and readability matters more.

The way to keep output short is to be selective about what you include (drop details that don't change what the reader would do next), not to compress the writing into fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

Checkpoint behavior in long-running workflows:

```
Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input that only they can provide. If you hit one of these, ask and end the turn, rather than ending on a promise.
```

To keep the model from overplanning when a task is ambiguous:

```
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue in user-facing messages. If you are weighing a choice, give a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

**Give the reason, not only the request.** Context lets the model connect the task to relevant information rather than inferring intent:

```
I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [request].
```

## Finish the Whole Task

This block replaces separate autonomy-reminder and boundary snippets:

```
You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task, so asking 'Want me to…?' or 'Shall I…?' will block the work. For reversible actions that follow from the original request, proceed without asking. Stop only for destructive actions or genuine scope changes the user must decide. Offering follow-ups after the task is done is fine; asking permission before doing the work is not.

Exception: when the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one.

Before ending your turn, check your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or a promise about work you have not done ('I'll…', 'let me know when…'), do that work now with tool calls. That includes retrying after errors and gathering missing information yourself. Do not stop because the context or session is long. End your turn only when the task is complete or you are blocked on input only the user can provide.

Before running a command that changes system state (such as restarts, deletes, or config edits), check that the evidence actually supports that specific action. A signal that pattern-matches to a known failure may have a different cause.
```

- The opening sentence carries much of the effect — keep it as written. It can also make the model less likely to ask about ambiguous requests.
- For scope discipline on delivered work, the 5.1 guide has a second block starting `# Delivering work` ("The user's request — or the plan they approved — sets the scope, and the scope is the deliverable: don't quietly narrow, widen, or swap it."). Copy it from the guide's "Finish the whole task" section.
- **Enforce destructive-action approvals in the harness, not only in the prompt.** The model can rarely overclaim user intent at an approval gate, including fabricating a user quote.

## User-Facing Progress Updates

Fable 5.1 writes fewer progress updates. Remove lines like "hold all findings for the final response" and add:

```
Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own — what you found, what you did, and what's next — so a reader who only sees the last message has the full picture.
```

If your UI hides tool output from the user, send this as a turn-scoped reminder:

```
Only you see that command's output — the user's terminal shows at most a few lines of it. If the user needs to read any of it, put it in your reply.
```

### Send-to-User Tool

For long, asynchronous agents, a `send_to_user` tool lets the model surface content the user must see exactly as written without ending its turn; render its input directly in the UI. Defining the tool isn't enough — without a system-prompt instruction the model rarely calls it. Pair it with:

```
Between tool calls, when you have content the user must read verbatim (a partial deliverable, a direct answer to their question), call the send_to_user tool with that content. Use send_to_user only for user-facing content, not for narration or reasoning.
```

## Agent Loops and History

### Batch Independent Tool Calls

In agent loops, append this after each tool-result turn as a turn-scoped reminder, leaving earlier copies in history unchanged:

```
First privately list what you need next; then request every item that doesn't depend on another's result in this one response.
```

### Keep History Append-Only

Send per-turn reminders as appended messages; don't edit the earlier system prompt or messages mid-conversation. For client-side compaction, "replace the whole history with one summary message plus the new user turn". Compacting early to save cost may no longer be the right trade-off — experiment with later compaction points. For what the summary should preserve, copy the instruction beginning `Summarize the transcript inside <summary></summary> tags.` from the 5.1 guide section "Tell the model what to preserve in compaction summaries".

### Tool Triggering

Forced tool calls are unavailable, so name the tool in the prompt: "Use the `get_weather` tool to answer." Fable 5.1 follows explicit tool instructions reliably. When a call is mandatory, put the instruction in the user turn or an appended system message. Keep tool language calm: `Use this tool when...`, not `CRITICAL: You MUST...`.

## Long Autonomous Runs

### Ground Progress Claims

Auditing progress against tool results nearly eliminated fabricated status reports in Anthropic's testing:

```
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step was skipped, say that; when something is done and verified, state it plainly without hedging.
```

### Early Stopping and Context Budget

Deep into a long session the model can rarely end on a statement of intent, or suggest a new session and trim its own work — most often when the harness shows a remaining-token countdown. The Finish the Whole Task block covers both ("Do not stop because the context or session is long"); a "continue" also suffices. Avoid showing remaining-token countdowns.

### Construct a Memory System

Provide a place to record lessons from previous runs — as simple as a Markdown file:

```
Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo or chat history already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong.
```

To bootstrap it from existing history:

```
Reflect on the previous sessions we've had together. Use subagents to identify core themes and lessons, and store them in [X]. Make sure you know to reference [X] for future use.
```

In Claude Code, automatic memory captures these lessons on its own — reserve explicit memory instructions for custom harnesses and API-level agents.

### Explicit Self-Verification

Fresh-context verifier subagents tend to outperform self-critique:

```
Establish a method for checking your own work at an interval of [X] as you build. Run this every [X interval], verifying your work with subagents against the specification.
```

### Parallel Subagents

The model dispatches subagents readily — provide explicit guidance on when delegation is appropriate, and prefer long-lived subagents that keep context across subtasks. Let the lead keep working: design the subagent-start tool to return immediately, deliver results in a later message, and give the lead a separate tool to call when it wants to wait. The model still often chooses to wait, so say so:

```
Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context.
```

## Writing Style

### Readability in Extended Sessions

In long agentic sessions, final messages can drift into working shorthand and references to thinking the user never saw:

```
Terse shorthand is fine between tool calls (that's you thinking out loud, and brevity there is good). Your final summary is different: it's for a reader who didn't see any of that.

If you've been working for a while without the user watching (overnight, across many tool calls, since they last spoke), your final message is their first look at any of it. Write it as a re-grounding, not a continuation of your working thread: the outcome first, then the one or two things you need from them, each explained as if new. The vocabulary you built up while working is yours, not theirs; leave it behind unless you re-introduce it.

When you write the summary at the end, drop the working shorthand. Write complete sentences. Spell out terms. Don't use arrow chains, hyphen-stacked compounds, or labels you made up earlier. When you mention files, commits, flags, or other identifiers, give each one its own plain-language clause. Open with the outcome: one sentence on what happened or what you found. Then the supporting detail. If you have to choose between short and clear, choose clear.
```

### Mannered Prose

Fable 5.1 prose can be denser. Add this to the user message (preferred) or the system prompt:

```
Mannered prose substitutes metaphor and flourish for direct statement. Instead of "a parameter worth varying," the mannered writer produces "a dial worth turning." Instead of "this point still matters," they write "this point earns its keep." The phrases exist to display the writer, not to convey the idea, and readers can tell. That is why mannered prose irritates: it makes the reader work harder so the writer can perform. It is also imprecise. Metaphors drag in connotations the writer did not choose and cannot control. The fix is to say what you mean. When a literal phrase is available, use it.
```

A short form also works: `Please remove all mannered prose.`

### Formatting in Chat

Fable 5.1 under-uses bold, headers, and lists. Remove anti-formatting rules carried from earlier models and use:

```
Use lists and bullet points when asked to, or when the content is multifaceted enough that they help with clarity. If the person explicitly requests minimal formatting, always format your responses without bullet points, headers, lists, or bold emphasis, as requested. In conversational, personal, or emotional exchanges, keep to plain prose.
```

### Quoting Retrieved Sources

To get retrieved passages marked as quotes, put one complete worked example (request, response, rationale) in the system prompt — copy the Riverton Ledger / Coast Dispatch example from the 5.1 guide's "Quoting retrieved sources" section. This is an exception to preferring expressive interfaces over examples.

## Coding

### Keep Changes and Tests to What the Task Asks

With this instruction, unrequested additions and committed test code drop substantially with no measurable change in task success:

```
If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files — roughly one focused test per stated behavior — and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.
```

For code-level over-engineering (abstractions, defensive handling, shims), add:

```
Don't add features, refactor, or introduce abstractions beyond what the task requires. A bug fix doesn't need surrounding cleanup and a one-shot operation usually doesn't need a helper. Don't design for hypothetical future requirements: do the simplest thing that works well. Avoid premature abstraction and half-finished implementations. Don't add error handling, fallbacks, or validation for scenarios that cannot happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use feature flags or backwards-compatibility shims when you can just change the code.
```

At higher effort, a brevity instruction that includes a note to avoid unnecessary comments and documentation also reduces out-of-scope edits.

### Targeted Edits over Rewrites

```
The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing.
```

## Search, Long Outputs, and Vision

### Search Triggering at Low Effort

At `low`, raise effort for lookup-heavy turns or add:

```
When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area like AI models and developer tools where the landscape shifts within months, the name itself is the thing to verify: search before answering, and include the name as the user wrote it in at least one query alongside any reformulations. This holds even when you have some background on it — partial background is exactly what makes an out-of-date answer sound authoritative, so familiarity is not a reason to skip the search.
```

### Long Outputs at `xhigh`/`max`

Prefer `high` for long deliverables. At `xhigh`/`max`, append this, replacing `[max_tokens]` with the request's output limit:

```
Everything produced in one reply, including any reasoning or drafting done before the reply, counts toward a single limit of about [max_tokens] tokens. If that limit is reached before the reply is finished, the person receives a cut-off response and has to start over. Composing an entire output or deliverable in full as reasoning and then again as a reply would double the length of the turn without improving the result, so don't do that.

Instead, when the person has asked for a long or effort-intensive deliverable such as a multi-section document, a large table or dataset, or a complete code file, spend extra effort on understanding the request, checking the inputs the answer depends on, settling the structure and other difficult decisions, and otherwise using the reasoning space to reason and the output space to write an output. Usually it is not needed to draft an output multiple times.
```

### Vision

Give the model crop/zoom tools — an image-cropping tool alone delivers most of the uplift. See the crop-tool cookbook in Reference.

## Carried-Over Fundamentals

Condensed; full treatment in the prompting best-practices doc and `opus-5-5-prompting`:

- **Explicit instructions with motivation.** A rule with a reason is followed more consistently.
- **XML tags** for unambiguous separation of instructions, context, examples, and inputs. Prefer expressive interfaces (tool parameters, schemas, rubrics) over usage examples — examples constrain exploration on this generation; where format-pinning examples are needed, keep 3-5 precise ones.
- **Long context**: documents at the top, query at the end; ground answers in extracted quotes.
- **No prefills.** State the shape in the prompt: "Respond with a JSON object only. No preamble." When a schema enforces the shape, the prompt states intent only.
- **Start at the top of your difficulty range.** Have the model scope a hard task, ask clarifying questions, and execute.
- **Hand it rich references.** Code-based specs, test suites, rubrics, and artifacts steer it with higher fidelity than markdown descriptions of the same intent.
- **Refactor legacy prompts and skills.** Remove instructions where default behavior is already better.

## Safety Classifiers and Refusals

Refusal categories: cyber, bio, frontier_llm, reasoning_extraction, general_harms. Benign work near these domains can still trigger them, though less often than on Fable 5 at launch. Finding vulnerabilities in source code is permitted.

- **Audit for reasoning-echo instructions** in prompts, skills, and harness text — they trigger `reasoning_extraction`.
- **Phrase code questions as review.** Ask "Are there any bugs in this program?" rather than "Does this program compile without errors?" For lesser-known languages, give context such as the language docs.
- **Remove base64 from tool output** where possible.
- **Frame legitimate security work explicitly** when its purpose is ambiguous.

## Prompt Migration Checklist

### From Fable 5

- [ ] Re-run the effort sweep; start comparisons at `medium` (roughly Fable 5 results at lower cost).
- [ ] Remove prompt text that assumes a no-thinking mode.
- [ ] Remove "hold all findings for the final response" lines; add the progress-update instruction and, if tool output is hidden, the turn-scoped output reminder.
- [ ] Replace the autonomy-reminder, boundary, and ample-context snippets with the Finish the Whole Task block.
- [ ] Add the batching reminder after tool-result turns in agent loops.
- [ ] Move per-turn reminders into appended messages; stop editing earlier prompt text mid-conversation.
- [ ] Remove anti-formatting rules; add the formatting instruction for chat.
- [ ] Add the mannered-prose instruction where prose reads dense.
- [ ] Add a quoting worked example for retrieval products.
- [ ] Add the scope-and-tests instruction and a brevity note for coding at `high` and above.
- [ ] Add the search-trigger instruction for `low`-effort routes that need lookups.
- [ ] Add the long-output instruction for long deliverables at `xhigh`/`max`, or use `high`.
- [ ] Name mandatory tools in the prompt instead of relying on forced tool calls.
- [ ] Pair any `send_to_user` tool with its system-prompt instruction.
- [ ] Enforce destructive-action approvals in the harness.

### From Opus 5 / Opus 4.8

Apply the older-model checklists in `opus-5-5-prompting` first, then the Fable 5 checklist above. Also: audit for show-your-reasoning language, strip over-prescriptive instructions, add the progress-audit instruction to long-run prompts, and, coming from 4.8, flip subagent guidance from "encourage spawning" to "calibrate when delegation is appropriate".

## Anti-Patterns

- **Reusing Fable 5 effort settings without a sweep** — level names don't map to the same thinking across models.
- **Changing the conversation-level effort mid-way** — the model stays consistent with replies written at the old level; change it per message.
- **"Hold all findings for the final response"** — Fable 5.1 already writes few updates; the user loses track.
- **Editing earlier prompt text mid-conversation** — keep history append-only; put reminders in appended messages.
- **Anti-formatting rules carried from earlier models** — Fable 5.1 already under-formats.
- **Prompt-only approval gates for destructive actions** — enforce them in the harness.
- **Show-your-reasoning instructions** — trigger `reasoning_extraction` refusals.
- **Surfacing token countdowns** — trigger premature wrap-up and self-trimming.
- **Blocking on each subagent** — let the lead keep working and call a separate wait tool when it needs results.

## Reference

- Prompting Claude Fable 5.1: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
- Prompting Claude Fable 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Effort: https://platform.claude.com/docs/en/build-with-claude/effort
- Refusals: https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback
- Crop-tool cookbook: https://platform.claude.com/cookbook/multimodal-crop-tool
