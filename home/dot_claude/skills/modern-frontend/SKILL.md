---
name: modern-frontend
description: 仕様書に基づいてフロントエンドを実装するスキル。プランニングスキルで作成された仕様書、または明確な要件がある状態で、目的・対象に適したビジュアルで実装する。可読性・情報優先・目的整合を不可侵の原則とし、装飾は最小限に抑える。
---

# モダンフロントエンド実装スキル

2025年基準の洗練されたフロントエンドを実装する。
可読性とアクセシビリティを絶対的な基盤としつつ、「深み」「空気感」「信頼感」のあるUIを構築する。

## 前提条件

- 「何を作るか」が明確な状態で使用する（プランニングスキルで要件定義済み）
- 特段の指定がない限り、Tailwind CSS を使用する
- React の場合は Lucide React をアイコンに使用

---

## 不可侵の原則

以下の3つは絶対に守る。

### 1. 可読性第一

- コントラスト比 4.5:1 以上（WCAG AA準拠）
- 背景にテキストを溶け込ませない
- 装飾がテキストの可読性を損なわない

### 2. 構造的階層

- 色ではなく「文字サイズ」「太さ」「余白」で情報の親子関係を示す
- 最も重要な情報が最も目立つ

### 3. 目的整合

- すべてのデザイン要素は目的に貢献する
- 仕様書の目的・対象・トーンに合っているか常に確認

---

## デザインシステム

### 配色（Tailwind）

