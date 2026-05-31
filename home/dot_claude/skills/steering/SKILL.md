---
name: steering
description: This skill should be used when starting a multi-day task, creating project plans, or when the user mentions "steering", ".steering", "requirements", "design document", or "tasklist". It provides structured project documentation in .steering/ directory with requirements.md, design.md, and tasklist.md templates.
---

# Steering スキル

PM作業における大規模タスクの計画・進捗管理を支援するスキル。

## 目的

- `.steering/YYYYMMDD-タスク名/` ディレクトリの自動構造化
- requirements.md, design.md, tasklist.md の統一フォーマット提供
- tasklist.md に基づく進捗追跡

## 適用タイミング

以下の条件でこのスキルを適用:

1. **複数日にまたがる作業** - 1日で完了しない規模のタスク
2. **要件定義が必要な作業** - 曖昧な要求を明確化する必要がある
3. **成果物が複数ファイルにわたる作業** - 複数の変更箇所がある
4. ユーザーが明示的に「.steering を作って」と依頼した場合

## ワークフロー

### Phase 0: ヒアリング（曖昧さ解消）

ステアリング開始時に、以下の3つの質問で要件を明確化する:

1. **「何を達成したい？」**（ゴール）
   - 曖昧な依頼を具体的な目標に変換

2. **「どうなったら成功？」**（成功基準）
   - できれば定量的に定義（精度XX%、〇〇が確認できる等）

3. **「うまくいかなかったらどうする？」**（フォールバック）
   - 第1案失敗時の代替案、撤退基準

**タスク種別に応じた追加質問**:
- 分析/PoC系（「分析」「PoC」「実験」を含む）→ 「具体的な分析手法は？」「精度の基準は？」
- 実装系（「実装」「開発」「構築」を含む）→ 「テスト計画は？」
- 移行系（「移行」「統合」を含む）→ 「ロールバック手順は？」

ヒアリング結果を踏まえて、Phase 1へ進む。

### Phase 1: ステアリングディレクトリ作成

1. 現在日付を取得（YYYYMMDD形式）
2. タスク名を kebab-case で決定
3. `.steering/YYYYMMDD-タスク名/` を作成

```
.steering/20260102-voice-migration/
├── requirements.md
├── design.md
└── tasklist.md
```

### Phase 2: ドキュメント作成

templates/ 配下のテンプレートを使用:

1. `requirements.md` - 背景・目標・決定事項を記録
2. `design.md` - 設計方針・技術的アプローチを記録
3. `tasklist.md` - 具体的なタスクをチェックリスト形式で記録

各ファイルは**1つずつ作成し、ユーザー承認後に次へ進む**。

**レビュー推奨**: design.md 作成後、品質に不安がある場合は `strict-writing-reviewer` でレビューを依頼できる。特に以下の場合に有効:
- 分析/PoC系タスクで精度基準が曖昧なとき
- フォールバック戦略が十分か確認したいとき
- 複雑なタスクで抜け漏れが心配なとき

### Phase 3: 実装中の進捗管理

tasklist.md の更新ルール:

- タスク開始時: `[ ]` → `[x]` に変更
- タスク完了時: 完了を確認
- **TodoWrite は補助、tasklist.md が正式記録**

### Phase 4: 振り返り

全タスク完了後、tasklist.md の「実装後の振り返り」セクションを更新:

- 実装完了日
- 計画と実績の差分
- 学んだこと
- 次回への改善提案

## テンプレート

テンプレートファイルは `templates/` ディレクトリを参照:

- `templates/requirements.md` - 要件定義テンプレート
- `templates/design.md` - 設計書テンプレート
- `templates/tasklist.md` - タスクリストテンプレート

## current-context.md との連携

大規模PJを開始したら、`.steering/current-context.md` にポインタを追加:

```markdown
## Active Work
- [ ] Voice PRD作成 → 詳細は `.steering/20260102-voice-prd/` 参照
```

## 重要なルール

1. **1ファイルずつ作成・承認** - まとめて作成しない
2. **tasklist.md を常に最新に** - 実装中は随時更新
3. **全タスク完了まで作業継続** - スキップは技術的理由のみ許可
4. **振り返りを必ず記録** - 未完了タスクがある状態で終了しない
