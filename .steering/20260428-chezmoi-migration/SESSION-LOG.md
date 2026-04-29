# セッションログ — 2026-04-29 (CMPC0397 / new work PC)

このセッションで何が起きたか時系列で記録。次セッションが「なぜ今この形になっているか」を理解できる粒度で残す。

## 環境

- このセッションが動いた PC: `CMPC0397`（新仕事PC、Apple Silicon、macOS 26.4.1）
- ブランチ: `feat/chezmoi-migration` を `git pull` して着手
- 開始時点の commit: `e203fac docs(steering): refresh HANDOFF.md after Phase E/G/K-1 completion`
- 終了時点の commit: capture-symbolichotkeys 追加（要 push）

## 流れ

### 1. 環境確認 → CMPC0397 と判明

- ユーザー指示: 「`feat/chezmoi-migration` を pull して steering の作業を進めて」
- `chezmoi --version` で chezmoi が未インストールと判明（`brew install chezmoi` で復旧）
- `scutil --get ComputerName` → **`CMPC0397`** = 新PC上で動いてることを確認
- HANDOFF.md は「旧PC `CMPC0113` で構築・検証中」前提で書かれていたので、認識を更新して
  Phase I（新PC実機検証）に進むことに

### 2. Phase D dry-run（Brewfile 検証）

- `chezmoi execute-template` で `run_onchange_before_install-packages-darwin.sh.tmpl` を展開
- `brew bundle check` 実行：syntax OK、未インストール扱いは想定通り（フレッシュPC）
- tasklist.md の Phase D dry-run 欄を完了マーク

### 3. Phase I 本番（chezmoi apply on CMPC0397）

新PCに `chezmoi apply --force` を打って初期セットアップ。4 回のイテレーションが必要だった:

1. **1回目**: `autoraise` cask が Homebrew に存在せず brew bundle 即死 → packages.yaml から除外
2. **2回目**: `mactex-no-gui` が 5GB ダウンロード律速で進まない → 除外（必要時手動）。
   さらに sudo 必須 cask 3 個（karabiner-elements / zoom / docker-desktop）が非対話環境で
   全部失敗 → brew bundle が exit 1 → スクリプトが exit 1 → dotfiles 配置されず
3. **3回目**: `run_onchange_before_install-packages-darwin.sh.tmpl` で brew bundle を `|| echo` で
   握り潰す形に変更、mas は独立ブロックで `mas account` ガード。dotfiles は配置されたが、
   `install-cursor-extensions.sh` が 1 個の rename ext (`austenc.tailwind-docs`) で全体停止 →
   nvim symlink 等の後続スクリプトに到達せず
4. **4回目**: `install-cursor-extensions.sh.tmpl` / `install-vscode-extensions.sh.tmpl` も
   個別失敗を `|| failed+=()` で蓄積する形に変更。ようやく完走

最終結果:
- dotfiles 24 ターゲット全配置 ✅
- brews 30/30、casks 25/29（残り 3 個は sudo 必要）、cursor ext 106/137、vscode ext 125/125
- nvim symlink ✅（`~/.config/nvim → ~/.local/share/chezmoi/nvim`）
- starship + git email = `higuchi.kokoro@commune.co.jp` で動作確認 ✅

⚠️ 重要：source-state を `~/.local/share/chezmoi → ~/.dotfiles` の symlink で済ませた
（フル `chezmoi init zerebom --apply` のクローンは行わず、既存 clone を再利用）。
これで chezmoi.toml は init で自動生成、source は既存のまま。

コミット: `8270171 feat(chezmoi): Phase I - new PC (CMPC0397) で実機検証 + 失敗許容化`

### 4. ユーザー指摘 — fzf が無くて zsh 起動エラー

`zsh -ic ":"` で `command not found: fzf` が出てたのを発見。
全 shell 設定をスキャンしたら以下が `packages.yaml` から漏れていた:

- `fzf`（複数の関数で必須）
- `coreutils`（`alias date='/usr/local/bin/gdate'` で参照）
- `zinit`（zsh プラグインマネージャ、.zshrc で source）

ついでにハードコード `/Users/zerebom/...` パスを `$HOME` 化、`.cargo/env` を `-f` ガード。

コミット: `1c665dd feat(chezmoi): macOS defaults を継続移行可能に + zsh 雑多 fix`

### 5. ユーザー指摘 — macOS 個別設定（Raycast / KeyRepeat 等）も引き継ぎたい、しかも継続的に

ここでスコープが拡大。当初設計では現実的に取り扱えていなかった「アプリ独自データ + macOS defaults」
を chezmoi 配下に **再現可能なフレームワーク** で取り込む方針に。

設計:
1. `home/.chezmoidata/macos-defaults.yaml` を **single source of truth** にする
2. `bin/capture-macos-defaults` で **現環境 → YAML** に書き戻し
3. `home/run_onchange_after_apply-macos-defaults.sh.tmpl` で **YAML → defaults write**
4. ループ運用：旧PCで `make capture-macos` → push → 新PCで `chezmoi apply`

