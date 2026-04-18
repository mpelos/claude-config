---
name: linear-activities
description: "Check what Marcelo Pelos did on Linear in the past day and format it as a Slack daily standup response. Use this when the user needs to answer their daily standup or wants a summary of yesterday's Linear activity."
allowed-tools: ["mcp__linear-server__list_users", "mcp__linear-server__list_issues", "mcp__linear-server__get_issue", "mcp__linear-server__list_comments"]
---

# Linear Activities - Daily Standup Skill

Generate a Slack-ready daily standup answer from Linear activity.

## Steps

### 1. Determine the time window

The window is **yesterday** (the calendar day before today). Use the `currentDate` from the system context to compute the ISO-8601 date for yesterday.

If today is Monday, yesterday means Friday (skip the weekend).

### 2. Fetch issues updated yesterday

Call `mcp__linear-server__list_issues` with:
- `assignee`: `"me"`
- `updatedAt`: the yesterday ISO date (e.g. `"2026-03-22"`)
- `orderBy`: `"updatedAt"`
- `limit`: `50`

Also call `mcp__linear-server__list_issues` with:
- `assignee`: `"me"`
- `createdAt`: the yesterday ISO date
- `orderBy`: `"createdAt"`
- `limit`: `50`

### 3. Inspect each issue in detail

**CRITICAL**: Do NOT classify issues based solely on `updatedAt` or `completedAt` timestamps from the list query. The list query only gives you a snapshot -- you must dig deeper to understand what actually happened yesterday.

For every issue returned, do the following **in parallel**:

1. Call `mcp__linear-server__get_issue` to get full details (status, completedAt, attachments, PRs).
2. Call `mcp__linear-server__list_comments` to read the comment history.

Then determine what **actually happened yesterday** by examining:

- **Comments**: Were any comments posted within the time window? By whom? What do they say?
- **Status changes**: Did the status change within the window? (e.g., moved to "In Progress", "Code Review", "Done")
- **completedAt**: Does it fall within the time window?
- **Attachments/PRs**: Were new PRs attached or updated?

**Filtering rules**:
- If an issue was already "Done" before yesterday and was only touched by a minor update (e.g., someone else commented "thank you", or it was part of a batch/cycle update), **exclude it** from the standup -- it's not meaningful work from yesterday.
- If `updatedAt` falls within the window but there are no comments, no status changes, and no new PRs from yesterday, it was likely a system/cycle update -- **exclude it**.
- Only include issues where you performed meaningful work yesterday (wrote code, moved status forward, submitted a PR, triaged, investigated, commented substantively, etc.).

### 4. Classify each issue

For every issue that passes the filter above, classify it into one of these buckets:

- **Completed**: `completedAt` falls within the time window
- **Started / Moved Forward**: status moved forward (e.g., to "In Progress", "Code Review") or meaningful progress was made (new PR, substantive comment, investigation)
- **Created**: `createdAt` falls within the window (mention only if not already in another bucket)
- **Blocked**: `status` is "Blocked" and `updatedAt` falls within the window

Deduplicate across both queries.

### 5. Format the standup answer

Output a message ready to paste into Slack, answering:

> **What did you finish or move forward yesterday?**

Format rules:
- Use bullet points (Slack `•` style with `-` prefix)
- Each bullet: `- [STATUS_EMOJI] **ISSUE-ID** - Short title (brief context if useful)`
- Status emojis: completed = `done`, moved forward = `progressed`, created/triaged = `new`, blocked = `blocked`
- Group by: Completed first, then Moved Forward, then Created/Triaged, then Blocked
- Keep it concise -no full descriptions, just enough context for the team to understand
- Use plain text compatible with Slack markdown (no HTML)
- Do NOT include any preamble or explanation -just the formatted standup answer ready to copy-paste

### Example output

```
- done **ENG-605** -Fixed COGS discrepancy between Production Run and Package Activity views (Cirona)
- progressed **ENG-584** -Investigating dashboard chart flickering issue (CPNY)
- new **ENG-604** -Triaged: Source Production Batch missing from Pick Lists (Cirona)
- blocked **ENG-555** -Reporting auto-send failures, waiting on infra clarification (iAnthus)
```
