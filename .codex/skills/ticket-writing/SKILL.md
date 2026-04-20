---
name: ticket-writing
description: Apply when writing, rewriting, or reviewing issue-tracker tickets (Jira, Linear, ClickUp, GitHub Issues, Asana). Covers titles, sections per type (PBI / Bug / Spike / Discovery), acceptance-criteria formats, bug reproduction fields, INVEST, linking, and common anti-patterns. Tool-agnostic. Project conventions always override these defaults.
---

# Ticket Writing

Match the project's existing conventions. When uncertain, read 3–5 recent tickets to infer local style — title form, section names, typical length, and link usage. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent ambiguity, lost provenance, and wasted triage regardless of project style.

- **Never ship a ticket whose title doesn't identify what will change.** Titles like "bug" or "update" force every reader to open the ticket to find out. Titles are scanned in lists and boards far more often than they're clicked.
- **Never omit Steps to reproduce on a Bug.** Without numbered, specific steps, the dev re-derives the repro path from scratch — the single biggest cause of "cannot reproduce" churn.
- **Never omit Expected and Actual results on a Bug.** "It's broken" is not a specification. Expected is the target to fix toward; Actual is what was observed.
- **Never write acceptance criteria using subjective terms** — "fast", "intuitive", "user-friendly", "good UX". They're untestable. Quantify ("search returns under 500 ms at p95") or describe observable behavior.
- **Never prescribe the solution inside the story body.** "As a user, I want a React dropdown with debounced autocomplete..." locks the team into an implementation. Describe what the user needs; leave how to the implementer.
- **Never mix multiple user roles in one story.** "As a user and admin, I want..." is two stories. Split them — different permissions, different flows, different tests.
- **Never leave placeholders in a published ticket** — `[TBD]`, `[TODO]`, `[paste link]`. Get the value before creating, ask, or add a follow-up comment after creation. Placeholders that survive to closure signal a weak process.
- **Never title a ticket with a trailing period.** Wastes characters in scan-width views and doesn't match imperative-mood form.
- **Never publish a ticket without a Source link** when the context came from a conversation, doc, or meeting. Tickets lose their origin within weeks.
- **Never block work on a dependency without linking the blocker.** If ticket A can't start until B ships, use a blocked-by link so the board and dependency tooling can surface it.

## Vocabulary

- **KISS** — shortest wording that still lands the point.
- **MECE** — mutually exclusive, collectively exhaustive. Sections cover the problem without overlap and without gaps.
- **Pareto** — 80% of value in 20% of words. Cut sentences that don't move the reader toward a decision.
- **PBI** — Product Backlog Item. A shippable user-facing feature, improvement, or experiment. Uses **Acceptance criteria**.
- **Bug** — defect in existing behavior. Uses **Steps to reproduce / Actual / Expected / Environment**.
- **Spike** — timeboxed technical investigation. Output is a decision, not shipped code. Uses **Goal / Method / Evidence / Conclusions**.
- **Discovery** — timeboxed product investigation. Output is a decision, not shipped code. Uses **Opportunity / Hypothesis / Open questions**.
- **INVEST** — Independent, Negotiable, Valuable, Estimable, Small, Testable. Sanity check for PBIs.
- **DoR** (Definition of Ready) — team-owned checklist saying a ticket can be picked up. Optional, lightweight.
- **DoD** (Definition of Done) — team-owned checklist applied to every ticket at completion. Different from acceptance criteria — AC is per-ticket, DoD is team-global.

## Naming

Imperative mood, sentence case, no trailing period. Test the title by completing: **"If applied, this ticket will ___."** If the result reads grammatically, the mood is right.

```
Good: Hide regular photo upsell buttons until first view completes
Good: Fix off-by-one error in pagination count
Good: Investigate three PDF libraries for performance and licensing
Good: Add CSV export to account transactions page

Bad:  Photo upsell bug                 (vague; no verb; no target)
Bad:  Fixed the thing                  (past tense; no specific target)
Bad:  Update files                     (vague verb; no target)
Bad:  Fix: dashboard crash.            (trailing period; redundant prefix)
Bad:  As a user I want to export...    (user-story format belongs in the body, not the title)
```

Aim for under ~70 characters when possible — that's the width where titles stay scannable in list and board views. Longer titles are fine when the extra words add clarity. Don't pad to hit the range, and don't truncate a clear title to squeeze under it.

## Body formatting

