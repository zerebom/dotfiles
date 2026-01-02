-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Indentation
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true

-- UI
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"

-- History
opt.history = 1000
opt.undofile = true

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
