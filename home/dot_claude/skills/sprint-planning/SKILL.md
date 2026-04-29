---
name: sprint-planning
description: Voice チームの Sprint Planning 準備を支援するスキル。Linear MCP から現スプリントの進捗を取得しメンバー別サマリーを作成、戦略ドキュメントとバックログから次スプリントの Goal・チケット案を提案し、MTG用アジェンダスクリプトを生成する。「スプリントプランニング」「sprint planning」「次スプリントの準備」「プランニング準備」などのリクエスト時に使用する。
---

# Sprint Planning Prep

Voice チーム（5名、2週間サイクル）の Sprint Planning MTG 準備ドキュメントを生成する。

## Linear MCP データ取得のコツ

MCP は JSON で大量データを返すため、効率的に取得・整理する工夫が必要。

### 基本原則: フィルタで絞ってから取得する

```
❌ 全件取得 → 手元で仕分け（トークン浪費・レスポンス肥大）
✅ パラメータで絞り込み → 必要な塊だけ取得
```

### 取得パターン別ガイド

| やりたいこと | ツール | 絞り込みパラメータ | 備考 |
|-------------|--------|------------------|------|
| 現Cycleのチケット一覧 | `list_issues` | `team: "Voice"`, `cycle: "current"` | cycle に `"current"` が使える |
| メンバー別チケット | `list_issues` | `team: "Voice"`, `assignee: "{名前}"` | メンバー毎に呼び分ける |
| ステータス別 | `list_issues` | `team: "Voice"`, `state: "In Progress"` | `state` は status name で指定 |
| バックログ | `list_issues` | `team: "Voice"`, `state: "backlog"` | state type も可 |
| PJ別チケット | `list_issues` | `project: "{PJ名 or slug}"` | PJ単位で深掘り時 |
| アクティブPJ一覧 | `list_projects` | `team: "Voice"` | status でさらに絞れる |
| PJ詳細 | `get_project` | `query: "{PJ名}"` | `includeMilestones: true` で MS も取得 |
| 現Cycle情報 | `list_cycles` | `teamId: "{teamId}"`, `type: "current"` | teamId は `list_teams` で事前取得 |
| チームメンバー | `list_users` | `team: "Voice"` | 名前・ID の対応表として使う |

### レスポンスが大きい場合の対処

1. **`limit` で件数制限**: デフォルト50件。多すぎる場合は `limit: 20` 等で絞る
2. **複数回に分けて取得**: assignee や state でフィルタし、小分けにして取得→統合
3. **cursor でページネーション**: 結果に `cursor` が含まれていたら次ページがある。必要な分だけ追加取得
4. **必要な深さだけ掘る**: `list_projects` で概況把握 → 気になるPJだけ `get_project` で詳細取得

### 推奨取得順序

```
1. list_teams(query: "Voice")           → teamId 確保
2. list_cycles(teamId, type: "current") → 現Cycle名・期間
3. list_users(team: "Voice")            → メンバー名一覧
4. list_issues(team: "Voice", cycle: "current", limit: 100) → 現Cycleの全チケット
   ※ 100件超なら assignee 別に分割取得
5. list_issues(team: "Voice", state: "backlog", limit: 50)  → バックログ
6. list_projects(team: "Voice")         → PJ一覧
7. get_project(query: "{PJ名}")         → 要注目PJのみ深掘り
```

## ワークフロー

### Phase 1: 情報収集（並列実行）

以下を並列で取得する。

**Linear MCP (`mcp__linear-server__*`) から取得:**

| # | ツール | パラメータ | 目的 |
|---|--------|----------|------|
| 1 | `list_teams` | `query: "Voice"` | チームID取得（後続クエリの前提） |
| 2 | `list_cycles` | `teamId: "{1で取得}", type: "current"` | 現Cycle名・期間・番号 |
| 3 | `list_users` | `team: "Voice"` | メンバー名・ID対応表 |
| 4 | `list_issues` | `team: "Voice", cycle: "current", limit: 100` | 現Cycleの全チケット |
| 5 | `list_issues` | `team: "Voice", state: "backlog", limit: 50` | バックログ候補 |
| 6 | `list_projects` | `team: "Voice"` | アクティブPJ一覧 |
| 7 | `list_documents` | `limit: 10` | 直近更新ドキュメント（必要時のみ） |

> **実行順序**: #1 を先に実行 → teamId を得てから #2〜#7 を並列実行。
> #4 が100件超の場合は assignee 別に分割取得する。

