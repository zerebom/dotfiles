return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,  -- 即時ロード
    keys = {
      { "<C-f>", "<cmd>Oil<cr>", desc = "Open Oil file browser" },
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    cmd = { "Oil" },  -- :Oil コマンドでもロード
    opts = {
      default_file_explorer = true,
      columns = {
        "icon",
        "size",
      },
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-s>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["-"] = "actions.parent",
        ["q"] = "actions.close",
        ["g?"] = "actions.show_help",
        ["<C-r>"] = "actions.refresh",
      },
    },
  },
  -- Disable neo-tree (LazyVim default) in favor of oil
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
}
