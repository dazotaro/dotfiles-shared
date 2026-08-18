-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local opt = vim.opt
opt.relativenumber = false -- Relative line numbers
opt.clipboard = 'unnamedplus' -- Sync with system clipboard (y/p work with Ctrl+V outside Neovim)

-- Blink configuration
--
-- false (LazyVim's default) pins blink.cmp to its latest release tag, which
-- ships a prebuilt Rust binary for the fuzzy matcher. true follows the main
-- branch instead and adds `build = "cargo build --release"`, which needs a
-- working Rust toolchain on every machine that uses this config.
--
-- Not worth it: releases now track main closely, and requiring cargo is a real
-- cost on a managed machine where installing a toolchain needs approval.
vim.g.lazyvim_blink_main = false