key の追加要望（"他にもあるんじゃないの"）への対応として、**16 ドメイン × 24 キー** をシード。
Hot Corners / Spotlight も追加。

### 6. スコープ拡大 — 高〜中優先の引き継ぎ対象を継続移行可能に

ユーザー指示: 「中までやってほしい。vscode は大丈夫」

VSCode 抜きで以下を `bin/capture-*` + `home/run_*` でフレームワーク化:

- Cursor user settings（chezmoi 直接ミラー）
- Claude Code カスタム（同上）
- SSH config（同上）
- Dock pinned apps（plist export/import）
- Login Items（YAML + osascript）
- ghq クローン済みリポ（一括 `xargs ghq get`）

`bin/capture-all` で全部まとめて叩けるようにし、`Makefile` に `make capture` を追加。
ドキュメント `docs/migration.md` で運用フローを文書化。

コミット: `a7a3e52 feat(chezmoi): 高〜中優先の引き継ぎ対象を継続移行可能に`

### 7. ユーザー操作 — 旧PCで初回 capture & push

ユーザーが CMPC0113 側で `make capture-macos` と Raycast Export を実行、commit & push:

- `78abf58 chore: capture macos-defaults from CMPC0113`
- `3c23ece chore: capture raycast-settings.rayconfig from CMPC0113`

CMPC0397 側で git pull → rebase → `chezmoi apply` で **実機反映**:
- KeyRepeat 2、InitialKeyRepeat 15、AutoCapitalization false、Screenshot location `~/ScreenShot` 等
- `applied=14, skipped=14`（残り null は今後 capture 範囲を広げて埋めていく）
- Raycast の `.rayconfig`（2.2MB）も commit 済み、`make raycast-import` で取り込み

### 8. ユーザー指摘 — ユーザ登録辞書も

System Settings → Keyboard → Text Replacements（macOS では日本語IMEの単語登録もここに同居）を追加。
`NSUserDictionaryReplacementItems` キーを `plutil -extract` で plist 化、apply 時に PlistBuddy 経由で
書き戻す。

コミット: `534b5e4 feat(chezmoi): Text Replacements / 日本語IMEユーザ辞書も継続移行`

### 9. Cmd+Space → Raycast 化

新PCで Spotlight が Cmd+Space を握ったままで Raycast の hotkey が効かなかったので:

1. `PlistBuddy` で `~/Library/Preferences/com.apple.symbolichotkeys.plist` の id 64 (Show Spotlight)
   を `enabled = false` に
2. `activateSettings -u` で即時反映
3. Raycast を再起動して Cmd+Space を取り直し

→ ユーザー確認「出たー」✅

これも継続移行のため `bin/capture-symbolichotkeys` + `run_onchange_after_apply-symbolichotkeys.sh.tmpl`
でフレームワーク化。`defaults export/import` 方式。

### 10. このログ + HANDOFF.md 更新

「これまでの作業を記録として残しておいてほしい」リクエストでこのファイルを作成。

## 学び

- **chezmoi は基本シンプルだが、「失敗許容」が必要なシーンが多い**:
  brew bundle / cask install / cursor extensions / mas — 全部失敗を握り潰す形にしないと
  apply 全体が止まって dotfiles すら配置されない。
- **run_once と run_onchange の使い分け**:
  - run_once: ghq の一括 clone（一度成功すれば再走らせる必要なし）
  - run_onchange: macOS defaults / Dock / Login Items / Text Replacements / SymbolicHotKeys
    （YAML/plist の hash が変われば再適用、冪等）
- **アプリ標準の Export/Import を尊重**:
  Raycast は plist で取れないので `.rayconfig` を commit + GUI Import。CLI 化を試みず素直に。
- **`stat` template 関数は便利**:
  capture 前は YAML/plist が無いので、apply スクリプトを `{{- if stat $path }}` で
  ガードできる。完全空状態でも `chezmoi apply` が exit 0 で通る。
- **`hasKey` は data オブジェクト用**:
  ファイルの存在チェックは `stat`、chezmoi data の key 存在チェックは `hasKey . "loginItems"`。
  混同すると `map has no entry for key` エラー。
- **ハードコード `/Users/<name>/...` は地雷**:
  zerebom → higuchi.kokoro で複数箇所を修正。今後は `$HOME` を徹底。

## 残タスク

### 旧PC `CMPC0113` 側（ユーザー手動）

```bash
cd ~/.dotfiles && git pull
make capture     # 新規追加分（cursor / claude / ssh / dock / login-items / ghq /
                 # text-replacements / symbolichotkeys）を一括取り込み
git diff home/   # 確認
git commit -am "chore: refresh captures from CMPC0113"
git push
```

### 新PC `CMPC0397` 側（残り）

- `brew install --cask zoom docker-desktop`（sudo パスワード手入力必須）
- App Store サインイン → `mas install` 6 個
- keychain 投入（github-token / gemini / anthropic）

### chezmoi 移行プロジェクト

- Phase J: master cutover、PR 作成
- Phase H: 旧PC側で chezmoi apply して symlink 構造置換、`.github_token` 削除等
- Phase K残: README / CLAUDE.md を chezmoi 前提に書き換え
