---
name: fable-5-2-prompting
description: Apply when creating or editing prompts, system prompts or agent instructions that target Claude Fable 5.2 (claude-fable-5-2) or Claude Mythos 5.2, including effort settings and migration from Fable 5.1 or Opus 5.5. Not for other models; for Opus 5.5 use opus-5-5-prompting.
---

# Fable 5.2 Prompting

## When to Use

- Creating or editing system prompts, skills, or agent files targeting Claude Fable 5.2 or Claude Mythos 5.2
- Designing long-running agents, harnesses, or subagent orchestration on Fable 5.2
- Migrating prompt text from Fable 5.1, Opus 5.5, or older Claude models
- Diagnosing early stops, unneeded approval requests, silent long turns, over-delegation, repeated code, or refusals on Fable 5.2

## Overview

Claude Fable 5.2 is Anthropic's model for demanding reasoning and long-horizon agentic work. For most workloads start with the latest Opus model (see `opus-5-5-prompting`), and move to Fable 5.2 when evals on Opus at higher effort still fall short (https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2). Claude Mythos 5.2 has the same capabilities for verified organizations, and this guidance applies to it. Thinking is always on, so effort is the control for thinking depth.

The Fable 5.2 guide is organized by observed behavior (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2). Add a snippet below only when the output shows the behavior it addresses, one change at a time, and measure its effect and its token cost.

Make prompt and tool-description changes in new conversations. On Fable 5.2 the API enforces the prefix check for every account: a request that sends thinking blocks back after `system`, `tools`, or an earlier message changed can return a 400, so a stored conversation resumed with new text can fail. To change instructions partway through, put them in the newest turn or, where mid-conversation system messages are available, append a system message.

The 5.2 guide does not restate several Fable 5.1 patterns: batching tool calls, chat formatting and prose density, quoting sources, compaction summaries, scope and tests, search at `low`, and long outputs. They are in `references/fable-5-1-carryover.md`. Keep each only where your output on Fable 5.2 still shows the behavior.

<context>
Behaviors to design around (Fable 5.2 page):

- **Follows instructions as written.** Approval rules, "never" rules, style limits, and cautions carried in notes or memory are applied closely, so broad or stale ones hold back routine work.
- **Can stop early.** On long multistep tasks a turn sometimes ends with a list of what remains, an offer to continue, or a stop at an ordinary obstacle such as a timeout. This is more frequent at `low` and `medium`.
- **Quiet during long tool runs.** It writes little user-facing text and may make its first tool call without saying what it is about to do. Updates arrive as progress-update thinking blocks, whose text is empty at the default `thinking.display` of `"omitted"`.
- **Sensitive to code ownership.** When the prompt says nothing about ownership, or presents the code as someone else's, it adds to the existing structure, even repeating code, and reports nearby problems instead of fixing them.
- **Delegation depends on the harness.** With a minimal subagent tool it rarely starts one. Where prompts invite delegation it delegates readily, and at `xhigh` and `max` it has used subagents to review its own work.
- **Thinks before almost every reply at `high` and above**, a greeting included. A line such as "answer directly without deliberating" does not stop it at `medium` and above.
</context>

## Effort

Start at `high`, the API default, and test each change on your own evals. Levels run in the same order across Claude models, but the amount of thinking behind each differs, so rerun the effort sweep instead of carrying over a setting tuned on Fable 5.1 or Opus 5.5. Tune effort alongside the prompt, because the level also changes how the model thinks and how many tool calls it makes.

| Level | Use for |
|---|---|
| `max` | Measuring the model's ceiling, or the rare task where time and tokens do not matter. Suits open-ended problems such as scientific discovery and mathematics. Slow, with many more tokens than `xhigh`. |
| `xhigh` | The hardest long-running coding and agentic work, where you have measured a gain. On Anthropic's coding evals it raised scores slightly and used many more tokens. |
| `high` | Default. Hard coding, research, agentic work, long unattended runs. Most of the capability gain is already present here; above it, gains are uneven and depend on the task. |
| `medium` | Interactive coding, chat, everyday knowledge work. Move down from `high` wherever your evals show quality holds. |
| `low` | Quick back-and-forth, well-specified tasks, high-volume workloads such as fast subagents. Scores sat close to Fable 5.1's at higher levels. |

