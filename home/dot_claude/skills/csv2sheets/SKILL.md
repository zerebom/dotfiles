---
name: csv2sheets
description: ローカルのCSVファイルをGoogle Spreadsheetにアップロードするスキル。複数CSVを1つのスプレッドシートの各シートに配置する。gog CLI（gogcli）を使用。「CSVをスプレッドシートにアップロード」「CSVをGoogle Sheetsに」「スプレッドシートに貼り付けて」「csv2sheets」などのリクエスト時に使用。
---

# csv2sheets

ローカルCSVファイルを `gog` CLI 経由で Google Spreadsheet にアップロードする。

## 前提条件

- `gog` CLI がインストール済みで認証済であること (`gog status` で確認)
- `python3` が利用可能であること（CSV→JSON変換に使用）

## ワークフロー

### 1. CSVファイルの特定

ユーザーからCSVファイルのパスを受け取る。ファイルが存在することを確認する。

```bash
ls -la path/to/files/*.csv
```

### 2. シート名の確認

ユーザーに各CSVのシート名を聞く。日本語OK。

提示テンプレート:
```
以下のCSVをアップロードします。各シート名を確認してください：
| # | CSVファイル | シート名（デフォルト） |
|---|-----------|-------------------|
| 1 | data.csv  | data              |
| 2 | users.csv | users             |

シート名を変更したい場合は教えてください。そのままでよければ進めます。
```

デフォルトのシート名はファイル名（拡張子除く）。

### 3. スプレッドシートのタイトル確認

デフォルト: `CSV Upload YYYY-MM-DD`（`/bin/date +%Y-%m-%d` で取得）

ユーザーが別のタイトルを指定した場合はそれを使用。

### 4. アップロード実行

スクリプトを実行:

```bash
~/.claude/skills/csv2sheets/scripts/csv2sheets.sh \
  -t "スプレッドシートのタイトル" \
  "path/to/data.csv:シート名1" \
  "path/to/users.csv:シート名2"
```

#### オプション

| フラグ | 説明 |
|--------|------|
| `-t, --title TITLE` | スプレッドシートのタイトル |
| `-a, --account EMAIL` | 使用する Google アカウント |
| `-i, --spreadsheet-id ID` | 既存スプレッドシートにシート追加 |
| `-f, --folder-id ID` | Drive 保存先フォルダ |
| `--no-open` | ブラウザを開かない |

#### 引数フォーマット

`CSVパス:シート名` の形式。シート名省略時はファイル名がデフォルト。

```bash
# シート名指定
"report.csv:月次レポート"

# シート名省略（シート名 = "report"）
"report.csv"
```

### 5. 結果の報告

スクリプトが出力するスプレッドシートURLをユーザーに伝える。ブラウザで自動的に開かれる。

## エラー対応

- `gog` が見つからない → `brew install gogcli` を案内
- 認証エラー → `gog login <email>` を案内
- CSV読み込みエラー → エンコーディング確認（UTF-8-BOM対応済み）
