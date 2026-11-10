# Fable 5.1 Carryover Patterns

Patterns from earlier Fable guides that the Fable 5.2 guide neither restates nor withdraws. Unless marked, each comes from https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1. The ones marked "Fable 5 page" come from https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5.

Whether Fable 5.2 still shows each behavior is not documented. Add a pattern only after you see the behavior in your own output on Fable 5.2, and measure the change. Where a pattern conflicts with SKILL.md, SKILL.md applies.

## Contents

- Agent loops: batching tool calls, hidden tool output, `send_to_user`, working while subagents run, tool triggering
- Scope: delivering work, changes and tests, targeted edits
- Long runs: checkpoints, overplanning, progress claims, compaction summary, memory notes
- Writing: chat formatting, mannered prose, quoting sources, giving the reason
- Effort-specific: long outputs at `xhigh` and `max`, search at `low`
- Refusals
- Vision

## Agent loops

**Batch independent tool calls.** When the model issues independent calls one per turn, append this after each tool-result turn as a turn-scoped system message (`role: "system"`, `clear_at: "next_user_message"`, beta header `mid-conversation-system-clear-at-2026-08-21`), and leave earlier copies untouched. Without the beta, put it in a text block after the `tool_result` blocks.

```
First privately list what you need next; then request every item that doesn't depend on another's result in this one response.
```

**Hidden tool output.** If the UI hides tool output, send this as a turn-scoped system message:

```
Only you see that command's output — the user's terminal shows at most a few lines of it. If the user needs to read any of it, put it in your reply.
```

**`send_to_user` tool.** For long asynchronous agents, a `send_to_user` tool (input: the message to display; return a simple acknowledgement) lets the model show content verbatim without ending its turn. Declare it in `tools` from the first request, because adding a tool later changes `tools` and invalidates earlier thinking blocks. Without a system-prompt instruction the model rarely calls it. Pair it with:

```
Between tool calls, when you have content the user must read verbatim (a partial deliverable, a direct answer to their question), call the send_to_user tool with that content. Use send_to_user only for user-facing content, not for narration or reasoning.
```

**Working while subagents run.** The tool that starts a subagent should return immediately, results should arrive in a later message, and the lead needs a separate tool to wait. If the lead still blocks on each subagent, add the sentence below. It asks for delegation, so check it against the Subagents section of SKILL.md first.

```
Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context.
```

**Tool triggering.** Forced tool use (`tool_choice` of `any` or `tool`) returns a 400 on Fable 5.2 (https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2), so name the tool in the prompt: "Use the `get_weather` tool to answer." Keep the wording calm: `Use this tool when...`, not `CRITICAL: You MUST...`.

## Scope

**Delivering work.** This block defines the user's request as the scope of the deliverable. It also tells the model to keep going, as the Finishing work text in SKILL.md does, so test the two together before using both.

```
# Delivering work

The user's request — or the plan they approved — sets the scope, and the scope is the deliverable: don't quietly narrow, widen, or swap it. Read ambiguity the way a careful colleague would: make routine judgment calls yourself, and check in only when different readings would lead to materially different work. If you see a real problem with the task as specified, say so in a sentence or two and keep building under stated assumptions; if the user hears the concern and reaffirms, that is their decision, so deliver the full request.

If a question comes up partway, first do everything that doesn't depend on the answer; then state the assumption you made, or — when going ahead on a wrong guess would be unsafe or would make the work useless — put the question at the end of a turn that also delivers that progress. If one part turns out to be blocked, complete every other part in full and say exactly what you left out and why — the whole task is the deliverable, and scaling it down is the user's call, not yours. A step you have decided on is something to run, not to announce: describing the next step and ending the turn leaves it undone until the user replies.

Keep changes to what the request needs. Something else you notice worth doing — cleanup or documentation the task didn't call for, a change to a file the task didn't require — is a suggestion to make at the end, not a change to make; actions clearly beyond what the ask implies, and risky or destructive ones, still need the user's go-ahead.
```

**Changes and tests.** This instruction works in the opposite direction from the ownership sentence in SKILL.md. Use it where the user wants the code changed as little as possible. In Anthropic's testing on Fable 5.1, unrequested additions and committed test code dropped substantially with no measurable change in task success.

```
If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files — roughly one focused test per stated behavior — and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.
```

**Targeted edits.** If the model rewrites whole files for small edits:

```
The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing.
```

## Long runs

**Checkpoints** (Fable 5 page). For long workflows where the model pauses too often:

```
Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input that only they can provide. If you hit one of these, ask and end the turn, rather than ending on a promise.
```

**Overplanning on ambiguous tasks** (Fable 5 page):

