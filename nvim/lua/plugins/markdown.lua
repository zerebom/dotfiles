return {
  -- Notion ライクな箇条書き体験：
  --   - <CR> でマーカー＋同インデントを自動継続
  --   - 行頭で <Tab> / <S-Tab> で demote / promote
  --   - 番号リストを自動リナンバー
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown", "text", "tex", "plaintex", "norg" },
    config = function()
      local autolist = require("autolist")
      autolist.setup()

      vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
      vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
      vim.keymap.set("i", "<Tab>", "<Esc>><cmd>AutolistRecalculate<cr>a<Space>")
      vim.keymap.set("i", "<S-Tab>", "<Esc><<cmd>AutolistRecalculate<cr>a")
      vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
    end,
  },

  -- ビジュアル選択で <Tab> / <S-Tab> → インデント増減（選択維持）
  {
    "LazyVim/LazyVim",
    keys = {
      { "<Tab>", ">gv", mode = "x", desc = "Indent selection" },
      { "<S-Tab>", "<gv", mode = "x", desc = "Outdent selection" },
    },
  },
}
