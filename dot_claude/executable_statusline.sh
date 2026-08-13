#!/usr/bin/env bash
# Claude Code status line — managed by chezmoi
# (source: dot_claude/executable_statusline.sh → ~/.claude/statusline.sh).
# Renders:  <dir> <git-branch*>  •  <model> ctx <bar> <pct>% (<used>k/<max>k)  •  $<cost>  +<add> -<rem>
# Claude Code pipes a JSON blob on stdin; fields per
# https://code.claude.com/docs/en/statusline.md#available-data . Runs locally,
# consumes no API tokens. `context_window.*` is pre-computed (used_percentage is
# input tokens only); context_window_size is already the right denominator.
set -uo pipefail

input=$(cat)

# --- extract fields (with fallbacks; some are null early in a session) --------
model=$(printf '%s'  "$input" | jq -r '.model.display_name // "Claude"')
dir=$(printf '%s'    "$input" | jq -r '.workspace.current_dir // .cwd // ""')
pct=$(printf '%s'    "$input" | jq -r '.context_window.used_percentage // 0 | floor')
used=$(printf '%s'   "$input" | jq -r '.context_window.total_input_tokens // 0')
max=$(printf '%s'    "$input" | jq -r '.context_window.context_window_size // 200000')
cost=$(printf '%s'   "$input" | jq -r '.cost.total_cost_usd // 0')
added=$(printf '%s'  "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(printf '%s' "$input" | jq -r '.cost.total_lines_removed // 0')

# --- colors -------------------------------------------------------------------
dim=$'\033[2m'; reset=$'\033[0m'
green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; cyan=$'\033[36m'
sep="  ${dim}•${reset}  "

# --- directory ----------------------------------------------------------------
dirname="${dir##*/}"; [[ -z "$dirname" ]] && dirname="~"

# --- git branch + dirty flag (computed locally against $dir) ------------------
git_seg=""
if [[ -n "$dir" ]] && branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then
    git_seg=" ${yellow} ${branch}*${reset}"   # dirty
  else
    git_seg=" ${green} ${branch}${reset}"      # clean
  fi
fi

# --- context bar (green < 50 ≤ yellow < 80 ≤ red) -----------------------------
if   (( pct >= 80 )); then cbar=$red
elif (( pct >= 50 )); then cbar=$yellow
else                       cbar=$green
fi
width=10
filled=$(( pct * width / 100 )); (( filled > width )) && filled=$width; (( filled < 0 )) && filled=0
empty=$(( width - filled ))
bar=""
(( filled > 0 )) && { printf -v f "%${filled}s" ""; bar="${f// /▓}"; }
(( empty  > 0 )) && { printf -v e "%${empty}s"  ""; bar="${bar}${e// /░}"; }
used_k=$(( used / 1000 )); max_k=$(( max / 1000 ))

# --- cost + lines changed -----------------------------------------------------
cost_fmt=$(printf '$%.2f' "$cost")
lines_seg=""
if (( added > 0 || removed > 0 )); then
  lines_seg="${sep}${green}+${added}${reset} ${red}-${removed}${reset}"
fi

# --- assemble -----------------------------------------------------------------
#   <dir> <git>  •  <model> ctx <bar> <pct>% (<used>k/<max>k)  •  $<cost>  +<add> -<rem>
printf '%s%s%s%s%s%s%s%s ctx %s%s %d%%%s %s(%dk/%dk)%s%s%s%s' \
  "$cyan" "$dirname" "$reset" "$git_seg" \
  "$sep" "$dim" "$model" "$reset" \
  "$cbar" "$bar" "$pct" "$reset" "$dim" "$used_k" "$max_k" "$reset" \
  "$sep" "${dim}${cost_fmt}${reset}" "$lines_seg"
