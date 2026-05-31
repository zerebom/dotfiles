-- Snacks の lsp_symbols(<leader>ss) のシンボルフィルタを調整する。
-- デフォルトの許可リストには Variable / Constant が含まれず、
-- `const Foo = () => {}` 形式の React コンポーネントが目次に出ない
-- (「No results found for lsp_symbols」になる)。
-- Variable / Constant を足してアロー関数コンポーネントも表示する。
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          lsp_symbols = {
            filter = {
              default = {
                "Class",
                "Constructor",
                "Enum",
                "Field",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                "Package",
                "Property",
                "Struct",
                "Trait",
                "Variable", -- アロー関数の const コンポーネントを表示するため追加
                "Constant", -- 同上
              },
            },
          },
        },
      },
    },
  },
}
