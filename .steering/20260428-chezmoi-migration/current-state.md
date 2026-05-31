# 旧仕事PC `CMPC0113` 現状スナップショット

> Phase A-C 実行前に旧PC で取得した実環境情報。AI 引き継ぎ時の真実情報源として使う。

## 1. リポジトリ情報

- **パス**: `/Users/zerebom/.dotfiles`
- **GitHub remote**: `git@github.com:zerebom/dotfiles.git`
- **現在のブランチ**: `master`
- **これから切るブランチ**: `feat/chezmoi-migration`

## 2. シークレット監査結果

### git 管理外（既に保護済み）

`.gitignore` で除外されている：

```
**/plugged/**
.vercel
.github_token
.zsh/secrets.zsh
```

### 実存するシークレット

#### `.zsh/secrets.zsh`（gitignore済み、移行対象）

```bash
# ローカルでの確認結果（ファイル形式）
export GEMINI_API_KEY="<実値あり>"
```

→ **新PCでは keychain から取得する形に変える**：
```bash
security add-generic-password -s gemini-api-key -a zerebom -w "<key>"
```
テンプレ側：
```bash
{{- if env "CI" }}
export GEMINI_API_KEY="ci-fake-key"
{{- else }}
export GEMINI_API_KEY="{{ keyring "gemini-api-key" "zerebom" | default "" }}"
{{- end }}
```

#### `.github_token`（リポジトリ直下）

- ファイル形式: シェルスクリプト（`# GitHub Personal Access Token` で始まる、`source` で読まれる）
- **`.zshenv:30` で `source $HOME/.dotfiles/.github_token` されている**
- **git 履歴調査結果**: `git log --all --oneline -- .github_token` → 出力なし → **履歴に存在しない**

#### **重要な設計修正**

当初 design.md / tasklist.md Phase H で「`.github_token` を git filter-repo で履歴削除＋force push」と記載していたが、**履歴に存在しないため不要**。手順を簡略化：

1. ❌ ~~`git filter-repo` での履歴削除~~ → 不要
2. ❌ ~~force push~~ → 不要
3. ✅ GitHub 上で当該 token を revoke
4. ✅ 新トークン発行 → keychain 投入
5. ✅ ローカルの `.github_token` ファイル削除（新PCでは `chezmoi apply` で生成しない）
6. ✅ `.zshenv.tmpl` から `source $HOME/.dotfiles/.github_token` の行を削除し、keyring 取得に置換

## 3. アプリ設定の実物確認

| 項目 | 状態 | 移行方針 |
|---|---|---|
| `~/.config/karabiner/karabiner.json` | 9836 bytes 存在、mode 0600 | `chezmoi add` で `home/dot_config/karabiner/karabiner.json` に取り込み |
| `~/.config/nvim` | symlink → `/Users/zerebom/.dotfiles/nvim` | 新PCでも `run_once_after_setup-nvim-symlink.sh.tmpl` で同じ symlink を再作成 |
| `~/.config/ghostty` | symlink → `/Users/zerebom/.dotfiles/.config/ghostty` | chezmoi 配下に取り込み（`home/dot_config/ghostty/config.tmpl`） |
| `~/.claude/CLAUDE.md` | symlink → `/Users/zerebom/.dotfiles/.claude/global.md` | `home/dot_claude/CLAUDE.md` に取り込み |
| `~/.claude/settings.local.json` | gitignore 想定（要確認）、1391 bytes | プロジェクト固有設定なので chezmoi 管理外（環境ごとに作る） |

## 4. Cursor / VS Code 拡張機能

- **Cursor**: 137個（`.steering/.../cursor-extensions.txt` に保存済み）
- **VS Code**: 125個（`.steering/.../vscode-extensions.txt` に保存済み）

新PCでは `run_onchange_install-cursor-extensions.sh.tmpl` 内で：
```bash
while IFS= read -r ext; do
  cursor --install-extension "$ext" || true
done < "${CHEZMOI_SOURCE_DIR}/.assets/cursor-extensions.txt"
```
の形を取る。拡張機能リストは `home/.assets/cursor-extensions.txt` として chezmoi 管理外（`.chezmoiignore` で除外せず、ただのデータファイルとして扱う）。

## 5. macOS カスタムショートカット

`defaults find NSUserKeyEquivalents` の出力 → **空**（`macos-shortcuts.txt` が0行）

→ 退避ファイル `home/private_dot_macos-shortcuts.txt` の作成は **不要**。design.md / tasklist.md の該当タスクをスキップ可能。

## 6. cmux のビルド情報

- バンドル ID: 不明（要確認）
- ソース: `~/ghq/` 配下にも見つからず、出所不明
- Info.plist には BuildMachineOSBuild 等しかなく、リポジトリ URL 情報なし

→ **chezmoi 自動セットアップから除外**。新PCで必要になった時点で個別対応。`run_once_install-cmux.sh.tmpl` の作成タスクは **保留**（tasklist.md Phase E から外す）。

## 7. `.zsh/` ディレクトリの実構成

```
.zsh/
├── aliases.zsh           # 普通のalias定義、テンプレ化不要
├── anyframe/             # ディレクトリ。中身要確認
├── exports.zsh           # PATH等の通常設定（シークレットなし、要テンプレ化）
├── function.zsh          # シェル関数
├── fzf.zsh               # FZF統合
├── prompt.zsh_v2         # プロンプト
└── secrets.zsh           # gitignore済み、シークレット入り
```

`exports.zsh` には Wantedly 時代のレガシー PATH（`$HOME/.wantedly/bin`）あり。`/Applications/Postgres.app/...` も古い。新PC移行時にクリーンアップ機会。

## 8. `.zshenv` の実構成

```bash
# 主要な処理
- /usr/local/bin/brew shellenv（Apple Silicon では /opt/homebrew が正解 → 要修正）
- source $HOME/.zsh/exports.zsh
- source $HOME/.zsh/aliases.zsh
- [[ -f .zsh/secrets.zsh ]] && source secrets.zsh
- [ -f .dotfiles/.github_token ] && source .github_token   # ← 削除対象
- rbenv init
- direnv hook zsh
- source $HOME/.cargo/env
```

**修正点**:
- `brewPrefix="/usr/local"` → `brewPrefix="/opt/homebrew"`（Apple Silicon）。テンプレ化して `{{- if eq .chezmoi.arch "arm64" }}` 分岐
- `.github_token` 読み込み行を削除し、keychain 経由に切替
- pyenv/nodenv/jenv のコメントアウト部分は cutover 時に削除

## 9. 既存の symlink 状態（cutover で整理対象）

`/Users/zerebom/.dotfiles/Makefile` が作る symlink：
- `~/.zshrc → ~/.dotfiles/.zshrc`
- `~/.zshenv → ~/.dotfiles/.zshenv`
- `~/.zsh → ~/.dotfiles/.zsh`
- `~/.tmux.conf → ~/.dotfiles/.tmux.conf`
- `~/.starship.toml → ~/.dotfiles/.starship.toml`
- `~/.vimrc → ~/.dotfiles/.vimrc`
- `~/.config/ghostty → ~/.dotfiles/.config/ghostty`
- `~/.claude/CLAUDE.md → ~/.dotfiles/.claude/global.md`
- `~/bin → ~/.dotfiles/bin`（`bin/` は既に削除済み、git status で `D bin`）

cutover 時にすべて削除し、chezmoi 生成ファイルに置換する。

## 10. ホスト名・computer name

- `hostname -s`: `CMPC0113`
- `scutil --get ComputerName`: 旧PCで実行して結果を `.chezmoi.toml.tmpl` の判定に使う（実機で `scutil --get ComputerName` を叩けば判明、現状の出力は未取得）

## 11. backup ファイル群（cutover時に削除）

```
.zshrc.backup.
.zshrc.backup.20250812
.config/ghostty/config.bak
.vim.bak/
nvim.bak/
.claude/settings.local.json   # gitignore 確認後に判断
LaunchAgents/                 # 内容確認後に判断
```

## 12. アプリ棚卸し最終確定リスト

`app-inventory.md` を真とする。Cask 32 + mas 6 = 38個。
