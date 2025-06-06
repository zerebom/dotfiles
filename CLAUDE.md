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