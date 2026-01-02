# Neovim 設定リファレンス

自分用のNeovim (LazyVim + oil.nvim) 設定まとめ。忘れた時にサッと確認する用。

---

## クイックリファレンス（使用頻度順）

```
Leader = <Space>

【毎日使う】
ファイラー:    - または Ctrl-F (oil.nvim)
ファイル検索:  <Space>ff (Telescope)
文字列検索:    <Space>sg (live grep)
定義ジャンプ:  gd
参照一覧:      gr

【週に数回】
バッファ切替:  Tab / Shift-Tab
コマンドパレット: <Space><Space>
Git:           <Space>gg (lazygit)

【たまに使う】
フォーマット:  <Space>cf
コメント:      gcc (行) / gc (選択)
プラグイン管理: :Lazy
```

**設定ファイルの場所:**
- `~/.config/nvim/` → `~/.dotfiles/nvim/` へのシンボリックリンク
- `lua/config/options.lua` - 基本オプション
- `lua/config/keymaps.lua` - カスタムキーマップ
- `lua/plugins/` - プラグイン設定

---

## oil.nvim（ファイラー）

### 基本概念

ディレクトリを**バッファとして編集**できるファイラー。ファイル操作がVimの編集操作と同じ感覚で行える。

```
普通のファイラー:  専用UIでファイル操作
oil.nvim:         ディレクトリ = 編集可能なバッファ
                  ファイル名変更 = テキスト編集 → :w
                  ファイル削除   = dd → :w
                  新規作成      = o で行追加 → :w
```

### キーバインド

| キー | 動作 |
|------|------|
| `-` または `Ctrl-F` | oil を開く（カレントファイルの親ディレクトリ） |
| `Enter` | ファイル/ディレクトリを開く |
| `-` | 親ディレクトリへ移動（oil内） |
| `q` | **oil を閉じて元に戻る** |
| `Ctrl-v` | 縦分割で開く |
| `Ctrl-s` | 横分割で開く |
| `Ctrl-t` | 新タブで開く |
| `Ctrl-r` | リフレッシュ |
| `g?` | ヘルプ表示 |

### ファイル操作の流れ

**ファイル名変更:**
```
1. - で oil を開く
2. j/k で目的のファイルへ移動
3. ファイル名を普通に編集（ciw, A など）
4. :w で変更を実行
```

**ファイル削除:**
```
1. - で oil を開く
2. 削除したいファイルの行で dd
3. :w で削除を実行
```

**新規ファイル作成:**
```
1. - で oil を開く
2. o で新しい行を追加
3. ファイル名を入力（例: new_file.py）
4. :w で作成を実行
5. Enter で開く
```

**ディレクトリ作成:**
```
1. - で oil を開く
2. o で新しい行を追加
3. ディレクトリ名/ を入力（末尾に / をつける）
4. :w で作成を実行
```

---

## 検索・移動（Telescope）

| キー | 動作 |
|------|------|
| `<Space>ff` | ファイル検索 |
| `<Space>fg` | Git管理ファイル検索 |
| `<Space>fr` | 最近のファイル |
| `<Space>sg` | 文字列検索（live grep） |
| `<Space>sw` | カーソル下の単語を検索 |
| `<Space>sb` | 現在のバッファ内検索 |
| `<Space><Space>` | コマンドパレット |
| `<Space>sk` | キーマップ検索 |

### Telescope操作（検索結果画面内）

| キー | 動作 |
|------|------|
| `Ctrl-j/k` | 上下移動 |
| `Enter` | 選択して開く |
| `Ctrl-v` | 縦分割で開く |
| `Ctrl-s` | 横分割で開く |
| `Ctrl-t` | 新タブで開く |
| `Esc` | 閉じる |

---

## LSP操作

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `gI` | 実装へジャンプ |
| `gy` | 型定義へジャンプ |
| `K` | ホバー情報（ドキュメント表示） |
| `<Space>ca` | コードアクション |
| `<Space>cr` | リネーム |
| `<Space>cf` | フォーマット |
| `]d` / `[d` | 次/前の診断へ移動 |
| `<Space>xx` | 診断一覧（trouble.nvim） |

---

## バッファ・ウィンドウ

### バッファ操作

