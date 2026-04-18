---
description: "Multi-agent deep PR review with Linear issue context, recursive decomposition, and production-aware analysis"
argument-hint: "<LINEAR-ISSUE> <PR-NUMBER>"
---

# Canix Deep PR Review

Thorough, multi-agent code review that produces senior engineer-level findings. Recursive decomposition ensures every file is read with full context. Findings focus on architectural insight, not mechanical pattern-matching.

Review PR **$1** against Linear issue **$0**.

**MANDATORY**: This command MUST use subagents via the Agent tool. Do NOT perform the review yourself. Do NOT skip agent spawning for any reason. Every file in scope must be read and understood by a subagent before findings are produced.

---

## Phase 0: Determine Review Scope

### 0.1 Fetch PR Details

Run these commands to gather the PR context:
```bash
gh pr view $1 --json title,body,baseRefName,headRefName,files,additions,deletions,commits,labels,reviews,comments
gh pr diff $1
```

### 0.2 Read Linear Issue

Use the Linear MCP server to fetch the issue details:
- Call `mcp__linear-server__get_issue` with id `$0` (set `includeRelations: true`)
- Extract: title, description, acceptance criteria, priority, labels, estimate, state
- If the issue has sub-issues or related/blocking issues, note them for context
- Call `mcp__linear-server__list_comments` with the issue ID to **read the comments** — the real context often lives in the discussion thread where the team debated the approach, not just the description

### 0.3 Gather the File List and Diff

From the PR diff, gather:
- **File list**: All files changed (with status: added/modified/deleted)
- **Diff**: The actual changes
- **Context**: Commits, branch name, Linear issue details

Exclude generated files (`web/src/**/__apollo__/**`, `web/src/**/__generated__/**`, `web/data/**`, `web/src/globalTypes.ts`, `web/src/backend_generated/**`, `web/src/col_id_types.backend-generated.ts`, `web/yarn.lock` unless `package.json` also changed) from the file list.

### 0.4 Measure Volume

Count files in scope. Note total, backend, frontend, test, config, workers/jobs. Also count approximate total lines changed.

### 0.5 Classify Change Type

Based on the Linear issue type, PR title, branch name, and nature of changes, classify the PR. This classification calibrates what reviewers prioritize:

| PR Type | Primary Lens | Secondary Lens | Deprioritize |
|---------|-------------|----------------|--------------|
| **Bug fix** | Root cause actually fixed? Regression test added? | Side effects of the fix | Architecture elegance, style nits |
| **Feature** | AC met? Architecture sound? Edge cases? | Security, compliance, test coverage | Micro-optimizations |
| **Refactor** | Behavior preserved exactly? Tests unchanged? | Is the new structure actually better? | New features sneaking in |
| **Performance** | Evidence of improvement (benchmarks, profiling)? | Correctness preserved? | Style concerns |
| **Migration/data** | Reversibility? Data integrity? Deploy safety? | Performance at scale | Code style |
| **Infrastructure** | Deploy safety? Backward compatibility? | Monitoring/observability | Code style |

---

## Phase 1: Context Assembly

You (the orchestrator) build a complete mental model. This work is NOT delegated.

### 1.0 Understand the Business (BEFORE reading code)

Read `CLAUDE.md` and `.rules/canix-context/tech-stack.md`. Answer for yourself:
- What does this product do? Who uses it? What's the core value proposition?
- What area of the product does this PR touch?
- What are the compliance/multi-tenancy implications?

This context MUST be included in every subagent prompt as **Business Context**. Subagents cannot produce business-aware findings without it.

### 1.1 Understand the Change Narrative

1. **Commit sequence analysis**: Read the commits in chronological order. The sequence reveals the author's thought process — did they scaffold first then iterate? Did they fix something mid-PR that suggests they discovered a problem? Note any "fixup" or "address review" commits.

2. **PR conversation history**: Read ALL existing review comments and author responses from `gh pr view $1 --json comments,reviews`. Do NOT re-raise issues the author has already addressed or explained. If a previous reviewer asked a question and the author answered, that context is part of the review record.

3. **Linked PRs and context**: Check the PR description and Linear issue for references to other PRs (e.g., "depends on #1234", "follow-up to #1230", "part 2 of 3") or related Linear issues. If found, fetch their titles/descriptions. A PR that is explicitly partial should NOT be penalized for incomplete functionality.

4. **Recent git history of changed files**: For key files, run `git log --oneline -5 -- <filepath>` to understand recent evolution. A file recently refactored may signal the author is deliberately continuing that direction. A file untouched for 2 years warrants more caution.