**ローカルから取得（Linear と並列可）:**
1. `steering/current-context.md` → 現在のコンテキスト
2. `work/strategy/` 配下の直近更新ファイル（roadmap, OKR等）
3. `work/products/voice/` 配下の直近更新ファイル（PRD, delivery_and_plan等）

### Phase 2: 分析・構造化

収集した情報から以下を分析する。

**現スプリント進捗分析:**
- メンバー別にチケットを分類（Done / In Progress / Todo / Blocked）
- 完了率を算出（Done数 / 全チケット数）
- ブロック・遅延しているチケットを特定
- 現スプリントのゴール達成状況を評価

**次スプリント方針検討:**
- 戦略ドキュメント（OKR, roadmap）から優先テーマを抽出
- 進行中プロジェクトの次ステップを特定
- バックログから優先度の高いチケットを選定
- 各メンバーのキャパシティと専門性を考慮した配分案

### Phase 3: ドキュメント生成

以下の構造でMarkdownファイルを生成する。出力先は `daily/meetings/YYYY-MM-DD-sprint-planning-prep.md`。

```markdown
---
title: "Sprint Planning Prep - Sprint XX"
type: meeting
created: YYYY-MM-DD
status: draft
tags: [voice, sprint-planning]
---

# Sprint Planning Prep - Sprint XX

## 1. 現スプリント進捗サマリー

### 全体概要
- Sprint Goal: [現スプリントのゴール]
- 完了率: X/Y チケット (Z%)
- 期間: MM/DD - MM/DD

### メンバー別進捗

#### [メンバー名]
| Status | チケット | Priority |
|--------|---------|----------|
| Done   | VOI-XXX: タイトル | High |
| In Progress | VOI-XXX: タイトル | Medium |

[特記事項・ブロッカーがあれば記載]

（各メンバー分繰り返し）

### 注意事項・リスク
- [ブロックされているチケットとその理由]
- [期間内に完了しなさそうなチケット]

## 2. 次スプリント提案

### Sprint Goal 案
> [戦略的方向性を踏まえた次スプリントのゴール案]

**根拠:**
- [なぜこのゴールが妥当か、戦略との紐付け]

### チケット案

#### 新規提案
| チケット案 | 担当候補 | 優先度 | 根拠 |
|-----------|---------|--------|------|
| [タイトル] | [名前] | High | [理由] |

#### バックログから移動推奨
| チケット | 担当候補 | 優先度 | 根拠 |
|---------|---------|--------|------|
| VOI-XXX: [タイトル] | [名前] | High | [理由] |

#### 前スプリントからの持ち越し
| チケット | 担当 | ステータス | 備考 |
|---------|------|----------|------|
| VOI-XXX: [タイトル] | [名前] | In Progress | [残作業] |

## 3. アジェンダスクリプト

### 開始（2分）
「今スプリントの振り返りと次スプリントの方針を共有します」

### 現スプリント振り返り（10分）
- 全体の完了率を共有
- 各メンバーに一言ずつ状況確認
  - [メンバー名]: 「[確認したいポイント]」
- ブロッカー・課題の確認

### 次スプリント方針（10分）
- Sprint Goal の提示と合意
- 「[ゴール案]を次のゴールにしたい。理由は〜」
- メンバーからのフィードバック

### チケット確認・調整（15分）
- 提案チケットの確認
- 各メンバーのキャパシティ確認
- 優先順位の調整

### クロージング（3分）
- 合意事項の確認
- 次のアクション
```

### Phase 4: ユーザー確認

生成したドキュメントをユーザーに提示し、以下を確認する:
- 現スプリントの進捗に認識のずれがないか
- Sprint Goal 案の方向性は合っているか
- チケット案の追加・削除・担当変更はあるか
- アジェンダスクリプトの調整箇所はあるか

ユーザーのフィードバックを反映して最終版を確定する。

## 判断ガイドライン

### Sprint Goal の設定基準
- OKR/ロードマップとの整合性を最優先
- 前スプリントの持ち越しが多い場合は「完了させる」系のゴールを検討
- 新機能とバグ修正のバランスを考慮（全部新規は危険）

### チケット配分の原則
- 1メンバーあたり 3-5チケット/スプリントが目安
- 不確実性の高いチケットは少なめに見積もる
- 各メンバーの得意領域・現在の担当領域を考慮

### 情報が不足している場合
- メンバーの進捗が不明瞭 → 「1on1で確認すべき項目」としてフラグ
- 戦略的方向性が不明 → ユーザーに確認してから Goal を提案
