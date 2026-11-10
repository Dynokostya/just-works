# Migrating Prompts to Fable 5.2

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2 ("Where to start" and "Review instructions written for earlier models"). For API changes, see https://platform.claude.com/docs/en/models/fable-5-2/migration-guide.

Roll prompt and tool-description changes out with new conversations. A stored conversation resumed after `system` or `tools` changed can return a 400.

## Order of work

1. Set `effort` to `high` explicitly, then run your evals at `medium` and `xhigh` as well.
2. Read the system prompts, skills, agent files, memory files, notes, and harness text you carry over. Remove or test the instructions in the lists below.
3. Run your longest agentic tasks. Note where the model stops early, asks for approvals it does not need, goes quiet, delegates more than the task needs, or adds to existing code where you wanted it restructured.
4. Apply the guidance in SKILL.md for each behavior you observed, one at a time, and measure its effect and its token cost.

## From Fable 5.1

- [ ] Rerun the effort sweep. Do not carry over the Fable 5.1 setting.
- [ ] Remove lines that ask the model to think less, such as "answer directly without deliberating", and lower effort instead.
- [ ] If the prompt carries the Fable 5.1 autonomy block ("You are operating autonomously..."), test it against the Finishing work text. Do not use both without measuring.
- [ ] Rewrite approval rules to name the exact actions they cover, and write each exception into its rule.
- [ ] Review lines in system prompts, skills, and agent files that tell the model to delegate.
- [ ] Remove a token budget that the harness writes into the prompt, and test without it.
- [ ] Stop editing earlier turns. On Fable 5.2 the prefix check applies to every account, so a harness that passed on Fable 5.1 can fail.
- [ ] Delete notes, memories, and cautions whose reason no longer holds. Rewrite absolute rules so that they state their scope and reason.
- [ ] Remove hard style limits before adding the report text.
- [ ] Keep each pattern in `fable-5-1-carryover.md` only where the behavior still shows on Fable 5.2.

## From Opus 5.5

Apply the Fable 5.1 list, and in addition:

- [ ] Set effort explicitly. The Fable 5.2 default is `high`, and the Opus 5.5 default is `medium`, so a request that omits effort runs one level higher.
- [ ] Leave out the "treat that answer as done" lines where the model should keep re-examining its earlier answers. Test before keeping them elsewhere.
- [ ] If the prompt carries the Opus 5.5 standing instruction for unattended runs, test it against the Finishing work text. Both target early stops.
- [ ] Handle the two refusal categories that Fable 5.2 adds: `frontier_llm` and `general_harms`.

## From older models

Apply the older-model steps from the `opus-5-5-prompting` skill first, then the two lists above.

## Final check

- An effort setting carried over without a sweep.
- Think-less lines left in the prompt.
- Prompt or tool edits rolled out into stored conversations.
- A bare "continue" as approval, or an approval rule that names a broad category.
- Confirmation for destructive actions that exists only in the prompt.
- A token budget shown to the model.
- Several fixes added at once, with no measurement of each.