### 1.2 Load Project Standards

Read these files (fail fast if missing):
1. `.rules/canix-context/multi-tenant.md`
2. `.rules/canix-context/compliance.md`
3. `.rules/canix-context/known-issues.md`
4. `.rules/canix-context/pr-review-comments.md`
5. `.rules/canix-context/pr-review-feedback.md`
6. `.rules/canix-context/tech-stack.md`
7. `AGENTS.md`

If the PR touches frontend files under `web/`, also read:
8. `docs/frontend-guidelines.md`

Condense into a **rules summary** (~500 words max) that every subagent will receive. Include Canix-specific rules:

**Multi-tenancy (non-negotiable)**:
- `loads: Types::FacilityType` on GraphQL mutations accepting facility arguments
- All queries scoped by facility_id/company_id
- `facility_id` as first parameter on all background jobs
- Raw SQL must include facility_id in WHERE clauses
- GraphQL query resolvers must be facility-scoped
- Association traversals must not cross facility boundaries

**Compliance & audit trail**:
- Waldit audit context for state-reportable changes (packages, plants, harvests, transfers, plant batches)
- Waldit NOT required for: UI preferences, user profile updates, pure read operations
- PostHog events for user-initiated business actions
- PostHog NOT required for: background job actions, internal bookkeeping
- `update_columns` bypasses Waldit — if used on compliance models, flag as blocking

**Production safety**:
- `add_index` on large tables MUST use `algorithm: :concurrently` + `disable_ddl_transaction!`
- Facilities can have 50k+ packages — loops must use `find_each`/`in_batches`
- Rolling deploys: new columns must be nullable or have defaults, removed columns need `ignored_columns`
- Sidekiq job arguments must be backward-compatible with in-flight jobs

**Test standards**:
- Factories, NEVER fixtures; `it` blocks, not `test` blocks
- Full integration tests — no method stubs (except external APIs)
- External API stubbing via `exact_request_path` helper
- Facility isolation tests required

**GraphQL rules**:
- Query resolvers MUST be read-only (no DB writes)
- Domain-specific helpers belong in dedicated modules, NOT in BaseMutation or shared base classes

### 1.3 Read the Changes

Read the full diff. You need line-level understanding.

### 1.4 Build the Initial Module Map

Group changed files into **logical modules** — coherent units with a beginning, middle, and end. A module is a path you can follow from data origin to final consumer.

**How to identify modules:**
1. Start from model/schema changes — each modified table anchors a module
2. Trace the data forward: mutations/services that write -> queries that read -> frontend that renders -> jobs that process
3. Group all files in that path into one module
4. Name the module by its purpose (e.g., "Package Transfer Pipeline", "Facility Settings End-to-End")

**Shared files** (schema, auth helpers, base classes, concerns): include them in every module that depends on them.

**Orphan files**: group into a "Shared / Standalone" module.

Every file in scope MUST appear in at least one module. No file left unassigned.

### 1.5 Classify Modules by Size

For each module, count files and estimate total lines. Classify:

| Size | Criteria | Next step |
|------|----------|-----------|
| **Small** | <10 files AND <800 lines | Skip decomposition, go directly to review (Phase 3) |
| **Medium** | 10-15 files OR 800-1500 lines | Go directly to review, but reviewer MAY propose a split if they realize mid-read they can't cover everything |
| **Large** | >15 files OR >1500 lines | MUST spawn a decomposer agent first (Phase 2) |

### 1.6 Create Tasks

Create one task per module. Each task includes:
- Module name
- List of files in the module
- Brief description of the module's purpose
- File count and approximate line count
- Size classification (Small / Medium / Large)
- Concurrency exposure: note if this module contains jobs, cron tasks, or operations that write to tables also written by other modules

---

## Phase 2: Decomposition (Large Modules Only)

This phase only applies to modules classified as **Large** (>15 files OR >1500 lines). Small and Medium modules skip directly to Phase 3.

### 2.1 Spawn Decomposer Agents

For each Large module, spawn a decomposer subagent. This is NOT a reviewer — its only job is to read the code, understand the structure, and propose how to split it.

**Decomposer prompt:**

