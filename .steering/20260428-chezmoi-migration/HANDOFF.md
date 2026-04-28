# 引き継ぎノート — chezmoi 移行プロジェクト

> このタスクを引き継ぐ人（または次セッションのAI）はまずこのファイルを読んでください。

## 1. ゴール（30秒で把握）

旧仕事PC `CMPC0113`（=このリポジトリが今動いている環境）の dotfiles を **chezmoi + Brewfile/mas** に移行し、新仕事PC `CMPC0397` を **30分以内**でセットアップできる基盤を作る。Plan B（chezmoi 全面採用、新ブランチで並行構築 → cutover 型）。

## 2. 現在地

- ブランチ: **`feat/chezmoi-migration`**（master からは分岐済み、未push）
- リモート: `git@github.com:zerebom/dotfiles.git`
- 完了フェーズ: **Phase A-C**（一部 C 残あり）
- 次フェーズ: **Phase C 残 → D → E → F → G → H → I → J → K**

## 3. 必読ドキュメント（順番）

| # | ファイル | 役割 |
|---|---|---|
| 1 | `requirements.md` | 背景・目標・成功基準・スコープ |
| 2 | `design.md` | アーキ設計（chezmoiroot、命名規則、ホスト分岐、シークレット、CI、検証） |
| 3 | `current-state.md` | 旧PCの実状態スナップショット（**最重要**：勝手に推測せずこれを真実情報源とする） |
| 4 | `app-inventory.md` | Brewfile に載せるアプリの確定リスト（Cask 32 + mas 6 = 38個） |
| 5 | `tasklist.md` | フェーズ別タスク（チェックボックス付き、Phase A-C 済み） |
| 6 | `cursor-extensions.txt` | Cursor 拡張機能 137個 |
| 7 | `vscode-extensions.txt` | VS Code 拡張機能 125個 |

調査エージェントが指摘した chezmoi 公式ベスプラ準拠への修正は `design.md` に反映済み（Brewfile を `~/Brewfile` ではなく `.chezmoidata/packages.yaml` + `run_onchange_before_*` で扱う等）。

## 4. すでに作ったもの

```
.dotfiles/
├── .chezmoiroot                              # 内容: "home"
└── home/
    ├── .chezmoi.toml.tmpl                    # ホスト分岐（scutil --get ComputerName）
    ├── .chezmoiignore
    ├── dot_zshrc
    ├── dot_zshenv.tmpl                       # Apple Silicon 分岐 + .github_token 行削除済み
    ├── dot_zsh/
    │   ├── aliases.zsh
    │   ├── empty_fzf.zsh
    │   ├── exports.zsh
    │   ├── function.zsh
    │   ├── prompt.zsh_v2
    │   └── secrets.zsh.tmpl                  # keyring + env "CI" ガード
    ├── dot_config/
    │   ├── ghostty/config
    │   └── karabiner/private_karabiner.json  # mode 0600
    ├── dot_claude/CLAUDE.md
    ├── dot_starship.toml
    └── dot_tmux.conf
```

検証済み：
- `chezmoi data` → `hostType: work-old`, `isWork: true`, `email: higuchi.kokoro@commune.co.jp`
- `chezmoi execute-template` で `dot_zshenv.tmpl` が `/opt/homebrew` に正しく展開
- `chezmoi managed` で 18パスを管理対象として認識

## 5. これから作るもの（Phase C残以降）

### Phase C 残 — gitconfig

```bash
# 既存の ~/.gitconfig を取り込んで template 化
chezmoi add --follow --source=$HOME/.dotfiles ~/.gitconfig
mv home/dot_gitconfig home/dot_gitconfig.tmpl
# email を {{ .email }} に置換
```

### Phase D — packages.yaml + run_onchange_before

`design.md` の「パッケージ管理の戦略」セクションのコード片をそのまま使う。`app-inventory.md` の「確定後の Brewfile 候補」リストが入力値。

```
home/.chezmoidata/packages.yaml
home/run_onchange_before_install-packages-darwin.sh.tmpl
```

### Phase E — run_once / run_onchange スクリプト

```
home/run_once_after_setup-nvim-symlink.sh.tmpl     # ln -sf ~/.dotfiles/nvim ~/.config/nvim
home/run_onchange_install-cursor-extensions.sh.tmpl # cursor --install-extension
```

Cursor 拡張機能リストは `.steering/.../cursor-extensions.txt` を `home/.assets/cursor-extensions.txt` に複製してスクリプトから参照。

### Phase F-K（design.md / tasklist.md 参照）

- F: シークレット投入 + 旧PCで `chezmoi diff` 確認 + `chezmoi apply`
- G: GitHub Actions CI
- H: シークレット keychain 化（履歴削除は不要、調査済み）
- I: 新PC `CMPC0397` で 30分タイマー検証
- J: master cutover（旧 Makefile 削除 or chezmoi ラッパに）
- K: docs/chezmoi.md 作成

## 6. 注意事項（厳守）

1. **`current-state.md` の内容を真とする**。推測で `.zshrc` の中身を改変しない。
2. **`.zsh/secrets.zsh` と `.github_token` は git 履歴に**ない**ことが確認済み**。force push 不要、`git filter-repo` も不要。
3. **`.github_token` の行**は `dot_zshenv.tmpl` から既に削除済み。元の `.zshenv` には残っているが触らない（cutover 時に削除）。
4. **`Makefile` と既存 symlink 構造**は cutover まで残す。途中で消さない。
5. **新PC `CMPC0397` での実行は別タイミング**。今はあくまで旧PCで構築・検証するフェーズ。
6. **`~/.gitconfig` のメアド**: 個人用は `higukkr@gmail.com`、仕事用は `higuchi.kokoro@commune.co.jp`（旧仕事 / 新仕事どちらも commune）。
7. **Wantedly は無関係**。ユーザーは Commune 所属。requirements/design 内に Wantedly が出てきたら誤り（参考ブログの著者の所属）。
8. **`chezmoi apply` を旧PCで実行するのは Phase F**。それ以前に走らせると現状の symlink 構造が壊れる。

## 7. 引き継ぎ時のチェックリスト（次セッション開始時に確認）

- [ ] `git -C ~/.dotfiles branch --show-current` が `feat/chezmoi-migration` か
- [ ] `git -C ~/.dotfiles log --oneline -3` で 3コミット見える（最新は `docs(steering): mark Phase A-C complete...`）
- [ ] `chezmoi --version` が 2.70.x 以上
- [ ] `chezmoi data --source=$HOME/.dotfiles | grep -E "computerName|hostType|isWork|email"` が期待値
- [ ] `find ~/.dotfiles/home -type f | wc -l` で 14ファイル前後
- [ ] `.steering/20260428-chezmoi-migration/` にこのファイル含む md 6本 + txt 3本

## 8. リモートへの push について

**未push**。次セッションで作業継続するなら：

```bash
git -C ~/.dotfiles push -u origin feat/chezmoi-migration
```

別マシンで作業継続したい場合のみ push 推奨。今のPCでそのまま続けるなら未push でも支障なし。

## 9. このプロジェクトを終了する条件

- 新仕事PC `CMPC0397` で `chezmoi init zerebom && chezmoi apply` 一発で 30分以内にセットアップ完了
- master へ merge 済み、`Makefile` の旧 install ターゲット削除（または chezmoi ラッパ化）
- `git grep -i 'token\|secret\|password'` でシークレット平文出ない
- `tasklist.md` の振り返りセクション記入済み
