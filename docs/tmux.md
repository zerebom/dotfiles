# tmux 設定リファレンス

自分用のtmux設定まとめ。忘れた時にサッと確認する用。

---

## クイックリファレンス（使用頻度順）

```
Prefix = Ctrl-S

【毎日使う】
ghq連携:     Ctrl-G (FZFでセッション切り替え)
ペイン分割:  Prefix | (縦) / Prefix - (横)
ペイン移動:  Prefix h/j/k/l
デタッチ:    Prefix d

【週に数回】
ウィンドウ:  Prefix c (新規) / Prefix Ctrl-H/L (左右切替、連打可)
リサイズ:    Prefix H/J/K/L (Shift、Prefix不要で連打可)
コピー:      Prefix v → v(選択) → y(コピー)

【たまに使う】
セッション:  Prefix s (一覧) / Prefix $ (名前変更)
レイアウト:  Prefix Space (次のレイアウト)
設定再読込:  Prefix : → source-file ~/.tmux.conf
```

**設定ファイルの場所:**
- `~/.tmux.conf` - メイン設定
- `~/.zshrc` (L113-186) - ghq連携の関数定義

---

## 基本概念

```
Session（作業単位）
  └── Window（タブのようなもの）
        └── Pane（分割された領域）
```

- **Session**: プロジェクト単位で作成。ghq連携でリポジトリ名がセッション名になる
- **Window**: 1つのセッション内で複数のタスクを切り替え
- **Pane**: 1つのウィンドウを分割して並行作業

**Prefixキー: `Ctrl-S`**
すべての操作はPrefix → コマンドキーの2段階。Prefixを押してから次のキーを押す。

---

## ghq連携（セッション管理）

### Ctrl-G: セッション切り替え

FZFでリポジトリを選択し、そのリポジトリ用のtmuxセッションに切り替え。

```
Ctrl-G
  ↓
FZFでリポジトリ選択
  ✓ = 既存tmuxセッション
  - = ghq管理下のリポジトリ（新規セッション作成）
  ↓
セッション名を自動決定
  ↓
切り替え or 新規作成
```

**セッション名の命名規則:**
- 通常リポジトリ: パスの最後の要素
  - 例: `~/ghq/github.com/user/my-project` → `my-project`
- worktree: `worktrees/` 以降を`-`で連結
  - 例: `~/ghq/github.com/user/project/worktrees/feature/new-ui`
    → `worktrees/` 以降の `feature/new-ui` を変換
    → `feature-new-ui`
  - ブランチ名がそのままセッション名になるので識別しやすい

**動作の違い:**
| 状況 | 動作 | 具体例 |
|------|------|--------|
| tmux外から実行 | 新規セッション作成＆アタッチ | ログイン直後にCtrl-G |
| tmux内・他セッション選択 | 既存セッションに切り替え | project-A → project-B |
| tmux内・同セッション選択 | 選択したリポジトリへcd | 既にproject-A内で再度project-A選択時 |

※同セッション時のcdは、worktree間の移動で便利（セッションは維持したまま作業ブランチ変更）

### Alt-G: ディレクトリ移動のみ

セッションを切り替えずに、選択したリポジトリへcdするだけ。

---

## キーバインド詳細

### ペイン操作

hjklで移動、大文字HJKLでリサイズ（Vim風）。

| 操作 | キー | 備考 |
|------|------|------|
| 縦分割 | `Prefix + \|` | 左右に分ける |
| 横分割 | `Prefix + -` | 上下に分ける |
| 左/下/上/右へ移動 | `Prefix + h/j/k/l` | |
| リサイズ（左/下/上/右） | `Prefix + H/J/K/L` | 5px単位、Prefix不要で連打可 |
| ペイン閉じる | `Prefix + x` | 確認あり |

### ウィンドウ操作

