# 引き継ぎノート — chezmoi 移行プロジェクト

> このタスクを引き継ぐ人（または次セッションのAI）はまずこのファイルを読んでください。

## 1. ゴール（30秒で把握）

旧仕事PC `CMPC0113`（=このリポジトリが今動いている環境）の dotfiles を **chezmoi + Brewfile/mas** に移行し、新仕事PC `CMPC0397` を **30分以内**でセットアップできる基盤を作る。Plan B（chezmoi 全面採用、新ブランチで並行構築 → cutover 型）。

## 2. 現在地（2026-04-29 更新）

- ブランチ: **`feat/chezmoi-migration`**（push 済み）
- リモート: `git@github.com:zerebom/dotfiles.git`
- 完了フェーズ: **Phase A-E + G + I（CMPC0397 で実機検証） + K一部**
- 次フェーズ: **Phase J（cutover）→ H（旧PC側のシークレット剥離）→ K残（README/CLAUDE.md 書換）**
- **Phase F は事実上不要**: 新PC `CMPC0397` を直接 chezmoi 一発でセットアップ済み。旧PC `CMPC0113` 上での検証 apply は試さなかった（cutover まで手元の symlink 構造を温存したまま、新PCで先に検証した）

直近のコミット履歴:

```
8270171 feat(chezmoi): Phase I - new PC (CMPC0397) で実機検証 + 失敗許容化
e203fac docs(steering): refresh HANDOFF.md after Phase E/G/K-1 completion
99eefaa chore: housekeeping + docs/chezmoi.md draft (Phase K-1)
4ed5878 feat(chezmoi): Phase G - CI workflow + harden secrets template
75de450 feat(chezmoi): Phase C-E complete - gitconfig, packages.yaml, run_* scripts
```

CI: 過去の green: Run 25058730028 (e203fac)。最新 push (8270171) の結果は `gh run list --branch feat/chezmoi-migration --limit 1` で確認。

## 3. 必読ドキュメント（順番）

| # | ファイル | 役割 |
|---|---|---|
| 1 | `requirements.md` | 背景・目標・成功基準・スコープ |
| 2 | `design.md` | アーキ設計（chezmoiroot、命名規則、ホスト分岐、シークレット、CI、検証） |
| 3 | `current-state.md` | 旧PCの実状態スナップショット（**最重要**：勝手に推測せずこれを真実情報源とする） |
| 4 | `app-inventory.md` | Brewfile に載せるアプリの確定リスト（Cask 32 + mas 6 = 38個） |
| 5 | `tasklist.md` | フェーズ別タスク（チェックボックス付き、Phase A-E + G 済み） |
| 6 | `cursor-extensions.txt` | Cursor 拡張機能 137個 |
| 7 | `vscode-extensions.txt` | VS Code 拡張機能 125個 |
| 8 | `../../docs/chezmoi.md` | **新PCセットアップ手順 + 日常運用 + トラブルシューティング** |

## 4. すでに作ったもの

```
.dotfiles/
├── .chezmoiroot                              # 内容: "home"
├── .github/
│   └── workflows/
│       ├── chezmoi-test.yml                  # matrix CI (ubuntu/macos), env CI=true
│       └── claude.yml                        # 既存（actions/checkout@v5 にバンプ済み）
├── docs/
│   └── chezmoi.md                            # 運用ガイド（30分タイマー / 日常運用 / トラブル）
└── home/
    ├── .chezmoi.toml.tmpl                    # ホスト分岐（scutil --get ComputerName）
    ├── .chezmoiignore                        # README/LICENSE/.assets/** + macOS-only ガード
    ├── .chezmoidata/
    │   └── packages.yaml                     # brews 30 + casks 26 + work casks 7 + mas 6
    ├── .assets/                              # スクリプトから参照する静的ファイル（ターゲット展開なし）
    │   ├── cursor-extensions.txt             # 137 行
    │   └── vscode-extensions.txt             # 125 行
    ├── dot_zshrc
    ├── dot_zshenv.tmpl                       # Apple Silicon 分岐 + .github_token 行削除済み
    ├── dot_zsh/
    │   ├── aliases.zsh
    │   ├── empty_fzf.zsh
    │   ├── exports.zsh
    │   ├── function.zsh
    │   ├── prompt.zsh_v2
    │   └── secrets.zsh.tmpl                  # output "sh" + security ... | trim 方式（堅牢化済み）
    ├── dot_config/
    │   ├── ghostty/config
    │   └── karabiner/private_karabiner.json  # mode 0600
    ├── dot_claude/CLAUDE.md
    ├── dot_starship.toml
    ├── dot_tmux.conf
    ├── dot_gitconfig.tmpl                    # email を {{ .email }}、excludesfile を homeDir で展開
    ├── dot_gitignore_global
    ├── run_onchange_before_install-packages-darwin.sh.tmpl   # brew bundle --file=/dev/stdin
    ├── run_once_after_setup-nvim-symlink.sh.tmpl             # workingTree/nvim → ~/.config/nvim
    ├── run_onchange_install-cursor-extensions.sh.tmpl        # 137 ext 再投入
    └── run_onchange_install-vscode-extensions.sh.tmpl        # 125 ext 再投入
```

検証済み（ローカル + CI）:

- `chezmoi data --source=$HOME/.dotfiles` → `hostType: work-old`, `isWork: true`, `email: higuchi.kokoro@commune.co.jp`
- CI（runner ホスト）→ `hostType: personal`, `email: higukkr@gmail.com` で正しく fallback
- `chezmoi managed` で 24 ターゲット
- `CI=true chezmoi apply --dry-run --force --source=$HOME/.dotfiles/home` → exit 0
- `chezmoi diff` → exit 0、未投入 keychain でもエラーなし
- `brew bundle check --file=<expanded-Brewfile>` → Brewfile syntax OK（実体未インストールは想定通り）
- 副次対応: `.zsh/anyframe` の submodule 残骸除去、`actions/checkout@v5` にバンプ

## 5. これから作るもの（残フェーズ）

### Phase I 完了レポート（2026-04-29 / CMPC0397 で実施）

**結果**: chezmoi 一発展開で 30 分以内にほぼフルセットアップ完了。`chezmoi diff` clean。

何が動いたか:
- dotfiles 24 ターゲット全配置（`.zshrc / .zshenv / .gitconfig / .tmux.conf / .starship.toml / .gitignore_global / .zsh/* / .config/{ghostty,karabiner,nvim} / .claude/CLAUDE.md`）
- brews 30/30（依存込み 117）
- casks 25/29
- cursor extensions 106/137
- vscode extensions 125/125
- nvim symlink: `~/.config/nvim → ~/.local/share/chezmoi/nvim`（`.local/share/chezmoi` は `~/.dotfiles` への symlink）
- starship + git email = `higuchi.kokoro@commune.co.jp` で動作確認

**運用メモ**: `~/.dotfiles` は既に clone 済みだったので `chezmoi init zerebom` でなく `ln -s ~/.dotfiles ~/.local/share/chezmoi` で source-state を共有する形にした。`chezmoi.toml` は init で自動生成。

### Phase I で見つかった問題と対応（コミット `8270171` で fix 済み）

| 問題 | 対応 |
|---|---|
| `autoraise` / `skitch` / `wkhtmltopdf` が Homebrew に存在しない | `packages.yaml` から除外、コメントで代替手段を記載 |
| `mactex-no-gui` 5GB ダウンロードが律速 | 必要時のみ手動 install。除外 |
| sudo 必須 cask（karabiner-elements / zoom / docker-desktop）が非対話で必ず失敗 | `brew bundle` を `\|\| echo` で握り潰し、apply は止めない |
| App Store 未サインインで mas が失敗 | mas を独立ブロックに分離、`mas account` チェックで fallback |
| 1 個の cursor 拡張 rename で 137 個全体が止まる | 個別 ext 失敗を蓄積し件数表示する形に変更 |

### Phase I 残作業（**ユーザー手動、対話シェル必須**）

```bash
# sudo 必須 cask 3 個（パスワード手入力）
brew install --cask karabiner-elements
brew install --cask zoom
brew install --cask docker-desktop

# App Store サインイン後、mas 6 個
open -a "App Store"   # GUI でサインイン
mas install 1352778147   # Bitwarden
mas install 409183694    # Keynote
mas install 462058435    # Microsoft Excel
mas install 1429033973   # RunCat
mas install 1518036000   # Sequel Ace
mas install 1475387142   # Tailscale

# 任意: keychain 投入（chezmoi の secrets.zsh.tmpl が取りに行く宛先）
security add-generic-password -s github-token      -a zerebom -w <new-token>
security add-generic-password -s gemini-api-key    -a zerebom -w <key>
security add-generic-password -s anthropic-api-key -a zerebom -w <key>
```

### Phase J — master cutover（次の本丸）

- 旧 `Makefile` の install/clean ターゲットを削除（または `chezmoi apply` のラッパに）
- 旧PC `CMPC0113` 上の symlink 構造は cutover で chezmoi 管理に置換される（旧PC側でいつ apply するかは要相談）
- `.zshrc.backup.*`、`.vim.bak/`、`nvim.bak/`、`.config/ghostty/config.bak` の削除
- PR 作成 → master merge

### Phase H — シークレット keychain 化の仕上げ（cutover 後 / 旧PC で）

