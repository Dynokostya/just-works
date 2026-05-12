---
name: sprint-estimation
description: Apply when creating a ticket that needs story points, when asked to estimate a task, or when a ticket description is pasted without other clear intent. Provides a calibration framework for assigning accurate Fibonacci story points (1–13) based on work volume, complexity, uncertainty, and risk. Triggers context gathering (code exploration, clarifying questions) before committing to a point value. Pairs with ticket-writing for body content and clickup-tickets for field discipline. Project conventions always override these defaults.
---

# Sprint Estimation

This skill calibrates how you assign story points. Story points measure relative effort — a composite of work volume, complexity, uncertainty, and risk. Use the Opti Scale below as the reference for all estimations unless the user specifies a different scale.

## Rules

- **Gather context before estimating.** Read the ticket fully. If the task involves code, explore the relevant files, dependencies, and integration points. If requirements are vague, ask clarifying questions. Assign points only after you understand what the work actually entails.
- **Estimate for the team, not a person.** Points reflect average team capability. Ignore who will pick it up.
- **Use the Fibonacci scale only: 1, 2, 3, 5, 8, 13.** No intermediate values. If torn between two, pick the higher one — uncertainty rounds up.
- **Recommend splitting above 8.** Tickets above 8 points carry high uncertainty. Propose concrete sub-tickets. Require splitting above 13 — do not assign 13+ without a decomposition proposal.
- **Flag missing information as uncertainty.** When the ticket lacks acceptance criteria, scope boundaries, technical context, or dependency info, state what's missing and note that the estimate assumes worst-case for those gaps.
- **Triangulate every estimate.** Compare against at least one lower and one higher reference from the scale table. If neither comparison confirms the estimate, re-evaluate.
- **Include the estimate in the ticket output.** When creating or rewriting a ticket, include the story point value. When asked only to estimate, output the value with a one-line rationale per factor.
- **Adapt to the user's scale if specified.** If the user says "we use t-shirt sizing" or "our scale is 1,2,4,8,16", map the same factors to their scale. Ask for reference stories if calibration is unclear.

## Opti Scale

| Points | What it means | FE example | BE example | DevOps example |
|--------|--------------|------------|------------|----------------|
| **1** | Trivial change — one file, no logic, no risk | Change button color, add icon | Update single endpoint response format, no logic change | Change VM instance type in Terraform |
| **2** | Simple contained piece — few files, clear path, minimal branching | Tooltip on hover, new form field with validation, simple 1-state component | Single API endpoint for existing service, simple DB script, entity generation | New env variable applied to single resource |
| **3** | Small module — one component/service method, some business logic | Form with validation rules, one UI screen without functionality | CRUD endpoint with a piece of business logic | Basic load balancer with minimal rules |
| **5** | Complex component or integration — multiple concerns, ready-made dependencies | Responsive nav with dropdown menus | Microservice with messaging integration, CRUD, ORM | CI/CD pipeline with env segregation |
| **8** | Big feature — non-trivial logic, cross-cutting concerns, third-party integration | User profile page: editable fields, validation, submission | Microservice with complex data flows or third-party integrations | Complex multi-resource infrastructure |
| **13** | Large or highly uncertain — consider splitting first | Multi-page wizard with cross-step state | Distributed workflow across services with eventual consistency | Full environment from scratch (networking, security, monitoring) |

## Factor evaluation

Assess each factor, then synthesize into a single point value.

| Factor | Signals that push estimate up |
|--------|-------------------------------|
| **Work volume** | Many files, endpoints, screens, DB tables, migrations |
| **Complexity** | Algorithmic difficulty, multiple integrations, intricate business rules, state machines |
| **Uncertainty** | Unfamiliar tech, unclear requirements, "TBD" in spec, legacy code with no tests, missing documentation |
| **Risk** | Data loss potential, security surface, production impact, no rollback path, shared infrastructure |

When factors conflict (low work volume but high uncertainty), the highest factor wins — you cannot deliver fast if you don't know what to build.

## Context gathering checklist

Before assigning points, verify you have answers to:

1. What code/systems does this touch? (explored, not guessed)
2. Are there existing patterns to follow or is this net-new?
3. Are dependencies documented and available?
4. Are acceptance criteria testable and unambiguous?
5. Is there a rollback path if this fails?

If any answer is "unknown", that's uncertainty — factor it in or ask the user.

## Output

**When estimating only** (user asks "how many points?" or similar):

```
**[X] points** — [one-line summary of primary driver]

Factors: volume [L/M/H], complexity [L/M/H], uncertainty [L/M/H], risk [L/M/H]
[Optional: "Missing: [X]. With clarification, could be [lower value]."]
[Optional: "Split recommendation: [sub-tickets]"]
```

**When creating a ticket** (used alongside ticket-writing):

Include `**Story points:** X` as a field in the ticket. No separate estimation block needed — the work is internalized.

## ClickUp integration

When a ClickUp task ID is provided:

1. Fetch the task via MCP to get full description, custom fields, subtasks, dependencies.
2. Apply the estimation framework to the fetched content.
3. Write back only when the user explicitly asks ("save it", "update the task", "write the estimate"). Check for a `Story Points` or `Estimate` custom field on the list. Add reasoning as a task comment if writing back.

## Anti-patterns to detect in tickets

Flag these when they affect estimability:

| Pattern | Impact on estimation |
|---------|---------------------|
| Bundled scope ("X and Y and Z") | Cannot estimate as one unit — split first |
| Solution prescribed in story | Hides complexity behind implementation assumption |
| Vague acceptance criteria | Unbounded uncertainty — ask before estimating |
| "Simple" / "just" in description | Minimization bias — estimate based on actual scope |
| Multiple user roles in one story | Different flows = different effort — split per role |
| Unlinked dependencies | Hidden blockers inflate actual effort |
