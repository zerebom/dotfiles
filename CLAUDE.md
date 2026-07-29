# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing shell configurations, development tools, and editor settings across macOS and Linux systems.

## Key Commands

### Installation
```bash
# Clone and install dotfiles
git clone git@github.com:zerebom/dotfiles.git
make install

# For Linux systems, install dependencies first
./install.sh
```

### Makefile Commands
- `make install` - Create symlinks from dotfiles to home directory
- `make clean` - Remove symlinks and repository
- `make list` - Show dotfiles that will be installed
- `make help` - Display available commands

## Architecture

### Core Structure
The repository uses a symlink-based approach where configuration files are stored in `~/.dotfiles/` and symlinked to their expected locations in the home directory.

## CRITICAL: 設定修正は必ずこのリポジトリ内のソースを編集する（ホーム側の実ファイルを直接いじらない）

nvim / zsh などの設定修正を任されたとき、**ホームディレクトリ側の適用先（`~/.config/nvim`、`~/.zshrc` 等）を直接書き換えてはいけない**。必ずこのリポジトリ内のソースを編集し、反映手順を経てリンク先 / 適用先に波及させる。リンク先や適用後の実ファイルを直接いじると git 管理から外れ、変更が追跡できなくなる。

このリポジトリは **2つの管理方式が混在** しているので、対象ごとに編集場所と反映方法が違う。

### 1. nvim（symlink 方式）
- 実体は **リポジトリ直下の `nvim/`**。`~/.config/nvim` → `<repo>/nvim` の symlink（`home/run_once_after_setup-nvim-symlink.sh.tmpl` が張る）。
- **`<repo>/nvim/...` を直接編集すれば、symlink 経由でそのまま反映される**（`make` 等の追加操作は不要）。
- `~/.config/nvim/...` を「別ファイル」として開いて編集しない（symlink を踏んでいるだけだが、混乱と事故の元）。

### 2. zsh / ghostty / karabiner / claude 設定など（chezmoi 方式）
- source-state は **`home/` 配下**（`.chezmoiroot` = `home`）。chezmoi 命名規則でファイル名が決まる:
  - `~/.zshrc` ← `home/dot_zshrc`、`~/.zshenv` ← `home/dot_zshenv.tmpl`
  - `~/.zsh/aliases.zsh` ← `home/dot_zsh/aliases.zsh`
  - `~/.config/ghostty/config` ← `home/dot_config/ghostty/config`
  - `~/.config/herdr/config.toml` ← `home/dot_config/herdr/config.toml`
  - `~/.claude/...` ← `home/dot_claude/...`
  - `*.tmpl` は Go テンプレート。`{{ }}` を壊さないよう注意。
- **`home/dot_*` のソースを編集 → `make apply`（= `chezmoi apply`）で反映**する。ホーム側の適用後ファイルを直接編集しない。
- 反映前に `make diff`（= `chezmoi diff`）で差分を確認できる。
- 管理対象パスは `make list`（= `chezmoi managed`）で確認できる。
- 注意: リポジトリ直下にも `.zshrc` / `.zsh` 等が残っているが、これは旧 symlink 方式の名残。chezmoi 管理対象の zsh 系は `home/dot_zshrc` / `home/dot_zsh/` が正。どちらが現在ホームに効いているか不明なときは `readlink ~/.zshrc` と `make list` で確認すること。

### 逆同期が要るファイル（アプリ自身が適用先を書き換える）

一部のツールは **適用先のファイルを自分で書き換える** ため、「ソース編集 → apply」の一方通行では管理できない。`chezmoi status` で drift（`MM` 表示）を検知したら、ホーム側の変更をソースへコピー（逆同期）してからコミットする。

- `~/.config/herdr/config.toml`: herdr が onboarding フラグや設定 UI の変更を直接書き込む
- `~/.claude/settings.json`: Claude Code 本体・`herdr integration install claude` が書き込む
- karabiner / Cursor / ssh なども同種。`bin/capture-*` スクリプト（`make capture-claude` 等）が吸い上げ用

**注意: `make apply` は `--force` 付きで全ファイルに波及する。** drift がある状態で叩くと、ホーム側の新しい変更が古いソースで上書きされて消える。apply 前に必ず `chezmoi status` を確認し、drift があるファイルは先に逆同期するか、`chezmoi apply <対象パス>` で対象を絞って適用する。

### 共通ルール
- 編集後は `git status` / `git diff` で **リポジトリ内に差分が出ていること** を確認する。差分が出ていなければ、ホーム側の実ファイルを誤って編集している可能性がある。
- 要するに: **「リポジトリ内のソースを直す → (nvim は symlink で自動 / chezmoi は `make apply` で) リンク先・適用先に波及」** が正しいフロー。適用先の実ファイルを直接いじるのは NG。

## シークレット / API キーの扱い

API キーやトークンなどの秘密情報は **リポジトリにコミットしない**。`home/dot_zshrc` に直接 `export FIGMA_API_KEY=...` のように書くと chezmoi 経由で git 管理に入りコミットされてしまうため禁止。

代わりに **chezmoi 管理外のローカル専用ファイル** `~/.config/zsh/secrets.zsh` に鍵の実体を手置きし、`home/dot_zshrc` 側には鍵を含まない source 行だけをコミットする運用にしている。

- 鍵の実体（各マシンで手置き、コミットされない）:
  ```bash
  mkdir -p ~/.config/zsh
  cat > ~/.config/zsh/secrets.zsh <<'EOF'
  export FIGMA_API_KEY="figd_..."
  EOF
  chmod 600 ~/.config/zsh/secrets.zsh
  ```
- 読み込み側（`home/dot_zshrc` にコミット済み・存在すれば読む）:
  ```zsh
  [[ -f "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"
  ```
- `~/.config/zsh/` は `home/` 配下ではないため chezmoi の管理対象外。`make list`（= `chezmoi managed`）に出てこないことが「コミットされない」ことの確認になる。
- さらに堅くするなら macOS Keychain（`security` コマンド）や 1Password CLI + chezmoi template（`{{ onepasswordRead ... }}`）も選択肢。

### Zsh Configuration
- **`.zshrc`** - Main configuration that loads modular components
- **`.zshenv`** - Environment setup (PATH, tool initialization)
- **`.zsh/`** directory contains modular configs:
  - `aliases.zsh` - Command aliases (git, docker, etc.)
  - `exports.zsh` - Environment variables
  - `function.zsh` - Custom shell functions
  - `fzf.zsh` - FZF integration
  - `prompt.zsh_v2` - Prompt configuration

### Key Integrations
- **Package Managers**: Homebrew (macOS), apt (Linux)
- **Shell Tools**: Starship prompt, FZF, zinit (plugin manager)
- **Development Tools**: pyenv, rbenv, nvm, cargo, direnv
- **Editors**: Neovim configuration in `nvim/` and `.vim/`

### Special Features
- **ghq Integration**: Repository management with tmux session handling
- **Custom Key Bindings**: 
  - `Ctrl-R` for fuzzy history search
  - `Ctrl-G` for ghq session management
  - Vi-mode with emacs keybindings preserved
- **Auto-completion**: Enhanced with zsh-completions and tool-specific completions

## Important Notes
- The repository tracks changes on the `dev` branch and merges to `master`
- Installation creates symlinks rather than copying files
- Linux installation requires running `install.sh` for dependency setup
- Zsh history is configured with deduplication and extensive storage