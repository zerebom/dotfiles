---
name: prefect-failure-investigator
description: Prefect Cloud の失敗フローランを調査・分析するスキル。「Prefectの失敗を調べて」「昨日こけたフローは？」「Prefect障害調査」「daily-orchestratorが落ちた原因」「productionのフロー失敗」「Prefectのバッジが赤い」などのリクエスト時に使用する。指定日の FAILED/CRASHED フローランを production 優先で一覧化し、ログから根本原因を特定してサマリーを出力する。
---

# Prefect Failure Investigator

commune-voice プロジェクトの Prefect Cloud 上のフロー失敗を優先度付きで調査する。

## 前提

- Prefect CLI は `prefect/` ディレクトリで `uv run prefect` 経由で実行
- 認証情報は `~/.prefect/profiles.toml` に格納
- **重要**: `prefect/.env` の `PREFECT_API_URL` がローカルサーバー向きのため、CLI 実行前に必ず環境変数を明示的に export すること

## ワークフロー

### Step 1: 認証情報の取得と export

`~/.prefect/profiles.toml` を読み、`PREFECT_API_URL`（`prefect.cloud` を含むURL）と `PREFECT_API_KEY` を取得して export する。

```bash
cat ~/.prefect/profiles.toml
export PREFECT_API_URL="<profiles.tomlから取得したURL>"
export PREFECT_API_KEY="<profiles.tomlから取得したKey>"
```

### Step 2: 失敗フローランの一覧取得

`scripts/list_failed_runs.py` で完全な UUID 付きの失敗一覧を取得する。production → staging の優先度順で出力される。

```bash
# 昨日の失敗（デフォルト）
python3 ~/.claude/skills/prefect-failure-investigator/scripts/list_failed_runs.py

# 特定日を指定（JST）
python3 ~/.claude/skills/prefect-failure-investigator/scripts/list_failed_runs.py --date 2026-03-13

# Production のみ
python3 ~/.claude/skills/prefect-failure-investigator/scripts/list_failed_runs.py --date 2026-03-13 --env production
```

### Step 3: ログの取得と分析（CLI）

Step 2 の UUID を使い、`prefect/` ディレクトリで CLI でログ取得。

```bash
cd <project-root>/prefect/

# ログ末尾を確認
uv run prefect flow-run logs <UUID> | tail -60

# エラー行のみ抽出
uv run prefect flow-run logs <UUID> | grep -E "(ERROR|Traceback|raise|Failed|Exception)"
```

#### 確認の優先順

1. **Production orchestrator** (daily/weekly-orchestrator) — どのブランドが失敗したか特定
2. **Production 子フロー** (topic_assign, data_transfer 等) — 具体的なエラー内容
3. **Staging orchestrator** — 低優先だが同じ原因なら production にも波及する可能性
4. **Staging 子フロー** — 最低優先

### Step 4: 根本原因の特定

ログのエラーメッセージに基づきコードベースを調査する。
既知のエラーパターンは [references/error-patterns.md](references/error-patterns.md) を参照。

調査対象:
- `prefect/src/flows/` — フロー定義
- `prefect/src/providers/` — クラスタリング等のプロバイダー
- `prefect/src/schemas/` — pandera スキーマ定義
- `prefect/pyproject.toml`, `prefect/uv.lock` — 依存関係バージョン

ライブラリバージョン変更の調査:
```bash
git log --oneline -p -- prefect/pyproject.toml prefect/uv.lock | grep -B5 -A5 "<パッケージ名>"
```

### Step 5: サマリー出力

以下の形式で調査結果をまとめる:

```markdown
## 失敗フロー調査結果（YYYY-MM-DD）

### Priority 1: Production
| フロー | ブランド | エラー | 根本原因 |
|--------|----------|--------|----------|

### Priority 2: Staging
| フロー | ブランド | エラー | 根本原因 |
|--------|----------|--------|----------|

### 対処案
- ...
```

## 注意事項

- daily-orchestrator は JST 02:00（UTC 前日 17:00）に実行。「3/13 のフロー」は UTC 3/12 17:00 〜 3/13 15:00
- weekly-orchestrator は毎週日曜 JST 05:00。手動実行は `auto-scheduled` タグなし
- orchestrator が FAILED でも子フローの大半は COMPLETED していることが多い。失敗ブランドだけ調査すればよい
