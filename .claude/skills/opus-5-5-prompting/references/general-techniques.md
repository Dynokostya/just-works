# General Claude Prompting Techniques for Opus 5.5

Techniques from the shared Claude guide (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) and Anthropic's context-engineering post (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models). They apply across Claude models. The snippets are condensed, calmer-toned adaptations of Anthropic's published ones (the originals use stronger wording such as MUST and BEFORE), so adapt them to the product.

## Contents

- Output format
- Tool-use triggering
- Parallel tool calls
- Action safety
- Action versus suggestion
- Test hard-coding, temporary files, LaTeX
- Structure and long context
- Prefill and forced tool calls
- Structured outputs
- Context hygiene

## Output format

1. Say what to do rather than what not to do: "compose your response of smoothly flowing prose paragraphs" beats "do not use markdown".
2. Use XML format indicators: "Write the prose sections of your response in `<smoothly_flowing_prose_paragraphs>` tags."
3. Match the prompt's style to the output style. Removing markdown from the prompt reduces markdown in the output.
4. Give detailed formatting instructions when formatting matters.

For bullet-heavy replies, add an `<avoid_excessive_markdown_and_bullet_points>` block: write long-form content in clear, flowing prose; reserve markdown mainly for inline code, code blocks, and simple headings; use lists only for truly discrete items or when the user asks for a list or ranking.

## Tool-use triggering

Keep language calm and conditional. Forceful phrasing written for older models causes overcorrection.

| Avoid | Use |
|---|---|
| `CRITICAL: You MUST use this tool when...` | `Use this tool when...` |
| `You MUST ALWAYS search before answering` | `Search before answering when the question involves specific facts` |
| `NEVER respond without checking...` | `Check [source] when the user asks about [topic]` |

Drop `CRITICAL`, `You MUST`, `ALWAYS`, `NEVER`, `REQUIRED`, `MANDATORY`, and `IMPORTANT:` in favor of direct statements or `should`.

## Parallel tool calls

```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between them, make all of the independent tool calls in parallel. For example, when reading 3 files, run 3 tool calls in parallel. If some tool calls depend on previous results to inform parameters, call them sequentially instead. Never use placeholders or guess missing parameters.
</use_parallel_tool_calls>
```

## Action safety

```xml
<action_safety>
Before taking any action, evaluate its reversibility and impact.
Ask for user confirmation before destructive operations (deleting files, dropping tables, overwriting data), hard-to-reverse operations (force push, database migrations, deployment), and operations visible to others (posting messages, sending emails, creating PRs).
Proceed without confirmation for reading files and gathering information, creating new files, running tests, local git commits, and writing to scratch/temporary files.
</action_safety>
```

## Action versus suggestion

The model takes verbs literally: say "change" or "implement", not "suggest changes". Pick one default:

```xml
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing.
</default_to_action>

<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. Default to providing information and recommendations rather than taking action. Only proceed with edits when the user explicitly requests them.
</do_not_act_before_instructions>
```

To stop speculation about unread code:

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, read the file before answering. Investigate and read relevant files before answering questions about the codebase.
</investigate_before_answering>
```

For code-level over-engineering:

```xml
<scope_constraints>
Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused:
- Don't add features, refactor code, or make "improvements" beyond what was asked.
- Don't add docstrings, comments, or type annotations to code you didn't change.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen.
- Don't create helpers, utilities, or abstractions for one-time operations.
</scope_constraints>
```

## Test hard-coding, temporary files, LaTeX

- Scratch files: "If you create any temporary files for iteration, remove them at the end of the task."
- Test hard-coding: "Write a general-purpose solution. Do not hard-code values or create solutions that only work for specific test inputs. If tests are incorrect, inform me rather than working around them."
- Opus models default to LaTeX for math. To opt out: "Use plain text notation rather than LaTeX. For example, write 'x^2 + 3x + 1' instead of '$x^2 + 3x + 1$'."

## Structure and long context

- Use consistent, descriptive XML tag names and nest where content has natural hierarchy (`<documents>`, then `<document index="n">` with `<source>` and `<document_content>`). Use markdown headers where they are enough.
- Put long documents at the top and the query at the end. Anthropic's tests show queries last can improve quality by up to 30 percent, especially with multi-document inputs.
- Ask the model to extract relevant quotes into `<quotes>` before answering.
- Prefer expressive interfaces (tool parameters, schemas, rubrics) to usage examples; on Claude 5-generation models examples constrain exploration. Where an example must pin an output format, use 3-5 precise ones in `<examples>`.
- If the harness compacts context, prevent premature wrap-up:

```
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working from where you left off. Do not stop tasks early due to token budget concerns. As you approach your budget, save progress to memory before the context refreshes. Never artificially stop a task early regardless of the context remaining.
```

## Prefill and forced tool calls

Prefilled assistant responses are not supported on current Claude models, so steer in the prompt:

- JSON or YAML shape: use structured outputs, or "Respond with a JSON object only. No preamble or explanation."
- No preamble: "Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc."
- Continuing after an interruption: in the user turn, "Your previous response was interrupted and ended with [previous_response]. Continue from where you left off."
- Role reminders: in the user turn or an appended system message.
- Forced tool use is not supported on every model and setting (https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools). Where it fails, name the tool in the prompt: "What's the weather in Paris? Use the get_weather tool."

Append prompt additions to the conversation, or put them in from the first request. Do not edit earlier prompt text mid-conversation.

## Structured outputs

When a schema enforces the shape, the schema owns the shape and the prompt owns the intent. Do not embed JSON templates in the prompt; duplication confuses the model. State the task ("Extract the customer's contact info from the message below.").

## Context hygiene

From the context-engineering post: Anthropic removed over 80 percent of Claude Code's system prompt for Claude 5-generation models with no measurable loss on its coding evals.

- Convert worst-case guardrails into principles and let the model use context and judgment.
- State each instruction once; keep tool-usage instructions in tool descriptions rather than repeating them in the system prompt.
- Keep CLAUDE.md light and spend its tokens on gotchas the model cannot see from the repo.
- Split long skills into files loaded when needed.
