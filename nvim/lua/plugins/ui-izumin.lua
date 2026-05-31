-- izumin さんの見た目を LazyVim 上で再現する UI セット。
-- 元ネタ: https://zenn.dev/layerx/articles/8c29b0367238b8
--   - catppuccin(mocha) カラースキーム
--   - 下のステータスライン(lualine)を消し、隅の incline にファイル情報を集約
--   - modes.nvim でモードごとに現在行の色を変える
--   - vimade で非アクティブな窓を薄くする
-- 元の LazyVim の見た目に戻したいときは、このファイルを消すか各 enabled を切り替える。

return {
  -----------------------------------------------------------------------------
  -- 1. カラースキーム: catppuccin (mocha)
  -----------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { flavour = "mocha" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },

  -----------------------------------------------------------------------------
  -- 2. 下のステータスラインを消す(incline に役割を移す)
  --    元のステータスバーが欲しければ enabled = true に戻す
  -----------------------------------------------------------------------------
  { "nvim-lualine/lualine.nvim", enabled = false },

  -----------------------------------------------------------------------------
  -- 3. incline.nvim: 画面隅にファイル名・アイコン・診断をフロート表示
  -----------------------------------------------------------------------------
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    config = function()
      local ok, palette = pcall(require, "catppuccin.palettes")
      local C = ok and palette.get_palette("mocha") or {}
      local devicons = require("nvim-web-devicons")

      local function diagnostics(props)
        local icons = { Error = "󰅚 ", Warn = "󰀪 ", Info = " ", Hint = "󰌶 " }
        local colors = { Error = C.red, Warn = C.yellow, Info = C.sky, Hint = C.teal }
        local label = {}
        for _, sev in ipairs({ "Error", "Warn", "Info", "Hint" }) do
          local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[sev:upper()] })
          if n > 0 then
            table.insert(label, { icons[sev] .. n .. " ", guifg = colors[sev] })
          end
        end
        return label
      end

      require("incline").setup({
        window = {
          margin = { vertical = 0, horizontal = 1 },
          padding = 2,
          winhighlight = {
            active = { Normal = "Normal" },
            inactive = { Normal = "Normal" },
          },
        },
        hide = { cursorline = true },
        render = function(props)
          local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if fname == "" then
            fname = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(fname)
          local modified = vim.bo[props.buf].modified
          local active = props.focused

          return {
            ft_icon and { " ", ft_icon, " ", guifg = ft_color } or "",
            { fname, gui = modified and "bold,italic" or "bold", guifg = active and C.text or C.overlay0 },
            modified and { " ● ", guifg = C.peach } or " ",
            diagnostics(props),
          }
        end,
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- 4. modes.nvim: モードに応じて現在行の色を変える
  -----------------------------------------------------------------------------
  {
    "mvllow/modes.nvim",
    event = "VeryLazy",
    config = function()
      local ok, palette = pcall(require, "catppuccin.palettes")
      local C = ok and palette.get_palette("mocha") or {}
      require("modes").setup({
        colors = {
          copy = C.yellow or "#f5e0dc",
          delete = C.red or "#f38ba8",
          insert = C.green or "#a6e3a1",
          visual = C.mauve or "#cba6f7",
        },
        line_opacity = 0.4,
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- 5. vimade: 非アクティブな窓を薄くする
  -----------------------------------------------------------------------------
  {
    "tadaa/vimade",
    event = "VeryLazy",
    opts = {
      fadelevel = 0.6,
    },
  },

  -----------------------------------------------------------------------------
  -- 6. noice: cmdline を画面下から消す(LazyVim 内蔵 noice の設定を上書き)
  -----------------------------------------------------------------------------
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      vim.opt.cmdheight = 0
      vim.opt.laststatus = 0 -- 下のステータスライン行ごと消す(incline に集約)
      return opts
    end,
  },
}