| 操作 | キー | 備考 |
|------|------|------|
| 新規作成 | `Prefix + c` | |
| 名前変更 | `Prefix + ,` | プロンプトで入力 |
| 左ウィンドウへ | `Prefix + Ctrl-H` | Prefix不要で連打可 |
| 右ウィンドウへ | `Prefix + Ctrl-L` | 同上 |
| 番号で選択 | `Prefix + 0-9` | ステータスバーの番号 |
| 一覧表示 | `Prefix + w` | FZF風に選択可能 |

### セッション操作

| 操作 | キー |
|------|------|
| デタッチ | `Prefix + d` |
| セッション一覧 | `Prefix + s` |
| セッション名変更 | `Prefix + $` |

### コピーモード（vi風）

| 操作 | キー | 備考 |
|------|------|------|
| コピーモード開始 | `Prefix + v` | |
| 選択開始 | `v` | コピーモード中 |
| コピー | `y` | pbcopyへ（macOS） |
| スクロール | `Ctrl-u/d` または `k/j` | マウスでも可 |

---

## よく使う操作シナリオ

### 新プロジェクト開始

1. `Ctrl-G` → FZFでリポジトリ検索・選択
2. セッション自動作成（リポジトリ名がセッション名に）
3. `Prefix |` で縦分割（左: エディタ、右: ターミナル）
4. 右ペインで `Prefix -` で横分割（上: サーバー、下: ログ監視）
5. `Prefix h/l` でペイン間を移動しながら作業

**実キーストローク例:**
```
Ctrl-G → my-project選択 → Ctrl-S | → Ctrl-S l → Ctrl-S -
```

### 複数プロジェクト切り替え

```
Ctrl-G → project-B選択 → 即座にセッション切り替え
戻りたい時: Ctrl-G → project-A選択
```

### worktree間の移動

同じセッション内で別のworktreeに移動したい時：
```
Ctrl-G → 同リポジトリの別worktree選択 → cdで移動
```

---

## レイアウト操作

| 操作 | キー | 備考 |
|------|------|------|
| 次のレイアウトに変更 | `Prefix + Space` | 連打で色々試せる |
| 横並びで等分 | `Prefix + Alt-1` | even-horizontal |
| 縦並びで等分 | `Prefix + Alt-2` | even-vertical |
| メイン横＋サブ縦 | `Prefix + Alt-3` | main-horizontal |
| メイン縦＋サブ横 | `Prefix + Alt-4` | main-vertical |
| タイル状 | `Prefix + Alt-5` | tiled |

**縦分割↔横分割を切り替えたい時:** `Prefix + Space` を何回か押す

---

## 忘れがちだが重要なコマンド

| 操作 | キー |
|------|------|
| ペイン→ウィンドウ化 | `Prefix + !` |
| ペインの順序入れ替え | `Prefix + {` / `Prefix + }` |

---

## マウス操作

以下の操作がマウスで可能（`set -g mouse on` で有効化済み）:
- ペインのサイズ変更（境界をドラッグ）
- ペイン選択（クリック）
- ウィンドウ選択（ステータスバーをクリック）
- スクロール（ホイール）

---

## トラブルシュート

### セッションが残っている

```bash
# セッション一覧確認
tmux ls

# 特定セッション削除
tmux kill-session -t セッション名

# 全セッション削除
tmux kill-server
```

### ペインがおかしくなった

```bash
# レイアウトリセット
Prefix + Space  # 次のレイアウトに切り替え

# ペインを閉じる
Prefix + x  # 確認あり
exit        # または単にexitコマンド
```

### 設定を再読み込み

```bash
# tmux内で
Prefix + :
source-file ~/.tmux.conf

# または外から
tmux source-file ~/.tmux.conf
```

### マウス操作が効かない

設定ファイルで有効化済み（`set -g mouse on`）。
効かない場合は設定再読み込みを試す。

### 日本語入力中にキーバインドが効かない

IME（日本語入力）がONだとCtrl-Sなどが効かない。

**対処法:**
1. **Escを押してからPrefix操作** - IMEがOFFになる
2. **英数キーを押してから操作** - 確実にIME OFF
3. **習慣づける** - tmux操作前に英数キーを押すクセをつける

```
日本語入力中 → 英数 → Ctrl-S → | (縦分割)
```
