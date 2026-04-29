SOURCE_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CHEZMOI    := $(shell command -v chezmoi)

.DEFAULT_GOAL := help

install: ## このリポジトリを chezmoi の source-state にして apply
	@if [ -z "$(CHEZMOI)" ]; then \
		echo "chezmoi not found. Install with: brew install chezmoi"; exit 1; \
	fi
	@if [ ! -e $$HOME/.local/share/chezmoi ]; then \
		mkdir -p $$HOME/.local/share; \
		ln -s $(SOURCE_DIR) $$HOME/.local/share/chezmoi; \
		echo "linked: $$HOME/.local/share/chezmoi -> $(SOURCE_DIR)"; \
	fi
	@chezmoi init --source=$(SOURCE_DIR)
	@chezmoi apply --force --source=$(SOURCE_DIR)

apply: install ## install のエイリアス

diff: ## chezmoi で現状との差分を表示
	@chezmoi diff

list: ## chezmoi 管理対象パスを表示
	@chezmoi managed

capture: ## 現環境の各種設定を repo に吸い上げる（旧PC で叩く）
	@$(SOURCE_DIR)/bin/capture-all

capture-macos: ## macOS defaults だけ吸い上げ
	@$(SOURCE_DIR)/bin/capture-macos-defaults

capture-macos-diff: ## macOS defaults 差分のみ表示（書かない）
	@$(SOURCE_DIR)/bin/capture-macos-defaults --diff

capture-cursor: ## Cursor の user settings を吸い上げ
	@$(SOURCE_DIR)/bin/capture-cursor

capture-claude: ## Claude Code カスタム（agents/commands/skills/output-styles）吸い上げ
	@$(SOURCE_DIR)/bin/capture-claude

capture-dock: ## Dock の plist を吸い上げ
	@$(SOURCE_DIR)/bin/capture-dock

capture-login-items: ## Login Items 一覧を吸い上げ
	@$(SOURCE_DIR)/bin/capture-login-items

capture-ghq: ## ghq でクローン済みの repo 一覧を吸い上げ
	@$(SOURCE_DIR)/bin/capture-ghq

capture-ssh: ## ~/.ssh/config を吸い上げ（鍵は除外）
	@$(SOURCE_DIR)/bin/capture-ssh

raycast-import: ## Raycast 設定インポートダイアログを起動
	@$(SOURCE_DIR)/bin/apply-raycast-settings

help: ## このヘルプ
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: install apply diff list \
	capture capture-macos capture-macos-diff capture-cursor capture-claude \
	capture-dock capture-login-items capture-ghq capture-ssh \
	raycast-import help
