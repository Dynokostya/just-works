# Opus 5 Behaviors Not Re-Addressed for 5.5

These mitigations come from the Opus 5 guide (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5). The Opus 5.5 guide does not re-address them. Run the prompt without a mitigation first and add it only where the output still shows the behavior.

## Contents

- Response length
- Written deliverable length
- Over-verification and scope
- Subagent spawning
- Self-correction and correction narration
- Code review prompts

## Response length

Opus 5 ran long by default, and effort changes thinking volume rather than reliably shortening the visible response. Opus 5.5 leads with the important information and uses less jargon. If replies still run long, prompt for length:

```
Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested.
```

In a long system prompt, pair it with a reminder near the end: `<tone_preference>Keep outputs reasonably concise.</tone_preference>`

## Written deliverable length

For reports and documents the model writes to disk:

```
Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.
```

## Over-verification and scope

Opus 5 verifies its own work without being told to. Remove instructions such as "include a final verification step for any non-trivial task" and "use a subagent to verify"; they cause over-verification and waste tokens with no quality gain. The same applies to legacy harness steps that add separate verification.

Opus 5 can also add steps nobody requested. For narrow tasks:

```
Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it. Finish the whole task, and stop short of actions that are clearly beyond what was asked.
```

## Subagent spawning

Opus 5 delegates more readily than earlier models, which multiplies cost and time on small tasks. Give criteria, or cap spawn counts in the harness:

```xml
<subagent_guidance>
Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide multi-file investigation. Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or double-check your own work. If one subagent can complete the task, use one rather than several, and keep spawn counts low.
</subagent_guidance>
```

## Self-correction and correction narration

Do not instruct re-checks the model already performs ("double-check your answer", "re-verify before responding"). The model also narrates corrections to earlier statements more than prior models, which can be unwanted in user-facing products:

```
Only correct an earlier statement when the error would change the user's code, conclusions, or decisions. State corrections plainly and briefly, then continue the task. For slips that change nothing for the user, make the fix and move on without noting it.
```

## Code review prompts

Opus 5 reviews code with high precision and recall, and accuracy holds at lower effort, which supports a fast pass at review time and a thorough pass later. A review prompt that says "only report high-severity issues" or "be conservative" is followed literally and drops real findings. Ask for everything and filter in a separate step. For example:

```
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```