- **Headers** — one level of boldness: Markdown bold (`**Header**`) or H2 (`## Header`), whichever the tool renders. No H1 inside the body. Pick one style per ticket and keep it uniform.
- **No horizontal rules** (`---`). Sections separate themselves through bold headers.
- **No em dashes as separators.** Use commas, periods, or semicolons. Em dashes inside prose are fine.
- **No blank line between a header and its first line of content.** Each section opens immediately.
- **Length** — 200–300 words is a reasonable soft target for PBIs and Bugs. Spikes and Discovery tickets may run longer when framing demands it. Shorter is fine when the problem is genuinely simple. Length is an artifact of clarity, not a goal.
- **Code, logs, error messages** — fenced code blocks for verbatim content. Don't paraphrase error messages; quote them exactly.

## PBI (Product Backlog Item)

A shippable user-facing change. Before writing, check it against INVEST:

- **Independent** — the ticket can ship without waiting on unrelated tickets. If it can't, link the blocker.
- **Negotiable** — the body captures the essence, not a locked contract. Implementation details are for the conversation, not the ticket.
- **Valuable** — value is to the user or customer. "So the team can build X faster" is not customer value.
- **Estimable** — enough is understood for a team member to size it within an order of magnitude.
- **Small** — fits within a sprint. If it doesn't, split it.
- **Testable** — behavior can be observed and verified.

Sections:

**Problem**
One paragraph. Who feels the pain, what they're trying to do, what happens today. Ground it in evidence (interview, support ticket, metric), not opinion.

**Proposed change**
What will be different after this ships. Keep it behavioral — what the user will see or do. Avoid implementation nouns (framework names, design patterns) unless the constraint is the point.

**Acceptance criteria**
Observable, independently testable. Plain bullets by default. Use Given-When-Then only when the flow has multiple conditions, roles, or integration points — otherwise it adds overhead without clarifying anything. Cap at 3–5 bullets; more than that usually means the story should split.

**Out of scope** (optional)
Adjacent things this does *not* do. Prevents scope creep and reviewer confusion.

**Links** (optional)
Parent epic, blocked-by, relates-to — each as a specific link type. See Linking.

**Source**
Permalink to the originating conversation, doc, or ticket. Preserves provenance so anyone reading the ticket months later can retrace the decision.

### Acceptance criteria — bullet vs Gherkin

Default to bullets. Switch to Given-When-Then only when:

- The flow has multiple preconditions that affect the outcome
- Multiple roles interact in the same scenario
- The criteria will feed an automated test suite directly

```
Plain bullets (default):
- A Download CSV button appears in Settings → Account → Transactions for signed-in users
- Clicking the button downloads a CSV with header row: date, amount, merchant, category, status
- The CSV covers the currently selected date range
- An empty range produces a CSV with header row only
- Download starts within 2 seconds for ranges up to 10,000 rows

Given-When-Then (only when logic branches):
- Given a signed-in user on the Transactions page with a date range selected
  When the user clicks Download CSV and the range contains fewer than 10,000 rows
  Then a CSV downloads within 2 seconds with columns: date, amount, merchant, category, status
- Given a signed-in user with a date range selected
  When the range contains more than 10,000 rows
  Then the user is prompted to narrow the range before download proceeds
```

Keep Gherkin scenarios independent — no shared state between scenarios. If two scenarios share setup, extract it into a Background block or fold them into one scenario.

## Bug

Sections:

**Summary**
One line: what's wrong, where, for whom. "Login fails on Chrome 125 / Windows 11 with valid credentials on staging."

**Steps to reproduce**
Numbered, specific, complete. A dev with no prior context should follow them verbatim and reproduce.

```
1. Open https://app.example.com/login in Chrome 125 on Windows 11
2. Enter a valid email and password
3. Click Sign in
```

**Actual result**
What happens. Specific and observable: "Page reloads with the form cleared. No error banner appears. Console: `POST /api/auth 401 — empty body`."

**Expected result**
What should happen: "Dashboard loads at /home with the user's display name in the header."

**Environment**
Enough detail to reproduce:

- OS and version (Windows 11 23H2, macOS 14.4)
- Browser or app and version (Chrome 125.0.6422.76, iOS app 2.18.0)
- Environment (prod / staging / local)
- Account tier or role if relevant
- Feature flags or toggles if relevant

**Severity** — technical impact of the defect:

- **Blocker** — system unusable, no workaround
- **Critical** — a core flow fails, no acceptable workaround
- **Major** — a significant flow fails, but a workaround exists
- **Minor** — annoying but non-blocking defect
- **Trivial** — cosmetic issue with no functional impact

**Priority** — business urgency to fix:

- **Urgent** — fix immediately, before other work
- **High** — fix in the current sprint
- **Medium** — fix in the next sprint or two
- **Low** — fix when convenient

Severity and priority are independent. A homepage typo during a product launch is Trivial severity + Urgent priority. A crash in a dev-only admin tool is Blocker severity + Low priority.