```
You are a decomposer agent. Your job is to read ALL files in this module, understand
the code structure, and propose how to split it into smaller, reviewable sub-modules.

## CRITICAL RULE: The default is to SPLIT.

For modules with >15 files or >1500 lines, you MUST split. You may ONLY say
"no split needed" if you can demonstrate that ALL files form a single linear flow
with fewer than 3 branches AND the total is under 2000 lines.

The burden of proof is on YOU to justify NOT splitting.

## Module: {module_name}
{module_description}

## Business Context:
{business_context}

## Files ({file_count} files, ~{line_count} lines):
{file_list}

## Your Task

1. Read EVERY file listed above. No skipping.
2. Map the import/dependency graph between files.
3. Identify logical flows (data paths from origin to consumer).
4. Propose sub-modules that each follow ONE coherent logical thread.

## Output (MANDATORY format)

### File Dependency Map
Brief description of how files connect (which imports which, which calls which).

### Proposed Sub-Modules

For each sub-module:
- **Name**: Descriptive name based on purpose
- **Files**: Complete list (include shared files like schema/auth in each sub-module that needs them)
- **Logical thread**: The flow from beginning -> middle -> end that connects these files
- **Why together**: Why these specific files must be reviewed as a unit (what cross-file understanding is required)
- **Estimated lines**: Approximate total

### Files NOT Split (if claiming no split needed)
- Demonstrate the single linear flow
- Explain why <3 branches
- Confirm total is under 2000 lines

Rules:
- Every file from the original module MUST appear in at least one sub-module
- Shared files (schema, auth, base classes, concerns) SHOULD be included in every sub-module that depends on them
- Each sub-module should have 5-15 files (sweet spot for thorough review)
- Each sub-module must have a coherent logical thread — not just "frontend files" or "backend files"
```

### 2.2 Process Decomposition Results

After each decomposer returns:
1. Update tasks: replace the parent module task with the proposed sub-module tasks
2. Check: does any sub-module still exceed the Large threshold (>15 files OR >1500 lines)?
   - If yes -> spawn another decomposer for that sub-module (max 2 levels of recursion)
   - If no -> all sub-modules are ready for review

### 2.3 Safety Valve

Maximum 2 levels of recursive decomposition. If a sub-module still exceeds thresholds after 2 splits, send it to review anyway — the reviewer must note what it couldn't fully cover.

---

## Phase 3: Review

Reviewers are spawned for all leaf-level modules (Small, Medium, and decomposed sub-modules). Each reviewer receives the full review instructions below.

**Spawn all review agents in parallel** (or in batches of 6-8 if there are many modules).

### Reviewer Prompt Template

```
You are a senior engineer reviewing a code module in the Canix cannabis compliance
platform. Your job is not to find pattern violations — it's to deeply understand
the code and evaluate whether the implementation correctly and safely achieves its
intent.

## Business Context
{business_context}

## Module: {module_name}
{module_description}

## Project Rules Summary
{rules_summary}

## Linear Issue Context
{linear_issue_summary}

## PR Type: {pr_type}
{pr_type_focus_guidance}

## Commit Narrative
{commit_narrative}

## PR Conversation (already resolved comments — do NOT re-raise)
{pr_conversation_summary}

## Files to Review (READ EVERY ONE — no skipping)
{file_list}
```

Then include all sections below (3.1 through 3.5).

### 3.1 Understanding First (MANDATORY)

Before producing ANY findings, complete this structured understanding exercise. You MUST fill every section. If you cannot, state what's missing and why.

```
## Module Understanding

**Business Problem**: What user-visible problem does this module solve?
Write one sentence from the USER's perspective, not the developer's.
Bad: "Manages package transfer records in the database"
Good: "Lets a dispensary operator transfer cannabis packages between facilities while maintaining compliance with state reporting requirements"

**Data Flow** (trace the full path, minimum 3 steps with file:line references):
1. Entry point: [What triggers this? User click? Scheduler? Sidekiq job? Metrc webhook?]
2. Write path: [What gets created/updated, in what order? Which facility scope applies?]
3. Read path: [What queries serve this data to the UI? Are they facility-scoped?]
4. External dependencies: [Metrc/BioTrack APIs, compliance sync, PostHog events, Sidekiq jobs]

**Design Decisions I Noticed** (minimum 2, each with WHAT/WHY/RISK):
- WHAT: The decision (e.g., "compliance_submitted flag checked before sync")
- WHY (my hypothesis): Why the author likely chose this (e.g., "prevents re-reporting already-synced data to Metrc")
- RISK: What could go wrong with this choice (e.g., "if the flag isn't set atomically with the sync, a crash could leave orphaned records")

**What's Conspicuously Absent**: What you'd EXPECT to find in a module like this but don't.
E.g., "No facility isolation test — if user from facility A can access facility B data, this is a compliance violation."
If nothing is missing, explain why the coverage is complete.
```

