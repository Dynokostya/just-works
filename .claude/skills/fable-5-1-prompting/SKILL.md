---
name: fable-5-1-prompting
description: Apply when creating or editing prompts, system prompts or agent instructions that target Claude Fable 5.1 (claude-fable-5-1), including effort settings and migration from Fable 5. Not for other models; for Opus 5.5 use opus-5-5-prompting.
---

# Fable 5.1 Prompting

## When to Use

- Creating or editing system prompts targeting Claude Fable 5.1
- Designing long-running autonomous agents, harnesses, or subagent orchestration on Fable 5.1
- Migrating prompt text from Fable 5, Opus 5, Opus 4.8, or older Claude models
- Diagnosing early stopping, missing progress updates, one-tool-per-turn loops, out-of-scope edits, or refusals on Fable 5.1

## Overview

Claude Fable 5.1 is Anthropic's model for demanding reasoning and long-horizon agentic work. For most other workloads start with Opus 5.5 (see `opus-5-5-prompting`). Anthropic reports it is particularly effective at end-to-end work that takes a person hours, days, or weeks, and that testing it only on simple workloads undersells it (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5).

Prompts written for Fable 5 should perform well on Fable 5.1 unchanged; the changes below are tuning (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1). Thinking is always on, so prompt text that assumes a no-thinking mode is obsolete.

<context>
Behaviors to design around (Fable 5.1 page unless noted):

- **Strong instruction following.** A brief instruction steers most behaviors, and explicit tool instructions are followed reliably (Fable 5 page).
- **Fewer progress updates.** Fewer user-facing updates than Fable 5, more so at higher effort and in long tool chains. The notes arrive as progress-update thinking blocks, which are empty under the default `thinking.display` of `"omitted"`.
- **One tool call per turn.** In coding and computer-use loops where independent calls are implied rather than requested, it may issue them one per turn.
- **Denser prose, lighter formatting.** Sentences run longer with fewer paragraph breaks; in chat it uses less bold, fewer headers and lists.
- **Unmarked quotation.** It reproduces passages of source text without marking them as quotes.
- **Unrequested extras.** It sometimes fixes nearby code, extends behavior, or commits more tests than the task needs. It can also take unrequested actions such as drafting an email or making defensive git-branch backups (Fable 5 page).
- **Rare early stopping.** Deep into long sessions it can end on a statement of intent without the tool call, or pause for permission it does not need (Fable 5 page).
</context>

## Effort

Effort is the primary control for intelligence, latency, and cost. The default is `high`. Re-run the sweep even if you ran one on Fable 5: "effort level names don't correspond to the same amount of thinking across models." Source: https://platform.claude.com/docs/en/build-with-claude/effort.

| Level | Implication for prompt authors |
|---|---|
| `max`, `xhigh` | Largest gains over Fable 5. Keep prompts lean. It may draft a long deliverable in thinking and write it again, so for long deliverables use the long-output note in `references/snippets.md` or run at `high`. |
| `high` | Default and recommended starting point. |
| `medium` | Roughly matches Fable 5 at lower cost. |
| `low` | Often competitive with Opus and Sonnet models on cost per task while scoring higher, but searches less and answers from memory more. Raise effort or add the search-trigger note (`references/snippets.md`) for lookup-heavy turns. |

- Lower effort before adding "think less" text. Reduce it when a task completes but takes longer than needed.
- Change effort per message rather than for the whole conversation; a per-message change keeps the prompt cache (effort page). The model stays consistent with earlier replies written at the old level.
- Do not tell the model to echo, transcribe, or explain its internal reasoning as response text. That triggers the `reasoning_extraction` refusal. Ask for a short explanation or a summary of actions instead, or read summarized thinking blocks (`display: "summarized"`).

## Steering with Brief Instructions

A short instruction steers most behaviors; there is no need to enumerate each pattern. These three come from the Fable 5 page.

Brevity, when un-steered output elaborates (option surveys, long root-cause write-ups, narrating comments):

