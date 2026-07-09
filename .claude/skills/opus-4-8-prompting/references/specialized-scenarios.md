# Opus 4.8 Specialized Scenarios — API Feature Reference

Companion to [../SKILL.md](../SKILL.md). Prompt-authoring implications for API features and product-integration scenarios: interactive coding products, task budgets, the memory tool, high-resolution image support, computer use, cybersecurity safeguards, and fast mode.

## Interactive Coding Products

Interactive multi-turn sessions cost more tokens than autonomous single-turn agents — 4.8 reasons more after user turns. That improves long-horizon coherence and instruction following, at token cost. Prompt-authoring implications:

- **Specify task, intent, and constraints upfront** in the first user turn. A well-specified first turn pays off more on 4.8 than on prior models.
- **Avoid ambiguous prompts conveyed progressively** across many turns — this pattern hurts efficiency and sometimes quality.
- **Favor auto modes** in prompts where safe — reduce required human interactions.
- **Use `xhigh` or `high` effort** to maximize both performance and token efficiency.

## Task Budgets — Prompting Implications

Task Budgets (beta) give the model an advisory token budget across a full agentic loop; it sees a running countdown and paces accordingly. Prompt-authoring implications:

- **Budget-aware prompts can skip scaffolding** like "work efficiently" or "don't get stuck" — the budget itself paces the model.
- **Budgets below 20k tokens are rejected and budgets that are clearly insufficient cause 4.8 to refuse or stop early.** If you are prompting for a large job, state the scope plainly rather than relying on the budget to keep the model focused.
- **Instruct the model to finish gracefully** if your task benefits from end-of-budget summaries: "As the task budget nears depletion, finalize and summarize progress rather than starting new subtasks."
- **Don't layer a task_budget onto open-ended research prompts** where quality matters more than speed — let the model run without the countdown.

Source: https://platform.claude.com/docs/en/build-with-claude/task-budgets

## Memory Tool and Long-Running Agents

4.8 is meaningfully better at writing and using file-system-based memory than 4.6. When a memory tool is in play, prompts should give domain-specific guidance (what to record, what to read) rather than re-explaining the tool.

Useful phrasings:

- "Before starting work, view /memories to load any prior progress."
- "Update /memories/progress.md when you finish a feature; record assumptions that may need verifying later."

For multi-session software development, use the initializer/subsequent-session pattern: first session writes a progress log, feature checklist, and startup script; subsequent sessions read memory before starting, work on one feature at a time, update memory before ending.

Path-safety: constrain file-path parameters in the prompt ("Only access paths under /memories") — path-traversal is a known concern.

Source: https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool

## High-Resolution Image Support

4.8 supports images up to 2576px / 3.75MP (inherited from 4.7), and model-emitted coordinates are 1:1 with actual image pixels.

Prompt-authoring implications:

- **Remove any "scale coordinates by X" instructions** from prompts carried over from 4.6 — 4.8 reports coordinates in actual pixel space.
- **For pointing / bounding-box / chart-transcription tasks**, you can ask for precise pixel coordinates without scaling caveats.
- **If your harness exposes a crop tool**, tell the model to crop into regions before detailed inspection: "If you need pixel-level detail from part of an image, call the crop tool to zoom into that region first, then analyze the crop."
- **Image-heavy prompts consume up to ~3x more tokens per full-res image** vs 4.6 — factor this into your context budgeting when you size prompts.

Source: https://platform.claude.com/docs/en/build-with-claude/vision#high-resolution-image-support-on-claude-opus-4-7

## Computer Use

Computer use works across resolutions up to 2576px / 3.75MP. Internal testing shows 1080p provides a good balance of performance and cost. For cost-sensitive workloads, 720p or 1366x768 are lower-cost options with strong performance. Experiment with effort settings to tune behavior.

Source: https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool

## Cybersecurity Safeguards

A real-time safeguard layer for cybersecurity topics (inherited from 4.7). Requests involving prohibited or high-risk cyber topics may lead to refusals (stop_reason: "refusal", with stop_details category now publicly documented on 4.8).

Prompt-authoring implications:

- **Legitimate security prompts (pen testing, vulnerability research, red teaming)** may be refused where older models would comply. Apply to the Cyber Verification Program for reduced restrictions: https://claude.com/form/cyber-use-case
- **Framing matters.** Be explicit about the defensive/legitimate purpose in the prompt when it is ambiguous ("You are assisting an authorized security engineer performing an internal pen test...").
- **Don't rely on prompt injection or roleplay** to bypass the safeguard — 4.8 is less susceptible.

## Fast Mode (New in 4.8)

Fast mode (speed: "fast") delivers up to 2.5x higher output tokens per second from the same model at premium pricing. Available as a research preview on the Claude API.

Prompt-authoring implications:
- No prompt changes required — same model behavior, just faster output.
- Useful for latency-sensitive interactive products where cost is secondary to speed.

Source: https://platform.claude.com/docs/en/build-with-claude/fast-mode
