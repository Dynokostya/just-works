---
name: clickup-tickets
description: Apply when creating, updating, or rewriting tasks in ClickUp. Covers ClickUp-specific field discipline (due dates, priority, assignees, tags, dependencies, linked tasks, subtasks, custom fields), MCP tool discovery, space introspection, and asking-over-defaulting. Pairs with ticket-writing for body content. Project conventions always override these defaults.
---

# ClickUp Tickets

Apply alongside `ticket-writing` — that skill handles body content and title form; this one handles ClickUp's native structure. When uncertain, read 3–5 recent tasks from the target list to infer local conventions before assuming.

## Never rules

- **Never put a structured attribute in the description when a native field exists.** Due dates → `due_date`, start dates → `start_date`, owners → `assignees`, priority → `priority`, blocked-by → dependency, relates-to → linked task, parent/epic → `parent`, effort → `time_estimate`. A date in prose is dead data; the same date in `due_date` drives reminders, Gantt, and filters.
- **Never auto-fill values the user didn't specify.** Priority, due date, assignees, tags, sprint membership — if the user didn't say, ask. The only exception is when the user explicitly grants discretion ("use your judgment", "go ahead", "you decide").
- **Never create a task without at least one assignee** unless the user explicitly says "no assignee yet". A task with no owner drifts.
- **Never set a tag that doesn't already exist in the Space.** ClickUp tags must preexist; creating with an unknown tag fails or silently drops it. Discover the Space's tags first.
- **Never use `description` when the source contains Markdown.** Use `markdown_content` — it takes precedence over `description` when both are sent.
- **Never overwrite an existing task's description on update.** Append with a timestamp marker (e.g., `--- update 2026-04-20 ---`). Overwriting loses context.
- **Never confuse subtask, dependency, and linked task.** Subtask = structural (parent/child). Dependency = temporal (A must finish before B). Linked task = reference-only. Pick the one that matches the relationship.
- **Never use a Text custom field when a typed field exists.** URL, Date, Email, Dropdown, Number — each has a typed variant that preserves sort, filter, and automation.
- **Never set `priority` to `normal` as a default.** In ClickUp, unset priority means "not yet triaged". Setting `normal` without a triage decision pollutes the signal.
- **Never guess IDs.** Task IDs, list IDs, user IDs, custom field IDs all require discovery or explicit input. Asking is cheaper than creating in the wrong place.

## Vocabulary

- **Task** — ClickUp's unit of work. Fields + description + relationships.
- **List / Folder / Space / Workspace** — hierarchy: Workspace > Space > Folder > List > Task.
- **Status** — per-List workflow state. Lists define their own (`backlog`, `in progress`, `done`, etc.). Not portable across lists.
- **Priority** — a 4-level triage signal: `urgent`, `high`, `normal`, `low`, plus null (untriaged). API-level integers: `1`, `2`, `3`, `4`.
- **Tag** — space-scoped label. Must preexist before assignment.
- **Custom field** — list/folder/space/workspace-scoped typed field. Discovered, not assumed.
- **Dependency** — temporal relationship between tasks. `waiting on` (blocked-by) / `blocks`.
- **Linked task** — reference-only association. "Relates to", no scheduling effect.
- **Subtask** — child task under a parent. Structural decomposition.

## MCP tool discovery

Before acting, enumerate the ClickUp MCP tools available to you. Different MCP servers name them differently — match by capability, not by hardcoded name.

| Capability | Tool-name pattern |
|------------|-------------------|
| Get list details (resolve name → id) | `*get_list*` |
| Workspace hierarchy (spaces, folders, lists) | `*workspace_hierarchy*`, `*get_spaces*` |
| Discover custom fields on a list | `*custom_fields*`, `*field_definitions*` |
| Find / resolve members by name | `*find_member*`, `*resolve_assignees*`, `*search_members*` |
| Get task details by ID | `*get_task*` |
| Create task | `*create_task*` |
| Update task | `*update_task*` |
| Add / remove tag on task | `*add_tag*` / `*remove_tag*` |
| Add / remove dependency | `*add_dependency*` / `*remove_dependency*` |
| Add / remove linked task | `*add_link*` / `*add_task_link*` |
| Attach file | `*attach*`, `*upload*` |
| Create comment | `*create_task_comment*`, `*add_comment*` |
| Filter / search tasks | `*filter_tasks*`, `*search*` |

