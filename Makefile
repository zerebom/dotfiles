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

capture-macos: ## 現環境の macOS defaults 値を YAML に書き戻す（旧PC で叩く想定）
	@$(SOURCE_DIR)/bin/capture-macos-defaults

capture-macos-diff: ## 上の --diff（書かずに差分のみ表示）
	@$(SOURCE_DIR)/bin/capture-macos-defaults --diff

raycast-import: ## Raycast 設定インポートダイアログを起動
	@$(SOURCE_DIR)/bin/apply-raycast-settings

help: ## このヘルプ
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: install apply diff list capture-macos capture-macos-diff raycast-import help
