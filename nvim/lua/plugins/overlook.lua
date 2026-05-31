-- overlook.nvim: ジャンプ先(定義など)をフロート窓でプレビューする。
-- 元のカーソル位置を見失わずにコードを潜って追える。複数回 peek すると
-- ポップアップがスタックされ、q で1枚ずつ閉じて元の場所に戻れる。
-- 参考: https://zenn.dev/layerx/articles/8c29b0367238b8
return {
  {
    "WilliamHsieh/overlook.nvim",
    opts = {
      ui = {
        border = "rounded",
        size_ratio = 0.65,
      },
      -- ポップアップ内のキーマップ
      keymaps = {
        close = "q",
      },
    },
    keys = {
      -- カーソル下の定義をフロートでプレビュー(一番使う)
      { "<leader>pd", function() require("overlook.api").peek_definition() end, desc = "Peek definition" },
      -- 現在位置をポップアップ化(メモ的に固定しておきたいとき)
      { "<leader>pp", function() require("overlook.api").peek_cursor() end, desc = "Peek cursor" },
      -- スタック操作
      { "<leader>pc", function() require("overlook.api").close_all() end, desc = "Close all peeks" },
      { "<leader>pu", function() require("overlook.api").restore_popup() end, desc = "Restore last peek" },
      { "<leader>pf", function() require("overlook.api").switch_focus() end, desc = "Switch focus (popup<->root)" },
      -- ポップアップを実ウィンドウに昇格させる
      { "<leader>ps", function() require("overlook.api").open_in_split() end, desc = "Open peek in split" },
      { "<leader>pv", function() require("overlook.api").open_in_vsplit() end, desc = "Open peek in vsplit" },
      { "<leader>pt", function() require("overlook.api").open_in_tab() end, desc = "Open peek in tab" },
      { "<leader>po", function() require("overlook.api").open_in_original_window() end, desc = "Open peek in current window" },
    },
  },
  -- which-key に <leader>p グループ名を登録
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>p", group = "peek (overlook)" },
      },
    },
  },
}
