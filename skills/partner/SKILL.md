---
name: partner
description: Pair-program with a Codex partner through one persistent `codex exec` thread — you hold the pen, the partner reviews and spars. Only the user starts it.
argument-hint: "[partner] [instruction] — empty: Default Partner, for the whole thread"
disable-model-invocation: true
---

# Partner

## Arguments

`$ARGUMENTS`

Read the arguments above before anything else:

- **Which partner.** No partner named → the **Default Partner**. A partner named
  (an identifier from the table below, such as "Specialist Partner" or "specialist",
  or a model id) → that one. A partner named here counts as the user asking for it by
  name, which is the only way the Specialist Partner is ever used.
- **What to do with it.** An instruction given (a task, a review, a plan to spar) →
  apply this process to that instruction; once it is done, the partner is no longer
  required for the rest of the thread unless the user says so. No instruction → this
  process governs the WHOLE thread from now on: every piece of work that follows goes
  through the partner as described below.

"The Partner" in the rest of this skill means the partner chosen above.

## House rules

The wall rule ("My requests are intent, not orders") and the design rules ("Design is
part of the deliverable") live in the global `CLAUDE.md`. They bind you here exactly as
everywhere else, and they are the Partner's review rubric: deliver them verbatim in the
onboarding briefing (§0) so he reviews against my criteria, in my vocabulary.

## Models

The single source of truth for model ids. Prose refers to models ONLY by their
identifier, so swapping a model means editing only this table.

| identifier             | model id         | role                                                                                           |
| ---------------------- | ---------------- | ---------------------------------------------------------------------------------------------- |
| **Default Partner**    | gpt-6.1-sol      | pair-programming partner via `codex exec`: reviews every diff, spars on plans and structure, takes a story occasionally when it fits |
| **Specialist Partner** | gpt-6-astra      | ONLY when I explicitly ask for it, by name, in a given task. Never pick it on your own judgement, never substitute it for the Default Partner, never use it for cold reviews unless I say so |
| **Scout**              | claude-opus-5-5  | subagents via the Agent tool (`model: 'opus'`): read-only exploration and verification         |
| **Specialist**         | claude-fable-5-1 | extremely expensive top-tier model. ONLY I choose to use it, by launching a session on it for very complex work. Never spawn it as a subagent or inside workflows, never route work to it on your own judgement |

"You" is whichever model I launched the session with — usually Scout's model, the
Specialist when the problem demands it. The process is identical either way.

Known asymmetries that shape it: you write the better code — naming, structure, APIs,
UI, and code that stays organized — so the pen is yours. The Partner is extremely
capable on hard logic and at finding what is wrong: the stronger reviewer, and a reviewer
who did not write the code sees what the author cannot. His code comes out less organized
than yours, so he writes only when §2 says so. Never use Haiku or Sonnet.

## The process: pair programming with you at the keyboard

You are the orchestrator, the developer, and the integrator. The Partner is your coworker,
not a dispatch target: ONE persistent codex thread that accumulates the project's context
from start to finish, so every exchange costs only its delta — no cold starts, no
re-exploration. Trust its auto-compaction.

### 0. Step zero — the Partner boots before the first edit

The FIRST action of any implementation work — before any file is touched — is making
sure the Partner is live and current. No thread alive → open one and deliver the
onboarding briefing: how we work (§2, §5, the house rules verbatim — they are his review
rubric), the product and stack, the current milestone with its plan docs, the exact
state of the work (committed, uncommitted, decisions pending); ask for an ack plus
questions, and forbid file changes in that round. Thread alive but behind → catch it up
before proceeding. Report the threadId to me before the first real task. From that
moment the Partner follows EVERYTHING: every diff, every decision, every wall reaches
the thread through one of §5's lanes — if he would be surprised by the current state of
the repo, the process has already failed.

### 1. Planning per milestone — the big sparring

Before any milestone, draft the high-level plan yourself (goal, slices, contracts, risks)
and send it to the Partner with an explicit request to attack it: what's missing, what
breaks, what can be simpler. One or two rounds until converged. The final plan goes to a
doc in `tmp/` with stories sliced; the pen is yours unless a story is explicitly marked
for the Partner per §2. This doc doubles as the reseed if the thread ever dies.

### 2. The pen is yours by default

- **You**: the implementation — logic, tests, migrations, contracts, UI, naming, file
  structure, integration. Writing settled code yourself is the default.
- **Partner**: a story only when ALL of these hold — it is self-contained, it is grinding
  work with no taste decisions left, its structure is already settled, and you have
  something to do in parallel in disjoint files — or when I assign it to him by name.
- Before handing the Partner a story, **write the skeleton yourself**: interfaces, types,
  names, where things live, acceptance criteria. Tight fences are what make its output
  come back organized. Every story prompt carries the wall rule.

### 3. The story loop — pipelined

Never idle while the Partner runs. Implement story N, send it for review (§5, review
lane) in the background, and implement story N+1 while he reads it; his findings on N
arrive while you are on N+1. Whoever did NOT write a story reviews it: he reviews yours
through the thread, which already has full context — one hop, no cold start; on the
occasions he writes, you read his actual diff (git diff, never the self-report).

A review send names the exact git range (`<sha>..<sha>`, or "the working tree") and he
reads the diff himself. Never send him your summary of the change: it carries your
assumptions, and he would review the summary instead of the code.

### 4. Review convergence — no infinite loops

His findings on your code:

- Each finding is a hypothesis, not an order. **Verify it against the code** before
  changing anything; reviewers hallucinate.
- Confirmed → fix it. Rejected → a written reply with the reason, so he doesn't re-raise
  it and stays current with why the code is the way it is.
- Fixes for functional findings go out in the next review send: ONE re-review round.
- Not converged after ~2 rounds: you decide and record the decision in the thread. The
  code is yours; the Partner has no veto.

Your findings on his code, when he wrote:

- Cosmetic/style issues: **fix them directly yourself**, no round-trip. If your direct
  fixes start becoming rewrites, the problem is your spec — tighten the skeleton.
- Functional problems: concrete written critique back to him, ONE fix round.
- Not converged after ~2 rounds: take the pen and finish it yourself. Escalating costs
  less than polishing at a distance.

### 5. Involvement — before, after, or delegated. Never never.

The thread's freshness is the asset this whole process buys. A diff the Partner never
saw is a debt: enough of them and he is a stranger to the codebase mid-project, and the
next big task pays exactly the re-explanation tax the persistent thread exists to avoid.
So NOTHING lands without passing through the thread — the only question is which lane,
and none of the three ever puts you on hold:

- **Review (after)** — the default lane for every diff you land, from a one-line fix to
  a whole story. Land it, then send the range plus a one-paragraph rationale to the
  thread in the background and KEEP WORKING — the send is async, so it costs zero
  wall-clock. His findings arrive while you're on the next thing; triage them per §4.
  The triage itself goes back to the thread (what you accepted, what you rejected and
  why): that write-back is what keeps him current.
- **Spar (before)** — anything that starts with an investigation ("why is this
  happening?") or ends in structure: public contracts, schemas, module boundaries, new
  modules, anything expensive to reverse, or a wall. The conversation happens BEFORE the
  pen moves; while he thinks, work on whatever doesn't depend on his answer. Afterward
  the normal rule applies: whoever didn't write it reviews it (§4 governs convergence).
- **Delegate** — the exception: a story that meets every condition in §2, or one I
  assigned to him by name. The skeleton exists before the send.

**Hot loop** (I am live-testing and reporting bugs): the pen stays with you for
turnaround, and every landed fix goes out on the review lane as it lands. When the loop
ends the Partner is already current — there is no bulk catch-up to schedule.

### 6. Cold review — the named exception

Security, destructive migrations, cutovers: one FRESH codex thread with no context beyond
the diff, one pass. A persistent partner slowly shares your blind spots; for high-stakes
work, buy back the independence deliberately.

### 7. Quota as rudder, not rule

A quota line may appear after tool calls (percentages are what REMAINS; parentheses are
hours to reset). If absent, ignore this section entirely — never slow down or remark on
it. When present: read it against the clock, never absolute. The default already routes
the writing to you; the line only adjusts the split — Claude scarce in the window → push
settled stories to the Partner via Delegate; GPT scarce → batch review sends, keep the
spar lane; a window near its reset with quota left is the PREFERRED destination (unused
quota expires worthless). Running a window to 0% is a fine outcome; stalling to protect
a number is not. If a provider is exhausted, the other takes over — say so, don't retry.

## Mechanics

The Partner is reached ONLY through the `codex exec` CLI, run by you through Bash. Never
the codex MCP server (`codex mcp-server` no longer exists since Codex 0.154) and never the
Codex plugin for Claude Code (`/codex:*` commands, the `codex:codex-rescue` subagent): the
plugin can only continue the latest task, not a named thread.

A thread lives on disk (`~/.codex/sessions/`) and ANY process continues it by its
threadId, so you own the project thread directly — no bridge agent.

### The two commands

Always run from the project root. Every prompt goes in a file, piped on stdin (`-`), so
quoting never breaks it. Exchange files live in `tmp/codex/` (git-ignored; add the
ignore if the project lacks it). `<model>` is the chosen Partner's model id from the
table; pass the same flags on every call, resume included.

The reasoning effort is `high`, always. Never raise it to `xhigh` on your own judgement,
not even for work that feels important or hard: `xhigh` does not necessarily give better
results, sometimes gives worse ones, and costs more. Only use a different effort when I
ask for it.

Open the project thread (step zero, and cold reviews):

```bash
codex exec --json -m <model> -c model_reasoning_effort=high \
  --dangerously-bypass-approvals-and-sandbox \
  -o tmp/codex/reply.md - < tmp/codex/send.md \
  > tmp/codex/events.jsonl 2> tmp/codex/stderr.log
```

Continue it:

```bash
codex exec resume --json -m <model> -c model_reasoning_effort=high \
  --dangerously-bypass-approvals-and-sandbox \
  -o tmp/codex/reply.md <threadId> - < tmp/codex/send.md \
  > tmp/codex/events.jsonl 2> tmp/codex/stderr.log
```

- **The threadId** is in the first event: `head -1 tmp/codex/events.jsonl` prints
  `{"type":"thread.started","thread_id":"..."}`. Report it to me, and write it at the
  top of the milestone doc (§1) so it survives a context compaction. Never use
  `resume --last`: another session's thread may be the newest.
- **The reply** is the Partner's final message, in `tmp/codex/reply.md`. Read that, not
  the event stream. `events.jsonl` holds the commands he ran, if you need them.
- **Errors:** a non-zero exit is a failed send; read `stderr.log`. With exit 0, stderr
  noise from Codex's own MCP servers (e.g. `insufficient_scope`) is harmless.

### The review send

Every review-lane send has the same shape, so reviews stay comparable:

- **Range**: the exact git range or "the working tree". He reads it with git.
- **Story**: what it was meant to do and its acceptance criteria.
- **Ask**: correctness, the house rules (design, gambiarra shapes), tests. Findings
  ranked by severity, each with `file:line` and why it matters. "No findings" is a
  valid answer; padding is not.
- **Fence**: review only — no file changes in this round.

### How a send runs

- **Always in the background.** Run the command with Bash `run_in_background: true` and
  keep working; you are notified when it exits, then read the reply. Rounds take 10–40
  min, past the foreground limit — never block on one, never poll.
- **One send in flight per thread.** The thread is ONE conversation: wait for a send's
  exit before the next one. Write each `send.md` fresh; never append to the last one.
  If story N+1 is ready before the review of N is back, it waits its turn.
- **One send buys exactly one reply.** A send is answered once, so "review A, then B,
  then C" collapses into one batched answer, and nothing you learn from A's review can
  reach B before it lands. Multi-stage work is therefore ONE SEND PER STAGE: send stage
  N, read it, act on it, then send N+1.
- **If a send fails or the thread is lost:** tell me, then open a fresh thread reseeded
  from the milestone doc plus a new briefing — never silently skip a review or drop
  the Partner.
- **Cold reviews** (the named exception above) open a fresh thread with the first
  command, one pass, no follow-ups; its threadId is never reused.

### The workspace

- The Partner works on the shared checkout on main. No worktrees or branches unless I
  ask — and once I have asked for one, it stays the project's workspace until I say
  otherwise. One pen per file at a time: if a delegated story could overlap with yours,
  serialize them.
- Scouts exist for two jobs only: read-only exploration fan-out and verification —
  never implementation, never the Partner's channel. Stop them (TaskStop) as soon as
  their report is processed.
