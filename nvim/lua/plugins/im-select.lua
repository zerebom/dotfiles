-- im-select.nvim: モード切替に連動して macOS の入力ソースを自動で切り替える。
-- 「日本語入力のまま挿入モードを抜けて hjkl が『あいうえ』になる」問題を解消する。
--   - 挿入モードを抜ける/Neovim起動/フォーカス復帰 → 英語(ABC)に戻す
--   - 挿入モードに入る → 直前に使っていた入力ソース(日本語など)に復帰
-- 外部ツール macism が必要(`brew install laishulu/homebrew/macism` で導入済み)。
-- 参考: https://www.runfunrun.dev/posts/nvim-japanese
return {
  {
    "keaising/im-select.nvim",
    event = "VeryLazy",
    opts = {
      -- 通常時(ノーマルモード等)に戻す入力ソース = 英語
      default_im_select = "com.apple.keylayout.ABC",
      -- macOS 用の入力ソース切替コマンド
      default_command = "/opt/homebrew/bin/macism",
      -- このイベントで default_im_select(英語) に戻す
      set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
      -- このイベントで「挿入モードを抜ける前の入力ソース」に復帰する
      set_previous_events = { "InsertEnter" },
      -- 起動時に macism が見つからなくても静かに無効化(エラーを出さない)
      keep_quiet_on_no_binary = false,
    },
  },
}
