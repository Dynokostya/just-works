# Anti-patterns

Soft smells that need contextual judgment (distinct from the unconditional Never rules in SKILL.md).

- **Overcrowded diagrams without grouping** -- more than ~15 ungrouped elements makes the diagram unreadable. Split or group.
- **Technical jargon in business-level diagrams** -- `POST /api/v2/orders` belongs in API docs, not in a diagram for stakeholders. Use "Creates order" instead.
- **Mixing styling approaches** -- combining inline colors (`#Red`), `skinparam`, and `<style>` blocks in one file creates conflicting rules and unpredictable rendering. Pick one approach per file; prefer `<style>`.
- **Deep nesting beyond 3 levels in component diagrams** -- deeply nested `package` blocks produce tiny, illegible boxes. Flatten the hierarchy or split into separate diagrams.
- **Missing titles and legends** -- a diagram without a title is useless in a document with multiple diagrams. Add `title` always, `legend` when relationships need explanation.
- **Using class diagrams when a simpler type suffices** -- showing `Order -> PaymentService` as a class relationship when a component or sequence diagram communicates the same thing more clearly. Choose the simplest diagram type that conveys the information.
- **Duplicating diagram content instead of using `!include`** -- copy-pasted participant declarations and styles across multiple files drift out of sync. Extract shared definitions into include files.
- **Forcing layout with direction keywords everywhere** -- sprinkling `-up->`, `-left->`, `-right->` on every arrow fights the layout engine and usually produces worse results. Use them sparingly, only when auto-layout genuinely fails.
- **Bare `autonumber`** -- plain sequential integers (1, 2, 3...) on every arrow add clutter without meaning. Use formatted autonumber or omit it.
- **Undeclared participants** -- letting PlantUML infer participants from usage produces unstable ordering that changes when you add a new message.
