---
name: smart-tag-experiment
description: commune-voiceプロジェクトでスマートタグのクラスタリング実験を実行するスキル。「〇〇ブランドでスマートタグ実験を実行したい」「brand_id=XXXでCEP分析したい」「新しいブランドでクラスタリング実験」などのリクエスト時に使用。BigQueryからデータ取得→クラスタリング→GCS出力→ローカルダウンロードの一連のワークフローを実行する。
---

# Smart Tag Experiment

commune-voiceのnew_batchでスマートタグのクラスタリング実験を実行するワークフロー。

## 最初にユーザーに確認すること

実行前に以下を確認:
1. **brand_id**: 対象ブランドのID（例: 3332）
2. **実験名**: 英語で（例: ajinomoto_apt, toyoko_inn_cep）

## Workflow

### Step 0: ブランチ確認・移動

commune-voiceリポジトリで`feature/csv-clustering-support`ブランチにいることを確認。いない場合は安全に移動:

```bash
# 現在のブランチと状態を確認
git status && git branch --show-current
```

`feature/csv-clustering-support`でない場合:
```bash
# 未コミットの変更がある場合はstash
git stash

# ブランチ移動
git checkout feature/csv-clustering-support

# 必要に応じてstash復元
git stash pop
```

### Step 1: 実験ディレクトリの作成

既存の実験configをコピー:

```bash
cp -r new_batch/experiments/toyoko_inn_cep new_batch/experiments/<experiment_name>
```

`config.yaml`のdescriptionを更新:

```yaml
exp:
  description: <ブランド名>のカテゴリーエントリーポイント（CEP）抽出実験
```

### Step 2: クラスタリング実行

```bash
docker compose run --rm new_batch uv run python src/main.py smart_tags cluster \
  --brand-ids <brand_id> \
  --exp-name <experiment_name> \
  --skip-db \
  --no-cache
```

**注**: `--skip-db`はデフォルトで付ける（DBへの保存をスキップ）

### Step 3: GCSからデータダウンロード

出力先: `/Users/zerebom/ghq/github.com/dayone-jp/commune-ds-poc/khiguchi/voice-adhoc-analysis/data/<experiment_name>/`

```bash
OUTPUT_DIR=/Users/zerebom/ghq/github.com/dayone-jp/commune-ds-poc/khiguchi/voice-adhoc-analysis/data/<experiment_name>
mkdir -p $OUTPUT_DIR

gcloud storage cp "gs://commune-voice-staging-voice-smart-tag-generator/experiments/<experiment_name>/brand_id=<brand_id>/posts.csv" $OUTPUT_DIR/
gcloud storage cp "gs://commune-voice-staging-voice-smart-tag-generator/experiments/<experiment_name>/brand_id=<brand_id>/relations.csv" $OUTPUT_DIR/
gcloud storage cp "gs://commune-voice-staging-voice-smart-tag-generator/experiments/<experiment_name>/brand_id=<brand_id>/smart_tags.csv" $OUTPUT_DIR/
```

### Step 4: 追加カラムのJOIN

posts.csvにbox_name, category_name, url, post_titleを追加:

```bash
# BigQueryから追加カラムを取得
bq query --use_legacy_sql=false --format=csv --max_rows=10000 "
SELECT
  CAST(post_id AS STRING) as post_id,
  box_name,
  category_name,
  post_url as url,
  post_title
FROM \`useful-theory-142502.dm_dept_customer_success.post_actions_count\`
WHERE brand_id = <brand_id>
" > /tmp/extra_cols.csv
```

```bash
# commune-ds-pocでpandasを使用してマージ
cd /Users/zerebom/ghq/github.com/dayone-jp/commune-ds-poc && uv run python << 'EOF'
import pandas as pd
posts_df = pd.read_csv('<OUTPUT_DIR>/posts.csv')
posts_df['post_id'] = posts_df['post_id'].astype(str)
extra_df = pd.read_csv('/tmp/extra_cols.csv')
extra_df['post_id'] = extra_df['post_id'].astype(str)
merged_df = posts_df.merge(extra_df, on='post_id', how='left')
merged_df.to_csv('<OUTPUT_DIR>/posts.csv', index=False)
print(f"Rows: {len(merged_df)}, Columns: {list(merged_df.columns)}")
EOF
```

### Step 5: 結果確認

ヘッダーがtoyoko_inn_cepと一致しているか確認:

```bash
head -1 /Users/zerebom/ghq/github.com/dayone-jp/commune-ds-poc/khiguchi/voice-adhoc-analysis/data/toyoko_inn_cep/posts.csv
head -1 <OUTPUT_DIR>/posts.csv
```

## Output Files

| ファイル | カラム |
|---------|--------|
| posts.csv | post_id, brand_id, text, created_at, box_name, category_name, url, post_title |
| relations.csv | post_id, raw_smart_tag_id, smart_tag_id, smart_tag_name, category |
| smart_tags.csv | smart_tag_id, smart_tag_name, category |