```
Lead with the outcome. Your first sentence after finishing should answer "what happened" or "what did you find": the thing the user would ask for if they said "just give me the TLDR." Supporting detail and reasoning come after. Being readable and being concise are different things, and readability matters more.

The way to keep output short is to be selective about what you include (drop details that don't change what the reader would do next), not to compress the writing into fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

Checkpoints in long workflows:

```
Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input that only they can provide. If you hit one of these, ask and end the turn, rather than ending on a promise.
```

Overplanning on ambiguous tasks:

```
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue in user-facing messages. If you are weighing a choice, give a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

Give the reason, not only the request: "I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [request]."

## Finish the Whole Task

For autonomous workloads, this block replaces separate autonomy-reminder and boundary snippets (Fable 5.1 page, "Finish the whole task"):

```
You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task, so asking 'Want me to…?' or 'Shall I…?' will block the work. For reversible actions that follow from the original request, proceed without asking. Stop only for destructive actions or genuine scope changes the user must decide. Offering follow-ups after the task is done is fine; asking permission before doing the work is not.

Exception: when the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one.

Before ending your turn, check your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or a promise about work you have not done ('I'll…', 'let me know when…'), do that work now with tool calls. That includes retrying after errors and gathering missing information yourself. Do not stop because the context or session is long. End your turn only when the task is complete or you are blocked on input only the user can provide.

Before running a command that changes system state (such as restarts, deletes, or config edits), check that the evidence actually supports that specific action. A signal that pattern-matches to a known failure may have a different cause.
```

- Keep the opening sentence as written; it carries much of the effect. If the product needs specific confirmations, add a sentence after it listing them. The block can also make the model ask less about ambiguous requests, so test that.
- A second block, "Delivering work", defines the user's request as the scope of the deliverable. Its full text is in `references/snippets.md`.
- Enforce destructive-action approvals in the harness, not only in the prompt.

## Progress Updates

Fable 5.1 writes fewer user-facing updates. First check the client: set `thinking.display` to `"updates"` (beta) and render each non-empty thinking block as a status line, or `"summarized"` to receive them with summarized reasoning. Then remove lines such as "hold all findings for the final response" and, if more narration is wanted, add:

```
Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own — what you found, what you did, and what's next — so a reader who only sees the last message has the full picture.
```

If the UI hides tool output, send this as a turn-scoped system message (`clear_at: "next_user_message"`, beta):

```
Only you see that command's output — the user's terminal shows at most a few lines of it. If the user needs to read any of it, put it in your reply.
```

For long asynchronous agents, a `send_to_user` tool (input: the message to display; return a simple acknowledgement) lets the model show content verbatim without ending its turn. Defining the tool is not enough; without a system-prompt instruction the model rarely calls it. Pair it with:

```
Between tool calls, when you have content the user must read verbatim (a partial deliverable, a direct answer to their question), call the send_to_user tool with that content. Use send_to_user only for user-facing content, not for narration or reasoning.
```

## Agent Loops and History

**Batch independent tool calls.** After each tool-result turn, append this as a turn-scoped system message (`role: "system"`, `clear_at: "next_user_message"`, beta header `mid-conversation-system-clear-at-2026-08-21`), leaving earlier copies untouched. Without the beta, put it in a text block after the `tool_result` blocks.

```
First privately list what you need next; then request every item that doesn't depend on another's result in this one response.
```

**Keep history append-only.** Append each assistant turn exactly as returned, thinking blocks included, and do not edit earlier turns. Where the check is enforced (new accounts, per the 5.1 page), thinking blocks are valid only in the conversation that produced them; a changed prefix returns a 400 or drops blocks. Adopt the pattern even where it is not enforced. The same edits restart the prompt cache: injecting and removing per-turn reminders, summarizing older turns in place, changing the system prompt mid-session. Send per-turn reminders as turn-scoped system messages. For client-side compaction, replace the whole history with one summary message plus the new user turn (summary instruction in `references/snippets.md`), and test later compaction points, since cheaper cache reads may make early compaction a poor trade.