```
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue in user-facing messages. If you are weighing a choice, give a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

**Progress claims** (Fable 5 page). Anthropic reports this nearly eliminated fabricated status reports in its testing:

```
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step was skipped, say that; when something is done and verified, state it plainly without hedging.
```

**Compaction summary.** For client-side compaction; server-side compaction already does this. Replace the whole history with one summary message plus the new user turn, so that no earlier turns remain after the summary.

```
Summarize the transcript inside <summary></summary> tags. Include relevant information in the summary such that this conversation will be continued by a new context window without needing to redo work or be reprovided with relevant constraints or context. Be sure to preserve: (1) any difficulties or problems that came up, and how they were handled or resolved; (2) any possibilities, options, or approaches that were raised, tried, or set aside, and why; (3) anything that was asked for, decided, agreed, ruled out, or established as a preference, constraint, or boundary — stated exactly; (4) exactly where things stand now — what has been covered, settled, or completed so far; (5) anything still open, unresolved, promised, or expected to happen next; (6) specific details that would be hard to reconstruct — names, numbers, dates, exact wording, links or references — kept exactly. Be complete on these even at the cost of length; keep everything else concise. Weight the two voices differently: keep what the user said, asked for, shared, or established carefully and close to their own words; your own explanations and reasoning can be condensed much further, to what they concluded or produced — as long as nothing in the six items above is dropped.
```

**Memory notes** (Fable 5 page). For custom harnesses and API-level agents; in Claude Code, automatic memory already captures lessons. Fable 5.2 follows stored cautions closely, so prune these notes regularly (SKILL.md, Caution That Builds Up).

```
Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo or chat history already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong.
```

## Writing

**Chat formatting.** Remove anti-formatting rules carried over from earlier models and use:

```
Use lists and bullet points when asked to, or when the content is multifaceted enough that they help with clarity. If the person explicitly requests minimal formatting, always format your responses without bullet points, headers, lists, or bold emphasis, as requested. In conversational, personal, or emotional exchanges, keep to plain prose.
```

**Mannered prose.** The short form `Please remove all mannered prose.` often works. The longer definition goes in the user message (preferred) or the system prompt:

```
Mannered prose substitutes metaphor and flourish for direct statement. Instead of "a parameter worth varying," the mannered writer produces "a dial worth turning." Instead of "this point still matters," they write "this point earns its keep." The phrases exist to display the writer, not to convey the idea, and readers can tell. That is why mannered prose irritates: it makes the reader work harder so the writer can perform. It is also imprecise. Metaphors drag in connotations the writer did not choose and cannot control. The fix is to say what you mean. When a literal phrase is available, use it.
```

**Quoting retrieved sources.** To get retrieved passages marked as quotes, put one complete worked example in the system prompt: the request, the response, and a sentence on why it is correct. Replace the two `[web_search: ...]` lines with your own tool's name so the model reads them as templated tool output rather than text to emit.

```
<example>
<user>look up how the Riverton Ledger and the Coast Dispatch each covered the Harbor Bridge closure and compare their reporting</user>
<response>
[web_search: Harbor Bridge closure Riverton Ledger]
[web_search: Harbor Bridge closure Coast Dispatch]
Both outlets agree on the basics: the bridge closed on March 3 after inspectors found cracked welds, and the state expects repairs to take about eight months. Where they differ is emphasis. The Ledger treats it as a local-economy story. The Dispatch frames it as a funding failure; its editorial calls the closure "entirely foreseeable." Read together, the Ledger explains who is affected now and the Dispatch explains how it came to this — neither account alone gives the whole picture.
</response>
<rationale>CORRECT: The response is organized around where the two outlets agree and differ, not as a walk through either article. Each outlet's reporting is conveyed in one or two sentences of the assistant's own indirect speech. One short marked phrase from one source; every other claim is reworded. The response is still specific and complete.</rationale>
</example>
```

**Give the reason, not only the request** (Fable 5 page): "I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [request]."

## Effort-specific

**Long outputs at `xhigh` and `max`.** Prefer `high` for long deliverables. At `xhigh` or `max` the model may draft a long deliverable in thinking and then write it again. Set `max_tokens` to leave room for thinking plus the reply, and append this to the end of the user message, replacing `[max_tokens]` with the request's actual `max_tokens`:

```
Everything produced in one reply, including any reasoning or drafting done before the reply, counts toward a single limit of about [max_tokens] tokens. If that limit is reached before the reply is finished, the person receives a cut-off response and has to start over. Composing an entire output or deliverable in full as reasoning and then again as a reply would double the length of the turn without improving the result, so don't do that.

Instead, when the person has asked for a long or effort-intensive deliverable such as a multi-section document, a large table or dataset, or a complete code file, spend extra effort on understanding the request, checking the inputs the answer depends on, settling the structure and other difficult decisions, and otherwise using the reasoning space to reason and the output space to write an output. Usually it is not needed to draft an output multiple times.
```

**Search at `low`.** At `low` the model is less likely to search. Raising effort for the affected turns is the simplest fix; otherwise add to the system prompt:

```
When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area like AI models and developer tools where the landscape shifts within months, the name itself is the thing to verify: search before answering, and include the name as the user wrote it in at least one query alongside any reformulations. This holds even when you have some background on it — partial background is exactly what makes an out-of-date answer sound authoritative, so familiarity is not a reason to skip the search.
```

## Refusals

- Phrase code questions as review: "Are there any bugs in this program?" rather than "Does this program compile without errors?"
- For lesser-known languages, give the model context such as the language's documentation.
- Remove base64-encoded data from tool output.

## Vision

Give the model crop and zoom tools; an image-cropping tool alone delivers most of the uplift (https://platform.claude.com/cookbook/multimodal-crop-tool).
