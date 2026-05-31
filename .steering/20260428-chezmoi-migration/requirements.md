# chezmoi移行 + Brewfile/mas統合による「30分PCセットアップ」基盤

## 背景

- 会社から新仕事PC（hostname: `CMPC0397`）が支給され、旧仕事PC（hostname: `CMPC0113`）からの移行が直近のゴール。今回の移行で「30分セットアップ」基盤を整え、次回以降も同じ仕組みで再現できるようにする。
- 現状の dotfiles は `Makefile` + `ln -s` 方式で運用しており、以下の限界がある：
  - **シークレット平文混入**: `.github_token` がリポジトリ直下にコミット済み（要対処）
  - **ホスト分岐なし**: 仕事Mac / 個人Mac / Linux で同一設定が配られる
  - **アプリ管理不在**: `Brewfile` がなく、CLI/GUI アプリは毎回手動で `brew install`
  - **手動同期の事故跡**: `.zshrc.backup.20250812` 等のバックアップファイルが残置
  - **CIなし**: 設定が壊れているか push 時点で気付けない
- 並行して、参考記事の知見を取り込む：
  - GUIアプリも `brew install --cask` で管理し、`brew bundle dump --describe` で再現可能に
  - macOSのカスタムキーバインドは `defaults find NSUserKeyEquivalents` で書き出して退避
  - Apple Silicon の `/opt/homebrew` 移行も初期化スクリプトで考慮

## 目標

1. 新仕事PC `CMPC0397` で `chezmoi init zerebom && chezmoi apply` → `brew bundle install` だけで GUI/CLI アプリと dotfiles が揃う状態を作る。
2. ホスト名（`CMPC0113` 旧仕事 / `CMPC0397` 新仕事 / `personal-mac` / `linux`）で設定を分岐できるテンプレート構造を整える。
3. シークレットを Git にコミットせず、macOS Keychain 経由で chezmoi テンプレートに注入する。
4. GitHub Actions で `chezmoi apply` の dry-run CI を回し、テンプレート構文エラーを検知する。

## 成功基準

- **定量基準（Done の定義）**: 新仕事PC `CMPC0397` で、以下を満たす：
  - `git`/`Homebrew` 導入後、**30分以内**に CLI 環境（zsh, neovim, tmux, ghostty）+ GUI アプリ（Cursor, Ghostty, Karabiner, Raycast, cmux）が起動可能になる。
  - 上記30分の内訳目安：`chezmoi apply` ≦ 5分、`brew bundle install` ≦ 25分（ネットワーク次第）。
- **定性基準**:
  - `git grep -i 'token\|secret\|password' -- ':!.steering' ':!docs'` でシークレット平文が出ない。
  - PR上で CI（macos-latest 上の chezmoi apply）が green。
  - 旧仕事PC `CMPC0113` でも `chezmoi apply` が**破壊的変更なし**で完了する（既存環境を壊さず移行できることの確認）。

## フォールバック戦略

- **第1案が失敗（chezmoi のテンプレート展開で詰まる）** → 該当ファイルだけ chezmoi 管理から外し、`run_once_` スクリプトで個別配置に切り替える。
- **それでもダメ（移行コスト > 効果）** → master の Makefile 方式に戻し、Brewfile + シークレット keychain 化だけ取り込む（Plan A 縮退）。新ブランチで作業しているので戻すのは容易。
- **CI が macos-latest で不安定** → ubuntu-latest + chezmoi の `--dry-run` のみに切り替え、Cask 系は CI 対象外にする。

## 決定事項

- **dotfiles manager**: chezmoi 採用（Plan B）。
- **移行戦略**: 新ブランチ `feat/chezmoi-migration` で並行構築 → 動作確認後に master へ cutover（A）。既存の Makefile 方式は cutover まで残す。
- **アプリ管理**: Homebrew Bundle (`Brewfile.tmpl`) + mas で CLI/GUI/AppStore を一元管理。
- **シークレット**: macOS Keychain + chezmoi の `keychain` テンプレート関数。Bitwarden/1Password は将来 Linux 対応時に再検討。
- **ホスト分岐**: `.chezmoi.hostname` で識別。
  - `CMPC0113` → 旧仕事Mac（移行元、現状の dotfiles 動作環境）
  - `CMPC0397` → 新仕事Mac（移行先・本命のテスト対象）
  - `personal-mac` → 個人Mac（hostname は実機で `hostname -s` 確認後に設計書へ追記。stub 扱い）
  - Linux 系は当面 stub のみ
- **移行の流れ**: 旧仕事PC（`CMPC0113`）で chezmoi 化 → リモートに push → 新仕事PC（`CMPC0397`）で `chezmoi init` → `chezmoi apply` で再現。
- **キーバインド退避**: `defaults find NSUserKeyEquivalents` の出力を `dot_macos-shortcuts.txt`（chezmoi 管理下）として保存。
- **`.github_token` 漏洩対処**: revoke + Keychain 化 + `git filter-repo` で履歴削除（強制 push が必要なため、cutover と同時に実施）。

## スコープ

### 含める

- `.zshrc`, `.zshenv`, `.zsh/*`, `.tmux.conf`, `.starship.toml`, `.gitignore` の chezmoi 化
- `.config/ghostty/config` の chezmoi 化（既存 symlink 置換）
- `nvim/` 全体の chezmoi 化
- `.claude/global.md` の chezmoi 化
- `Brewfile.tmpl`（CLI + Cask + mas をホスト分岐込みで定義）
- macOS Keychain 連携（`github-token` 等）
- Cursor / Karabiner-Elements / Raycast / cmux / Ghostty の設定取り込み
- macOSキーバインド退避ファイル
- GitHub Actions CI（chezmoi apply dry-run）
- 移行ドキュメント `docs/chezmoi.md`（新PCでの初期化コマンド集）

### 含めない

- iCloud/Dropbox 経由の Mackup 同期（chezmoi と機能が重複するため）
- Linux ホスト固有設定の本格対応（stub のみ。本格対応は将来タスク）
- Bitwarden/1Password CLI 連携（将来タスク）
- 移行アシスタント等の macOS 標準機能との連携
- 旧 `.zshrc.backup.*` の温存（cutover 時に削除）

## 成果物

- `.steering/20260428-chezmoi-migration/{requirements,design,tasklist}.md`
- `feat/chezmoi-migration` ブランチ上の chezmoi リポジトリ構造
- `Brewfile.tmpl`（仕事/個人Mac分岐込み）
- `home/dot_zshrc.tmpl` 等のテンプレートファイル群
- `.github/workflows/chezmoi-test.yml`
- `docs/chezmoi.md`（新PC初期化手順）
- master cutover PR