**Tool triggering.** Forced tool use (`tool_choice` of `any` or `tool`) is not supported on every model and setting (https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools), so where it fails, name the tool in the prompt: "Use the `get_weather` tool to answer." Keep the wording calm: `Use this tool when...`, not `CRITICAL: You MUST...`.

## Long Autonomous Runs

- **Ground progress claims.** Anthropic reports this nearly eliminated fabricated status reports in its testing (Fable 5 page):

```
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step was skipped, say that; when something is done and verified, state it plainly without hedging.
```

- **Context budget.** Avoid showing remaining-token countdowns; they most often trigger suggestions of a new session or self-trimming. If the harness must show them, add: "You have ample context remaining. Do not stop, summarize, or suggest a new session on account of context limits. Continue the work."
- **Subagents.** The model dispatches subagents readily. Give explicit guidance on when delegation is appropriate and prefer long-lived subagents that keep context. The tool that starts a subagent should return immediately, results should arrive in a later message, and the lead needs a separate tool to wait. The model still often chooses to wait, so add: "Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context."
- **Verification and memory.** Fresh-context verifier subagents tend to outperform self-critique, and a place to record lessons from earlier runs helps. Snippets for both are in `references/snippets.md`.

## Writing Style

- **Formatting in chat.** Remove anti-formatting rules carried over from earlier models and use:

```
Use lists and bullet points when asked to, or when the content is multifaceted enough that they help with clarity. If the person explicitly requests minimal formatting, always format your responses without bullet points, headers, lists, or bold emphasis, as requested. In conversational, personal, or emotional exchanges, keep to plain prose.
```

- **Dense or mannered prose.** The short form `Please remove all mannered prose.` often works; a longer definition is in `references/snippets.md`.
- **Final messages after long runs** can drift into working shorthand. A re-grounding instruction is in `references/snippets.md`.
- **Quoted sources.** To get retrieved passages marked as quotes, put one complete worked example (request, response, rationale) in the system prompt. This is an exception to preferring expressive interfaces over examples. The full example is in `references/snippets.md`.

## Coding

With this instruction, unrequested additions and committed test code drop substantially with no measurable change in task success (Fable 5.1 page, "Keep changes and tests to what the task asks for"):

```
If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files — roughly one focused test per stated behavior — and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.
```

If it rewrites whole files for small edits, add: "The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing."

Vision: give the model crop and zoom tools; an image-cropping tool alone delivers most of the uplift (https://platform.claude.com/cookbook/multimodal-crop-tool).

## Refusals

Fable 5.1 runs safety classifiers; a blocked request returns `stop_reason: "refusal"` with a `stop_details.category` of `cyber`, `bio`, `frontier_llm`, `reasoning_extraction`, or `general_harms` (https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback). False positives are fewer than Fable 5 had at launch, and finding vulnerabilities in source code is permitted.

- Audit prompts, skills, and harness text for show-your-reasoning instructions; they trigger `reasoning_extraction`, which server-side fallback does not retry.
- Phrase code questions as review: "Are there any bugs in this program?" rather than "Does this program compile without errors?"
- For lesser-known languages, give the model context such as the language's documentation.
- Remove base64-encoded data from tool output.

## Reference Files

- `references/snippets.md`: read when you need the full text of a snippet named above (Delivering work, compaction summary, quoting example, mannered prose, final-message readability, long-output note, search trigger, memory, verification, over-engineering).
- `references/migration.md`: read when converting prompts from Fable 5, Opus 5, or Opus 4.8.

## Reference

- Prompting Claude Fable 5.1: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
- Prompting Claude Fable 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Effort: https://platform.claude.com/docs/en/build-with-claude/effort
- Refusals: https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback
- Crop-tool cookbook: https://platform.claude.com/cookbook/multimodal-crop-tool
