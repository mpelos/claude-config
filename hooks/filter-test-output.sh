#!/bin/bash
# PreToolUse(Bash) hook: quando o comando é um test runner ou typecheck, reescreve
# para mostrar só falhas e o resumo. A saída completa continua disponível se o
# modelo rodar o comando de novo com redirecionamento para arquivo.
# Baseado no exemplo oficial em https://code.claude.com/docs/en/costs
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# já filtrado/encadeado por pipe, ou saída para arquivo: não mexer
case "$cmd" in *'|'*|*'>'*) echo '{}'; exit 0;; esac

if printf '%s' "$cmd" | grep -Eq '(^|[;&] *)(pnpm( run)? (test(:[a-z:-]+)?|typecheck)( |$)|(pnpm exec |npx |bunx )?(vitest|tsc)( |$))'; then
  pattern='(FAIL|✗|×|Error|error TS|AssertionError|expected|Tests |Test Files|Duration|exit code)'
  filtered="{ $cmd; echo \"exit code: \$?\"; } 2>&1 | grep -E -A 8 '$pattern' | head -150"
  printf '%s' "$input" | jq --arg filtered "$filtered" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: (.tool_input + {command: $filtered})}}'
else
  echo '{}'
fi
