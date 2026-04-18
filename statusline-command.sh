#!/bin/sh
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -z "$used" ]; then
  printf "%s" "$model"
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
    printf "%s [%s] %s" "$model" "$bar" "$token_str"
  else
    printf "%s [%s]" "$model" "$bar"
  fi
fi
