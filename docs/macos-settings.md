# macOS 設定の継続移行

`~/.config/X` で完結しない macOS 個別設定（KeyRepeat、Dock、Raycast 等）を **chezmoi 管理下** に置いて、PC 間で継続的に同期する仕組み。

## アーキテクチャ

```
home/.chezmoidata/macos-defaults.yaml         ← 設定値（YAML、source of truth）
home/run_onchange_after_apply-macos-defaults.sh.tmpl   ← 適用スクリプト（YAML を読んで defaults write）
home/.assets/raycast-settings.rayconfig       ← Raycast Export ファイル
bin/capture-macos-defaults                    ← 現環境の値 → YAML
bin/apply-raycast-settings                    ← Raycast Import を open で起動
```

設定が変わる度に旧PCで `make capture-macos` を実行 → commit → 他PCで `chezmoi apply` で反映、という運用。

## 運用フロー

### 旧PC（または「設定が最新」のPC）で

```bash
# 1. 現状の値を YAML に書き戻す
make capture-macos

# 2. 差分を確認
git diff home/.chezmoidata/macos-defaults.yaml

# 3. 問題なければ commit & push
git commit -am "chore: refresh macos-defaults snapshot"
git push
```

`capture-macos` は `home/.chezmoidata/macos-defaults.yaml` に既存リストされたキーのみ読みに行く。**新規キーを追加したい場合は YAML に空の項目を足してから capture を再実行**する。

### 新PC（または「設定を取り込む側」のPC）で

```bash
git pull
chezmoi apply --force      # YAML が変わってたら run_onchange が走り、defaults write が実行される
```

`defaults write` は冪等なので、何度走らせても安全。Dock / Finder は最後に `killall` で再起動する。

### 値を確認したいだけのとき

```bash
make capture-macos-diff    # YAML を書かずに差分のみ表示
```

## Raycast 設定

Raycast は内部 DB にバイナリで保存しているため `defaults` では引っ張れない。**Raycast 自身の Export/Import を使う**。

### 旧PCでエクスポート（手動）

1. Raycast を起動
2. `⌘,` で Settings を開く
3. **Advanced** タブ → **Export** ボタン
4. 出力先に `~/.dotfiles/home/.assets/raycast-settings.rayconfig` を指定
5. git add & commit & push

```bash
# 確認
ls -la ~/.dotfiles/home/.assets/raycast-settings.rayconfig
git add home/.assets/raycast-settings.rayconfig
git commit -m "chore: refresh raycast-settings.rayconfig"
git push
```

### 新PCでインポート

```bash
git pull
make raycast-import   # Raycast がインポートダイアログを開く → "Import" を押す
```

> Raycast には CLI Import が無いため、ダイアログを `open -a Raycast <path>` で起動して GUI で確定する形になる。

## 追加したい設定キーが分かっているとき

例: `com.apple.menuextra.battery ShowPercent` を追跡対象に加えたい。

1. `home/.chezmoidata/macos-defaults.yaml` に追加:
   ```yaml
       - domain: "com.apple.menuextra.battery"
         key: "ShowPercent"
         type: "-bool"
         value: null
   ```
2. `make capture-macos` で現環境の値を埋める
3. commit & push
4. 他PCで `chezmoi apply`

## 何が漏れているか分からないとき

`defaults domains | tr ',' '\n' | wc -l` で全ドメイン数が出る（数百個）。全部追跡は現実的でないので、**気になる動作の差分が出たときに該当ドメインを足す** の繰り返しがおすすめ。代表的な探し方:

```bash
# 旧PC で設定を変えた直後に走らせて、変更されたファイルを見つける
defaults find <キーワード>    # 例: defaults find KeyRepeat

# どのドメインに何が書かれているか見る
defaults read com.apple.dock | head -30
```

## 制限

- **System Settings の中でも `defaults` で取れない設定**は手動移行（例: 一部の Privacy 設定、Trackpad の細かい速度、ログイン項目）。
- **マウス/Trackpad のスクロール速度** は `defaults read .GlobalPreferences com.apple.trackpad.scaling` 等で取れるが、System Settings の UI 値とは粒度が違う場合あり。
- **Karabiner-Elements** は別建て（`~/.config/karabiner/karabiner.json` を chezmoi で管理）。