- For agentic work at `low` or `medium`, add the Finishing work text below, because early stops are more likely there.
- If easy requests take too long or cost too much, lower effort for those turns. Remove lines that ask the model to think less; they have no effect at `medium` and above.
- Effort barely changes reply length. Set length and tone in the prompt.
- Levels can be mixed in one workflow, for example planning at `medium` and raising effort for the long unattended part. A per-message effort change (beta, `mid-conversation-output-config-2026-07-01`) keeps the prompt cache; a new top-level `effort` value starts the cache over.
- At `high` and above, set a large `max_tokens`: it is a hard limit on thinking plus response text (https://platform.claude.com/docs/en/build-with-claude/effort).

## Finish the Whole Task

If the agent ends turns while work is still owed, add text like this to the system prompt:

```
# Finishing work
Please avoid stopping while you still owe work the user asked for. Be persistent and do not stop unless needed.

While status notes are welcome, as is clarifying with the user on open decisions, carry on with work that does not depend on the user's answer without unnecessary stops.

If you notice yourself inviting the user to redirect you or offering to wait, instead proceed on the next part of the task. You may meet ordinary obstacles like errors, timeouts, locked files, empty results or failing tools. Diagnose them first, and when they are not real blockers, work through them with the access you have (wait and retry, fix the request, use another tool or source) rather than stopping unnecessarily.

If someone clearly decided something is a hard blocker, such as a file marked not to be touched, access that was intentionally withheld, or a safety guardrail, leave it alone, say plainly what you found, and look for another safe way to finish the task. Stopping before the task is complete is very rarely merited, as in when the task can't move forward without user input, or where the blocker is deliberate and should not be worked past. This does not override the need for confirmation on risky or destructive actions.
```

- The text separates ordinary obstacles (errors, timeouts, failing tools), which the model should diagnose and work through, from deliberate blockers (a file marked not to be touched), which it should leave alone and report. Keep that distinction when you adapt the text.
- Anthropic replayed recorded coding-agent sessions at `medium`. With a version of this text, about half as many sessions ended with doable work left, and output tokens rose by about 30 percent. It removed most endings that ask permission or offer to continue, but not endings that list what remains and then stop.
- The model asks less often with this text, so keep your own confirmation step for risky or irreversible actions.

### Approvals

- When you tell the model to keep going, say what is approved: "Yes, run the migration on the staging database", not "go" or a bare "continue".
- Name the exact actions each approval rule covers, because the model applies rules as written. In Anthropic's testing with nobody there to approve, a rule that listed "sending messages to people outside this conversation" made the model hold back roughly half of its routine requests to colleagues and other teams.

## Code Ownership

To have the model improve structure as it works, merging repeated code and making related fixes unasked, say that the code is its own:

```
This codebase is yours: what it's for and how it's built are your call, and you'll keep building on it.
```

- In Anthropic's testing on small coding tasks, the model merged repeated code in about half of the tries with this sentence and in under a tenth without it. The requested feature worked in nearly every try either way.
- The cost is about 1.5 times the output tokens, changes nobody asked for (many of them tests and documentation), and, apart from bug fixes, a change to how an existing feature behaves in one try in six to ten, more often at higher effort. The closing summary often leaves out small changes, so review the diff.
- Leave the sentence out where the user owns the code and wants it changed as little as possible. A scope rule elsewhere in the prompt does not cancel it: with "No drive-by refactors, renames or cleanups" in the same prompt, the model still merged repeated code in about a third of the tries.

## Progress Updates

Updates matter most when a user watches the work in real time. Four levers, in order:

1. **Receive the updates.** Set `thinking.display` to `"updates"` (beta, `thinking-display-updates-2026-08-18`) for a short summary of each update, or to `"summarized"` to get the updates with summarized reasoning. Render the non-empty thinking blocks between tool calls.
2. **Remind after a silent stretch.** Have the harness count consecutive tool-calling steps that give the user nothing to read: no text block and no thinking block with text. After several, append this after the latest tool results as a turn-scoped system message (`clear_at: "next_user_message"`, beta, `mid-conversation-system-clear-at-2026-08-21`). In Anthropic's testing it roughly halved the longest silent stretch, with no noticeable increase in tokens or time. Leave each reminder in `messages` on later requests: removing or rewording one edits an earlier turn and invalidates the thinking blocks after it.

```
The user hasn't heard from you in a while: say in a few words what you're doing, then continue.
```

3. **Ask for an opening line, brief updates, and a recap** in the system prompt, where a human is directly in the loop. With this text the model spoke before its first tool call every time, and output tokens per task rose by roughly 20 percent.

```
Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own (what you found, what you did, and what's next), so a reader who only sees the last message has the full picture.
```

4. **Where the harness cannot change**, or the platform has no mid-conversation system messages, add this sentence to the system prompt:

```
Every few tool calls, give the user a one-line update on where things stand.
```

Even with levers 2 and 3 together, expect runs of several tool calls between updates. On long asynchronous tasks, where the user comes back for the result, the gaps matter less.

## Subagents

- **Review delegation lines first.** If system prompts, skills, or agent files tell the model to delegate, and it starts more subagents than the tasks need, remove the lines you no longer need.
- **Rewrite the subagent tool's description only if the model still over-delegates.** State what a subagent adds to the cost of a session, when delegation is worth it and when it is not, and how to brief a subagent, with cost first. In Anthropic's testing on short tasks, the model delegated about a third less often with such a description than with one that mostly listed reasons to delegate, at the same task success. Say less about cost if the model delegates too little. A tool with a plain description, in a prompt that does not ask for delegation, likely needs no change.
- **Check which model the harness runs subagents on.** Subagents can account for a large part of what a session costs. Early testers had good results with Fable 5.2 as planner and orchestrator for other models.

## Caution That Builds Up

Cautious instructions accumulate wherever context carries over: memory, notes, instruction files, and messages between agents. Fable 5.2 follows them closely, so it may ask for approvals it does not need or hold back routine work, mostly where several agents work together. If that shows up, clean up what the agents carry. The figures are from Anthropic's testing on simulated tasks.

- **Remove notes you no longer need.** With a dozen notes from earlier sessions in context, one of which said never to retry, the model retried after a busy tool in about four in ten tries, down from nearly all.
- **Name the steps that need no approval.** A line at the end of the rules that listed retries among such steps raised retries from almost none to about half of the tries. A general instruction to act more freely changed nothing. Name retries only for calls that are safe to repeat.
- **Check what reviewer agents attach.** A reviewer's "stop at the first error" in context kept the model from retrying in about a third of the tries, even with retries listed as needing no approval.
- **Write the exception into the rule.** Under a "never" rule, the model took a step the person in charge had approved in about one try in ten, and a separate line saying an approved step has its go-ahead changed little. When the rule itself said to get a go-ahead first, the model took the step in about nine tries in ten.

## Instructions Written for Earlier Models

When you carry over a system prompt, skills, or a harness written for Fable 5.1 or Opus 5.5, reconsider these:

- **Standing instructions to delegate.** See Subagents above.
- **A token budget the harness writes into the prompt.** The size of the budget changes how much the model spends. On coding tasks at `high` and `xhigh`, removing a large budget lowered cost at equivalent performance. This is about prompt text, not the API's task budgets.
- **Harness code that edits earlier turns.** Changing the system prompt, the tools, or an earlier message invalidates the thinking blocks after the changed point: the Messages API rejects the request, and the Message Batches API drops the blocks. Keep the history append-only, apart from context editing and compaction that keeps no earlier turns after the summary. Setting `thinking.block_binding.prefix_mismatch_behavior` to `"drop_block"` (beta, `thinking-binding-controls-2026-08-01`) drops the blocks instead of failing, and the model then thinks again; measure output tokens before relying on it.
- **The "treat that answer as done" lines** from the Opus 5.5 guide for chat system prompts. At `high` they reduced thinking on follow-up questions but made the model far less likely to point out mistakes in its earlier answers. Leave them out where the model should keep re-examining its answers, and test before adopting them elsewhere.
- **Instructions to think less.** Remove them and lower effort.
- **Hard style limits** such as "one instruction per sentence, in 20 words or fewer". The model follows them closely enough to make its prose choppy. Remove the ones you no longer need before adding the report text below.
- **Rules, notes, and memories that have built up**, some written by the model itself. Delete cautions whose reason no longer holds, and rewrite absolute rules so that they state their scope and reason. If a system is already stuck, consider restarting it with trimmed memory and notes, and keep a copy of the originals.

## Final Reports

The people who read a final report after long agentic work usually have not seen the tool calls or files behind it. For final reports and handoffs, add this to the system prompt and adjust it to your readers:

```
# Communicating clearly
Write for an intelligent but low-context reader. The person reading has not seen your tool calls, your reasoning or the files you opened, and may be switching in from other work. Messages should generally be self-contained: the reader should understand what you mean without having to dig for other context. Put the key points in the first few sentences. Practice progressive disclosure in your sentence order, and do not use undefined references and ideas in line 1 that won't make sense until the reader reaches line 12.

Use plain words, and write in clear, understandable full sentences. Do not use a term or abbreviation that you made up during the work. Say what the thing is in a way any reader would understand. Write mostly in the style of ASD-STE100 Simplified Technical English: short sentences, one idea per sentence, active voice, and consistently using the same word for the same thing. Use a paragraph of flowing prose where ideas connect, and keep bullets for lists of separate items. Leave out unnecessary details unless the reader asks and practice concision, but do ensure that your messages have the key context. Aim to make your user-facing text as human-readable and clear as possible.
```

In Anthropic's testing this made final reports less dense, and on workflow automation tasks it also made sentences shorter. Add instructions about length or required details as needed.

## Refusals

Fable 5.2 runs safety classifiers. A declined request returns `stop_reason: "refusal"` with a `stop_details.category` of `cyber`, `bio`, `frontier_llm`, `reasoning_extraction`, or `general_harms` (https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback).

- Remove instructions in prompts, skills, and tool descriptions that ask the model to write its reasoning in the response; they can be declined as `reasoning_extraction`. To see how the model reasoned, set `display: "summarized"` and read the thinking blocks.
- Benign cybersecurity and life sciences work can trigger the `cyber` and `bio` classifiers. Organizations whose legitimate work is blocked can apply to Anthropic's Cyber Verification Program or Life Sciences Verification Program. Claude Mythos 5.2 is available only to organizations verified through them.
- With server-side fallback, a category with no recommended fallback, such as `reasoning_extraction`, still comes back as a refusal.

## Reference Files

- `references/fable-5-1-carryover.md`: read when output on Fable 5.2 shows a behavior the 5.2 guide does not cover: one tool call per turn, hidden tool output, over-formatted or dense prose, unmarked quotes, scope creep or extra tests, whole-file rewrites, cut-off long outputs, skipped searches at `low`, or unverified progress claims. Also read it when writing compaction or memory instructions.
- `references/migration.md`: read when converting prompts from Fable 5.1, Opus 5.5, or older Claude models.

## Reference

- Prompting Claude Fable 5.2: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2
- What's new in Claude Fable 5.2: https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2
- Claude Fable 5.2 migration guide: https://platform.claude.com/docs/en/models/fable-5-2/migration-guide
- Prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Effort: https://platform.claude.com/docs/en/build-with-claude/effort
- Preserved thinking: https://platform.claude.com/docs/en/build-with-claude/preserved-thinking
- Refusals: https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback
