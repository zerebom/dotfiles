# Claude Code Configuration

このファイルはClaude Codeの動作設定を定義します。

## 通知設定

- YOU MUST: タスク完了またはユーザーにメッセージを返すときに最後に一度だけ `play -n synth 0.5 sine 1000-100 vol 0.2` コマンドを実行して通知する

## Worktree運用（Claude Code並列実行）

### いつworktreeを提案する？
以下の状況では、ユーザーにworktree使用を提案すること：
- 緊急割り込み（hotfix等）で現在の作業を中断する必要がある時
- 独立した複数タスクを並列で進められそうな時
- 長時間かかるタスクを任された時

### 提案の仕方
worktreeを使った方が良いと判断した場合、理由を説明してユーザーに確認を取る：
「このタスクは〇〇なので、worktreeを使って並列で進めた方が効率的だと思います。worktreeを作成しますか？」

### ツール
- **ccmanager**: 並列セッション管理UI（`ccmanager`で起動）
- **wtp**: worktree作成（`wtp add feature/xxx`）