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

-- Q でバッファ削除（ウィンドウレイアウトは維持）。デフォルトのQ（マクロ再生）は潰す
map("n", "Q", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

-- Move through wrapped lines
map("n", "j", "gj", { desc = "Move down (wrapped)" })
map("n", "k", "gk", { desc = "Move up (wrapped)" })

-- ノーマルモードの矢印 = ウィンドウ移動
-- Karabiner で left_ctrl+hjkl → 矢印 にしているため、nvim には <C-h> ではなく <Left> が届く。
-- これにより Ctrl+hjkl が tmux 感覚のウィンドウ移動になる（カーソル移動は素の hjkl が担当）
map("n", "<Left>", "<C-w>h", { desc = "Go to left window" })
map("n", "<Down>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<Up>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<Right>", "<C-w>l", { desc = "Go to right window" })

-- Find files including hidden ones (. 始まりのファイルも対象)
-- LazyVim は Snacks picker を使用。Alt+h トグルなしで常に隠しファイル込みで検索する。
map("n", "<leader>fh", function()
  Snacks.picker.files({ hidden = true })
end, { desc = "Find Files (hidden)" })

-- Grep including hidden files (隠しファイルの中身も全文検索)
map("n", "<leader>fH", function()
  Snacks.picker.grep({ hidden = true })
end, { desc = "Grep (hidden)" })

-- Yank current file path to clipboard (yp: relative, yP: absolute)
map("n", "<leader>yp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Yank relative path" })

map("n", "<leader>yP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Yank absolute path" })