- GitHub 上で旧 `.github_token` を **revoke**
- `.zshenv.tmpl` から `source $HOME/.dotfiles/.github_token` の行を削除（**既に削除済み**）
- ローカルの `.github_token` / `.zsh/secrets.zsh` を削除（apply で空相当に置換される）
- `git filter-repo` 等での履歴剥離は **不要**

### Phase K 残 — ドキュメント整備（cutover と同時）

- `README.md` を chezmoi 前提に書き換え
- `CLAUDE.md`（プロジェクトの指示書）を chezmoi 前提に更新
- `docs/cmux.md`, `docs/nvim.md`, `docs/tmux.md` で chezmoi 前提のパスがあれば修正

## 6. 注意事項（厳守）

1. **`current-state.md` の内容を真とする**。推測で `.zshrc` の中身を改変しない。
2. **`.zsh/secrets.zsh` と `.github_token` は git 履歴に**ない**ことが確認済み**。force push 不要、`git filter-repo` も不要。
3. **`.github_token` の行**は `dot_zshenv.tmpl` から既に削除済み。元の `.zshenv` には残っているが触らない（cutover 時に削除）。
4. **`Makefile` と既存 symlink 構造**は cutover まで残す。途中で消さない。
5. **新PC `CMPC0397` で Phase I 完了済み**（2026-04-29）。次は cutover の番。
6. **`~/.gitconfig` のメアド**: 個人用は `higukkr@gmail.com`、仕事用は `higuchi.kokoro@commune.co.jp`（旧仕事 / 新仕事どちらも commune）。
7. **Wantedly は無関係**。ユーザーは Commune 所属。requirements/design 内に Wantedly が出てきたら誤り（参考ブログの著者の所属）。
8. **旧PC `CMPC0113` で chezmoi apply を打つタイミング**: master cutover と同時推奨。新PC側は既に chezmoi 管理下なのでブロッカー無し。

## 7. 引き継ぎ時のチェックリスト（次セッション開始時に確認）

- [ ] `git -C ~/.dotfiles branch --show-current` が `feat/chezmoi-migration` か
- [ ] `git -C ~/.dotfiles log --oneline -6` で最新が `8270171 feat(chezmoi): Phase I - new PC ...`
- [ ] `git -C ~/.dotfiles status -sb` の先頭行が `## feat/chezmoi-migration...origin/feat/chezmoi-migration`
- [ ] `chezmoi --version` が 2.70.x 以上
- [ ] `chezmoi data | grep -E "computerName|hostType|isWork|email"` が期待値（CMPC0397 なら `work-new`、CMPC0113 なら `work-old`、それ以外 `personal`）
- [ ] `chezmoi managed | wc -l` で 24
- [ ] `chezmoi diff` が clean（CMPC0397 なら）
- [ ] `gh run list --branch feat/chezmoi-migration --limit 1` の最新が `success`

## 8. リモート push 状況

**push 済み** — `feat/chezmoi-migration` は `origin` を tracking、CI も green で確認済み。

別マシンで作業を継続したい場合は:

```bash
git clone git@github.com:zerebom/dotfiles.git
cd dotfiles
git checkout feat/chezmoi-migration
```

## 9. このプロジェクトを終了する条件

- 新仕事PC `CMPC0397` で `chezmoi init zerebom && chezmoi apply` 一発で 30分以内にセットアップ完了
- master へ merge 済み、`Makefile` の旧 install ターゲット削除（または chezmoi ラッパ化）
- `git grep -i 'token\|secret\|password' -- ':!.steering' ':!docs'` でシークレット平文出ない
- `tasklist.md` の振り返りセクション記入済み

## 10. このセッションで判明したこと（次に活かす）

- **`keyring` 関数は値が無いとエラー終了する**: chezmoi 公式ドキュメントは `default ""` で逃げるよう書いているが、実際には `default` フィルタが届く前にエラーが上がる。回避策は `output "sh" "-c" "security find-generic-password -s X -a Y -w 2>/dev/null || true" | trim`。`secrets.zsh.tmpl` がこの方式。
- **`chezmoi apply --dry-run` が TTY を要求する場面がある**: ファイルが手元で改変されたとき。CI / 非対話環境では `--force` を必須に。
- **`brew bundle check` は手動 .dmg を「未インストール」と判定する**: brew 経由ではないため。新PC（フレッシュ）では問題化しない。旧PCで apply した場合は brew が既存 .app を adopt する形になるはず。
- **`actions/checkout@v4` の Node 20 deprecation**: 2026-09-16 までに v5 以降必須。今回はバンプ済み。
- **`.chezmoiignore` のパスは「ターゲットファイル」基準**: source state 上のパスではなく、`~/` から見た相対パス。`.assets/**` と書く（`home/.assets/**` ではない）。
