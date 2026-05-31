# 設計書 — chezmoi移行 + Brewfile/mas統合

## 概要

既存の `Makefile` + `ln -s` 方式の dotfiles を **chezmoi** に移行し、`Brewfile.tmpl` + `mas` で GUI/CLI/AppStore アプリを一元管理する。シークレットは macOS Keychain 経由でテンプレート展開時に注入する。新仕事PC `CMPC0397` でのワンショット復元（30分以内）を Done 基準とする。

## アプローチ

### 段階移行（cutover型）

旧仕事PC `CMPC0113`（=現在の作業環境）の master を壊さず、新ブランチ `feat/chezmoi-migration` で並行構築する。検証完了後にまとめて master へ cutover する。

| フェーズ | 場所 | 内容 |
|---|---|---|
| A. ブランチ作成 | `CMPC0113` | `feat/chezmoi-migration` を切る、旧 Makefile/symlink は残す |
| B. chezmoi 初期化 | `CMPC0113` | `home/` 以下に source-state を構築（symlink は触らない） |
| C. 取り込み | `CMPC0113` | 既存 `.zshrc` 等を `chezmoi add` で取り込み、テンプレ化 |
| D. ホスト分岐 | `CMPC0113` | `.chezmoi.toml.tmpl` でホスト識別、`Brewfile.tmpl` 等に分岐 |
| E. 破壊的変更チェック | `CMPC0113` | `chezmoi diff` で生成結果と現状の差分が**意図したもののみ**であることを確認 |
| F. CI整備 | リモート | GitHub Actions で apply dry-run |
| G. シークレット剥離 | `CMPC0113` | `.github_token` revoke + Keychain 投入 + `git filter-repo` で履歴削除 |
| H. 新PC検証 | `CMPC0397` | `chezmoi init && chezmoi apply && brew bundle install` で30分タイマー |
| I. cutover | リモート | PR merge、master の旧 Makefile を削除（シンボリックリンクの残骸も整理） |

各フェーズは `tasklist.md` で個別タスク化する。

## 構成

### リポジトリディレクトリ構造（cutover後）

```
~/.dotfiles/
├── .chezmoiroot              # "home" を指定 → home/ がソースディレクトリ
├── home/                     # chezmoi の source-state（ここだけ chezmoi が触る）
│   ├── .chezmoi.toml.tmpl    # 初期化時にホスト分岐の data を生成
│   ├── .chezmoiignore        # OS別に無視するパス
│   ├── .chezmoidata/
│   │   └── packages.yaml     # brew/cask/mas をデータとして宣言
│   ├── dot_zshrc.tmpl
│   ├── dot_zshenv.tmpl
│   ├── dot_zsh/              # `.zsh/` 配下
│   │   ├── aliases.zsh
│   │   ├── exports.zsh.tmpl  # シークレット参照あり（CI ガード付き）
│   │   ├── function.zsh
│   │   ├── fzf.zsh
│   │   └── prompt.zsh_v2
│   ├── dot_tmux.conf
│   ├── dot_starship.toml
│   ├── dot_gitconfig.tmpl    # email/name をテンプレ化（個人/仕事で分岐）
│   ├── dot_config/
│   │   ├── ghostty/
│   │   │   └── config.tmpl
│   │   └── karabiner/
│   │       └── karabiner.json
│   ├── dot_claude/
│   │   └── CLAUDE.md         # = 旧 .claude/global.md
│   ├── private_dot_macos-shortcuts.txt           # defaults find 出力の退避
│   ├── run_onchange_before_install-packages-darwin.sh.tmpl  # brew bundle 実行
│   ├── run_once_install-cmux.sh.tmpl             # cmux 自前ビルド
│   ├── run_once_after_setup-nvim-symlink.sh.tmpl # ~/.config/nvim を symlink
│   └── run_onchange_install-vscode-extensions.sh.tmpl  # 拡張機能リスト変更時に再実行
├── nvim/                     # chezmoi 管理外（外部ツールで管理）
│   └── ... (LazyVim 一式)
├── .github/
│   └── workflows/
│       └── chezmoi-test.yml
├── docs/
│   ├── chezmoi.md            # 新PC初期化手順（新規）
│   ├── cmux.md               # 既存
│   ├── nvim.md               # 既存
│   └── tmux.md               # 既存
├── CLAUDE.md                 # 既存（プロジェクト固有指示）
└── README.md
```

