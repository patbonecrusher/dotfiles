# tool-alts.zsh — remember the modern replacements you actually have installed.
#
#   alts            list every classic command -> the modern tools you have
#   alts top        show modern alternatives for `top`
#   top             (intercepted) fzf-pick which top-like tool to run; Esc = real top
#
# Add more intercepts via ALTS_INTERCEPT below. Descriptions are hardcoded so the
# picker stays instant (no `brew desc` calls at runtime).

# classic command -> modern alternative binaries (best first)
typeset -gA MODERN_ALTS=(
  top   'btm zenith'
  cat   'bat'
  ls    'eza'
  du    'dust'
  find  'fd'
  grep  'rg ag'
  ack   'rg ag'
  sed   'gsed'
  vi    'nvim'
  vim   'nvim'
  diff  'delta'
  xxd   'hexyl'
  hexdump 'hexyl'
  tree  'eza'
  ps    'btm'
  cd    'zoxide'
)

# binary -> short description (no runtime brew calls)
typeset -gA ALT_DESC=(
  btm    'bottom — graphical process/system monitor'
  zenith 'zoomable terminal system metrics'
  bat    'cat with syntax highlighting + git'
  eza    'modern ls (icons, tree, git)'
  dust   'intuitive du'
  fd     'fast, friendly find'
  rg     'ripgrep — fast recursive search'
  ag     'the_silver_searcher — code search'
  gsed   'GNU sed'
  nvim   'neovim'
  delta  'syntax-highlighting diff/pager'
  hexyl  'hex viewer'
  zoxide 'smarter cd (z)'
)

# The user-facing `alts` command lives in ~/.local/autoloaded/alts (so `help`
# documents it). It reads the MODERN_ALTS / ALT_DESC maps defined above.

# Commands to intercept with an fzf chooser (space-separated). Extend freely.
# Only unaliased, occasional commands belong here — aliased ones (ls, cat, grep,
# tree) never reach the function anyway (alias expansion wins).
: ${ALTS_INTERCEPT:=top du ps cat}

# shared chooser used by the intercept functions
_alts_offer() {
  emulate -L zsh
  local cmd=$1; shift
  local -a choices; local bin
  for bin in ${(z)MODERN_ALTS[$cmd]}; do
    (( $+commands[$bin] )) && choices+=$bin
  done
  choices+=$cmd                                   # always allow the real command
  # Skip the picker (run the real command) when there's nothing to choose, when
  # fzf is missing, or when output isn't a terminal (piped/redirected/scripted) —
  # so `du -sh * | sort` and `ps aux | grep x` behave normally.
  if (( ${#choices} <= 1 )) || ! (( $+commands[fzf] )) || [[ ! -t 1 ]]; then
    command $cmd "$@"; return
  fi
  local pick
  pick=$(
    for bin in $choices; do
      printf '%s\t%s\n' "$bin" "${ALT_DESC[$bin]:-the original $cmd}"
    done | fzf --delimiter='\t' --with-nth='1,2' --height='~40%' --reverse \
               --prompt="$cmd ▶ " --header="pick a tool  (Esc = $cmd)"
  )
  pick=${pick%%$'\t'*}
  [[ -z $pick ]] && pick=$cmd
  command $pick "$@"
}

# define the intercept functions (drop any conflicting alias first, e.g.
# cat='bat -A' — aliases otherwise shadow the function; removing cat from
# ALTS_INTERCEPT restores your original alias).
() {
  local c
  for c in ${=ALTS_INTERCEPT}; do
    unalias $c 2>/dev/null
    # Fall back to the real command when _alts_offer isn't in scope. These wrapper
    # functions can be inherited by a shell that never loaded this helper (so
    # _alts_offer is undefined); without the guard, cat/du/ps/top would then throw
    # "_alts_offer: command not found".
    functions[$c]="if (( \$+functions[_alts_offer] )); then _alts_offer $c \"\$@\"; else command $c \"\$@\"; fi"
  done
}
