# Migrating Prompts to Opus 5.5

Sources: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5, the Opus 5 guide, and the shared best-practices guide. The steps for Opus 4.8 and older come from the shared guide and the context-engineering post (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models).

## Contents

- From Opus 5
- From Opus 4.8
- From Opus 4.7 or older

## From Opus 5

- [ ] Run existing prompts unchanged first; edit only for measured gaps.
- [ ] Retest effort: start at `medium`, try `low` for subagents and latency-sensitive routes, keep `xhigh` and `max` only where measured. To reduce thinking, lower effort rather than adding instructions.
- [ ] Remove show-your-reasoning instructions (`reasoning_extraction`), and rework prompts written for thinking disabled.
- [ ] Remove "think carefully before answering" lines from chat prompts; add the answer-finality snippet if re-examination is a problem.
- [ ] Opus 5 narrated a lot and Opus 5.5 can go quiet: render progress notes (`display: "updates"`), add a send-the-user-a-message tool, keep the intent and recap instruction, add the silent-stretch nudge.
- [ ] For unattended agents: add the continuation harness and the standing turn-ending instruction; treat text-only turn ends as reports. Add time signals to multi-agent harnesses.
- [ ] Add the explore-first instruction to multi-app workflows; keep untrusted content out of searched sources.
- [ ] Wrap pasted content in id-tagged `<pasted_content>` blocks and add the system-prompt note.
- [ ] Replace general "avoid a generic AI look" frontend instructions with specific named patterns.
- [ ] Retest vision scaffolding; add crop tools or higher-resolution inputs for the densest images.
- [ ] Put prompt additions in from the first request or as appended messages; do not edit earlier prompt text.
- [ ] Retest the Opus 5 mitigations (long responses, over-verification, scope, correction narration, subagent spawning; see the carry-over file linked from SKILL.md) and keep each only where the behavior still shows.
- [ ] Frame legitimate security and biology work explicitly; the biology classifier is new.

## From Opus 4.8

Apply these, then the Opus 5 steps above:

- [ ] Remove verification and self-check instructions ("include a final verification step", "use a subagent to verify").
- [ ] Replace subagent encouragement with explicit delegation criteria where spawning runs high.
- [ ] Remove "think step by step" and hand-written reasoning plans.
- [ ] Revalidate vision and frontend counter-prompting tuned for 4.8's house style.
- [ ] Rightsize context: convert worst-case guardrails to principles, state each instruction once across system prompt, tool descriptions, and CLAUDE.md, and move detail into selectively loaded skills.

## From Opus 4.7 or older

- [ ] Replace CRITICAL, MUST, ALWAYS, NEVER, REQUIRED, and MANDATORY with calm, direct wording.
- [ ] Remove anti-laziness prompts ("be thorough", "think carefully", "do not be lazy") and think-tool instructions.
- [ ] Replace prefill-based shape enforcement with structured outputs or "respond with JSON only".
- [ ] Remove "summarize every N tool calls" scaffolding.
- [ ] Add action-safety guardrails, a LaTeX opt-out if needed, and defensive-purpose framing for security prompts.
