---
name: herdr
description: herdr（AI コーディングエージェント向けターミナルワークスペースマネージャ）を CLI から操作するスキル。「herdr でワークスペース作って」「別 workspace で agent を起動して」「herdr のペインを分割して」「エージェントの状態を見て」「herdr の設定を変えて」などのリクエスト時、または並列開発のために worktree + herdr ワークスペースを立てるときに使用する。どのリポジトリでも有効（commune-voice 内では commune-worktree スキルの手順を優先する）。
---

# herdr 操作

## 大原則: help を叩く。記憶に頼らない

herdr の CLI は自己文書化されており更新も速い。コマンドやオプションは記憶で書かず、
必ず `herdr <subcommand> --help` / 設定項目は `herdr --default-config` で現物を確認する。
このスキルに書くのは help では分からない環境固有の事実と、確立済みのレシピだけ。

## 操作前チェック

- `herdr status` でサーバー接続を確認する。Claude Code をターミナル外・SSH 等で動かしていると
  socket に繋がらないことがある。その場合 herdr 操作はスキップし、やろうとした内容（パス等）だけ報告する。

## この環境の固有事情

- **prefix は ctrl+s**（tmux に合わせて変更済み。デフォルトの ctrl+b ではない）。
- タブ/workspace 移動は **矢印キーにバインドしてある**。Karabiner が左Ctrl+hjkl をグローバルに
  矢印へ変換するため、ctrl+h/l は herdr に届かない。キーバインドを提案・変更するときはこの変換を前提にする。
- 設定は chezmoi 管理: ソースは dotfiles リポジトリの `home/dot_config/herdr/config.toml`。
  **ただし herdr 自身が `~/.config/herdr/config.toml` を書き換える**（onboarding フラグ、設定UI からの変更）。
  編集はリポジトリ側で行い `chezmoi apply` で反映しつつ、`chezmoi status` で drift を検知したら
  ホーム側の変更をリポジトリに逆同期（コピー）する。反映後は `herdr server reload-config`。
- Claude Code との連携 hook（`~/.claude/hooks/herdr-agent-state.sh` と settings.json の SessionStart 等）は
  `herdr integration install claude` が生成・管理する。手で編集しない。壊れたら再 install。

## レシピ: worktree + workspace で並列開発を立ち上げる

```bash
herdr workspace create --cwd "$DIR" --label "my-label" --focus
# ID は list の JSON から label で引く（.result.workspaces[]）
WS=$(herdr workspace list | jq -r '.result.workspaces[] | select(.label=="my-label") | .workspace_id')
herdr agent start claude --workspace "$WS" -- claude
herdr wait agent-status <pane_id> --status idle --timeout 60000   # 起動完了待ち
```

- 状態確認・操作: `herdr agent list` / `herdr agent read <target>` / `herdr agent send <target> <text>`
- 片付け: `herdr workspace close <workspace_id>`

## 踏んだ罠

- `herdr agent send` は**リテラル文字列を書くだけで Enter を送らない**。
  コマンドとして実行させたいときは `herdr pane run` を使う。
- `[keys]` の `split_vertical` / `split_horizontal` のどちらが左右/上下かは CLI から検証できない。
  変更したら実際にキーを叩いて確認する。

## 並列開発の提案トリガー

ユーザーが「並列で作業したい」「複数タスクを同時に」と言ったら、wtp で worktree を作り
herdr workspace + `agent start claude` で並列セッションを立てる構成を提案する（起動はユーザー承認後）。