純粋な黒(#000)や白(#fff)は避け、目に優しいオフカラーを使用する。

#### ライトテーマ

```
背景:       bg-white, bg-slate-50
テキスト:   text-slate-900（主）, text-slate-500（副）
ボーダー:   border-slate-200
```

#### ダークテーマ

```
背景:       bg-slate-950, bg-zinc-950
テキスト:   text-slate-50（主）, text-slate-400（副）
ボーダー:   border-white/10, border-slate-700
```

#### アクセントカラー

- ブランドカラーは1色に絞る
- 彩度を落としすぎない（例: indigo-600, teal-600, emerald-600）
- CTAボタン、リンク、強調に一貫して使用

---

## 質感と奥行き

フラットデザインではなく「レイヤー構造」を意識する。

### 影（Shadow）

濃い影は避け、広範囲にぼかした薄い影を使う。

```html
<!-- 推奨 -->
<div class="shadow-lg shadow-slate-200/50">...</div>
<div class="shadow-xl shadow-black/5">...</div>

<!-- 避ける -->
<div class="shadow-2xl shadow-black">...</div>
```

### ボーダー

繊細で薄いボーダーで境界を示す。

```html
<!-- ライトテーマ -->
<div class="border border-slate-200">...</div>

<!-- ダークテーマ -->
<div class="border border-white/10">...</div>
```

### グラスモーフィズム（条件付き許可）

背景ぼかしは、ボーダーとセットで使用する場合のみ許可。

```html
<!-- 許可: ボーダーとセット -->
<div class="bg-white/80 backdrop-blur-md border border-white/50">...</div>

<!-- 禁止: ボーダーなし、または可読性を損なう使用 -->
<div class="bg-white/20 backdrop-blur-sm">読みにくいテキスト</div>
```

---

## タイポグラフィ

### フォント選択

```html
<!-- 日本語 -->
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;600;700&display=swap" rel="stylesheet">

<!-- 英数字（必要に応じて） -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### サイズと行間

```html
<!-- 見出し: 大きく、詰め気味 -->
<h1 class="text-4xl sm:text-5xl font-bold tracking-tight">...</h1>

<!-- 本文: 行間ゆったり -->
<p class="text-base leading-relaxed text-slate-600">...</p>
```

### 強調の表現

太字だけでなく、グレーとの対比で強調する。

```html
<p class="text-slate-500">
  これは通常のテキストで、
  <span class="text-slate-900 font-medium">ここが強調</span>
  されています。
</p>
```

---

## レイアウト

### Bento Grid

情報をカード（区画）に整理して配置する。

```html
<div class="grid grid-cols-12 gap-5">
  <div class="col-span-7">大きいカード</div>
  <div class="col-span-5">中くらいのカード</div>
  <div class="col-span-5">中くらいのカード</div>
  <div class="col-span-7">大きいカード</div>
</div>
```

### 余白

窮屈さを避ける。`p-4` よりも `p-6`, `p-8` を積極的に使う。

```html
<!-- 推奨: ゆったり -->
<div class="p-8 sm:p-12">...</div>

<!-- 避ける: 窮屈 -->
<div class="p-2">...</div>
```

### 角丸

モダンな印象を与えるため、少し大きめにする。

```html
<!-- 推奨 -->
<div class="rounded-xl">...</div>
<div class="rounded-2xl">...</div>

<!-- 避ける: 小さすぎる -->
<div class="rounded">...</div>
```

---

## マイクロインタラクション

静止画を作らない。ユーザー操作に対するフィードバックを実装する。

### Hover効果

色が変わるだけでなく、物理的な挙動を入れる。

```html
<!-- ボタン: 浮く + 影が濃くなる -->
<button class="
  bg-indigo-600 text-white px-6 py-3 rounded-xl
  shadow-lg shadow-indigo-600/25
  hover:bg-indigo-500 hover:-translate-y-0.5 hover:shadow-xl hover:shadow-indigo-600/30
  transition-all duration-200
">
  ボタン
</button>

<!-- カード: ボーダーが強調 -->
<div class="
  border border-slate-200
  hover:border-indigo-500
  transition-colors duration-200
">
  カード
</div>
```

### トランジション

すべての変化にトランジションを適用する。

```html
<div class="transition-all duration-200 ease-in-out">...</div>
```

---

## コンポーネントパターン

### ボタン

```html
<!-- プライマリ -->
<button class="
  inline-flex items-center gap-2 px-6 py-3
  bg-indigo-600 text-white font-semibold rounded-xl
  shadow-lg shadow-indigo-600/25
  hover:bg-indigo-500 hover:-translate-y-0.5 hover:shadow-xl
  transition-all duration-200
">
  ボタン
  <svg class="w-4 h-4" ...></svg>
</button>

<!-- セカンダリ -->
<button class="
  px-6 py-3
  bg-white text-slate-700 font-medium rounded-xl
  border border-slate-200
  hover:bg-slate-50 hover:border-slate-300
  transition-all duration-200
">
  セカンダリ
</button>
```

### カード

```html
<div class="
  p-8 bg-white rounded-2xl
  border border-slate-200
  shadow-lg shadow-slate-200/50
  hover:shadow-xl hover:border-slate-300
  transition-all duration-200
">
  <h3 class="text-lg font-bold text-slate-900 mb-2">タイトル</h3>
  <p class="text-slate-500">説明文</p>
</div>
```

### セクション区切り

背景色の切り替えで区切りを表現する。

```html
<section class="py-24 bg-white">...</section>
<section class="py-24 bg-slate-50">...</section>
<section class="py-24 bg-slate-950 text-white">...</section>
```

---

## 禁止事項

| 禁止 | 理由 |
|------|------|
| 原色・蛍光色（#ff0000, #00ff00, #b4ff39等） | 安っぽい、目が疲れる |
| ノイズテクスチャ | 可読性低下、画面が汚れて見える |
| グリッドパターン背景 | 視覚的ノイズ |
| Bootstrap風デフォルトスタイル | 古臭い印象 |
| 意味のないグラデーションテキスト | 輪郭がぼやけ読みにくい |
| 純粋な黒(#000)と白(#fff)の組み合わせ | コントラストがきつすぎる |

---

## 実装プロセス

1. **要件確認**: 仕様書から目的・対象・トーンを読み取る
2. **骨組み**: Tailwindでグリッドと余白を定義
3. **装飾**: 影、ボーダー、背景色で奥行きを追加
4. **インタラクション**: hover、transitionを実装
5. **検証**: コントラスト比とレスポンシブ挙動の最終チェック

---

## 検証チェックリスト

### 不可侵の原則

- [ ] コントラスト比 4.5:1 以上
- [ ] 最も重要な情報が最も目立っている
- [ ] 仕様書の目的・トーンに合っている

### 質感

- [ ] ボーダーと影でレイヤー感がある
- [ ] 背景色の切り替えでセクションが区切られている
- [ ] 角丸が適切（rounded-xl以上）

### インタラクション

- [ ] ボタン・カードにhover効果がある
- [ ] すべての変化にtransitionがある

### 避けるべきもの

- [ ] 原色・蛍光色を使っていない
- [ ] ノイズ・グリッド背景を使っていない
- [ ] Bootstrap風になっていない
