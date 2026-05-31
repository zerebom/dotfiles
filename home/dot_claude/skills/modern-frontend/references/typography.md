# タイポグラフィリファレンス

## 基本原則

### 1. 可読性が最優先

```
チェック項目:
- 本文は16px以上（モバイルでも14px以上）
- 行間は1.5〜1.75（本文）
- 文字間は詰めすぎない
- 1行あたり45〜75文字程度（日本語は25〜40文字）
```

### 2. 階層を明確に

```
視覚的な階層:
- 見出し → 太く、大きく
- 本文 → 標準
- 補足 → 小さく、薄く

サイズの比率:
- 各レベルで1.2〜1.5倍の差をつける
```

### 3. フォント数は最小限

```
推奨:
- 1種類（ウェイト違いで変化をつける）
- 最大2種類（見出し + 本文）

避ける:
- 3種類以上のフォントを混在
- 意味なくフォントを変える
```

---

## フォント選択ガイド

### 日本語フォント

```
信頼・フォーマル:
- Noto Sans JP
- Hiragino Sans (macOS)
- 游ゴシック (Windows)
- BIZ UDGothic

親しみ・カジュアル:
- Rounded Mplus 1c
- M PLUS Rounded 1c

高級・プレミアム:
- Noto Serif JP
- 游明朝
- Hiragino Mincho
```

### 欧文フォント

```
信頼・フォーマル:
- Inter
- -apple-system, BlinkMacSystemFont (システムフォント)

革新・先進:
- Inter
- Geist (Vercel)
- DM Sans

親しみ・カジュアル:
- Nunito
- Quicksand
- Poppins

高級・プレミアム:
- Cormorant
- Playfair Display
- EB Garamond
```

### Google Fonts CDN

```html
<!-- Noto Sans JP -->
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">

<!-- Inter -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

<!-- Nunito -->
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700&display=swap" rel="stylesheet">

<!-- DM Sans -->
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&display=swap" rel="stylesheet">
```

---

## サイズシステム

### 推奨スケール

```css
:root {
  /* ベースサイズ */
  --text-xs: 0.75rem;    /* 12px - 注釈、ラベル */
  --text-sm: 0.875rem;   /* 14px - 補足テキスト */
  --text-base: 1rem;     /* 16px - 本文 */
  --text-lg: 1.125rem;   /* 18px - リード文 */
  --text-xl: 1.25rem;    /* 20px - 小見出し */
  --text-2xl: 1.5rem;    /* 24px - セクション見出し */
  --text-3xl: 1.875rem;  /* 30px - ページ見出し */
  --text-4xl: 2.25rem;   /* 36px - ヒーロー見出し */
  --text-5xl: 3rem;      /* 48px - 大きなヒーロー */
}
```

### レスポンシブタイポグラフィ

```css
/* clampを使った流体タイポグラフィ */
h1 {
  font-size: clamp(1.875rem, 4vw, 3rem);
}

h2 {
  font-size: clamp(1.5rem, 3vw, 2.25rem);
}

/* 本文は固定でOK */
body {
  font-size: 1rem;
}
```

---

## 行間・文字間

### 行間（line-height）

```css
/* 見出し: 詰め気味 */
h1, h2, h3 {
  line-height: 1.2;
}

/* 本文: ゆったり */
p, li {
  line-height: 1.6;
}

/* 長文: さらにゆったり */
article p {
  line-height: 1.75;
}
```

### 文字間（letter-spacing）

```css
/* 見出し: 少し詰める（日本語の場合は調整不要なことも） */
h1, h2 {
  letter-spacing: -0.02em;
}

/* 本文: デフォルトのまま */
p {
  letter-spacing: normal;
}

/* 大文字のラベル: 少し広げる */
.label-uppercase {
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
```

---

## 避けるべきパターン

### 可読性を損なうスタイル

```
避ける:
- 本文14px未満
- 行間1.3未満（本文）
- 薄すぎるフォントウェイト（300以下で本文）
- コントラスト不足の文字色

特に注意:
- 白背景に薄いグレー文字
- ダーク背景に暗いグレー文字
```

### 一貫性のないスタイル

```
避ける:
- 見出しごとにフォントが違う
- サイズのルールがバラバラ
- 太さの使い方に一貫性がない
```

### 装飾的すぎるフォント

```
使用注意:
- 筆記体（Script）
- 極端に太い/細いディスプレイフォント

使って良い場面:
- ロゴ
- 短いキャッチコピー
- 装飾的な要素（本文には使わない）
```

---

## 実装例

### 基本設定

```css
html {
  font-size: 16px; /* ベース */
}

body {
  font-family: 'Inter', 'Noto Sans JP', sans-serif;
  font-size: 1rem;
  line-height: 1.6;
  color: var(--text-primary);
  -webkit-font-smoothing: antialiased;
}

h1, h2, h3, h4, h5, h6 {
  font-weight: 700;
  line-height: 1.2;
  color: var(--text-primary);
}

h1 { font-size: clamp(1.875rem, 4vw, 3rem); }
h2 { font-size: clamp(1.5rem, 3vw, 2.25rem); }
h3 { font-size: 1.25rem; }

p {
  margin-bottom: 1rem;
}

small, .text-sm {
  font-size: 0.875rem;
  color: var(--text-secondary);
}
```
