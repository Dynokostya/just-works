# Gemini 3.x Tools and Grounding

Prompt wording for function calling and Google Search grounding. Parameter names follow the Interactions API shown in the current Google docs; the older `generateContent` API may spell them differently, so check the linked pages for the API in use.

## Contents

- Function declarations as prompt text
- Function-calling modes
- Calls, results, and thought signatures
- Google Search grounding

## Function declarations as prompt text

Source: https://ai.google.dev/gemini-api/docs/function-calling ("Best practices").

- Use descriptive function names without spaces or special characters.
- Write specific, unambiguous descriptions. The model relies on them to pick a function, so "Gets data" is a prompt-quality bug.
- Describe each parameter: valid ranges, units, enum meanings. State what omitting an optional parameter means.
- Use strong types (integer, string, enum).
- Keep the active tool set to 10-20 tools. Prune tools the current workflow will not call.
- For chains such as `get_location()` then `get_weather(location)`, let the model orchestrate. Do not prescribe the sequence in prose.

## Function-calling modes

The Interactions API sets the mode with `tool_choice` in `generation_config`:

| Mode | Prompt implication |
|---|---|
| `auto` (default) | Say when a tool call is appropriate and when a prose answer is enough. |
| `any` | A call will happen; focus the prompt on argument selection. |
| `validated` | Describe when each path (call or prose) is preferred; the schema is validated. |
| `none` | Treat as prompt-only; do not reference tools. |

## Calls, results, and thought signatures

- Each function result is returned with the `call_id` of the call it answers.
- Thought signatures are encrypted representations of the model's reasoning, required for continuity across turns. In stateful Interactions API mode the server handles them. If you manage history yourself, resend all thought blocks exactly as received, including signatures on built-in tool call and result blocks (https://ai.google.dev/gemini-api/docs/thinking, "Thought signatures").
- When hand-authoring conversation history in prompt scaffolds, dropping or editing these fields breaks reasoning continuity.

## Google Search grounding

Source: https://ai.google.dev/gemini-api/docs/google-search.

- Use the `google_search` tool. The older `google_search_retrieval` tool applies to older models only; update tool-instruction text that still names it.
- Phrase prompts so retrieval is needed: "What is the current price of ...", "What are the latest ...", "Use up-to-date information from Google Search."
- For time-sensitive tasks, give the current date in the system instruction (see the time-awareness clause in SKILL.md).
- Responses carry `url_citation` annotations that link text segments to sources. Render citations from the annotations in the application; ask the model for inline citations only when the product needs them in the text itself.