**Attachments** (when relevant)
Screenshot, screen recording, log excerpt, HAR file. Redact PII before attaching.

**Links** (optional)
Related tickets, the regression-introducing PR, the parent epic.

**Source**
How this bug was found — support ticket, user report, internal discovery.

## Spike (technical)

A timeboxed investigation that produces a decision, not shippable code. Two rules keep spikes useful: **one specific question** and **a strict timebox**. When the timebox runs out, report findings and decide whether to re-spike — don't extend silently.

Sections:

**Goal**
One concrete question. "Can we replace library X with library Y without losing feature Z?" — not "Research library Y."

**Timebox**
Duration in effort, not calendar. "2 days", "8 hours". State it explicitly so it's visible in the ticket, not only in someone's head.

**Method**
How the investigation will run — prototype, benchmark, read source, interview SMEs, review docs. Concrete enough that a reader knows what the work will look like.

**Expected output**
What the spike will produce — a recommendation doc, a small proof-of-concept, a design sketch. Not working production code.

**Open questions** (optional)
Things known to be unknown going in. Helps scope the investigation.

**Source**
The conversation, decision, or risk that triggered the spike.

## Discovery (product)

The product-research variant of a spike. Used when the question is about what to build and why, not how to build it.

Sections:

**Opportunity**
What the team has noticed — a user pattern, a competitor signal, a support trend. Ground it in evidence.

**Hypothesis**
A falsifiable claim: "If we do X, then Y will change by Z." Not "we think users want this."

**Open questions**
Explicit unknowns that block a go/no-go decision. Numbered for reference.

**Source**
The signal or conversation that triggered the discovery.

## Linking

Pick the most specific link type. Links are labels, not enforced logic — teams must pre-agree on semantics, because the same word can mean different things across boards.

- **Blocks / Is Blocked By** — hard dependency. One must ship before the other can start or finish.
- **Duplicates / Is Duplicated By** — same work already captured elsewhere. Close the duplicate; keep the canonical.
- **Clones / Is Cloned By** — intentional split into parallel copies that will diverge (e.g., the same feature across two platforms).
- **Relates To** — general association without a specific dependency. Use as a last resort when nothing more specific fits.
- **Parent / Sub-task** — hierarchy, not a link type. Epic → Story → Sub-task. Sub-tasks don't need explicit blocked-by links to their parent — the hierarchy implies it.

Common mistake: using "Relates To" for everything. If one ticket actually blocks another, link it as blocked-by so the board and automation can surface the dependency.

## Definition of Ready (optional)

DoR is a lightweight, team-owned agreement. Use it as a conversation starter during refinement, not as a gate to block tickets from entering a sprint. A rigid DoR becomes a weapon against collaboration; teams have abandoned it for that reason.

Minimum DoR worth enforcing:

- Title passes the "If applied…" test
- Problem and proposed change are clear
- INVEST sanity check passed (for PBIs) or Steps / Expected / Actual / Environment present (for Bugs)
- Source link present
- At least one acceptance criterion (PBI) or one expected behavior (Bug)

Skip formal DoR if refinement conversations already cover these items. The checklist is a backstop, not a ritual.

## Workflow

**When a ticket is sourced from a meeting or transcript** — link the transcript or recording permalink in **Source**. Without it, the conversation context is gone within days.

**When a required value is unknown at creation** — ask before creating, or omit it and add a follow-up comment the same day. Don't insert `[TBD]` or `[paste link]`; those become permanent.

**When rewriting an existing ticket** — preserve the original Source link. Rewrite the title to imperative mood. Restructure into the correct sections for the ticket type. Enforce the Never rules. If the ticket describes two distinct changes, split them rather than letting them ride together.

**Before creating or saving**, verify:

- Title passes "If applied, this ticket will ___"
- Right section names for the type (Acceptance criteria on PBI; Steps / Actual / Expected on Bug; Goal / Method on Spike; Opportunity / Hypothesis on Discovery)
- Source URL present and clickable
- No placeholders
- No em-dash separators, no horizontal rules
- Length in range, or the overrun is justified by the framing

## Anti-patterns