**`.chezmoiroot` の役割**: `chezmoi` はデフォルトでリポジトリ直下を source-state と見なすが、`.chezmoiroot` に `home` と書くだけで `home/` 配下だけを source-state として扱う。これにより `nvim/`, `.github/`, `docs/` は chezmoi の管理外に残り、混在を避けられる。

### chezmoi のファイル命名規則（採用するもの）

公式の正規順序：通常ファイルは `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_`、スクリプトは `run_` → (`once_` | `onchange_`) → (`before_` | `after_`)。

| プレフィックス／サフィックス | 意味 | 例 |
|---|---|---|
| `dot_` | 先頭 `.` のファイル/ディレクトリ | `dot_zshrc` → `~/.zshrc` |
| `private_` | パーミッション 0600 | `private_dot_macos-shortcuts.txt` |
| `.tmpl` | Go template として展開 | `dot_zshrc.tmpl` |
| `run_once_<name>` | 名前変更時に1回だけ実行 | `run_once_install-cmux.sh.tmpl` |
| `run_onchange_before_<name>` | 内容変更時に dotfile 適用 **前** に再実行 | `run_onchange_before_install-packages-darwin.sh.tmpl` |
| `run_once_after_<name>` | 初回 apply の **後** に1回実行 | `run_once_after_setup-nvim-symlink.sh.tmpl` |

**`before_`/`after_` を必ず明示**：パッケージインストール（dotfileより前）と、symlink作成（dotfileより後）で順序が異なるため。`run_once_` と `run_onchange_` は冪等性が重要。スクリプト内で「既にインストール済みならスキップ」を必ず書く。

### ホスト分岐の設計

`.chezmoi.toml.tmpl` を `chezmoi init` 時に展開して、後段のテンプレで参照できる data を生成する。

**macOS 公式推奨**: `hostname` はネットワーク接続状況で揺れる場合があるため、`scutil --get ComputerName` を `output` 関数で叩くほうが堅牢。

```toml
{{/* home/.chezmoi.toml.tmpl */}}
{{- $computerName := "" -}}
{{- if eq .chezmoi.os "darwin" -}}
{{-   $computerName = output "scutil" "--get" "ComputerName" | trim -}}
{{- else -}}
{{-   $computerName = .chezmoi.hostname -}}
{{- end -}}

[data]
  computerName = {{ $computerName | quote }}
{{- if or (eq $computerName "CMPC0397") (eq .chezmoi.hostname "CMPC0397") }}
  hostType = "work-new"
  isWork = true
  email = "higuchi.kokoro@commune.co.jp"
{{- else if or (eq $computerName "CMPC0113") (eq .chezmoi.hostname "CMPC0113") }}
  hostType = "work-old"
  isWork = true
  email = "higuchi.kokoro@commune.co.jp"
{{- else }}
  hostType = "personal"
  isWork = false
  email = "higukkr@gmail.com"
{{- end }}
```

> **既知の代替**: `promptStringOnce` / `promptBoolOnce` で初回 `chezmoi init` 時に対話的に決める方法も公式が推奨。今回はホスト名が一意に決まる前提なので自動判定優先。新ホスト追加時のみ条件追加で済む。

利用側（例: `dot_gitconfig.tmpl`）:

```toml
[user]
  name = zerebom
  email = {{ .email }}
{{- if .isWork }}
  signingkey = ...
{{- end }}
```

### パッケージ管理の戦略（chezmoi 公式推奨パターン）

> **方針変更**: 当初 `home/Brewfile.tmpl` → `~/Brewfile` に展開する案だったが、公式の **"Install packages declaratively"** ガイドに従い、`.chezmoidata/packages.yaml` + `run_onchange_before_*` スクリプトで `brew bundle --file=/dev/stdin` を叩くパターンに変更する。利点は (1) `~/Brewfile` が常駐しない、(2) パッケージリスト変更時のみ実行、(3) Linux 等への横展開が容易。

