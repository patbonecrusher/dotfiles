-- nvim half of vim-tmux-navigator (the tmux half lives in
-- dot_config/tmux/tmux.conf as the matching plugin).
--
-- Makes <C-h/j/k/l> move between nvim splits AND tmux panes seamlessly: at the
-- edge of nvim's windows the keypress hands off to the adjacent tmux pane
-- instead of doing nothing. <C-\> jumps to the previously-focused pane.
--
-- These override LazyVim's default window-only <C-h/j/k/l> maps with the
-- tmux-aware equivalents.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Go to left window/pane" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Go to lower window/pane" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Go to upper window/pane" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Go to right window/pane" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Go to previous window/pane" },
    },
  },
}
