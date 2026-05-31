-- ghq リポジトリ一覧を Snacks.picker で開く(旧: telescope-ghq からの移行)。
-- <Space>gr で `ghq list` の結果を一覧表示し、選んだリポジトリへ移動して
-- そのままファイル検索(Snacks files)を開く。
-- Telescope への依存をなくし、picker を Snacks に統一するためのファイル。
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<Space>gr",
        function()
          Snacks.picker.pick({
            source = "ghq",
            title = "ghq repositories",
            finder = function()
              local paths = vim.fn.systemlist({ "ghq", "list", "--full-path" })
              if vim.v.shell_error ~= 0 then
                Snacks.notify.error("ghq list に失敗しました(ghq は入っていますか?)")
                return {}
              end
              return vim.tbl_map(function(path)
                return { text = path, file = path, dir = true }
              end, paths)
            end,
            format = "file",
            confirm = function(picker, item)
              picker:close()
              if not item then
                return
              end
              -- 選んだリポジトリをこのタブのカレントディレクトリにして
              vim.cmd.tcd(item.file)
              -- そのままファイル検索を開く
              Snacks.picker.files()
            end,
          })
        end,
        desc = "ghq repositories",
      },
    },
  },
}
