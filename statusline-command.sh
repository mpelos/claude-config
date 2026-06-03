#!/bin/sh
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

if [ -n "$effort" ]; then
  effort_str="${effort} · "
else
  effort_str=""
fi

if [ -z "$used" ]; then
  if [ -n "$effort" ]; then
    printf "%s %s" "$model" "$effort"
  else
    printf "%s" "$model"
  fi
else
  pct=$(printf "%.0f" "$used")
  filled=$(( pct / 10 ))
  empty=$(( 10 - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done

  # Sum input + cache_read + cache_creation to match /context token count
  tokens=$(echo "$input" | jq -r '
    .context_window.current_usage |
    if . == null then ""
    else
      ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) | tostring
    end
  ')

  if [ -z "$tokens" ] || [ "$tokens" = "" ]; then
    token_str=""
  else
    token_str=$(echo "$tokens" | awk '{
      n = $1 + 0
      if (n >= 1000000) {
        v = n / 1000000
        if (v == int(v)) printf "%.0fM", v
        else printf "%.1fM", v
      } else if (n >= 1000) {
        v = n / 1000
        if (v == int(v)) printf "%.0fK", v
        else printf "%.1fK", v
      } else {
        printf "%d", n
      }
    }')
  fi

  if [ -n "$token_str" ]; then
    printf "%s %s[%s] %s" "$model" "$effort_str" "$bar" "$token_str"
  else
    printf "%s %s[%s]" "$model" "$effort_str" "$bar"
  fi
fi