### 3.2 Analysis Passes (MANDATORY — complete all three in order)

Do NOT scan for pattern violations. Instead, work through these three passes
sequentially. Each pass is a different mode of thinking. Only report a finding
if your analysis produces a concrete, traceable risk.

#### Pass 1: Correctness (does the happy path work?)

Pick the most important user action this module supports. Trace it end-to-end:
UI click -> GraphQL mutation -> service object -> model -> Sidekiq job (if any) -> response -> UI update.
At each step, note the file:line and confirm the data shape matches what the
next step expects.

Then check state transitions: if this module has status fields, enumerate every
valid transition. For each transition, confirm:
- The code that triggers it
- The UI that reflects it
- Whether every terminal state is reachable AND escapable (or intentionally terminal)
- What happens if the process crashes mid-transition — is the state recoverable?
- Whether Waldit audit context covers the transition (for compliance models)

For modules with 5+ files, also evaluate architectural fitness:
- Are file boundaries drawn where they'll age well?
- What's the implicit contract with callers — is it typed (Sorbet) or just hoped for?
- If a new state is added or a new integration point appears, how much changes?
- Would changing one file require knowing to change another? Is that coupling obvious?

**Canix-specific correctness checks:**
- GraphQL mutations: `loads: Types::FacilityType` present for facility arguments?
- New mutations registered in `mutation_type.rb`?
- `BaseMutation` helper methods (`save_and_handle_error`, `save_entire_collection`, `save_partial_collection`) used correctly?
- Model validations have matching database constraints?

#### Pass 2: Robustness (what happens when things go wrong?)

For EACH external call (Metrc/BioTrack API, Leaflink, QBO), database operation, or mutation in this module, analyze failure modes. Report only rows where the answer reveals a gap:

| Operation (file:line) | Fails with error | Returns empty/null | Times out (>10s) | Receives malformed data |
|---|---|---|---|---|
| [operation] | [what happens?] | [what happens?] | [what happens?] | [what happens?] |

Then perform **input boundary analysis**. For each function's arguments:
- Identify boundary values: nil, empty string, empty array, 0, negative numbers, extremely long strings, special characters, duplicate entries
- Trace what happens when each boundary value reaches the function. Does the validator catch it? Does the database reject it? Or does it silently corrupt state?
- Pay special attention to arguments from user input, GraphQL variables, or external API responses

**Canix-specific robustness checks:**
- Transaction boundaries: never wrap Metrc/BioTrack API calls inside a DB transaction
- `update_columns` on compliance models — bypasses Waldit audit trail
- Sidekiq jobs: idempotent? Primitive arguments (never ActiveRecord objects)? Explicit retry config for external API jobs?
- Silent error swallowing (`rescue => e; nil; end`) — especially dangerous in compliance paths

Finally, check for silent failures:
- Any catch block that returns a success-like value or swallows the error?
- Any error path where the user sees a spinner forever?
- Any operation that should be idempotent but isn't?
- Any timeout that should exist but doesn't?
- Any resource acquired but never released?

#### Pass 3: Concurrency (what happens when operations overlap?)

**This pass is MANDATORY.** Enumerate every pair of operations in this module
that could execute concurrently. Sources of concurrency include:
- User double-clicks or rapid repeated actions
- Multiple browser tabs / devices for the same user
- Sidekiq job triggering while a manual action is in progress
- Compliance sync running while user edits the same record
- Multiple users at the same facility acting on shared data
- Metrc/BioTrack webhooks arriving during user operations

For EACH concurrent pair you identify (minimum 2 pairs, or explain why
concurrency is impossible in this module):

