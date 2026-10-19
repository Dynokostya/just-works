# Migrating Prompts to Gemini 3.x

Prompt-level changes when moving from Gemini 2.5, or from an earlier 3.x release, to a current 3.x endpoint. Source: https://ai.google.dev/gemini-api/docs/gemini-3 ("Migration from Gemini 2.5").

## From Gemini 2.5

- [ ] Remove manual chain-of-thought instructions ("Let's think step by step", "Think carefully before answering"). Set `thinking_level` instead; Google suggests trying `high` with simplified prompts.
- [ ] Remove prompt text and code that assume `temperature` below 1.0. Google recommends dropping explicit low temperatures to avoid looping and degraded performance on complex tasks.
- [ ] Shorten verbose prompts to direct instructions.
- [ ] Move persona, constraints, and output format to the start (system instruction); move the question to the end, after the context.
- [ ] Review broad negatives ("do not infer"): keep them for verbatim extraction, replace them with specific rules for reasoning tasks.
- [ ] Remove in-prompt JSON schema templates when the caller now uses a response schema.
- [ ] Replace `google_search_retrieval` mentions with `google_search`.
- [ ] Replace `thinking_budget` wording with `thinking_level`. `thinking_budget` still works for compatibility but cannot be combined with `thinking_level` in one request.
- [ ] Image segmentation (pixel-level masks) is not supported on Gemini 3 Pro or Gemini 3 Flash. Google suggests staying on Gemini 2.5 Flash with thinking off for that workload; drop segmentation instructions from Gemini 3 prompts.
- [ ] Test dense PDF parsing with the `media_resolution_high` setting, and reduce media resolution if requests now exceed the context window.

## Between 3.x releases

- [ ] Re-check the `thinking_level` table in https://ai.google.dev/gemini-api/docs/thinking. Defaults and supported levels differ by endpoint, and some endpoints reject `minimal`.
- [ ] Re-check endpoint names and aliases against https://ai.google.dev/gemini-api/docs/deprecations before changing a hardcoded model name.
- [ ] Re-run few-shot and grounding prompts on the new endpoint. Do not assume phrasing tuned for one release behaves the same on another.
