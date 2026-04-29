---
name: imagegen
description: Gemini API（gemini-3-pro-image-preview）を使った画像生成・編集スキル。スライド、ドキュメント、UIモックアップ、SNS画像などの作成時に、プロンプトから画像を生成する。単体での使用も、他のスキル（pptx、docx、modern-frontend等）からの呼び出しも可能。
---

# 画像生成スキル（imagegen）

Gemini API（gemini-3-pro-image-preview）を使用して画像を生成・編集するスキル。

## 用途

- スライド・ドキュメント用のビジュアル生成
- UIモックアップ用の画像素材
- SNS投稿用の画像
- 既存画像の編集・スタイル変換

## 重要: 実行時の注意

**環境変数 `GEMINI_API_KEY` は既にシェルに設定済みです。**

コマンド実行時に API キーを含めないでください：
- ❌ `GEMINI_API_KEY="..." python generate.py --prompt "..."`
- ✅ `python ~/.claude/skills/imagegen/generate.py --prompt "..."`

スクリプトは自動的に環境変数から API キーを読み取ります。

## 基本的な使い方

### Text-to-Image（テキストから画像生成）

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "モダンなコーヒーショップのロゴ、ミニマルデザイン、白背景" \
  --output ./logo.png
```

### Image-to-Image（画像編集）

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "背景を夕焼けに変更" \
  --input ./original.png \
  --output ./edited.png
```

## オプション一覧

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--prompt` | 画像の説明または編集指示（必須） | - |
| `--output` | 出力ファイルパス（必須） | - |
| `--input` | 入力画像（編集時に使用） | なし |
| `--aspect-ratio` | アスペクト比 | `1:1` |
| `--size` | 解像度（1K / 2K / 4K） | `1K` |
| `--api-key` | APIキー（環境変数より優先） | 環境変数から取得 |

### 対応アスペクト比

`1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9`

### 解像度と出力サイズ（1:1の場合）

| サイズ | 解像度 |
|--------|--------|
| 1K | 1024x1024 |
| 2K | 2048x2048 |
| 4K | 4096x4096 |

## プロンプトのコツ

### 良いプロンプトの書き方

**シーンを描写する（キーワードの羅列ではなく）**

```
❌ "猫, かわいい, 窓, 日光"
✅ "窓辺で日向ぼっこをしている茶トラの猫。柔らかい午後の光が差し込み、猫は目を細めてリラックスしている。"
```

**写真風の場合はカメラ用語を使う**

```
"85mmポートレートレンズで撮影したような、浅い被写界深度のポートレート。
 ゴールデンアワーの柔らかい光、背景はボケている。"
```

**スタイルを明確に指定**

```
"ミニマリストなイラスト、フラットデザイン、パステルカラー"
"ゴッホの星月夜風の油絵タッチ"
"Studio Ghibli風のアニメーション背景"
```

## 使用例

### 1. プレゼン用のコンセプト画像

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "未来的なスマートシティの俯瞰図。緑豊かな屋上庭園、空飛ぶ車、ソーラーパネル。クリーンで明るい色調。" \
  --output ./smart_city.png \
  --aspect-ratio 16:9 \
  --size 2K
```

### 2. ロゴデザイン

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "コーヒーショップ 'Morning Brew' のモダンなロゴ。コーヒーカップと太陽を組み合わせたシンプルなデザイン。白背景。" \
  --output ./logo.png \
  --aspect-ratio 1:1
```

### 3. 既存画像のスタイル変換

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "この写真を水彩画風に変換。柔らかいタッチで、色は少し淡く。" \
  --input ./photo.jpg \
  --output ./watercolor.png
```

### 4. SNS用画像

```bash
python ~/.claude/skills/imagegen/generate.py \
  --prompt "『新商品発売！』のテキストが入ったSNS告知画像。明るくポップなデザイン。" \
  --output ./announcement.png \
  --aspect-ratio 1:1 \
  --size 2K
```

## 他のスキルからの呼び出し

他のスキル（pptx、docx等）から画像が必要な場合、このスキルを使って生成できる。

```python
import subprocess

result = subprocess.run([
    "python", "~/.claude/skills/imagegen/generate.py",
    "--prompt", "ビジネスミーティングのイラスト",
    "--output", "/tmp/meeting.png",
    "--aspect-ratio", "16:9"
], capture_output=True, text=True)

if result.returncode == 0:
    # /tmp/meeting.png が生成された
    pass
```

## 注意事項

- 生成される画像にはSynthID透かしが含まれます
- 著作権のある作品の直接的な複製は避けてください
- 人物の顔を含む画像の編集は、元の特徴が変わる場合があります
