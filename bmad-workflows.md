# BMAD Workflows

This guide shows which BMad Method skills to run for a piece of work, from a change that fits one session to a project with several epics. It ends with a one-line [reference](#skill-reference) for every skill in this fork. The fork, Dynokostya/BMAD-METHOD, follows upstream's v7 draft, which is not released yet, and adds a few changes of its own, described under [Fork changes](#fork-changes).

## Install and set up

You need Claude Code and [uv](https://docs.astral.sh/uv/), which runs the Python scripts the skills call.

1. Install every skill of the fork for Claude Code, for all your projects:

   ```sh
   npx skills add "https://github.com/Dynokostya/BMAD-METHOD#feature/claude-code-specific-bmad" -g --agent claude-code --skill '*' -y --copy
   ```

   `-g` installs for your user instead of one project, and `--copy` copies the skill files instead of linking them. The install includes `bmad` and the three module records, `bmod-method`, `bmod-core-tools` and `bmod-toolsmith`. A module record is a metadata skill that setup reads; you never invoke it.
2. In each project, ask the `bmad` skill to run `bmad setup`. It creates the project's `_bmad/` folder and asks the configuration questions.

Later, ask for `bmad status` to check versions without changing anything. Ask for `bmad setup` to update: it runs `npx skills update` when a module has a newer version, refreshes `_bmad/`, offers to delete renamed and removed skills, and ends by offering any migration that applies. Doctor and repair are other names for the same flow.

## Where the work is kept

Skills write their documents under the output folder, which is `_bmad-output/` unless `core.output_folder` is changed in `_bmad/custom/config.toml`. Each document is a folder named `<type>-<slug>/` that holds `<type>-<slug>.md`, for example `prd-checkout/prd-checkout.md`.

An initiative is one body of work, such as a product or a large feature, kept in its own folder `initiative-<slug>/` under the output folder. Skills write into the active initiative, which is recorded as `active_initiative` under `[core]` in `_bmad/custom/config.user.toml`. Ask `bmad` to show, switch, create or clear it. When none is active, some skills hand off to `bmad` to set one, some ask once per session whether the work belongs to one, and the rest write straight into the output folder.

The ticket tree is how `bmad-ticket` plans and tracks the work inside the initiative folder. Each epic has its own `epic-<slug>/` folder, and each initiative or epic has a `tickets.toml`, called its breakdown, that lists its children in build order. An epic's stories are entries in its breakdown, each with an `id`: `1.2` names entry 2 of epic 1. A story gets its own file only when it is refined, reviewed or published to a tracker. Bugs and stories with no epic go in `backlog/` under the output folder. A ticket's status lives in the build's plan file beside it: a build moves it as far as `built`, and only you or an orchestrator mark it `done`. The ticket script is installed at `_bmad/method/scripts/tickets.py`.

A v6 project still has its files in the old planning and implementation folders (the `planning_artifacts` and `implementation_artifacts` settings, which v7 no longer reads), often with `epics.md` and `sprint-status.yaml`. Run `bmad migrate method` to move it onto this layout: it moves the documents into one initiative folder and turns the epics and sprint status into a ticket tree. `bmad` shows the plan and asks before changing anything.

---

## Fast: one build session

For a change that one session can understand, build, review and finish, such as a feature, a story or a bug fix. A typo or a formatting edit needs no skill.

| Step     | Command       | Description                                                                         |
| -------- | ------------- | ----------------------------------------------------------------------------------- |
| 1. Build | `/bmad-build` | Clarifies the intent, plans, implements, reviews, and commits locally. Never pushes. |

`bmad-build` takes free text, a ticket from the tree (`1.2`, its file or its title), a plan to resume, or any file as intent. Given nothing, it builds the next ready ticket of the active initiative. One session is one goal, roughly 500 changed lines not counting tests. Its review uses one lens (`quick`) by default; say `none` or `thorough` (four lenses) in the request to change that. In this fork, `bmad-real-test` runs after the commit.

**Unattended variant:** `/bmad-build-auto` builds one ticket with nobody present. It never asks a question; anything unclear halts it as `blocked`, with the reason written into the plan. It needs subagents and, under version control, a clean working tree on a branch that fits the work. Use `bmad-build` for risky or foundational tickets, or whenever a person should approve the plan.

## Medium: research, then build

For a feature that needs investigation but no planning documents.

| Step           | Required | Command             | Description                                                                                       |
| -------------- | -------- | ------------------- | ------------------------------------------------------------------------------------------------- |
| 1. Research    | optional | `/bmad-deep-recon`  | Research for a decision: market, domain, technical, competitive, user-voice, academic literature. |
| 2. Build       | yes      | `/bmad-build`       | Builds the change in one session.                                                                 |
| 3. Code review | optional | `/bmad-code-review` | Independent reviewers over the diff, with triaged findings. Adds little right after a `thorough` build review. |

## Spec-driven: a spec, one epic of tickets, a build per ticket

For work bigger than one session that you can already explain, or have notes, a transcript, a brief or a PRD for. This is the route the method module's own help recommends in that case. `bmad-spec` condenses the input into a spec, `bmad-ticket` plans the stories as one epic, and each story is built in its own session, with you present or unattended.

| Step                 | Required | Command                                   | Description                                                                                                  |
| -------------------- | -------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| 1. Research or brief | optional | `/bmad-deep-recon`, `/bmad-product-brief` | Ground the idea first when it is thin; `bmad-spec` condenses input and does not coach.                       |
| 2. **Spec**          | yes      | `/bmad-spec`                              | Writes `spec-<slug>/spec-<slug>.md` (why, capabilities with stable `CAP-N` ids, constraints, non-goals, success signal) and companion files. |
| 3. Architecture      | optional | `/bmad-architecture`                      | Records the decisions that keep separately built parts consistent. `bmad-spec` adopts it as a companion.     |
| 4. **Stories**       | yes      | `/bmad-ticket` ("break this into stories") | Plans the epic with you; its breakdown entries cite the spec's `CAP-N` ids. `bmad-spec` offers this hand-off once when the spec reads as several slices. |
| 5. **Build** (each)  | yes      | `/bmad-build` or `/bmad-build-auto`       | "build story 1.2", or "ticket 1.2" for an unattended run. One run per ticket.                                |
| 6. Mark done         | yes      | `/bmad-ticket` ("mark story 1.2 done")    | After you have looked at the work.                                                                           |
| 7. Retrospective     | optional | `/bmad-retrospective`                     | After the epic's last ticket.                                                                                |

**Cycle:** ask `bmad-ticket` "what's next?". It runs `tickets.py next` and lists what is ready to refine, ready to start, in progress and blocked. A story needs no refining before `bmad-build`, which plans its acceptance criteria from the epic and the entry. Before an unattended run, review the stories with `bmad-ticket`.

**Unattended runs:** `bmad-build-auto` builds only the ticket it is given and never moves on to another. The loop is run by you, a script, or an AI coding session that starts one worker per ticket. After each run, read `status` in the plan or `tickets.py status`, not the chat output. A blocked ticket halts every later run of it until you fix the cause and set the status to resume from with `tickets.py mark <ref> <status>`.

## Full: complete planning pipeline

For major features, new services and work with several epics, team handoffs, approvals, compliance or integrations. Stakes decide how heavy the planning is; use this path when approvers, parallel teams or required documents call for it.

| Phase | Step               | Required  | Command                                         | Description                                                                          |
| ----- | ------------------ | --------- | ----------------------------------------------- | ------------------------------------------------------------------------------------ |
| plan  | Brainstorm         | optional  | `/bmad-brainstorming`                           | Facilitated ideation with varied techniques.                                         |
| plan  | Research           | optional  | `/bmad-deep-recon`                              | Market, domain, technical or competitive research.                                   |
| plan  | Brief              | optional  | `/bmad-product-brief`                           | A 1-2 page brief of a product you already believe in.                                |
| plan  | PRFAQ              | optional  | `/bmad-prfaq`                                   | Working Backwards test of whether the concept holds up; an alternative to the brief. |
| plan  | **PRD**            | yes       | `/bmad-prd`                                     | Requirements with stable ids, sized to the stakes. Creates, updates or validates.    |
| plan  | UX                 | optional  | `/bmad-ux`                                      | `DESIGN.md` and `EXPERIENCE.md`. May come first.                                     |
| plan  | **Architecture**   | yes       | `/bmad-architecture`                            | Settles the contracts and formats more than one epic must adopt.                     |
| plan  | Spec               | optional  | `/bmad-spec`                                    | Absorbs the PRD and adopts the UX and architecture files. `bmad-ticket` also accepts the PRD directly. |
| plan  | **Epics**          | yes       | `/bmad-ticket` ("split this initiative into epics") | Proposes epic boundaries and writes the initiative's breakdown in build order.   |
| plan  | **Stories**        | yes       | `/bmad-ticket` ("incept the first epic")        | Plans one epic's stories as entries in its breakdown.                                |
| ship  | **Build** (each)   | yes       | `/bmad-build`                                   | "build story 1.2": clarify, plan, implement, review, commit.                         |
| ship  | QA tests           | optional  | `/bmad-qa-generate-e2e-tests`                   | API and end-to-end tests for what was built.                                         |
| ship  | Code review        | optional  | `/bmad-code-review`                             | With no argument it offers the tickets in review.                                    |
| ship  | **Mark done**      | yes       | `/bmad-ticket` ("mark story 1.2 done")          | Only you or an orchestrator mark a ticket done.                                      |
| ship  | Retrospective      | optional  | `/bmad-retrospective`                           | Judges the finished epic against its Done when; writes `epic-<slug>-retrospective.md`. |
| ship  | Correct course     | as needed | `/bmad-correct-course`                          | A significant change mid-flight. Needs a PRD or a spec; lists epic and story changes to apply with `bmad-ticket`. |

**Story cycle:** "what's next?" → build → (QA) → (code review) → mark done → next story. After an epic's last ticket, run the retrospective, then close the epic through `bmad-ticket`.

**Trackers:** by default the ticket files in the repository are the store. To use GitHub Issues, Jira, Linear, Notion or Trello instead, tell `bmad-ticket` "set up the ticket store"; the choice goes in `_bmad/custom/ticketing-store-config.toml`. The markdown files stay the working copy, nothing syncs on its own, and "publish the tickets" sends them. On a tracker store `tickets.py next` and `mark` refuse, so move tickets through `bmad-ticket`. The repository store is the most tested; the trackers are lightly tested.

## Choosing between spec-driven and full

|                     | Spec-driven                                   | Full                                                  |
| ------------------- | --------------------------------------------- | ----------------------------------------------------- |
| Team                | One or two people                             | Several roles, handoffs, approvals                    |
| Planning documents  | A spec, optionally a brief and architecture   | Brief or PRFAQ, PRD, UX, architecture, then a spec    |
| Epics               | Usually one, planned from the spec            | An initiative split into several epics                |
| Builds              | `bmad-build` or `bmad-build-auto` per ticket  | `bmad-build` per story                                |
| First time with BMad | Start here                                   | Move here when the work needs it                      |

Both paths end in the same ticket tree, so you can move between them. To add a PRD, UX or architecture later, fold it into the spec with `bmad-spec`; a spec update names the tickets whose description no longer matches and offers to re-slice them with `bmad-ticket`. A full project goes lean by giving its PRD to `bmad-spec`.

---

## Fork changes

- **`bmad-real-test` (new skill).** After a change, it runs the project's test suites past unit tests: the integration, end-to-end, API and contract tiers that can run locally. When the change touches an HTTP API and the project has no API tests that can run, it starts the server locally and calls the changed endpoints as a smoke check. It stays on this machine and reports a tier that needs a remote environment or real credentials as blocked. It fixes failures the change caused, reports failures that already existed, writes the results under `## Real Test Result` in the build's plan, and commits its fixes locally when the working tree was clean at the start. It never pushes. `bmad-build` calls it through its `on_complete` hook after the build's local commit, and `bmad-build-auto` does the same, unattended, when the run ends `built` or `done`. If the skill is not installed, the builds skip it. You can also run it directly: "run real tests". The plan templates of both builds ask for these tiers in the plan's verification commands.
- **Platform overrides.** One file, `skills/bmad/scripts/platform-overrides.md`, adapts the skills to the tools of Claude Code, Codex CLI, GitHub Copilot in VS Code and Copilot CLI. `bmad setup` installs it into `_bmad/scripts/`, and the skills read it when they start: through `activation_steps_prepend` in their `customize.toml`, or a short section in `SKILL.md` for `bmad`, `bmad-customize`, `bmad-advanced-elicitation` and `bmad-real-test`. `bmad-eval` does not load it. Each section applies only when its tools exist: structured questions (`AskUserQuestion`, `request_user_input`, `askQuestions`, `ask_user`), plan tracking (`update_plan`, `todos`, `manage_todo_list`), and subagent delegation (`Agent`, `spawn_agent`, `runSubagent`, `task`). Where a workflow's own text forbids something, the workflow wins. Codex accepts `request_user_input` only in Plan mode, so in Default mode the skills ask in plain text.
- **Plan size in `bmad-build`.** The planning step checks structure instead of a 1600-token limit. When a plan has more than 15 tasks, 5 code blocks, 12 subsection headings or 30 lines of Design Notes, it shows which limits were exceeded and asks whether to split the work or keep the plan. Token count is informational only. `bmad-build-auto` keeps upstream's warning, which marks a plan above 1600 tokens as `oversized` and continues.

---

## Skill reference

Every skill in this fork with a one-line description, grouped by module.

### Method: analysis and planning

| Command                 | Description                                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------------------------------- |
| `/bmad-product-brief`   | Creates, updates or validates a 1-2 page product brief.                                                       |
| `/bmad-prfaq`           | Tests a concept with Amazon's Working Backwards method: press release, hard questions, a verdict.             |
| `/bmad-prd`             | Creates, updates or validates a PRD.                                                                          |
| `/bmad-ux`              | Captures the UX vision in `DESIGN.md` (how it looks) and `EXPERIENCE.md` (how it behaves).                    |
| `/bmad-architecture`    | Creates, updates or validates a short document of the decisions that keep separately built parts consistent.   |
| `/bmad-spec`            | Condenses any input into `spec-<slug>.md` and companion files, the contract builds read; updates and validates specs. |
| `/bmad-ticket`          | Plans initiatives, epics, stories and bugs as a ticket tree and runs it as a board, with an optional tracker. |
| `/bmad-project-context` | Sets up, adopts, refreshes or audits the agent-instructions block in `AGENTS.md`; records agent mistakes as pitfalls. |

### Method: implementation and validation

| Command                       | Description                                                                                              |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| `/bmad-build`                 | One session of delivery: clarify, plan, implement, review, commit locally.                               |
| `/bmad-build-auto`            | One unattended build of one ticket; halts as `blocked` instead of asking.                                |
| `/bmad-real-test`             | Fork only. Runs the real test tiers against a change, fixes what the change broke, and reports what ran. |
| `/bmad-code-review`           | Reviews any diff, PR or branch with several independent reviewers in parallel, then triages the findings. |
| `/bmad-walkthrough`           | Guides a human review of a commit, PR, file or directory.                                                |
| `/bmad-qa-generate-e2e-tests` | Generates API and end-to-end tests for features that already exist.                                      |
| `/bmad-retrospective`         | Reviews a finished epic folder against its evidence: findings, action items, an acceptance decision.     |
| `/bmad-correct-course`        | Assesses a significant midstream change and writes a change proposal.                                    |

### Core tools

| Command                      | Description                                                                                                   |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `/bmad`                      | Answers BMad questions and recommends the next skill; runs setup, status, update and migrate; shows or changes the active initiative. |
| `/bmad-customize`            | Writes override files under `_bmad/custom/` for installed skills and agents.                                  |
| `/bmad-brainstorming`        | Facilitates a brainstorming session with varied creative techniques.                                          |
| `/bmad-party-mode`           | Runs a group discussion between installed agents or custom personas; helps author custom parties.            |
| `/bmad-advanced-elicitation` | Makes the model reconsider and improve its recent output, for example with a pre-mortem or red team.          |
| `/bmad-review`               | Runs review lenses (adversarial, edge cases, verification gaps, structure, prose) over code or documents, when you ask for a review. |
| `/bmad-forge-idea`           | Tests a half-formed idea in a questioning conversation with personas; can write a short brief.                |
| `/bmad-deep-recon`           | Research for a decision: drafts a prompt for another tool, summarizes a finished report, or researches here.  |

### Toolsmith

| Command           | Description                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `/bmad-toolsmith` | Smithy the Toolsmith builds, converts, reviews, packages, validates and migrates skills, agents and modules. Writes nothing before you approve a read-back. |
| `/bmad-eval`      | Runs a skill's evals: against the bare model, against another version, against a rubric, and for trigger accuracy.       |

### Agents

Each agent is a persona you talk to across turns; it offers a menu of the skills for its phase.

| Command                   | Persona                                                           |
| ------------------------- | ----------------------------------------------------------------- |
| `/bmad-agent-analyst`     | Mary, business analyst: research, brainstorming, briefs, PRFAQs   |
| `/bmad-agent-pm`          | John, product manager: PRDs, epics and stories, midstream changes |
| `/bmad-agent-ux-designer` | Sally, UX designer                                                |
| `/bmad-agent-architect`   | Winston, system architect                                         |
| `/bmad-agent-dev`         | Amelia, senior software engineer: builds, tests, reviews, board   |

The v6 epics-and-stories and sprint-planning skills are retired; `bmad-ticket` replaces both. `bmad setup` offers to delete retired skills that are still installed.
