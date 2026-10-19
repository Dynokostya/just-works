# Gemini 3.x Jinja Prompt Patterns

Templates for prompts rendered with Jinja. Each follows the layout in SKILL.md: rules first, examples and context next, the task last.

## Contents

- Few-shot classification
- Classification with a confidence field
- JSON output without an enforced schema
- Multi-source synthesis
- Prompt chains
- Reasoning task

## Few-shot classification

```jinja
Classify the following {{ item_type }} into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
{{ item_type }}: {{ example.input }}
Category: {{ example.category }}

{% endfor %}
{{ item_type }}: {{ input_item }}
Category:
```

## Classification with a confidence field

```jinja
Classify each message into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
Message: {{ example.message }}
Category: {{ example.category }}
Confidence: {{ example.confidence }}

{% endfor %}
Message: {{ input_message }}
Category:
```

## JSON output without an enforced schema

Use this only when no response schema is configured. With a schema, state the task and let the schema define the shape.

```jinja
Extract {{ fields | join(", ") }} from the following text.

Text: {{ input_text }}

Respond in JSON format:
{
  {% for field in fields %}
  "{{ field }}": "..."{% if not loop.last %},{% endif %}
  {% endfor %}
}

JSON:
```

## Multi-source synthesis

Wrap each document in an indexed tag and anchor the question to the full set.

```jinja
{% for doc in documents %}
<document id="{{ loop.index }}">
{{ doc }}
</document>
{% endfor %}

Based on the entire set of documents above, provide a comprehensive answer
to the following question. Reference specific documents by ID when citing
information.

Question: {{ question }}
```

## Prompt chains

Split a prompt into stages when one prompt carries several jobs. Each stage receives the previous stage's output.

Sequential chain:

```
Stage 1 (extract): "Extract all dates, names, and monetary amounts from the contract above. Respond in JSON format."
Stage 2 (analyze, receives stage 1): "Given the extracted data above, identify any clauses where the effective date is more than 90 days from the signing date."
Stage 3 (summarize, receives stage 2): "Summarize the flagged clauses in plain language for a non-legal audience."
```

Verification step that stops the model from falling back on training data:

```jinja
First, check if the document above contains information about {{ topic }}.
If it does, answer the following question based on that information:
{{ question }}
If the document does not contain relevant information, state that clearly
instead of answering from general knowledge.
```

Parallel decomposition with an aggregation step:

```jinja
{% for section in document_sections %}
Prompt {{ loop.index }}: "Summarize the following section in 2-3 sentences: {{ section }}"
{% endfor %}

Aggregation: "Given the section summaries above, write a unified executive summary in one paragraph."
```

## Reasoning task

Keep it short and rely on `thinking_level`.

```jinja
{{ question }}

Provide your analysis and final answer.
```

When the answer must include visible reasoning:

```jinja
{{ question }}

Show your reasoning step by step, then provide your final answer.
```
