-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Escape with jk/jj
map("i", "jk", "<Esc>", { desc = "Escape" })
map("i", "jj", "<Esc>", { desc = "Escape" })

-- Clear search highlights with double Esc
map("n", "<Esc><Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })

-- Tab navigation (buffer switching)
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Move through wrapped lines
map("n", "j", "gj", { desc = "Move down (wrapped)" })
map("n", "k", "gk", { desc = "Move up (wrapped)" })
