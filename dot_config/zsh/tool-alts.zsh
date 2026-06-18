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

# `alts [cmd]` — show installed modern alternatives
alts() {
  emulate -L zsh
  local cmd=$1 key bin shown
  if [[ -z $cmd ]]; then
    print -P "%BModern tool cheat-sheet%b — what you have installed:"
    for key in ${(ko)MODERN_ALTS}; do
      shown=""
      for bin in ${(z)MODERN_ALTS[$key]}; do
        (( $+commands[$bin] )) && shown+="$bin "
      done
      [[ -n $shown ]] && printf '  %-8s → %s\n' "$key" "${shown% }"
    done
    print -P "\nType e.g. %Balts top%b for descriptions."
    return
  fi
  local list=${MODERN_ALTS[$cmd]}
  [[ -z $list ]] && { print "No modern alternatives mapped for '$cmd'."; return 1; }
  print -P "Modern alternatives for %B$cmd%b:"
  for bin in ${(z)list}; do
    (( $+commands[$bin] )) && printf '  %-8s %s\n' "$bin" "${ALT_DESC[$bin]:-}"
  done
}

# Commands to intercept with an fzf chooser (space-separated). Extend freely.
: ${ALTS_INTERCEPT:=top}

# shared chooser used by the intercept functions
_alts_offer() {
  emulate -L zsh
  local cmd=$1; shift
  local -a choices; local bin
  for bin in ${(z)MODERN_ALTS[$cmd]}; do
    (( $+commands[$bin] )) && choices+=$bin
  done
  choices+=$cmd                                   # always allow the real command
  if (( ${#choices} <= 1 )) || ! (( $+commands[fzf] )); then
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

# define the intercept functions
() {
  local c
  for c in ${=ALTS_INTERCEPT}; do
    functions[$c]="_alts_offer $c \"\$@\""
  done
}
