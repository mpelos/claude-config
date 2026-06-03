#!/bin/bash
# PreToolUse(Bash) hook: block `git push` from Claude Code.
# Exit code 2 is a blocking error; stderr is fed back to Claude.
# Inspects the full command (not just a `git push *` prefix) so variants like
# `git -C <dir> push` and compound commands (`... && git push`) are also caught.
command=$(jq -r '.tool_input.command // empty')

if printf '%s' "$command" | grep -Eq '\bgit\b.*\bpush\b'; then
  echo "Blocked: 'git push' is disabled for Claude Code. Ask the user to push manually." >&2
  exit 2
fi

exit 0
