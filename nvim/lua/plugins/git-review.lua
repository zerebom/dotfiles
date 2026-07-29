-- PRレビュー用プラグイン
--   diffview.nvim: diff を見ながら LSP ジャンプ（gd/gr/K）できるのが最大の強み
--   octo.nvim:     GitHub PR の閲覧・コメント・Approve を nvim 内で完結
--
-- 基本フロー（AIが作ったPRのレビュー）:
--   1. gh pr checkout <num>   ← PRのコードを実体としてローカルに持つ（LSPが効く前提）
--   2. <Space>gv              ← デフォルトブランチとの merge-base 比較（GitHubのPR表示と同じdiff）
--   3. 気になる箇所で gd / gr / K → <C-o> で diff に戻る
--   4. コメントを返すなら <Space>gr（Octo review start）

-- 比較対象ブランチを解決して merge-base 比較で Diffview を開く
-- 解決順: ① gh で現在ブランチのPRのベースブランチ（スタックPR対応） ② origin/HEAD ③ origin/main
-- --imply-local: 比較の右側を実ファイル扱いにして LSP を効かせる
local function diffview_pr_diff()
  local lib = require("diffview.lib")
  if lib.get_current_view() then
    vim.cmd("DiffviewClose")
    return
  end
  -- ① 現在ブランチに紐づくPRがあれば、そのベースブランチと比較（base が main 以外のスタックPRでも正しい diff になる）
  local ref = vim.trim(vim.fn.system("gh pr view --json baseRefName -q .baseRefName 2>/dev/null"))
  if vim.v.shell_error == 0 and ref ~= "" then
    ref = "origin/" .. ref
  else
    -- ② デフォルトブランチ（origin/HEAD）
    ref = vim.trim(vim.fn.system("git rev-parse --abbrev-ref origin/HEAD"))
    if vim.v.shell_error ~= 0 or ref == "" then
      -- ③ origin/HEAD 未設定のリポジトリ向けフォールバック
      -- （git remote set-head origin -a で恒久設定できる）
      ref = "origin/main"
    end
  end
  vim.notify("Diffview: " .. ref .. "...HEAD", vim.log.levels.INFO)
  vim.cmd("DiffviewOpen " .. ref .. "...HEAD --imply-local")
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", diffview_pr_diff, desc = "Diffview: PR diff（デフォルトブランチ比較・トグル）" },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: 現在ファイルの履歴" },
    },
    opts = function()
      local actions = require("diffview.actions")
      return {
        enhanced_diff_hl = true, -- 削除/追加の行内ハイライトを強調
        view = {
          default = { winbar_info = true }, -- どっち側のrevを見てるかをwinbarに表示
          file_history = { winbar_info = true },
        },
        hooks = {
          -- Diffviewが開いたバッファを<Tab>(bnext)のバッファ巡回に混ぜない
          -- （--imply-local だと実ファイルが listed バッファとして溜まっていくため）
          diff_buf_read = function(bufnr)
            vim.bo[bufnr].buflisted = false
          end,
        },
        keymaps = {
          -- ツリーで Enter = 「開いて diff 側にフォーカス移動」（デフォルトは開くだけで帰れない）
          -- o = 「開くだけ（フォーカスはツリーに残す）」でプレビュー的に流し見できる
          file_panel = {
            { "n", "<cr>", actions.focus_entry, { desc = "Open and focus the diff" } },
          },
          file_history_panel = {
            { "n", "<cr>", actions.focus_entry, { desc = "Open and focus the diff" } },
          },
        },
      }
    end,
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    keys = {
      { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "Octo: PR一覧" },
      { "<leader>gr", "<cmd>Octo review start<cr>", desc = "Octo: 現在ブランチのPRレビュー開始" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      picker = "snacks", -- LazyVim 標準の picker に合わせる
      enable_builtin = true, -- :Octo 単体で actions メニューを開く
    },
  },
}
