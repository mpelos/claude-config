---
name: partner
description: Pair-program with a Codex partner through one persistent `codex exec` thread — you write the code, the partner reviews and spars. Only the user starts it.
argument-hint: "[partner] [instruction] — empty: Default Partner, for the whole thread"
disable-model-invocation: true
---

# Partner

`$ARGUMENTS`

- No partner named → the Default Partner; otherwise the one named.
- An instruction → apply the process to it only. None → the process governs the whole
  thread from now on.

## Models

| identifier             | model id         | use                                                    |
| ---------------------- | ---------------- | ------------------------------------------------------ |
| **Default Partner**    | gpt-6.1-sol      | the Partner, unless I name another                     |
| **Specialist Partner** | gpt-6-astra      | only when I name it                                    |
| **Scout**              | claude-opus-5-5  | subagents (`model: 'opus'`): read-only exploration and verification |
| **Specialist**         | claude-fable-5-1 | never spawn it                                         |

Never use Haiku or Sonnet.

## Roles

You drive: you write the code. The Partner navigates: it shapes the plan with you and
reviews what you write — not having written it, it sees what you can't. Its job is
finding the best path, not approving yours; if it agrees with everything, ask what it
would do differently.

It is one persistent thread for the whole project, so it accumulates context instead of
starting cold. Each round costs 10–40 min while code is cheap for you, so spend rounds
where they pay off.

## Process

**Before the first edit**, make sure the Partner's thread is live and caught up on the
project and the work in progress. Report its threadId to me.

**Plan by sparring.** Before each milestone, agree with the Partner on the approach, the
slices, and how each slice is verified. Slice so each review covers one coherent change
small enough to review in depth. Save the plan to `tmp/` with the threadId at the top;
it reseeds the thread if lost.

**Nothing lands without the Partner seeing it:**

- **Review after** — each slice once it's done; small fixes ride along with the next
  one. If a slice outgrows the plan, split its review along natural seams.
- **Spar before** — only what is expensive to reverse (contracts, schemas, data
  migrations) and walls. Everything else, the code is the proposal.
- **Delegate** — only settled, self-contained grinding work while you have something else
  to do, or when I ask. Give it the skeleton first: interfaces, names, where things live,
  acceptance criteria.

**Its findings are hypotheses.** Verify each in the code before acting. Only blocking
findings get another round; handle the rest yourself and say what you did in the next
send. When a debate would cost a round, settle it in code: implement the alternative and
send the result.

**Rounds.** The first review covers the whole slice; later ones only the fixes and open
points. A slice is done when the Partner approves it. After ~3 rounds on a blocking
point, you decide.

**When it writes**, review its git diff, not its report. Fix small things yourself; send
functional issues back once, then take over.

**High risk** — security, destructive migrations, cutovers: allow up to ~5 rounds and
bring a lasting split to me instead of deciding. Add one cold review: a fresh, one-shot
thread with only the diff, since a long-running partner comes to share your blind spots.

**Quota.** If a quota line appears after tool calls (% remaining; hours to reset in
parentheses), let it shift the split: Claude low → delegate more; GPT low → batch
reviews. Spend quota that is about to reset; never stall to protect it. If a provider
runs out, the other covers — tell me.

## Mechanics

Reach the Partner only through `codex exec` — not the codex MCP server, not the Codex
plugin. Reasoning effort is always `high`, never `xhigh` unless I ask. Exchange files go
in `tmp/codex/`, git-ignored.

Open a thread:

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

- The threadId is in the first line of `events.jsonl`. Never `resume --last`; another
  session's thread may be newer.
- With exit 0, MCP errors in `stderr.log` are harmless.
- Always run in the background, never poll.
- One send in flight per thread, one stage per send — a send gets one reply, so batched
  stages come back already done.
- A review send names the git range, never your summary of it, plus proof the slice
  works: the agreed checks, run, and the failure reproduced before a fix. It forbids file
  changes and asks for all findings at once, each marked blocking or not, ending in a
  verdict: approved, or blocking findings remain.
- If a send fails or the thread is lost, tell me and reseed from the plan doc. Never
  silently skip a review.

## Workspace

The Partner shares your checkout: one pen per file at a time. Scouts only explore and
verify.