| キー | 動作 |
|------|------|
| `Tab` | 次のバッファ |
| `Shift-Tab` | 前のバッファ |
| `` <Space>` `` | 直前のバッファに切り替え |
| `Ctrl-^` | 直前のバッファに切り替え（標準vim） |
| `<Space>bb` | バッファ一覧から選択 |
| `<Space>bd` | **現在のバッファを閉じる** |
| `<Space>bo` | 他のバッファを全て閉じる |

### ジャンプ履歴

| キー | 動作 |
|------|------|
| `Ctrl-o` | 前の位置に戻る（gd後に戻るなど） |
| `Ctrl-i` | 次の位置に進む |

### ウィンドウ操作

| キー | 動作 |
|------|------|
| `<Space>-` | 横分割 |
| `<Space>\|` | 縦分割 |
| `Ctrl-h/j/k/l` | ウィンドウ間移動 |
| `<Space>wd` | 現在のウィンドウを閉じる |
| `Ctrl-w q` | ウィンドウを閉じる（標準vim） |

---

## 編集

| キー | 動作 |
|------|------|
| `jk` または `jj` | Esc（挿入モードから） |
| `gcc` | 行コメント切替 |
| `gc` | 選択範囲コメント切替（ビジュアルモード） |
| `Esc Esc` | 検索ハイライト消去 |
| `<Space>sr` | 検索と置換 |

---

## Git

| キー | 動作 |
|------|------|
| `<Space>gg` | lazygit を開く |
| `<Space>gf` | ファイルのGit履歴 |
| `<Space>gb` | Git blame |
| `]h` / `[h` | 次/前の変更箇所へ |
| `<Space>ghp` | 変更のプレビュー |
| `<Space>ghr` | 変更を元に戻す |

---

## よく使う操作シナリオ

### プロジェクト内でファイルを探して開く

```
<Space>ff → ファイル名を入力 → Enter
```

### コード内の文字列を検索

```
<Space>sg → 検索ワードを入力 → Ctrl-j/k で選択 → Enter
```

### 関数の定義を確認して戻る

```
gd → 定義を確認 → Ctrl-o で戻る
```

### ファイルを新規作成

```
- → o → ファイル名入力 → Esc → :w → Enter
```

### 複数ファイルの一括置換

```
<Space>sg → 検索 → Ctrl-q でQuickfixへ送る
:cdo s/old/new/gc → 確認しながら置換
:wa → 全て保存
```

---

## 設定ファイル構造

```
~/.dotfiles/nvim/
├── init.lua                 # エントリーポイント
├── lua/
│   ├── config/
│   │   ├── lazy.lua         # lazy.nvim設定
│   │   ├── options.lua      # Vimオプション ★
│   │   ├── keymaps.lua      # キーマップ ★
│   │   └── autocmds.lua     # 自動コマンド
│   └── plugins/
│       ├── oil.lua          # oil.nvim設定 ★
│       └── example.lua      # 設定例（参考用）
└── stylua.toml
```

### カスタマイズ方法

**プラグイン追加:**
```lua
-- lua/plugins/myplugin.lua を作成
return {
  {
    "author/plugin-name",
    opts = {
      -- 設定
    },
  },
}
```

**キーマップ追加:**
```lua
-- lua/config/keymaps.lua に追加
local map = vim.keymap.set
map("n", "<leader>xx", "<cmd>SomeCommand<cr>", { desc = "説明" })
```

---

## トラブルシュート

### プラグイン更新

```vim
:Lazy update
```

### プラグイン状態確認

```vim
:Lazy
```

### LSPが動かない

```vim
:LspInfo          " LSP状態確認
:Mason            " LSPインストーラーを開く
```

### 設定の健全性チェック

```vim
:checkhealth
```

### キャッシュクリア（最終手段）

```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
nvim  # 再起動でプラグイン再インストール
```

### oil.nvimで変更が反映されない

```
1. :w で保存したか確認
2. Ctrl-r でリフレッシュ
3. 権限エラーの場合は sudo で nvim 起動
```

---

## 便利なコマンド

| コマンド | 説明 |
|----------|------|
| `:Lazy` | プラグイン管理画面 |
| `:Mason` | LSP/ツールインストーラー |
| `:LspInfo` | LSP状態確認 |
| `:checkhealth` | 設定の健全性チェック |
| `:Telescope keymaps` | キーマップ検索 |
| `:Oil` | oil.nvimを開く |
