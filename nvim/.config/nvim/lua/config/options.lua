-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local opt = vim.opt
opt.relativenumber = false -- Relative line numbers
opt.clipboard = 'unnamedplus' -- Sync with system clipboard (y/p work with Ctrl+V outside Neovim)

-- Blink configuration
vim.g.lazyvim_blink_main = true
