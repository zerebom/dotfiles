# タスクリスト — chezmoi 移行 + Brewfile/mas 統合

実行は旧仕事PC `CMPC0113` で行う。新仕事PC `CMPC0397` での検証は Phase H。

## Phase A: ブランチ作成と前準備 ✅

- [x] `.steering/20260428-chezmoi-migration/{requirements,design,app-inventory,current-state}.md` 作成
- [x] App Store ID 採番（`brew install mas && mas list`）
- [x] cask 名確定（linear-linear / docker-desktop、CMake.app は cask 不在）
- [x] `git checkout -b feat/chezmoi-migration` で新ブランチ作成
- [x] 既存ファイルの漏れ確認（`git status` で未追跡ファイルが steering に紛れていないか）
- [x] commit: `docs(steering): add chezmoi migration steering docs`

## Phase B: chezmoi 初期化 ✅

- [x] `brew install chezmoi` で chezmoi インストール（v2.70.2）
- [x] リポジトリ直下に `.chezmoiroot` 作成（中身: `home`）
- [x] `home/` ディレクトリ作成
- [x] `home/.chezmoi.toml.tmpl` 作成（hostType / isWork / email を `scutil` 経由で判定）
- [x] `home/.chezmoiignore` 作成（README.md, LICENSE, Linux で macOS 限定ファイル除外）
- [x] `chezmoi init --apply=false --source=$HOME/.dotfiles` で初期化動作確認
- [x] `chezmoi data` でホスト分岐 data が正しく出力されるか確認
  - `computerName: "CMPC0113"`, `hostType: "work-old"`, `isWork: true`, `email: higuchi.kokoro@commune.co.jp`

## Phase C: dotfiles 取り込み ✅

### C-1. シェル系 ✅

- [x] `home/dot_zshrc`（テンプレ化不要、現状そのまま）
- [x] `home/dot_zshenv.tmpl`（Apple Silicon 用 `/opt/homebrew` 分岐、`.github_token` source 行削除）
- [x] `home/dot_zsh/` 作成
  - [x] `aliases.zsh`, `function.zsh`, `prompt.zsh_v2` はそのまま
  - [x] `empty_fzf.zsh`（0byte ファイルの chezmoi 規約）
  - [x] `exports.zsh` はそのまま（シークレットなし、PATH のみ）
  - [x] `secrets.zsh.tmpl` 新規作成（`keyring` + `env "CI"` ガード）
- [x] `home/dot_starship.toml` 配置
- [x] `home/dot_tmux.conf` 配置

### C-2. 設定ファイル系 ✅

- [x] `home/dot_config/ghostty/config` 配置（テンプレ化は将来必要時）
- [x] `home/dot_config/karabiner/private_karabiner.json` 取り込み（mode 0600 維持）
- [x] `home/dot_claude/CLAUDE.md` 作成（旧 `.claude/global.md` の内容）
- [x] `home/dot_gitconfig.tmpl` 作成（既存 `~/.gitconfig` 取り込み、email を `{{ .email }}` で展開、excludesfile を `{{ .chezmoi.homeDir }}/.gitignore_global` で展開）
- [x] `home/dot_gitignore_global` 取り込み（実体ファイル `~/.gitignore_global` を chezmoi 管理下へ）

### C-3. macOS キーバインド退避

> current-state.md の調査により `defaults find NSUserKeyEquivalents` は **空** だったため、退避ファイル作成は不要。タスクスキップ。

## Phase D: パッケージ管理（chezmoidata + run_onchange）✅

- [x] `home/.chezmoidata/packages.yaml` 作成（design.md のリスト転記、common.brews 30 + common.casks 26 + work.casks 7 + work.mas 6）
- [x] `home/run_onchange_before_install-packages-darwin.sh.tmpl` 作成
  - [x] hash 行 `# packages hash: {{ .packages.darwin | toYaml | sha256sum }}` を冒頭に
  - [x] `cat <<EOF | brew bundle --file=/dev/stdin` 構造
  - [x] `.isWork` 分岐
- [x] `chezmoi execute-template` で `isWork: true` 時に work casks/mas が含まれる Brewfile が展開されることを確認
- [ ] **dry-run**: 展開結果を `/tmp/Brewfile` に出して `brew bundle check --file=/tmp/Brewfile` でチェック（Phase F の事前確認として実行）

## Phase E: アプリ個別の取り込みスクリプト ✅

- [ ] ~~`home/run_once_install-cmux.sh.tmpl` 作成~~ → cmux のビルド情報未取得のため保留。新PCで必要時に手動対応
- [x] `home/run_once_after_setup-nvim-symlink.sh.tmpl` 作成（`{{ .chezmoi.workingTree }}/nvim` → `~/.config/nvim` を symlink、既存symlink整合チェック付き）
- [x] `home/run_onchange_install-cursor-extensions.sh.tmpl` 作成（`.assets/cursor-extensions.txt` を読み `cursor --install-extension --force` ループ、CLI未導入時はスキップ）
- [x] `home/run_onchange_install-vscode-extensions.sh.tmpl` 作成（同上で `code` CLI 利用）
- [x] `home/.assets/cursor-extensions.txt`（137行）と `vscode-extensions.txt`（125行）配置
- [x] `home/.chezmoiignore` に `.assets/**` を追加してターゲット展開から除外

