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

  -- インバッファのマークダウンレンダリング (見出し・bullet・code block の見栄え向上)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  -- Mermaid 等をバッファ内に画像表示 (diagram.nvim + image.nvim / Ghostty kitty protocol)
  {
    "3rd/image.nvim",
    ft = { "markdown" },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = { enabled = false },
        neorg = { enabled = false },
        asciidoc = { enabled = false },
        typst = { enabled = false },
        syslang = { enabled = false },
      },
      hijack_file_patterns = {},
      editor_only_render_when_focused = true,
      tmux_show_only_in_active_window = true,
      -- デフォルト 50% だと複雑な図の文字が潰れる
      max_height_window_percentage = 90,
      max_width_window_percentage = 95,
    },
  },
  {
    "3rd/diagram.nvim",
    ft = { "markdown" },
    dependencies = { "3rd/image.nvim" },
    opts = function()
      local mermaid_config = vim.fn.stdpath("config") .. "/mermaid-config.json"
      return {
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter" },
          clear_buffer = { "BufLeave" },
        },
        renderer_options = {
          mermaid = {
            theme = "dark",
            background = "transparent",
            scale = 2,
            width = 2800,
            height = 2400,
            cli_args = { "-c", mermaid_config },
          },
        },
      }
    end,
    keys = {
      {
        "<leader>cm",
        function()
          require("diagram").show_diagram_hover()
        end,
        ft = "markdown",
        desc = "Mermaid diagram tab",
      },
      {
        "<leader>cR",
        function()
          vim.fn.delete(require("diagram").get_cache_dir() .. "/mermaid", "rf")
          require("diagram").render()
          vim.notify("Mermaid cache cleared and re-rendered")
        end,
        ft = "markdown",
        desc = "Mermaid re-render (clear cache)",
      },
    },
  },

  -- ブラウザプレビュー (mermaid / plantuml / katex 等)
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_close = 1
    end,
    config = function()
      vim.cmd([[do FileType]])
    end,
  },
}
