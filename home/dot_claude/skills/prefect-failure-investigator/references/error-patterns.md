# 既知のエラーパターン

## Production で観測されたエラー

### 1. UMAP _raw_data AttributeError

```
AttributeError: 'UMAP' object has no attribute '_raw_data'
```

- **発生箇所**: `src/providers/cluster.py` → `umap/umap_.py` の `transform()`
- **発生フロー**: `topic_assign`（`fit_cluster=False` でキャッシュモデルをロード）
- **原因候補**:
  - GCS 上の pickle モデルが古い UMAP バージョンで作成された
  - `topic_cluster`（`fit_cluster=True`）が正常完了していない、またはモデル保存が不完全
  - Docker イメージのリビルドで依存関係が変化した
- **調査手順**:
  1. 該当ブランドの直近の `topic_cluster` 実行が COMPLETED か確認
  2. `pyproject.toml` / `uv.lock` の `umap-learn` バージョンが変わっていないか確認
  3. Cloud Build 履歴で Docker イメージ更新タイミングを確認
- **対処**: 該当ブランドに対して `topic_cluster`（fit モード）を再実行

### 2. Pandera SchemaError (topic_type)

```
SchemaError: column 'topic_type' not in DataFrameSchema
```

- **発生箇所**: `src/flows/commune_post_topic_flow.py` → `TopicsSchema.validate()`
- **発生フロー**: `topic_assign` の `assign_normalized_topic` タスク
- **原因**: GCS にキャッシュされたトピックデータに `topic_type` カラムが含まれているが、
  `TopicsSchema`（pandera, `strict=True`）は `topic_id` と `topic_name` のみ許可
- **背景**: feature ブランチで `topic_type` が追加されたが main 未マージ。
  feature ブランチのコードで `topic_cluster` が実行された結果、GCS データにカラムが追加された
- **対処**: main ブランチのコードで `topic_cluster` を再実行するか、スキーマを更新

### 3. Cloud Run Job タイムアウト

```
Reached configured timeout of XXXXs for cloud run job
```

- **発生フロー**: orchestrator が子フローの完了を待機中にタイムアウト
- **原因**: 子フロー（topic_assign 等）の失敗・リトライが連鎖してタイムアウト上限に到達
- **調査**: 子フローの個別ログを確認して根本原因を特定

### 4. data_transfer 失敗

```
RuntimeError: data_transfer failed for brand_id=XXXX
```

- **発生フロー**: `daily_orchestrator` → `data_transfer`
- **原因候補**: BigQuery クエリ失敗、ネットワークエラー、Cloud Run リソース不足
- **調査**: 子フローの `data_transfer` ログを確認

## フロー構成の理解

### daily-orchestrator（毎日 JST 02:00）
1. `data_transfer` → 2. `metadata_generation` → 3. `topic_assign`（各ブランド順次、ブランド間は並列）

### weekly-orchestrator（毎週日曜 JST 05:00）
1. `topic_cluster`（全ブランド並列）

### 環境判別
- **Production**: tags に `production` 含む、work pool = `commune-voice-production-cloud-run-v2-pool`
- **Staging**: tags に `staging` 含む、brands = [9, 73, 1514]
- **Production brands**: 33ブランド（prefect.production.yaml 参照）
