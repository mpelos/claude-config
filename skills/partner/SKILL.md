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
reviews what you write. It did not write your checks, so it is the only thing in the
loop that can notice a check built to confirm rather than to fail. Its job is finding the
best path, not approving yours; if it agrees with everything, ask what it would do
differently.

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

Inside T3 Code the Partner is a T3 child thread; outside it, a `codex exec` thread.
Inside T3, `mcp__t3-code__*` tools are in your tool list, usually deferred — load them
with ToolSearch. If a ToolSearch finds none, you're outside T3. Never use the `codex` MCP
server or the Codex plugin. Reasoning effort is `high` unless I ask
otherwise; always pass it explicitly, since the defaults are lower.

### Inside T3

- **Open:** `delegate_task` with `target: {providerInstanceId: "codex", model: <model id>,
  options: {reasoningEffort: "high"}}`. The returned `childThreadId` is the Partner's
  threadId.
- **Continue:** `t3_thread_send` to that `childThreadId`. T3's own guidance is a fresh
  `delegate_task` per review round; we keep one thread on purpose, because the Partner's
  value is the context it accumulates.
- **Cold review:** a new `delegate_task`, never continued.
- Completion arrives as a notification — don't poll. `t3_thread_read` has the full reply.

### Outside T3

Exchange files go in `tmp/codex/`, git-ignored. Always run in the background, never poll.

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

### Every send

- One send in flight per thread, one stage per send — a send gets one reply, so batched
  stages come back already done.
- A review send names the git range, never your summary of it, plus proof the slice
  works: the agreed checks, run; the failure reproduced before a fix; and, for each new
  test, the mutation that made it fail and which test failed. Gate output goes in as
  output — exit codes and failure names — never your assessment of it. It forbids file
  changes and asks for all findings at once, each marked blocking or not, ending in a
  verdict: approved, or blocking findings remain.
- The send also asks for a claim audit: every factual claim in the diff's comments and in
  the commit message — about another module, a library, the platform, a third party or a
  measurement — marked verifiable-from-the-diff or not, with the not-verifiable ones
  checked at the source. And one question, always: name any claim here that is stronger
  than the evidence attached to it.
- The review may re-run the red with a mutation of the Partner's choosing. It shares the
  checkout: one edit, one test run, revert. A mutation chosen by whoever did not write the
  test is the strongest check available — if its red and yours disagree, the test protects
  one thing and claims another.
- If a send fails or the thread is lost, tell me and reseed from the plan doc. Never
  silently skip a review.

## Workspace

The Partner shares your checkout: one pen per file at a time. Scouts only explore and
verify.
