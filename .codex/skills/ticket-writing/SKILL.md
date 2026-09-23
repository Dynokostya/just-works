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
- **Never block work on a dependency without linking the blocker.** If ticket A can't start until B ships, use a blocked-by link so the board and dependency tooling can surface it.
- **Never create a ticket without checking that a similar one isn't already open.** Duplicates fragment discussion, split assignment, and waste triage. Search the target tracker by title keywords and by likely tags first. Surface near-matches to the requester and let them decide: dedupe, link as relates-to, or proceed.
- **Never include a section, field, or value the user didn't request or you haven't confirmed.** Required values for the type get asked, not guessed (Bug's Severity in the body; Spike's timebox and Bug's priority in native fields). Optional sections stay omitted unless the user supplies the content (Open questions, Attachments, Links). Inventing values to match a template pollutes the ticket with content the user must re-check, and erodes trust that the body reflects their intent.

## Vocabulary

- **PBI** — Product Backlog Item. A shippable user-facing feature, improvement, or experiment. Uses **Acceptance criteria**.
- **Bug** — defect in existing behavior. Uses **Steps to reproduce / Actual / Expected / Environment**.
- **Spike** — timeboxed technical investigation. Output is a decision, not shipped code. Uses **Goal / Method / Expected output**.
- **Discovery** — timeboxed product investigation. Output is a decision, not shipped code. Uses **Opportunity / Hypothesis / Open questions / Expected output**.
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
- **Header punctuation** — end the header with `:` when it introduces a list, a single-value line below, or a definition (`Steps to reproduce:`, `Severity:`, `Acceptance criteria:`). Omit the colon when the header opens a prose paragraph (`Summary`, `Problem`, `Proposed change`).
- **Single-value sections** — for one-line values like `Severity`, put the header on its own line and the value on the next line. Don't inline the value next to the header.
- **Native fields stay out of the body** — time estimate or timebox, due date or deadline, story points or complexity, and priority go in the tracker's native fields. Duplicating them in the body lets the two copies drift out of sync. Severity stays in the body because most trackers (ClickUp, Linear) have no native severity field.
- **No horizontal rules** (`---`). Sections separate themselves through bold headers.
- **No em dashes as separators** — never to join a label or value to its explanation in a field list (`Major — no workaround`), never between sections. Use a period, comma, or colon instead. Em dashes inside prose sentences are fine.
- **No blank line between a header and its first line of content.** Each section opens immediately.
- **Numbered and bulleted lists** — no blank lines between items. Each item ends with a period.
- **Inline code with backticks** — wrap technical identifiers in backticks: field names (`due_date`, `postId`), enum values (`high`, `urgent`), env var names (`OPENROUTER_API_KEY`), file paths (`src/api/auth.ts`), id expressions (`postId = 69c2c683039c4ad6d45387bcb7ede`). Keep plain URLs and product-path references (`Settings → Account → Transactions`) unformatted.
- **Capitalize proper nouns** — environment names (`Prod`, `Stage`, `Dev`), browser names (`Chrome`, `Firefox`, `Safari`), OS names (`Windows`, `macOS`), service and team names (`Platform`, `AI backend`, `Ops`), vendor names (`AWS`, `Slack`), and standard acronyms (`API`, `URL`, `HTTP`).
- **Length** — as short as the problem allows. A long body usually means the ticket should split or link a doc.
- **Code, logs, error messages** — fenced code blocks for verbatim multi-line content; inline backticks for short identifiers. Don't paraphrase error messages; quote them exactly.

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
What will be different after this ships. Keep it behavioral — what the user will see or do. Avoid implementation nouns (framework names, design patterns) unless the constraint is the point. When a concrete adjacent risk exists, add at most one inline constraint sentence ("Do not change search ranking or pagination."), not a separate section. Lists of non-goals belong in PRDs and pitches, not tickets.

**Acceptance criteria**
Observable, independently testable. Plain bullets by default. Use Given-When-Then only when the flow has multiple conditions, roles, or integration points — otherwise it adds overhead without clarifying anything. Write as many as are useful and no more (Mike Cohn's heuristic). A long list is a signal to consider splitting, not a rule.

**Links** (optional)
Parent epic, blocked-by, relates-to — each as a specific link type. See Linking.

### Acceptance criteria — bullet vs Gherkin

Default to bullets. Switch to Given-When-Then only when:

- The flow has multiple preconditions that affect the outcome
- Multiple roles interact in the same scenario
- The criteria will feed an automated test suite directly

```
Plain bullets (default):
- A Download CSV button appears in Settings → Account → Transactions for signed-in users.
- Clicking the button downloads a CSV with header row: date, amount, merchant, category, status.
- The CSV covers the currently selected date range.
- An empty range produces a CSV with header row only.
- Download starts within 2 seconds for ranges up to 10,000 rows.

Given-When-Then (only when logic branches):
- Given a signed-in user on the Transactions page with a date range selected
  When the user clicks Download CSV and the range contains fewer than 10,000 rows
  Then a CSV downloads within 2 seconds with columns: date, amount, merchant, category, status.
- Given a signed-in user with a date range selected
  When the range contains more than 10,000 rows
  Then the user is prompted to narrow the range before download proceeds.
```

Keep Gherkin scenarios independent — no shared state between scenarios. If two scenarios share setup, extract it into a Background block or fold them into one scenario.

## Bug

Sections:

**Summary**
One line: what's wrong, where, for whom. "Login fails on Chrome 125 / Windows 11 with valid credentials on staging."

**Steps to reproduce**
Numbered, specific, complete. A dev with no prior context should follow them verbatim and reproduce.

```
1. Open https://app.example.com/login in Chrome 125 on Windows 11.
2. Enter a valid email and password.
3. Click Sign in.
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

**Severity** — technical impact of the defect: Blocker (system unusable, no workaround) / Critical (core flow fails, no acceptable workaround) / Major (significant flow fails, workaround exists) / Minor (annoying, non-blocking) / Trivial (cosmetic, no functional impact).

Priority is business urgency to fix: Urgent (before other work) / High (current sprint) / Medium (next sprint or two) / Low (when convenient). Set it in the tracker's native priority field, not the body.

Severity and priority are independent. A homepage typo during a product launch is Trivial severity + Urgent priority. A crash in a dev-only admin tool is Blocker severity + Low priority.

**Attachments** (when relevant)
Screenshot, screen recording, log excerpt, HAR file. Redact PII before attaching.

**Links** (optional)
Related tickets, the regression-introducing PR, the parent epic.

## Spike (technical)

A timeboxed investigation that produces a decision, not shippable code. Two rules keep spikes useful: **one specific question** and **a strict timebox**, set in the tracker's estimate or due-date field. When the timebox runs out, report findings and decide whether to re-spike — don't extend silently.

Sections:

**Goal**
One concrete question. "Can we replace library X with library Y without losing feature Z?" — not "Research library Y."

**Method**
How the investigation will run — prototype, benchmark, read source, interview SMEs, review docs. Concrete enough that a reader knows what the work will look like.

**Expected output**
What the spike will produce — a recommendation doc, a small proof-of-concept, a design sketch. Not working production code.

**Open questions** (optional)
Things known to be unknown going in. Helps scope the investigation.

## Discovery (product)

The product-research variant of a spike. Used when the question is about what to build and why, not how to build it. Timeboxed like a spike; the timebox goes in the tracker's estimate or due-date field.

Sections:

**Opportunity**
What the team has noticed — a user pattern, a competitor signal, a support trend. Ground it in evidence.

**Hypothesis**
A falsifiable claim: "If we do X, then Y will change by Z." Not "we think users want this."

**Open questions**
Explicit unknowns that block a go/no-go decision. Numbered for reference.

**Expected output**
The decision artifact the discovery will produce — a go/no-go recommendation, a research summary. Not a spec or shipped code.

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
- At least one acceptance criterion (PBI) or one expected behavior (Bug)

Skip formal DoR if refinement conversations already cover these items. The checklist is a backstop, not a ritual.

## Workflow

**When a ticket comes from a meeting, thread, or report** — put the substance of why it exists (the decision, the report, the signal) in Problem, Summary, Goal, or Opportunity, and attach the origin (Slack thread, support ticket, meeting) through the tracker's native link or integration, not a body section. Trackers capture origin natively (Linear customer requests, GitHub backlinks, Jira issue links), and coding agents read only title, body, and comments, so a bare permalink they can't open carries no context.

**When a required value is unknown at creation** — ask before creating, or omit it and add a follow-up comment the same day. Don't insert `[TBD]` or `[paste link]`; those become permanent. If the user can't supply a value the type demands (e.g., a Spike with no timebox), the type is probably wrong — propose a different type rather than fabricating a placeholder.

**Before creating, search for existing tickets** — query the target tracker by title keywords and by likely tags. If candidates exist, surface them to the requester. They decide: close as duplicate, link as relates-to or blocks, or proceed. Skip this step only when the user has already confirmed it's a new ticket.

**When rewriting an existing ticket** — preserve existing tracker links. Rewrite the title to imperative mood. Restructure into the correct sections for the ticket type. Enforce the Never rules. If the ticket describes two distinct changes, split them rather than letting them ride together.

**Before creating or saving**, verify:

- Title passes "If applied, this ticket will ___"
- Right section names for the type (Acceptance criteria on PBI; Steps / Actual / Expected on Bug; Goal / Method on Spike; Opportunity / Hypothesis on Discovery)
- No placeholders
- No em-dash separators, no horizontal rules
- Body as short as the problem allows; a long one is split or links a doc
- Duplicate search done; no near-matches, or near-matches reviewed with the requester
- Every section and value came from the user or was confirmed — nothing added to fit the template

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
- **Padding or piling up acceptance criteria** — write as many as are useful and no more. A long list is a signal to consider splitting, not a rule.
- **Scope creep in comments** — new requirements added after creation without updating the body. Either update the ticket and note the change, or create a follow-up.
- **Estimates in the title or body** — "Fix login bug (2h)", or a Deadline or Priority section in the body. Estimates, deadlines, and priority belong in native fields.
- **Placeholders surviving to closure** — `[TBD]`, `[paste link]`. See Workflow.
- **"Relates to" as a catch-all link** — pick the most specific link type, or none.
- **Stories treated as full specification documents** — three pages of prose for a two-day change. Tickets are conversation starters; use docs for deep specs and link them.
- **Filing without a duplicate search** — filing a near-duplicate fragments the discussion, splits the work, and signals weak hygiene. Search first; surface candidates to the requester before creating.
- **Inventing values to look complete** — filling Severity, Priority, Timebox, or any other field with a guess so the ticket "feels finished". The user can't tell guess from confirmed and ends up re-checking everything. Ask, or omit.

## Rewrite examples

One full example inline; `references/rewrite-examples.md` has the PBI and Spike before/after pairs.

### Bug — before

Title: **Login bug**

Body:

> Login doesn't work. Please fix ASAP.

### Bug — after

Title: **Fix silent login failure on Chrome 125 / Windows 11**

Body:

**Summary**
Users on Chrome 125 / Windows 11 see no error when login credentials are rejected. The page reloads with the form cleared.

**Steps to reproduce:**
1. Open https://app.example.com/login in Chrome 125 on Windows 11.
2. Enter a valid email and an incorrect password.
3. Click Sign in.

**Actual result**
Page reloads. Form fields cleared. No error banner. Console: `POST /api/auth 401 — empty body`.

**Expected result**
An error banner appears above the form: "Invalid email or password." Form fields remain populated so the user can correct them.

**Environment**
Chrome 125.0.6422.76, Windows 11 23H2, Stage, web client v2.18.0. Reproduced on two accounts.

**Severity:**
Major. Failed logins give no feedback on the affected platform; the workaround is retrying credentials or the password-reset flow.

**Attachments**
`login-failure.mp4`, a screen recording of the failure.