If a capability has no matching tool, skip it gracefully and tell the user which feature is unavailable in the current MCP.

## Space introspection

Before creating a task in a list you haven't used this session, discover:

1. **Custom fields** — fetch the list's custom field definitions. Each has `id`, `type`, and (for dropdowns) `options`. Custom fields cannot be set without their id.
2. **Tags** — sample recent tasks in the list to see which tag conventions exist. Tags must preexist.
3. **Statuses** — each list has its own workflow. Don't set a status the list doesn't have.
4. **Members** — resolve assignee names to user IDs via member lookup.
5. **Task types** — some spaces define custom types (`Bug`, `Feature`, `Milestone`). Confirm the type exists before using a non-standard one.

Cost: 2–4 MCP calls per new list. Cache within the session.

## Field set

Canonical ClickUp task fields (Create Task API).

| Field | Type | Notes |
|-------|------|-------|
| `name` | string (required) | Title. Apply `ticket-writing` naming rules. |
| `markdown_content` | string | Body. Prefer over `description` when the source has Markdown. |
| `description` | string | Plain-text body. Use only when source is plain. |
| `assignees` | string[] | User IDs. Resolve names via member lookup first. |
| `tags` | string[] | Must preexist in the Space. |
| `status` | string | Must match the list's configured states. |
| `priority` | `urgent` \| `high` \| `normal` \| `low` \| null | Null = untriaged. Don't default to `normal`. |
| `due_date` | `YYYY-MM-DD` or `YYYY-MM-DD HH:MM` | The MCP handles timezone conversion. |
| `start_date` | same as `due_date` | |
| `time_estimate` | int (ms) | Effort in milliseconds. |
| `parent` | string \| null | Parent task ID → creates subtask relationship. |
| `custom_fields` | `[{id, value}]` | Requires discovery first. |
| `custom_item_id` | number | Custom task type (`0` = standard). |
| `task_type` | string | Alternative to `custom_item_id` — by name. |
| `check_required_custom_fields` | bool | Fail if required fields missing. Recommended `true`. |
| `notify_all` | bool | Notify watchers on create. Default `false` for bot-authored tasks. |

Dependencies (`blocks` / `waiting on`) are NOT set at create time — use the add-dependency call after the task exists.

## Field-vs-description mapping

