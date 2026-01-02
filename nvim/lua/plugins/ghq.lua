return {
  {
    "nvim-telescope/telescope-ghq.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "<Space>gr", "<cmd>Telescope ghq list<cr>", desc = "ghq repositories" },
    },
    config = function()
      require("telescope").load_extension("ghq")
    end,
  },
}