## Phase F: シークレット投入と動作確認（旧PC）

- [ ] keychain に投入
  - [ ] `security add-generic-password -s github-token -a zerebom -w <new-token>`
  - [ ] `security add-generic-password -s anthropic-api-key -a zerebom -w <key>` （他必要分）
- [ ] `chezmoi diff` で生成結果と現状の差分を確認
  - [ ] **意図したテンプレ展開差分のみ** か検証
  - [ ] 意図しない差分があれば該当テンプレを修正
- [ ] `chezmoi apply --dry-run --verbose` でエラーなし
- [ ] **本番 apply**: `chezmoi apply` 実行（旧PCは現状維持の構成のはず）
- [ ] `source ~/.zshrc` で再読込み、PATH や function が壊れていないか確認

## Phase G: CI 整備 ✅（ローカル検証まで）

- [x] `.github/workflows/chezmoi-test.yml` 作成（matrix: ubuntu-latest, macos-latest）
  - `env.CI: "true"` を job レベルで設定
  - `chezmoi init --apply=false`、全 `*.tmpl` の execute-template、`apply --dry-run --force --verbose` の3段
- [x] ローカルで CI 相当を再現: `CI=true chezmoi apply --dry-run --force` が exit 0
- [x] `secrets.zsh.tmpl` の `env "CI"` ガードが効くことをローカルで確認（fake 値展開）
- [ ] 実際の PR 上で CI が green になるまで調整（push 後に確認）
- [ ] CI 不安定なら ubuntu-latest 単独に縮退（フォールバック発動）

### `dot_zsh/secrets.zsh.tmpl` 堅牢化 ✅

未投入の keychain エントリでも展開エラーにならないよう、`keyring` 関数から `output "sh" "-c" "security find-generic-password ... 2>/dev/null || true"` 方式へ変更。投入があれば値、無ければ空文字。

## Phase H: シークレット keychain 化（履歴剥離は不要）

> current-state.md の調査により `.github_token` も `.zsh/secrets.zsh` も **git 履歴に存在しない** ことが判明（`.gitignore` 済み）。force push は不要。

- [ ] GitHub 上で旧 `.github_token` の token を **revoke**
- [ ] 新トークンを発行 → `security add-generic-password -s github-token -a zerebom -w <new-token>`
- [ ] `GEMINI_API_KEY` を keychain へ移行 → `security add-generic-password -s gemini-api-key -a zerebom -w <key>`
- [ ] `.zshenv.tmpl` から `source $HOME/.dotfiles/.github_token` の行を削除し、keyring 取得式に置換
- [ ] `.zsh/secrets.zsh` を `dot_zsh/secrets.zsh.tmpl` 化、keyring 経由に置換
- [ ] cutover 時にローカルの `.github_token` / `.zsh/secrets.zsh` を削除（chezmoi 適用で空相当に置換される）

## Phase I: 新PC `CMPC0397` での検証（30分タイマー）

- [ ] 新PC受領時の初期セットアップ（Apple ID ログイン、iCloud 同期等）
- [ ] **計測開始**
- [ ] `xcode-select --install`
- [ ] Homebrew インストール（公式 install.sh）
- [ ] `eval "$(/opt/homebrew/bin/brew shellenv)"` を `~/.zprofile` に追記
- [ ] `brew install chezmoi`
- [ ] keychain にシークレット投入（USB or AirDrop で運搬した bootstrap スクリプト）
- [ ] `chezmoi init zerebom --apply` 実行 → 5分以内に dotfiles 展開完了
- [ ] パッケージ自動インストール完了確認（`run_onchange_before_install-packages-darwin.sh.tmpl` が走る）
- [ ] **計測終了** — 30分以内に Cursor / Ghostty / Karabiner 起動確認
- [ ] `mas list` で AppStore 6個揃っていること
- [ ] `git grep -i 'token\|secret\|password' -- ':!.steering' ':!docs'` でシークレット平文出ない

## Phase J: cutover（master 切替）

- [ ] PR `feat/chezmoi-migration` → `master` を作成
- [ ] CI green を確認
- [ ] PR レビュー（自分自身）
  - [ ] requirements.md / design.md と乖離がないか
  - [ ] 不要ファイル（`.zshrc.backup.*`, `.vim.bak`, `nvim.bak`）の削除を含むか
- [ ] `Makefile` の install/clean ターゲットを **chezmoi コマンドのラッパ** に書き換え（`make install` で `chezmoi apply` を叩く等）、または完全削除
- [ ] PR merge
- [ ] 旧 symlink を `chezmoi managed` で確認、不整合あれば手動整理

## Phase K: ドキュメント整備

- [ ] `docs/chezmoi.md` 作成（新PC初期化手順、トラブルシューティング、シークレット投入手順）
- [ ] `README.md` を chezmoi 前提に書き換え
- [ ] `CLAUDE.md`（プロジェクトの指示書）を chezmoi 前提に更新
- [ ] `docs/cmux.md`, `docs/nvim.md`, `docs/tmux.md` で chezmoi に関連するパスがあれば修正

---

## 実装後の振り返り

<!-- 完了後に記入 -->
- 実装完了日:
- 計画と実績の差分:
- 学んだこと:
- 次回への改善提案:
