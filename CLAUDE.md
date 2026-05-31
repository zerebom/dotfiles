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
  - `~/.claude/...` ← `home/dot_claude/...`
  - `*.tmpl` は Go テンプレート。`{{ }}` を壊さないよう注意。
- **`home/dot_*` のソースを編集 → `make apply`（= `chezmoi apply`）で反映**する。ホーム側の適用後ファイルを直接編集しない。
- 反映前に `make diff`（= `chezmoi diff`）で差分を確認できる。
- 管理対象パスは `make list`（= `chezmoi managed`）で確認できる。
- 注意: リポジトリ直下にも `.zshrc` / `.zsh` 等が残っているが、これは旧 symlink 方式の名残。chezmoi 管理対象の zsh 系は `home/dot_zshrc` / `home/dot_zsh/` が正。どちらが現在ホームに効いているか不明なときは `readlink ~/.zshrc` と `make list` で確認すること。

### 共通ルール
- 編集後は `git status` / `git diff` で **リポジトリ内に差分が出ていること** を確認する。差分が出ていなければ、ホーム側の実ファイルを誤って編集している可能性がある。
- 要するに: **「リポジトリ内のソースを直す → (nvim は symlink で自動 / chezmoi は `make apply` で) リンク先・適用先に波及」** が正しいフロー。適用先の実ファイルを直接いじるのは NG。

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