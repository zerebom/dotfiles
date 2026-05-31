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

## CRITICAL: 編集は必ずこのリポジトリ内のファイルに対して行う

このリポジトリは symlink ベースで運用されている。各設定ファイル / ディレクトリ（例: `~/.config/nvim` → `<repo>/nvim`、`~/.zshrc` → `<repo>/.zshrc`）は、ホームディレクトリ側がリンクで、**実体はこのリポジトリ内**にある。

そのため nvim / zsh などの設定修正を任されたときは、以下を厳守すること:

- **必ずこのリポジトリ内のファイルを編集する**（例: `<repo>/nvim/lua/...`、`<repo>/.zshrc`）。symlink 元を直すことで、リンク先（`~/.config/nvim` 等）にも自動的に修正が波及する。
- **リンクの実体パス（ホーム側の解決済みパス）を「別ファイル」として直接書き換えない**。symlink を踏んでホーム側を編集しても結局リポジトリ内ファイルを編集しているだけだが、リポジトリ外に実体コピーを作る／リンクを実ファイルに置き換えるような操作は禁止。それをやると git 管理から外れ、変更が追跡できなくなる。
- 新規に設定ファイル/ディレクトリを追加した場合は、リポジトリ直下に置いたうえで `make install`（`ln -snf` でホームに symlink を張る）で反映する。
- 編集後は `git status` / `git diff` でリポジトリ内に差分が出ていることを確認する。差分が出ていなければ、リポジトリ外の実ファイルを誤って編集している可能性がある。

要するに: **「dotfiles（リポジトリ実体）を直す → symlink 経由でリンク先に波及」** が正しいフロー。リンク先を実ファイルとして直接いじるのは NG。

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