#### `home/.chezmoidata/packages.yaml`

ホスト跨ぎで参照される静的データ。`packages.darwin.brews` のように OS ネームスペースを切る。

```yaml
packages:
  darwin:
    common:
      brews:
        - git
        - gh
        - ghq
        - fd
        - ripgrep
        - bat
        - eza
        - jq
        - yq
        - jnv
        - neovim
        - tmux
        - reattach-to-user-namespace
        - starship
        - zoxide
        - atuin
        - direnv
        - gnupg
        - pinentry-mac
        - pyenv
        - uv
        - fnm
        - deno
        - duckdb
        - ffmpeg
        - graphviz
        - pandoc
        - tree
        - wget
        - mas
      casks:
        - ghostty
        - google-chrome
        - raycast
        - karabiner-elements
        - cleanshot
        - obsidian
        - cursor
        - visual-studio-code
        - claude
        - chatgpt
        - spotify
        - autoraise
        - monitorcontrol
        - showyedge
        - amical
        - skitch
        - warp
        - drawio
        - figma
        - miro
        - todoist
        - notion
        - tableplus
        - postman
        - font-plemol-jp-nf
    work:
      casks:
        - slack
        - discord
        - zoom
        - linear-linear
        - docker-desktop
        - mactex-no-gui
        - wkhtmltopdf
      mas:
        - { name: Bitwarden,       id: 1352778147 }
        - { name: Keynote,         id: 409183694 }
        - { name: Microsoft Excel, id: 462058435 }
        - { name: RunCat,          id: 1429033973 }
        - { name: Sequel Ace,      id: 1518036000 }
        - { name: Tailscale,       id: 1475387142 }
    personal:
      # 個人Macで使うアプリは将来追記
```

#### `home/run_onchange_before_install-packages-darwin.sh.tmpl`

```bash
#!/usr/bin/env bash
{{- if eq .chezmoi.os "darwin" -}}
set -euo pipefail

# ハッシュをコメントで埋め込んでおき、packages.yaml が変わったときだけ再実行されるようにする
# packages hash: {{ .packages.darwin | toYaml | sha256sum }}

cat <<'EOF' | brew bundle --file=/dev/stdin
{{- range .packages.darwin.common.brews }}
brew "{{ . }}"
{{- end }}
{{- range .packages.darwin.common.casks }}
cask "{{ . }}"
{{- end }}

{{- if .isWork }}
{{- range .packages.darwin.work.casks }}
cask "{{ . }}"
{{- end }}
{{- range .packages.darwin.work.mas }}
mas "{{ .name }}", id: {{ .id }}
{{- end }}
{{- end }}
EOF
{{- end }}
```

**ポイント**:
- ファイル冒頭の `# packages hash:` コメントが `run_onchange_` のトリガー。`packages.yaml` を編集して hash が変われば再実行される。
- `cat | brew bundle --file=/dev/stdin` で Brewfile を一時ファイル化せずに渡す（公式の `Install packages declaratively` 通り）。
- 仕事/個人の判定は `.isWork`（次節 .chezmoi.toml.tmpl で決定）。

### シークレット戦略

#### 投入

ユーザーが新仕事PC `CMPC0397` でセットアップ時、以下を手動実行（1回だけ）：

```bash
security add-generic-password -s github-token -a zerebom -w <token>
security add-generic-password -s anthropic-api-key -a zerebom -w <key>
# その他必要なシークレット
```

#### 取得（テンプレート内）

公式の汎用関数 `keyring "service" "user"` を使う（macOS Keychain / Linux Secret Service / Windows Credential Manager に対応）。CI 環境では keychain にシークレットがないため `default` でフォールバック、さらに `env "CI"` でガードする。

```bash
# home/dot_zsh/exports.zsh.tmpl
{{- if env "CI" }}
export GITHUB_TOKEN="ci-fake-token"
export ANTHROPIC_API_KEY="ci-fake-key"
{{- else }}
export GITHUB_TOKEN="{{ keyring "github-token" "zerebom" | default "" }}"
export ANTHROPIC_API_KEY="{{ keyring "anthropic-api-key" "zerebom" | default "" }}"
{{- end }}
```

