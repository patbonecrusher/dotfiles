#!/usr/bin/env bash
# Claude Code status line — managed by chezmoi
# (source: dot_claude/executable_statusline.sh → ~/.claude/statusline.sh).
# Shows the current model and how much of the session CONTEXT WINDOW is used.
# Claude Code pipes a JSON blob on stdin; `context_window.*` is pre-computed
# (used_percentage is input tokens only), and context_window_size is already the
# right denominator (200k, or 1M for extended-context models). Runs locally,
# consumes no API tokens. Docs: https://code.claude.com/docs/en/statusline.md
set -uo pipefail

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
pct=$(printf '%s'  "$input" | jq -r '.context_window.used_percentage // 0 | floor')
used=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
max=$(printf '%s'  "$input" | jq -r '.context_window.context_window_size // 200000')

used_k=$(( used / 1000 ))
max_k=$(( max / 1000 ))

# Color by how full the context is: green < 50 ≤ yellow < 80 ≤ red.
if   (( pct >= 80 )); then color=$'\033[31m'   # red
elif (( pct >= 50 )); then color=$'\033[33m'   # yellow
else                      color=$'\033[32m'    # green
fi
dim=$'\033[2m'; reset=$'\033[0m'

# 10-cell progress bar (▓ filled / ░ empty).
width=10
filled=$(( pct * width / 100 )); (( filled > width )) && filled=$width
(( filled < 0 )) && filled=0
empty=$(( width - filled ))
bar=""
(( filled > 0 )) && { printf -v f "%${filled}s" ""; bar="${f// /▓}"; }
(( empty  > 0 )) && { printf -v e "%${empty}s"  ""; bar="${bar}${e// /░}"; }

printf '%s%s%s  %sctx%s %s%s %d%%%s %s(%dk/%dk)%s' \
  "$dim" "$model" "$reset" \
  "$dim" "$reset" \
  "$color" "$bar" "$pct" "$reset" \
  "$dim" "$used_k" "$max_k" "$reset"
