#!/usr/bin/env bash
# Claude Code status line — managed by chezmoi
# (source: dot_claude/executable_statusline.sh → ~/.claude/statusline.sh).
# Two lines:
#   1) <dir> <git-branch*>  •  <model> ⚙<effort>  ctx <bar> <pct>% (<used>k/<max>k)
#   2) $<cost>  +<add> -<rem>  •  ⏱<duration>  •  ⚡5h <pct>%
# Claude Code pipes a JSON blob on stdin; fields per
# https://code.claude.com/docs/en/statusline.md#available-data . Runs locally,
# consumes no API tokens. Segments that are null/absent (git outside a repo,
# effort on models without it, rate_limits unless Pro/Max) are omitted.
set -uo pipefail

input=$(cat)

# --- extract fields (with fallbacks; some are null early in a session) --------
model=$(printf '%s'   "$input" | jq -r '.model.display_name // "Claude"')
dir=$(printf '%s'     "$input" | jq -r '.workspace.current_dir // .cwd // ""')
pct=$(printf '%s'     "$input" | jq -r '.context_window.used_percentage // 0 | floor')
used=$(printf '%s'    "$input" | jq -r '.context_window.total_input_tokens // 0')
max=$(printf '%s'     "$input" | jq -r '.context_window.context_window_size // 200000')
cost=$(printf '%s'    "$input" | jq -r '.cost.total_cost_usd // 0')
added=$(printf '%s'   "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(printf '%s' "$input" | jq -r '.cost.total_lines_removed // 0')
effort=$(printf '%s'  "$input" | jq -r '.effort.level // ""')
dur_ms=$(printf '%s'  "$input" | jq -r '.cost.total_duration_ms // 0')
rl5=$(printf '%s'     "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor')

# --- colors -------------------------------------------------------------------
dim=$'\033[2m'; reset=$'\033[0m'
green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; cyan=$'\033[36m'
sep="  ${dim}•${reset}  "

# green < 50 ≤ yellow < 80 ≤ red — shared threshold for context & rate limit.
heat() { local p=$1; if (( p >= 80 )); then printf '%s' "$red"; elif (( p >= 50 )); then printf '%s' "$yellow"; else printf '%s' "$green"; fi; }

# --- directory ----------------------------------------------------------------
dirname="${dir##*/}"; [[ -z "$dirname" ]] && dirname="~"

# --- git branch + dirty flag (computed locally against $dir) ------------------
git_seg=""
if [[ -n "$dir" ]] && branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then
    git_seg=" ${yellow} ${branch}*${reset}"
  else
    git_seg=" ${green} ${branch}${reset}"
  fi
fi

# --- effort (next to model) ---------------------------------------------------
effort_seg=""
[[ -n "$effort" ]] && effort_seg=" ${dim}⚙${effort}${reset}"

# --- context bar --------------------------------------------------------------
cbar=$(heat "$pct")
width=10
filled=$(( pct * width / 100 )); (( filled > width )) && filled=$width; (( filled < 0 )) && filled=0
empty=$(( width - filled ))
bar=""
(( filled > 0 )) && { printf -v f "%${filled}s" ""; bar="${f// /▓}"; }
(( empty  > 0 )) && { printf -v e "%${empty}s"  ""; bar="${bar}${e// /░}"; }
used_k=$(( used / 1000 )); max_k=$(( max / 1000 ))

# --- session stats (line 2) ---------------------------------------------------
cost_fmt=$(printf '$%.2f' "$cost")

lines_seg=""
(( added > 0 || removed > 0 )) && lines_seg="  ${green}+${added}${reset} ${red}-${removed}${reset}"

# duration: ms → Xs / Xm / XhYm
dur_seg=""
secs=$(( dur_ms / 1000 ))
if (( secs >= 1 )); then
  if   (( secs < 60 ));   then dur="${secs}s"
  elif (( secs < 3600 )); then dur="$(( secs / 60 ))m"
  else                         dur="$(( secs / 3600 ))h$(( (secs % 3600) / 60 ))m"
  fi
  dur_seg="${sep}${dim}⏱${dur}${reset}"
fi

# 5-hour rate limit (Pro/Max only; absent otherwise)
rl_seg=""
if [[ -n "$rl5" ]]; then
  rl_seg="${sep}$(heat "$rl5")⚡5h ${rl5}%${reset}"
fi

# --- assemble two lines -------------------------------------------------------
line1=$(printf '%s%s%s%s%s%s%s%s%s ctx %s%s %d%%%s %s(%dk/%dk)%s' \
  "$cyan" "$dirname" "$reset" "$git_seg" \
  "$sep" "$dim" "$model" "$reset" "$effort_seg" \
  "$cbar" "$bar" "$pct" "$reset" "$dim" "$used_k" "$max_k" "$reset")

line2=$(printf '%s%s%s%s%s%s' \
  "$dim" "$cost_fmt" "$reset" "$lines_seg" "$dur_seg" "$rl_seg")

printf '%s\n%s' "$line1" "$line2"