`chezmoi apply` 実行時に keychain から取得され、生成ファイル `~/.zsh/exports.zsh` に展開される。生成ファイルは git 管理外（`.zsh/` 配下の生成物のみ展開先で、source-state は `home/dot_zsh/exports.zsh.tmpl` のみがコミットされる）。

> **`keychainPassword` ではなく `keyring`**: `keychainPassword` も macOS で動くが、`keyring` のほうが OS 横断で記述が変わらず公式リファレンス上の主流。

#### 既存リーク `.github_token` の対処

順序を厳守：

1. GitHub 上で当該 token を **revoke**
2. 新トークンを発行 → `security add-generic-password` で keychain へ投入
3. `chezmoi apply` で `~/.zsh/exports.zsh` に反映
4. `git filter-repo --path .github_token --invert-paths` で履歴削除
5. force push（`master` への push 権限を一時的に有効化）
6. ローカルの `.github_token` ファイルを削除

cutover タイミングで実施。force push が伴うため、PR と切り分けて単独コミットで進める。

### アプリ設定の移行戦略

| アプリ | 戦略 | 実装 |
|---|---|---|
| Karabiner-Elements | chezmoi 直管理 | `home/dot_config/karabiner/karabiner.json` を `chezmoi add` |
| Ghostty | chezmoi 直管理（ホスト分岐あり） | `home/dot_config/ghostty/config.tmpl` |
| Raycast | Cloud Sync 利用（ファイル管理せず） | docs/chezmoi.md に「Raycast Pro の Cloud Sync を有効化」と記載 |
| Cursor | 拡張機能のみ chezmoi 管理 | `run_onchange_install-vscode-extensions.sh.tmpl` で `code --list-extensions` の出力を保存→新PCで再インストール。`settings.json` は当面 Settings Sync (GitHub) に任せる |
| macOS カスタムショートカット | 退避ファイル | `defaults find NSUserKeyEquivalents > home/private_dot_macos-shortcuts.txt`、新PCでは手動再投入の参照資料として保存 |
| cmux | 自前ビルド | `run_once_install-cmux.sh.tmpl` で git clone + build |

### CI 戦略

`.github/workflows/chezmoi-test.yml`（shunk031 の Bats 構成を参考にしつつ最小化）：

```yaml
name: chezmoi-test
on:
  pull_request:
    branches: [master]
  push:
    branches: [master]

env:
  CI: "true"   # exports.zsh.tmpl 等のガードに利用

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
      - name: Initialize (no apply)
        run: chezmoi init --apply=false --source=./home
      - name: Template syntax check
        run: chezmoi execute-template < home/dot_zshrc.tmpl > /dev/null
      - name: Apply dry-run
        run: chezmoi apply --dry-run --verbose
```

**設計上のポイント**:
- `env.CI` を立てることで、`exports.zsh.tmpl` 内の `{{ if env "CI" }}` ガードが効き、`keyring` を呼ばずに偽トークンに置換できる。
- `--dry-run` 中は `run_onchange_*` の **スクリプト本体は実行されない**（テンプレ展開のみ）。Brewfile が実際に通るかは別途 `brew bundle check` のローカル検証で担保する。
- macos-latest が不安定／時間がかかるなら ubuntu-latest 単独に縮退する（フォールバック）。

## 検証方法

### 旧PC `CMPC0113`（破壊的変更なし）

```bash
chezmoi init --source=./home --apply=false
chezmoi diff
```

期待結果: 出力される差分が **意図した変更のみ**（権限調整、テンプレ展開で変わる行）。`.zshrc` 全置換等の予期しない大規模差分が出たら設計を見直す。

### 新PC `CMPC0397`（30分タイマー）