1. **Name the pair**: Operation A (file:line) and Operation B (file:line)
2. **Trigger scenario**: How they run concurrently (e.g., "user edits package while compliance sync updates the same package from Metrc")
3. **Trace the interleaving**: Write out the dangerous execution order:
   - Op A step 1: [reads/writes what]
   - Op B step 1: [reads/writes what — does it see A's write?]
   - Op A step 2: [reads/writes what — does it see B's write?]
   - Op B step 2: [final state]
4. **Consequence**: What state corruption or user-visible bug results?
5. **Is there a guard?**: Does the code have a mechanism to prevent this? (e.g., `lock!`, `with_lock`, database unique index, optimistic locking). If yes, is the guard complete?

**Canix-specific concurrency concerns:**
- Read-then-write without `lock!` or `with_lock` on shared resources
- Uniqueness: model-level validations need matching database unique index for concurrent safety
- Compliance sync vs user edits on the same compliance model
- Multiple Sidekiq workers processing the same facility's data

Report concurrency findings using this structure in the Findings section:
- **Operations**: [Op A] and [Op B] (file:line for each)
- **Trigger**: [How they run concurrently]
- **Interleaving**: [Step-by-step trace]
- **Consequence**: [What state corruption or user-visible bug results]
- **Guard gap**: [What's missing in the existing protection, if any]

### 3.3 Output Format (MANDATORY)

```
## Module Understanding
[Structured template from 3.1 — ALL sections filled]

## Coverage Report
List EVERY file assigned to you:
- [check] `path/file.rb` — Read fully (N lines)
- [warn] `path/file.rb` — Read partially (lines X-Y of N total) — reason
- [fail] `path/file.rb` — Could not read — reason

## Dependencies Outside My Scope
Files my module references but that were NOT in my file list:
- `path/to/file.rb` — called at `myFile.rb:42`, concern: [specific thing to verify]

## Findings

IMPORTANT: Every finding MUST follow this structure. Findings without all 4
components will be rejected by the orchestrator.

### Blocking (will break in production, is a security risk, or violates compliance)

**`file:line` — [Title]**
- **What I see**: [Factual description of the code]
- **Author's likely intent**: [Why this code probably exists]
- **The risk**: [Concrete scenario where this causes a problem — not abstract]
- **Suggested approach**: [How to fix while preserving the author's intent]

### Should Fix (real improvement, not cosmetic)
[Same 4-component structure]

### Design Observations (MANDATORY for modules with 5+ files)
Issues at the design/architecture level. Not bugs — trade-off discussions.
- `file(s)` — What the current design optimizes for, what it sacrifices,
  and whether that trade-off still makes sense.
Minimum 1 observation for modules with 5+ files.

### Questions (genuinely curious — the author likely has good answers)
- `file:line` — Question phrased with humility and curiosity.

### What's Done Well
- `file:line` — Specific praise with WHY it's good. Not filler.
```

### 3.4 What DISQUALIFIES a Finding

DROP a finding if ANY of these are true:
- **The code was NOT changed by the author in this PR** — you may ONLY comment on lines/logic that the author actually added or modified in the diff. Pre-existing code, patterns, or issues that were already there before this PR are OUT OF SCOPE. Reading sibling files and existing code is for UNDERSTANDING CONTEXT, not for generating findings. If you see a problem in pre-existing code, ignore it completely — that is not this PR's responsibility.
- A linter, Rubocop, or type checker could catch it (that's their job, not yours)
- You can't explain WHY it matters in this specific codebase (not in general)
- You can't describe a concrete scenario OR trace a specific interleaving/input value that triggers the issue
- The same pattern appears in 3+ sibling files (it's a local convention — different modules like Metrc, BioTrack, QBO, Leaflink have different patterns for good reasons)
- Your finding is "X should have Y" without explaining what breaks without Y
- A previous reviewer raised the same concern and the author already addressed it

**EXCEPTION**: Race conditions, data corruption risks, facility scope bypass, and compliance violations are NEVER dropped for being "speculative." If you can trace the interleaving step by step, it's concrete enough.

**A senior engineer's review has 5 devastating observations, not 15 checkbox items.**

### 3.5 Reviewer Mindset

**You are a senior colleague who reads the code to understand the author's intent before forming opinions.**

Every line of code exists because someone thought about it. Your job is to:
1. Understand WHAT the author built
2. Understand WHY they built it that way (read sibling files, commit history, comments)
3. THEN evaluate whether the implementation achieves that intent correctly and safely

DO:
- **ONLY comment on code the author actually changed in this PR** — read sibling files and existing code for context, but NEVER flag pre-existing issues. Your scope is the diff, not the codebase.
- Read 2-3 sibling files per directory to understand local conventions
- Phrase uncertain findings as questions, not accusations
- Prioritize what's MISSING over what's "wrong" (in the author's changes)
- Give specific praise for good patterns — this proves you read the code carefully
- Include `file:line` references for every finding
- Think about WHY the author made each design choice before judging it
- Check `BaseMutation` helper methods before flagging "missing error handling"

---

## Phase 4: Cross-Module Synthesis

After all module reviews complete, this phase catches what falls between modules.

### 4.1 Active Validation of Subagent Output

For EACH module review that returns, the orchestrator performs these checks BEFORE accepting the results:

**Understanding Quality Gate (score 1-3):**
- **3 (Pass)**: Business Problem references user outcome. Data Flow has 3+ steps with file refs. Design Decisions have WHAT/WHY/RISK. Absences are specific.
- **2 (Marginal)**: One section is shallow but others are strong. Accept with a note.
- **1 (Fail)**: Business Problem is technical jargon. Data Flow is abstract without file refs. Design Decisions only have WHAT. Absences section is empty or says "nothing missing."

**If score = 1**: Spawn a new review subagent with this feedback:
"A previous reviewer produced a shallow understanding. Here is their summary: [paste]. Specific problems: [list failures]. Your job: read every file and produce a DEEPER understanding. Focus on: [failed sections]. Then perform the full review."
Maximum 1 re-review per module.

**Findings Quality Gate:**
- More than 5 findings that are single-line pattern matches without reasoning -> flag as "mechanical review" in the report
- Zero Design Observations for a module with 10+ files -> likely shallow
- Findings that contradict the Understanding Summary -> reviewer didn't integrate their own understanding

### 4.2 Collect Coverage

Aggregate all Coverage Reports:
- Every file in scope should appear as fully read in at least one reviewer's report
- Files marked as partially read or not read -> spawn a gap-filling subagent
- "Dependencies Outside My Scope" -> check if another reviewer covered them. If not -> spawn a gap-filling subagent.

### 4.3 Cross-Module Boundary Analysis

Spawn a **cross-module synthesis subagent** if there are 3+ modules. This agent receives all module understanding summaries, all "Dependencies Outside My Scope" sections, all findings, and the rules summary.

**The synthesis agent answers these specific questions:**

1. **Contract Violations**: For every "Dependency Outside Scope" entry, verify the caller's usage matches the callee's validators/return type. Read both files if needed.

2. **Inconsistent Patterns**: Compare how different modules handle error handling, facility scoping, Waldit context, PostHog events, status transitions. If different, which approach is correct?

3. **Duplicated Logic**: Code that appears in 3+ modules in slightly different forms. Is it intentional variation (different external API constraints — Metrc vs BioTrack vs Leaflink) or a missed shared abstraction?

4. **"One Change Breaks Everything" Test**: Pick 2-3 likely product changes (new compliance state, new integration, new facility type). Trace which modules would need to change. Is the blast radius reasonable?

5. **Integration Gaps**: Trace the full pipeline from user action -> mutation -> compliance sync -> state reporting API. Is there a gap where an error is silently swallowed? A gap where the user sees a spinner forever?

6. **Cross-Module Concurrency**: Identify operations that span module boundaries and could execute concurrently. Specifically:
   - List all mutations/actions across modules that write to the same tables
   - For each pair, determine: can they be triggered concurrently? (e.g., compliance sync in module A + user action in module B)
   - Trace the interleaving across module boundaries
   - Check for implicit ordering assumptions

7. **Finding Conflicts**: If two reviewers flagged the same code differently, investigate and resolve with specific evidence.

### 4.4 Gap Analysis — What's NOT in the Diff

Based on what changed, check for corresponding changes that SHOULD exist but don't:

**If schema/migration changed:**
- [ ] Model validations updated?
- [ ] Sorbet type annotations updated?
- [ ] Factory definitions updated (`test/factories/`)?
- [ ] GraphQL types expose new fields?
- [ ] Indexes for new query patterns (check `db/structure.sql`)?
- [ ] Frontend handles new fields/states?
- [ ] `add_index` on large tables uses `algorithm: :concurrently` + `disable_ddl_transaction!`?
- [ ] New columns nullable or with defaults (rolling deploy safety)?

**If new GraphQL mutation added:**
- [ ] Registered in `mutation_type.rb`?
- [ ] Has `loads: Types::FacilityType` for facility arguments?
- [ ] Has Waldit audit context (for compliance models)?
- [ ] Has PostHog event (for user-initiated actions)?
- [ ] Frontend consuming it handles the `errors` array?

**If model behavior changed:**
- [ ] Tests updated to cover new behavior?
- [ ] Facility isolation test present?
- [ ] Compliance sync implications considered?

**If Sidekiq job added/changed:**
- [ ] `facility_id` as first parameter?
- [ ] Idempotent?
- [ ] Primitive arguments only?
- [ ] Appropriate queue selection?
- [ ] Explicit retry configuration for external API jobs?

**If frontend component added/changed:**
- [ ] Loading/error/empty states handled?
- [ ] GraphQL-level errors AND network errors handled?
- [ ] Uses MUI5 components, theme colors via `sx`/`theme.palette`?
- [ ] Apollo vs Relay — not mixed in single component?
- [ ] Generated types used (not hand-written interfaces)?

### 4.5 Acceptance Criteria Verification

YOU verify AC — not a separate agent. You now have the full picture from all agent reports:
- Map each AC from the Linear issue to the implementation
- Flag AC that appear unaddressed
- Flag implementation that exceeds AC (scope creep)
- Note if the PR is explicitly partial ("part 1 of N") and adjust expectations
- Consider: would a QA engineer be able to verify this works based on the changes?

---

## Phase 5: Final Report

### 5.1 Prioritize Findings

Gather all findings from all reviewers + synthesis. Prioritize ruthlessly:

1. Security (facility scope bypass, authorization, data leak) -> Always blocking
2. Data corruption (race conditions, missing transactions, unsafe migrations) -> Blocking
3. Compliance violations (missing Waldit, compliance_submitted, missing PostHog) -> Blocking for compliance-touched code
4. Production safety (N+1 on large tables, unbounded queries, deploy-unsafe changes) -> Blocking
5. User-facing bugs (crashes, missing error handling, stuck states) -> Should Fix / Blocking
6. Cross-boundary contract violations -> Should Fix / Blocking
7. Missing functionality (AC not met, gap analysis findings) -> Should Fix
8. Design trade-offs -> Design Observation
9. Style -> Drop entirely

**Findings budget:**
- Maximum 10 findings total (blocking + should fix + design observations)
  - Of these, at most 5 may be architectural/design findings
  - No cap on concurrency, compliance, or data-corruption findings within the 10
- Maximum 4 blocking
- Maximum 3 questions
- Maximum 2 nits
- Zero mechanical/linter findings — if Rubocop or a type checker could catch it, drop it

Every finding you include means you're saying "this is worth 2 minutes of the author's attention." If it's not worth that, drop it.

### 5.2 Output the Report

Output the full report directly in the conversation. Include the copy-paste comment (Phase 6) at the end.

---

### PR Review Report: $0 — PR #$1

> **Review scope**: [What was reviewed]
> **Review strategy**: [files: N, modules: M, decompositions: D, reviewers: R]
> **PR type**: [Bug fix / Feature / Refactor / Performance / Infrastructure / Mixed]
> **Review focus**: [What was prioritized based on PR type]
> **Coverage**: [X/Y files fully read, Z partially read, W not read]

#### Linear Issue Summary
> [One-paragraph summary of what the ticket asks for]

#### What's Done Well
> 1-3 specific things with `file:line` references. Not filler — prove you understood the code.

- [Specific praise with `file:line` reference]

#### Review Overview
| Dimension | Score (1-5) | Key Finding |
|-----------|:-----------:|-------------|
| Security & Compliance | X/5 | [One-line summary] |
| Architecture & Correctness | X/5 | [One-line summary] |
| Integration & Data Flow | X/5 | [One-line summary] |
| Frontend Quality | X/5 | [One-line summary — only if web/ files in PR] |
| Acceptance Criteria | X/5 | [One-line summary] |
| **Overall** | **X/5** | |

**Score calibration**: 5 = exceptional, no issues. 4 = solid, minor suggestions. 3 = at least one substantive issue. 2 = blocking issues or multiple concerns. 1 = fundamental problems. A bug fix that correctly fixes the bug with a regression test is a 4-5/5 even if the code could be more elegant.

#### Confidence Level
**Confidence: X/10** — Start at 10, deduct 1 for: couldn't trace full data flow, unfamiliar domain, complex migration, unclear AC, missing test coverage, partial file coverage, compliance implications hard to verify, status machines not fully traced, linked PRs not reviewed, files not read.

#### Coverage Report
> Files fully reviewed: X/Y
> Files partially reviewed: Z (list with what was missed)
> Files NOT reviewed: W (list with reason — should be empty)

#### Questions for the Author
> The most important part of the review. Genuine questions about decisions that weren't immediately clear. The author likely has good answers — these are conversation starters, not accusations.
> If none, write: "No questions — the intent was clear throughout."

**Design decisions** (genuinely curious, likely good answers exist):
- `file:line` — [Question phrased with curiosity and humility]

**Potential concerns** (things that look risky but might be intentional):
- `file:line` — [Question phrased with curiosity and humility]

#### Blocking Issues (must fix before merge)
> Only list if genuinely blocking. Security/compliance violations and data corruption risks are always blocking.
> If none, write: "No blocking issues found."

**`file:line` — [Title]**
- **What I see**: [description]
- **Author's likely intent**: [hypothesis]
- **The risk**: [concrete scenario]
- **Suggested approach**: [preserving intent]

#### Should Fix
> If none: "No recommendations."

[Same 4-component structure]

#### Design Observations
> Architecture-level trade-off discussions. If none: "No design concerns."

#### Nits (max 2)
> If none: "No nits — clean PR!"

#### Acceptance Criteria Checklist
- [x] or [ ] [Each AC from the Linear issue mapped to implementation status]
- If partially met, explain what is covered and what is not

#### Impact Analysis
- **Files changed**: X (Y backend, Z frontend, W tests, V config)
- **Lines added/removed**: +X / -Y
- **Blast radius**: [Low/Medium/High] — [Details]
- **Rollback safety**: [Safe/Needs care/Risky] — [Specific: migration reversibility, data transformations]
- **Deploy safety**: [Safe/Needs care/Risky] — [Specific: rolling deploy compatibility, job backward compat]
- **Migration risk**: [None/Low/High] — [Specific: large table locks, data migration, irreversibility]

---

## Phase 6: Copy-Paste Comment

Self-contained, shareable. Under 40 lines. First person ("I noticed"). Lead with verdict. Include at the end of the report output.

````markdown
## PR Comment (copy-paste ready)

---

### Review: $0 — PR #$1

Hey! Here are some thoughts on this PR. Overall: **[one sentence verdict]**

#### What's done well
- [1-3 specific things with file references]

#### Questions
> Genuine questions — you likely have good answers.

- **`file:line`** — [Question in humble tone]

[If none: "No questions — the intent was clear throughout."]

#### Suggestions

**Blocking** (if any — otherwise omit):
- **`file:line`** — [Description. Why it's blocking. Link to `.rules/` if applicable.]

**Worth considering** (if any — otherwise omit):
- **`file:line`** — [Description. Phrased as suggestion, not command.]

**Nits** (if any — otherwise omit):
- `file:line` — [Take-or-leave suggestion]

[If nothing: "No suggestions — clean PR!"]

#### Acceptance Criteria
- [x] or [ ] [Each AC mapped to implementation]

---

<sub>Reviewed with [Claude Code](https://claude.ai/code)</sub>
````

---

## Tone & Communication Rules

1. **Understand before judging**: Read sibling files and commit history. The author knows the domain better than the reviewer.
2. **Humble, not authoritative**: "I think", "it seems like", "could we consider..."
3. **Curious, not accusatory**: Frame issues as questions when intent unclear. The author likely had a reason.
4. **Suggest, don't command**: "Would it make sense to..." instead of "You should..."
5. **Acknowledge uncertainty**: "I might be wrong, but..."
6. **Praise what's good**: Specific, not generic
7. **Questions are first-class findings**: A question like "How does this behave when a facility has 50k packages?" is MORE valuable than a nit about naming.

### When to Ask vs Flag
- **Ask**: decision could be intentional, you lack domain context, multiple valid approaches
- **Flag as blocking**: clearly violates a `.rules/` standard, is a known security pattern (missing `loads:`, unscoped query, missing Waldit), or would definitely break in production

## Important Rules

1. **ONLY REVIEW CODE THE AUTHOR CHANGED**: This is the #1 rule. Every finding, question, and suggestion MUST refer to code that was added or modified in the PR diff. Pre-existing code is read for CONTEXT ONLY — never flag it, never suggest improvements to it, never ask questions about it. If a pre-existing pattern is problematic, that's a separate ticket, not this PR review's concern. The orchestrator MUST drop any finding that references unchanged code.
2. Questions > nits. 3 good questions and 0 nits > 0 questions and 10 nits
3. Empty "Blocking" is a GOOD sign — do not invent problems
4. Always include `file:line` references
5. Link to `.rules/` when a finding maps to a documented standard
6. No false positives — if unsure, phrase as question
7. Respect the author — assume good intent, the author is a competent engineer who made deliberate choices
8. Context over rules — matching sibling files = probably correct (Metrc, BioTrack, QBO, Leaflink all have different patterns for good reasons)
9. Score honestly — correct + safe = 4/5 minimum
10. Never flag generated files
11. **UNDERSTANDING IS NON-NEGOTIABLE**: Every reviewer must produce a complete Module Understanding before findings. The orchestrator validates this.
12. **CONCURRENCY PASS IS NON-NEGOTIABLE**: Every reviewer must complete Pass 3 (Concurrency) and enumerate at least 2 concurrent pairs, or explain why concurrency is impossible in their module.
13. **ORCHESTRATOR IS ACTIVE**: The orchestrator validates Understanding Summaries against quality gates, re-spawns reviewers if quality is insufficient, and **drops any finding that targets pre-existing code not changed in the diff**.