- **Technical stories posing as user stories** — "As an API, I want to expose an endpoint..." Systems aren't users. Drop the user-story framing and describe the technical change directly.
- **Stories slicing by technology layer** — "Backend for feature X" plus "Frontend for feature X". Neither is shippable alone. Slice vertically by user-visible value.
- **Stories too large to ship in a sprint** — break them into smaller stories, each independently valuable.
- **Over-specifying the solution** — "Use React Query with a 30-second stale time and a custom retry handler." Unless the constraint is the point, describe behavior and let the implementer choose.
- **Acceptance criteria that can't be tested** — "The UI should feel snappy." Replace with a measurable threshold or an observable behavior.
- **Confusing acceptance criteria with Definition of Done** — AC is per-ticket. DoD is team-global (tests passing, code reviewed, deployed to staging). Don't duplicate DoD items in every ticket's AC.
- **Gherkin for every ticket** — adds overhead on simple changes. Plain bullets by default.
- **Mixing user roles in one story** — "As a user and admin, I want..." Split the story.
- **Product manager as proxy user** — describe the real end user, not the PM's guess of what the user wants.
- **More than 4–5 acceptance criteria** — usually means the story is too big. Consider splitting.
- **Scope creep in comments** — new requirements added after creation without updating the body. Either update the ticket and note the change, or create a follow-up.
- **Estimates in the title** — "Fix login bug (2h)". Estimates belong in the estimate field, not the title.
- **Placeholders surviving to closure** — `[TBD]`, `[paste link]`. See Workflow.
- **"Relates to" as a catch-all link** — pick the most specific link type, or none.
- **Tickets without a Source** — no way to retrace the origin. Conversation context evaporates.
- **Stories treated as full specification documents** — three pages of prose for a two-day change. Tickets are conversation starters; use docs for deep specs and link them.

## Rewrite examples

### Bug — before

Title: **Login bug**

Body:

> Login doesn't work. Please fix ASAP.

### Bug — after

Title: **Fix silent login failure on Chrome 125 / Windows 11**

Body:

**Summary**
Users on Chrome 125 / Windows 11 see no error when login credentials are rejected. The page reloads with the form cleared.

**Steps to reproduce**
1. Open https://app.example.com/login in Chrome 125 on Windows 11
2. Enter a valid email and an incorrect password
3. Click Sign in

**Actual result**
Page reloads. Form fields cleared. No error banner. Console: `POST /api/auth 401 — empty body`.

**Expected result**
An error banner appears above the form: "Invalid email or password." Form fields remain populated so the user can correct them.

**Environment**
Chrome 125.0.6422.76, Windows 11 23H2, staging, web client v2.18.0. Reproduced on two accounts.

**Severity** Major — blocks user feedback for every failed login on the affected platform.
**Priority** High — affects every user on Chrome / Windows hitting an auth failure.

**Attachments**
`login-failure.mp4` — screen recording of the failure.

**Source**
Support ticket #4812 (17 Apr): https://support.example.com/t/4812

### PBI — before

Title: Add that export thing we discussed

### PBI — after

Title: **Export transaction history to CSV from account settings**

Body:

**Problem**
Finance-facing users currently export transactions by copying rows out of the web table — about 15 minutes per account per month. Reported by the ops team and two customer support tickets (see Source).

**Proposed change**
Add a Download CSV button in Settings → Account → Transactions. The file covers the currently selected date range and includes date, amount, merchant, category, and status.

**Acceptance criteria**
- A Download CSV button appears in Settings → Account → Transactions for signed-in users
- Clicking the button downloads a CSV with header row: `date, amount, merchant, category, status`
- The CSV covers the currently selected date range
- An empty range produces a CSV with header row only
- Download starts within 2 seconds for ranges up to 10,000 rows

**Out of scope**
Excel export, email delivery, scheduled exports. These are separate tickets if demand appears.

**Links**
Parent: ACCT-410 — Self-service reporting epic

**Source**
Ops team Slack thread (18 Apr): https://example.slack.com/archives/C01/p1713456789

### Spike — before

Title: Look at PDF libraries

Body:

> We need PDFs. See what's out there.

### Spike — after

Title: **Pick a PDF generation library for invoice exports**

Body:

**Goal**
Recommend one PDF library to generate styled invoice PDFs from our existing HTML templates. Decision criteria: render fidelity vs the current Chrome reference, bundle size, license compatibility (commercial distribution), active maintenance.

**Timebox**
2 days.

**Method**
1. Shortlist three libraries based on current industry usage: Puppeteer (headless Chrome), wkhtmltopdf, and Playwright print-to-PDF.
2. Render the current invoice template through each and diff against the Chrome reference.
3. Record output fidelity, render time on a representative sample of 100 invoices, bundle impact, and license terms.
4. Write a one-page recommendation with the tradeoffs.

**Expected output**
A comparison table, a recommendation with reasoning, and three sample PDFs (one per library) attached to this ticket.

**Open questions**
1. Are we constrained to run this in-process, or can it run as a side-car service?
2. Is the commercial license for wkhtmltopdf a blocker given our distribution model?

**Source**
Engineering sync (14 Apr): https://example.atlassian.net/wiki/spaces/ENG/pages/1234