```bash
# 0:00 — 計測開始
xcode-select --install                                     # Xcode CLT
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install chezmoi
# Keychain 投入（事前に必要なシークレットを ~/secret-bootstrap.sh にメモして USB/AirDrop で運搬）
sh ~/secret-bootstrap.sh

chezmoi init zerebom --apply
# ↑ ここで dotfiles 展開完了 — 5分以内目標

cd ~ && brew bundle install --file=~/Brewfile  # Brewfile は chezmoi が ~/Brewfile に展開する想定
# ↑ ネットワーク次第で 25分以内目標

# 30:00 — Cursor / Ghostty / Karabiner 起動確認
```

**Done 判定**:
- ターミナル（ghostty）で zsh プロンプトが starship 表示
- `nvim` でプラグインが解決済み（lazy.nvim の cache はあるはず）
- Cursor 起動 → 拡張機能が `run_onchange_*` で復元
- `mas list` で AppStore 6個揃う
- `git grep -i 'token\|secret' -- ':!.steering' ':!docs'` でシークレット平文出ない

### Brewfile 単体検証（旧PCで先行）

```bash
chezmoi execute-template --file home/Brewfile.tmpl > /tmp/Brewfile
brew bundle check --file=/tmp/Brewfile  # 全部入っているか
```

`brew bundle check` は「Brewfile に書かれているがインストールされていないもの」を列挙する。これが空になるよう、旧PCで足りないアプリは先にインストール → 再 dump → Brewfile.tmpl 反映、を回す。

## 技術的考慮事項

- **chezmoi の source-state 場所**: デフォルトは `~/.local/share/chezmoi`。今回は既存リポジトリ `~/.dotfiles/` 直下に `.chezmoiroot`（中身は `home`）を置くことで `home/` 配下が source-state になる。`chezmoi init --source=$HOME/.dotfiles` で初期化する。**`.chezmoi.toml.tmpl` も `home/` 配下に置くこと**（リポジトリ直下では読まれない）。
- **Apple Silicon の path 競合**: 旧 `/usr/local/bin/brew` が残っていれば事前削除。`docs/chezmoi.md` の手順に明記。
- **`nvim/` を chezmoi 管理下に入れない理由**: LazyVim 配下の `lazy-lock.json` が頻繁に変わり、`chezmoi diff` のノイズになる。`external_` ディレクティブは公式が「大きいディレクトリには使うな」と明記しており不適。`~/.config/nvim` は `ln -sf ~/.dotfiles/nvim ~/.config/nvim` で直接リンクする方針を維持（`run_once_after_setup-nvim-symlink.sh.tmpl` で対応、初回 apply 後に1回だけ実行）。
- **既存 `.zshrc.backup.*`**: cutover 時に削除。chezmoi 管理下に入れない。
- **`bin/` ディレクトリ削除済み**: `git status` を見ると `D bin` 表記あり。chezmoi 化と独立して進む。
- **chezmoi の冪等性**: `chezmoi apply` は何度叩いても同じ結果になる設計。CI で安全に dry-run 可能。
- **`.chezmoiignore` の必要性**: macOS と Linux で適用ファイルを分けたい場合に使う。当面 macOS のみ運用なので最小限。
- **Brewfile を dotfile 化しない理由**: chezmoi 公式の "Install packages declaratively" は **`.chezmoidata/packages.yaml` + `run_onchange_before_*` で `brew bundle --file=/dev/stdin`** を推奨。`~/Brewfile` を生成するパターンは動くが、(1) `~/Brewfile` がユーザーから見えるところに常駐する、(2) パッケージ更新で apply 全体が走らない、というデメリットがあるため不採用。

## 参照

- chezmoi 公式: https://www.chezmoi.io/
- chezmoi の `keychainPassword` テンプレ関数: https://www.chezmoi.io/reference/templates/functions/keychainpassword/
- chezmoi の `run_*` script: https://www.chezmoi.io/reference/source-state-attributes/
- 既存 docs/cmux.md, docs/nvim.md, docs/tmux.md は cutover 後も維持
- 参考記事1: chezmoi導入記事（テンプレート/シークレット/CIの統合）
- 参考記事2: Homebrew Cask + mas + Mackup 記事（Apple Silicon path 競合 / `defaults find NSUserKeyEquivalents` / `brew bundle dump --describe`）
