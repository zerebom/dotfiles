# 配色リファレンス

## 配色選択の原則

### 1. コントラスト最優先

どんな配色でも、テキストの可読性が最優先。

```
最低基準:
- 本文テキスト: 4.5:1以上
- 大きな見出し: 3:1以上
- UIコンポーネント: 3:1以上
```

### 2. 色数は少なく

```
基本構成:
- ベース色: 1色（背景）
- テキスト色: 2色（メイン + サブ）
- アクセント色: 1色（CTA、強調）
- ボーダー色: 1色

追加は慎重に:
- 成功/エラー/警告などの意味を持つ色
- グラフ等のデータビジュアライゼーション用
```

### 3. 意味のある色使い

```
色には意味を持たせる:
- アクセント色 → 行動を促す要素（ボタン、リンク）
- 成功色（緑系）→ 完了、成功
- エラー色（赤系）→ エラー、警告
- 情報色（青系）→ 情報、ヒント

意味なく色を散らさない
```

---

## トーン別配色セット

### 信頼・フォーマル（ライト）

```css
:root {
  /* ベース */
  --bg-base: #ffffff;
  --bg-surface: #f8fafc;
  --bg-muted: #f1f5f9;
  
  /* テキスト */
  --text-primary: #0f172a;
  --text-secondary: #475569;
  --text-muted: #94a3b8;
  
  /* アクセント */
  --accent: #2563eb;
  --accent-hover: #1d4ed8;
  
  /* ボーダー */
  --border: #e2e8f0;
  --border-strong: #cbd5e1;
  
  /* セマンティック */
  --success: #059669;
  --error: #dc2626;
  --warning: #d97706;
}
```

### 革新・先進（ダーク）

```css
:root {
  /* ベース */
  --bg-base: #09090b;
  --bg-surface: #18181b;
  --bg-muted: #27272a;
  
  /* テキスト */
  --text-primary: #fafafa;
  --text-secondary: #a1a1aa;
  --text-muted: #71717a;
  
  /* アクセント */
  --accent: #3b82f6;
  --accent-hover: #60a5fa;
  
  /* ボーダー */
  --border: #27272a;
  --border-strong: #3f3f46;
  
  /* セマンティック */
  --success: #10b981;
  --error: #ef4444;
  --warning: #f59e0b;
}
```

### 親しみ・カジュアル（ライト）

```css
:root {
  /* ベース */
  --bg-base: #ffffff;
  --bg-surface: #fef3c7;  /* 温かみのあるクリーム */
  --bg-muted: #fef9c3;
  
  /* テキスト */
  --text-primary: #292524;
  --text-secondary: #57534e;
  --text-muted: #a8a29e;
  
  /* アクセント */
  --accent: #f97316;
  --accent-hover: #ea580c;
  
  /* ボーダー */
  --border: #e7e5e4;
  --border-strong: #d6d3d1;
  
  /* セマンティック */
  --success: #22c55e;
  --error: #ef4444;
  --warning: #eab308;
}
```

### 高級・プレミアム（ライト）

```css
:root {
  /* ベース */
  --bg-base: #fafaf9;
  --bg-surface: #ffffff;
  --bg-muted: #f5f5f4;
  
  /* テキスト */
  --text-primary: #0c0a09;
  --text-secondary: #44403c;
  --text-muted: #78716c;
  
  /* アクセント */
  --accent: #a16207;  /* ゴールド系 */
  --accent-hover: #854d0e;
  
  /* ボーダー */
  --border: #e7e5e4;
  --border-strong: #d6d3d1;
  
  /* セマンティック */
  --success: #166534;
  --error: #991b1b;
  --warning: #92400e;
}
```

---

## 避けるべき配色

### 蛍光色

```
避ける色:
- #b4ff39（蛍光イエローグリーン）
- #ff00ff（マゼンタ）
- #00ff00（蛍光グリーン）
- #ffff00（蛍光イエロー）

理由:
- 目に刺激が強い
- 安っぽい印象
- 長時間の閲覧に不向き
- BtoBの信頼感を損なう
```

### 低コントラストの組み合わせ

```
避ける組み合わせ:
- 薄いグレー文字(#9ca3af) on 白背景(#ffffff) → コントラスト 2.7:1 ✗
- 白文字(#ffffff) on 薄い青(#93c5fd) → コントラスト 1.6:1 ✗

確認方法:
- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
```

### 意味のない多色使い

```
避けるパターン:
- 「カラフルにしたい」だけの理由で色を増やす
- セクションごとに違うアクセント色
- 統一感のないグラデーション
```

---

## グラデーションの使い方

### 使って良い場合

```
1. 背景の微妙な変化
   - 単色だと単調に見える広い面積
   - ただし変化は控えめに

2. アクセント要素の強調
   - ヒーローセクションの背景
   - CTAボタン（控えめに）

3. ブランドカラーがグラデーションの場合
```

### 使ってはいけない場合

```
1. テキストにグラデーション
   - 可読性が下がる
   - 輪郭がぼやける

2. 背景と文字のコントラストが不安定になる場合
   - グラデーションの端と端で色が大きく変わる
   - 一部のテキストが読みにくくなる

3. 安易な「紫→ピンク」「青→シアン」
   - AI生成感が出る
   - 既視感が強い
```

### 良いグラデーションの例

```css
/* 微妙な変化のグラデーション */
background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);

/* ダーク背景の深み */
background: linear-gradient(180deg, #09090b 0%, #18181b 100%);

/* 避ける: 変化が激しいグラデーション */
/* background: linear-gradient(135deg, #8b5cf6 0%, #ec4899 100%); */
```