| Attribute | Goes in | Not in |
|-----------|---------|--------|
| Due date | `due_date` | Description prose ("Due: 25 Apr") |
| Start date | `start_date` | Description |
| Priority | `priority` | Description ("Priority: High") |
| Owner / assignee | `assignees` | Description ("Assigned to: Kostia") |
| Blocks / blocked-by | Dependency relationship | Description ("Blocked by: TASK-123") |
| Relates to | Linked task | Description ("Related to: TASK-123") |
| Parent / epic | `parent` (subtask) | Description ("Parent: EPIC-5") |
| Sprint membership | Custom field or tag (discover the Space's convention) | Description |
| Sprint points | Native `points` if the Space uses it, else a discovered tag pattern | Description |
| Effort estimate | `time_estimate` | Description |
| Attachment | File upload call | URL pasted into prose |
| Category / type | Custom task type or dropdown custom field | Description or tag |

Rule: if it's searchable, filterable, sortable, or automatable, it belongs in a field. Description is for narrative only.

## Dependency vs linked task vs subtask

Three distinct relationships. Teams confuse them.

- **Dependency** — temporal. A waits on B means B must finish before A can start (or close). Triggers auto-reschedule in ClickUp. Use when work genuinely cannot proceed until the other does.
- **Linked task** — reference. "Relates to" without blocking. Use for context cross-refs — e.g., a design task linked to a spec. No scheduling effect.
- **Subtask** — structural. Parent/child hierarchy. Use when decomposing a larger work item into named pieces, each with its own assignee and status. Don't set an explicit blocked-by between a subtask and its parent; the hierarchy implies it.

When the user says "X relates to Y" — clarify: temporal (dependency), referential (linked task), or hierarchical (subtask)? Don't guess.

## Priority semantics

| Value | Meaning |
|-------|---------|
| `urgent` | Fix immediately, before other work. |
| `high` | Fix in the current sprint. |
| `normal` | Fix in the next sprint or two. |
| `low` | Fix when convenient. |
| null | Not yet triaged. |

Leave null when the user hasn't signalled urgency. "Normal" is not a default — it's a triage verdict meaning "fix next-ish". Ask clarifies intent; defaulting obscures it.

## Tags as metadata

When the Space lacks a native field for a concept (sprint membership, rollout state, story points without the native `points` field), the team may encode it in tags. Examples you might discover: `sp1`, `sp2`, `sp3`; `sprint:2026-04-06_2026-04-17`; `on-stage`, `on-prod`; `bug`, `feature`.

Protocol:

1. Discover the Space's existing tags first (sample recent tasks or call a tag-listing tool if available).
2. If a matching convention exists, reuse it exactly — match the pattern, don't invent a variant.
3. If no convention exists for a concept the user mentioned, ask: "I don't see a tag for sprint points in this Space. Add one, use a custom field, or skip?"

## Orchestration sequence (create flow)

1. **Resolve list.** Convert list name → id via get-list if needed. Require the user to name the list; never guess.
2. **Introspect** (once per list per session): custom fields, tags, statuses, members, task types.
3. **Resolve assignees.** Convert names → user IDs via member lookup.
4. **Compose body** per `ticket-writing` — title, sections, formatting.
5. **Collect missing values by asking.** For every unspecified attribute — due date, priority, tags, parent, status — ask the user. Bundle related questions. Don't default. Skip this step only when the user grants discretion.
6. **Create task** with a single call: `name`, `markdown_content`, `assignees`, `tags`, `priority`, `due_date`, `status`, `parent`, `custom_fields`, `check_required_custom_fields: true`, `notify_all: false`.
7. **Attach relationships** separately: add-dependency for blocks/blocked-by, add-link for relates-to, attach-file for attachments.
8. **Return the task URL** as `https://app.clickup.com/t/<task_id>`. Confirm the fields back to the user.

## Update-vs-create

- **Update** when the user says "update", "edit", "append", "fix this task", or provides a task URL / ID.
- **Create** when the user says "create", "add", "new ticket", "file a bug".
- **Description updates**: append with a timestamp marker. Don't overwrite unless the user says "replace".
- **Field updates** (priority, assignee, due date, status): safe to overwrite — they're single-valued.

## Anti-patterns

- **Description-stuffing** — "Due: Apr 25. Blocked by TASK-123. Assigned to Kostia." Every attribute belongs in its field.
- **Parent task with many assignees** — a parent assigned to five people has no real owner. Assign the parent to one lead; give subtasks individual owners.
- **Subtask-as-dependency** — subtasks imply "part of", not "waits on". If B can't start until A ships, they're peer tickets with a dependency, not parent/child.
- **Dependency-as-linked-task** — "Relates to" when you mean "blocked by" buries the dependency. Pick the specific relationship.
- **Default `normal` priority** — leaves untriaged signal indistinguishable from intentionally-normal. Leave null until triage.
- **`description` when Markdown is available** — fall back to plain only when the source is plain.
- **Overwriting descriptions on update** — history matters. Append with timestamps.
- **Typed data in Text custom fields** — URL, Date, Email, Dropdown, Number all have typed variants that preserve filterability.
- **Inventing tags** — always reuse existing ones unless the user explicitly asks to create a new convention.
- **Guessing the list** — always ask. Creating in the wrong list is a slow revert.

## When no MCP is available

If the environment has no ClickUp MCP, produce the ticket text (per `ticket-writing`) with a structured field summary the user can paste manually:

```
**List:** <name or id>
**Assignees:** <names>
**Priority:** <level or null>
**Due date:** <YYYY-MM-DD or null>
**Start date:** <YYYY-MM-DD or null>
**Tags:** <comma-separated>
**Parent:** <id or null>
**Dependencies:** <blocked-by ids>
**Linked tasks:** <ids>
---
<body from ticket-writing>
```

Surface every field so nothing gets lost. Don't silently skip.
