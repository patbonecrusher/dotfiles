-- Pin nvim-treesitter (and textobjects) to the `master` branch.
--
-- nvim-treesitter's new `main`-branch rewrite removed the
-- `nvim-treesitter.query_predicates` module, but the installed LazyVim still does
-- `require("nvim-treesitter.query_predicates")` (lazyvim/plugins/treesitter.lua).
-- That mismatch throws "module 'nvim-treesitter.query_predicates' not found" on
-- startup. The `master` branch keeps that API, matching this LazyVim version.
return {
  { "nvim-treesitter/nvim-treesitter", branch = "master" },
  { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
}
