# BMAD Workflow Flows

Three paths through the BMM module by task complexity.

> **Note:** BMAD formally defines two paths — Quick Flow (anytime tools) and the full phased BMM pipeline. The "Medium" path below is a practical composition of anytime tools for tasks that need research but not a full PRD/architecture pipeline.

---

## Fast — Quick Flow

For small changes, brownfield additions, utilities. Skips planning entirely.


| Step         | Command               | Agent                       |
| ------------ | --------------------- | --------------------------- |
| 1. Quick Dev | `/bmad-bmm-quick-dev` | Barry (Quick Flow Solo Dev) |


---

## Medium — Research + Quick Flow

For features that need investigation but not the full PRD/architecture pipeline. Composed from BMAD anytime tools.


| Step           | Required | Command                                                       | Agent                       |
| -------------- | -------- | ------------------------------------------------------------- | --------------------------- |
| 1. Research    | optional | `/bmad-bmm-technical-research` or `/bmad-bmm-domain-research` | Mary (Analyst)              |
| 2. Quick Dev   | yes      | `/bmad-bmm-quick-dev`                                         | Barry (Quick Flow Solo Dev) |
| 3. Code Review | optional | `/bmad-bmm-code-review`                                       | Amelia (Developer)          |


---

## Full — Complete BMM Pipeline

For major features, new services, architectural changes, multi-epic work. All steps listed; **bold** = required, rest are optional gates.


| Phase            | Step                       | Required     | Command                                    | Agent               |
| ---------------- | -------------------------- | ------------ | ------------------------------------------ | ------------------- |
| 1-analysis       | Brainstorm Project         | optional     | `/bmad-brainstorming`                      | Mary (Analyst)      |
| 1-analysis       | Market Research            | optional     | `/bmad-bmm-market-research`                | Mary (Analyst)      |
| 1-analysis       | Domain Research            | optional     | `/bmad-bmm-domain-research`                | Mary (Analyst)      |
| 1-analysis       | Technical Research         | optional     | `/bmad-bmm-technical-research`             | Mary (Analyst)      |
| 1-analysis       | Create Brief               | optional     | `/bmad-bmm-create-product-brief`           | Mary (Analyst)      |
| 2-planning       | **Create PRD**             | **required** | `/bmad-bmm-create-prd`                     | John (PM)           |
| 2-planning       | Validate PRD               | optional     | `/bmad-bmm-validate-prd`                   | John (PM)           |
| 2-planning       | Edit PRD                   | optional     | `/bmad-bmm-edit-prd`                       | John (PM)           |
| 2-planning       | Create UX                  | optional     | `/bmad-bmm-create-ux-design`               | Sally (UX Designer) |
| 3-solutioning    | **Create Architecture**    | **required** | `/bmad-bmm-create-architecture`            | Winston (Architect) |
| 3-solutioning    | **Create Epics & Stories** | **required** | `/bmad-bmm-create-epics-and-stories`       | John (PM)           |
| 3-solutioning    | **Check Readiness**        | **required** | `/bmad-bmm-check-implementation-readiness` | Winston (Architect) |
| 4-implementation | **Sprint Planning**        | **required** | `/bmad-bmm-sprint-planning`                | Bob (Scrum Master)  |
| 4-implementation | Sprint Status              | optional     | `/bmad-bmm-sprint-status`                  | Bob (Scrum Master)  |
| 4-implementation | **Create Story**           | **required** | `/bmad-bmm-create-story`                   | Bob (Scrum Master)  |
| 4-implementation | Validate Story             | optional     | `/bmad-bmm-create-story` (validate mode)   | Bob (Scrum Master)  |
| 4-implementation | **Dev Story**              | **required** | `/bmad-bmm-dev-story`                      | Amelia (Developer)  |
| 4-implementation | QA Automation Test         | optional     | `/bmad-bmm-qa-automate`                    | Quinn (QA Engineer) |
| 4-implementation | Code Review                | optional     | `/bmad-bmm-code-review`                    | Amelia (Developer)  |
| 4-implementation | Retrospective              | optional     | `/bmad-bmm-retrospective`                  | Bob (Scrum Master)  |


**Story cycle:** CS → (VS) → **DS** → (QA) → (CR) → back to DS if fixes, or next CS, or ER at epic end.

**Tip:** For validation workflows (Validate PRD, Check Readiness, Code Review), use a different high-quality LLM for independent verification.

---

## Anytime Tools

Available regardless of phase:


| Name                     | Command                                                            | Agent               |
| ------------------------ | ------------------------------------------------------------------ | ------------------- |
| Document Project         | `/bmad-bmm-document-project`                                       | Mary (Analyst)      |
| Generate Project Context | `/bmad-bmm-generate-project-context`                               | Mary (Analyst)      |
| Correct Course           | `/bmad-bmm-correct-course`                                         | Bob (Scrum Master)  |
| Write Document           | Load `/bmad-agent-bmm-tech-writer`, then ask                       | Paige (Tech Writer) |
| Validate Document        | Load `/bmad-agent-bmm-tech-writer`, then ask to "VD [doc]"         | Paige (Tech Writer) |
| Mermaid Generate         | Load `/bmad-agent-bmm-tech-writer`, then ask to "MG [description]" | Paige (Tech Writer) |
| Adversarial Review       | `/bmad-review-adversarial-general`                                 | (core tool)         |
| Edge Case Hunter         | `/bmad-review-edge-case-hunter`                                    | (core tool)         |
| Help                     | `/bmad-help`                                                       | (core tool)         |


