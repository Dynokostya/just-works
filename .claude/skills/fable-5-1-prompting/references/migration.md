# Migrating Prompts to Fable 5.1

Sources: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1 and https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5.

## From Fable 5

- [ ] Re-run the effort sweep; start comparisons at `medium`, which roughly matches Fable 5 at lower cost.
- [ ] Remove prompt text that assumes a no-thinking mode.
- [ ] Remove "hold all findings for the final response" lines; set `thinking.display` so progress notes reach the client; add the progress-update instruction and, if tool output is hidden, the turn-scoped output reminder.
- [ ] Replace separate autonomy-reminder, boundary, and ample-context snippets with the Finish the Whole Task block.
- [ ] Add the batching reminder after tool-result turns in agent loops.
- [ ] Move per-turn reminders into appended turn-scoped system messages; stop editing earlier prompt text mid-conversation.
- [ ] Remove anti-formatting rules; add the chat formatting instruction.
- [ ] Add the mannered-prose instruction where prose reads dense.
- [ ] Add a quoting worked example for retrieval products.
- [ ] Add the scope-and-tests instruction for coding at `high` and above.
- [ ] Add the search-trigger instruction for `low`-effort routes that need lookups.
- [ ] Add the long-output note for long deliverables at `xhigh` or `max`, or use `high`.
- [ ] Pair any `send_to_user` tool with its system-prompt instruction.
- [ ] Enforce destructive-action approvals in the harness.

## From Opus 5 or Opus 4.8

Apply the older-model steps from the `opus-5-5-prompting` skill first, then the Fable 5 list above. In addition:

- [ ] Audit for show-your-reasoning language; it triggers `reasoning_extraction` refusals.
- [ ] Strip over-prescriptive instructions. Anthropic reports skills written for earlier models are often too prescriptive for Fable-class models and can degrade output.
- [ ] Add the progress-audit instruction to long-run prompts.
- [ ] Coming from 4.8, flip subagent guidance from "encourage spawning" to "state when delegation is appropriate."

## Anti-patterns worth a final check

- Reusing Fable 5 effort settings without a sweep.
- Changing conversation-level effort partway through instead of per message.
- Editing earlier prompt text or history mid-conversation.
- Prompt-only approval gates for destructive actions.
- Surfacing token countdowns to the model.
- Blocking the lead agent on each subagent.
