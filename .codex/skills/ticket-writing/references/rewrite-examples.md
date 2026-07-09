# Rewrite examples — PBI and Spike

Companion to the Bug rewrite in SKILL.md. Same rules, applied to the other ticket types.

## PBI — before

Title: Add that export thing we discussed

## PBI — after

Title: **Export transaction history to CSV from account settings**

Body:

**Problem**
Finance-facing users currently export transactions by copying rows out of the web table — about 15 minutes per account per month. Reported by the ops team and two customer support tickets (see Source).

**Proposed change**
Add a Download CSV button in Settings → Account → Transactions. The file covers the currently selected date range and includes date, amount, merchant, category, and status.

**Acceptance criteria:**
- A Download CSV button appears in Settings → Account → Transactions for signed-in users.
- Clicking the button downloads a CSV with header row: `date, amount, merchant, category, status`.
- The CSV covers the currently selected date range.
- An empty range produces a CSV with header row only.
- Download starts within 2 seconds for ranges up to 10,000 rows.

**Out of scope**
Excel export, email delivery, scheduled exports. These are separate tickets if demand appears.

**Links:**
Parent: ACCT-410, Self-service reporting epic.

**Source**
Ops team Slack thread (18 Apr): https://example.slack.com/archives/C01/p1713456789

## Spike — before

Title: Look at PDF libraries

Body:

> We need PDFs. See what's out there.

## Spike — after

Title: **Pick a PDF generation library for invoice exports**

Body:

**Goal**
Recommend one PDF library to generate styled invoice PDFs from our existing HTML templates. Decision criteria: render fidelity vs the current Chrome reference, bundle size, license compatibility (commercial distribution), active maintenance.

**Timebox:**
2 days.

**Method:**
1. Shortlist three libraries based on current industry usage: Puppeteer (headless Chrome), wkhtmltopdf, and Playwright print-to-PDF.
2. Render the current invoice template through each and diff against the Chrome reference.
3. Record output fidelity, render time on a representative sample of 100 invoices, bundle impact, and license terms.
4. Write a one-page recommendation with the tradeoffs.

**Expected output**
A comparison table, a recommendation with reasoning, and three sample PDFs (one per library) attached to this ticket.

**Open questions:**
1. Are we constrained to run this in-process, or can it run as a side-car service?
2. Is the commercial license for wkhtmltopdf a blocker given our distribution model?

**Source**
Engineering sync (14 Apr): https://example.atlassian.net/wiki/spaces/ENG/pages/1234
