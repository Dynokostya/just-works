# Migrating to GPT-6

Source for the API and parameter items: the "Migration quickstart" in https://developers.openai.com/api/docs/guides/latest-model. The prompt-level items come from the same guide and https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra.

## Order of work

Change one variable at a time. Switch the model, pin reasoning effort, run representative evals, then make the smallest edit that fixes each measured regression. Do not rewrite a working prompt in the same step as a model switch. To debug, collect a few real failing traces, find the instruction or contradiction behind each, make one edit, and re-run the same cases. The blog post also suggests asking Astra itself to audit prompts and skills against its guidance.

## From GPT-5.6

Prompt text:

- [ ] Pin reasoning effort. Move `none` and `minimal` routes to `low` on Astra and `gpt-6.1-sol`, and test a familiar task one level lower than the GPT-5.6 setting.
- [ ] Replace blanket brevity instructions with the writing-style snippet; Astra defaults to detailed, formatted output. State format and length in the output contract.
- [ ] Replace "proactive by default" assumptions with the bias-to-action, "can you...", and concrete-approval snippets.
- [ ] Remove "ask first," "stop for review after the first implementation," and "confirm scope expansion" language on safe work. Grant explicit permission for safe workflows.
- [ ] Put running, inspecting, and fixing the result inside the definition of done.
- [ ] Replace "always run tests" and "run the most relevant check" nudges with the testing snippet.
- [ ] Audit skills and AGENTS.md: short descriptions, minimal router files, docs referenced by context, user-over-skill precedence.
- [ ] Add delegation encouragement and the legible-messages snippet for multi-agent setups.
- [ ] Keep outcome-first structure, retrieval budget, tool routing, and Programmatic Tool Calling routing.

API and harness settings:

- [ ] `none` reasoning effort returns HTTP 400 on Astra, and `gpt-6.1-sol` rejects `none` and `minimal`.
- [ ] Use the Responses API for tool calling. Chat Completions with Astra or `gpt-6.1-sol` does not support function calling; `gpt-6-sol` and `gpt-6-luna` support it only with `reasoning_effort: "none"`.
- [ ] When reasoning effort is not `none`, remove `temperature`, `top_p`, and `top_logprobs` from requests.
- [ ] To change effort between turns without breaking the cached prompt prefix, use `configuration_update` input items and leave request-level `reasoning.effort` unchanged.
- [ ] Moving from GPT-5.5 or earlier: replace `prompt_cache_retention` with `prompt_cache_options.ttl`.

## From older models

These two entries are this skill's recommendations, not OpenAI-published guidance.

- **GPT-5.5, GPT-5.4, GPT-5.3-Codex**: run a lean-prompting pass first, since these prompts carry the most process scaffolding and tool-persistence blocks, then apply the GPT-5.6 list.
- **GPT-4o, GPT-4.1**: remove defensive prompting, start Astra at `low`, add an output contract only if outputs drift, and add approval boundaries for agentic use.
