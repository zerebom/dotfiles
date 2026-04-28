# chezmoi 運用ガイド

自分用、新PCセットアップと日常運用のメモ。設計の経緯は `.steering/20260428-chezmoi-migration/` に集約。

---

## クイックリファレンス（使用頻度順）

```
【毎日】
chezmoi diff                # ローカル状態と source-state の差分
chezmoi apply               # 差分を反映（symlink/ファイル/スクリプト）

【週に数回】
chezmoi cd                  # source-state ディレクトリへ移動（編集後 git commit）
chezmoi edit ~/.zshrc       # source の dot_zshrc を $EDITOR で開く
chezmoi re-add              # 手元の変更を source-state に取り込み

【たまに】
chezmoi data                # template に渡る変数を JSON で確認
chezmoi managed             # 管理対象パスの一覧
chezmoi execute-template < FILE   # 単一テンプレを試し展開
chezmoi state delete-bucket --bucket=scriptState   # run_once / run_onchange の再実行
```

**source-state 場所:** 旧PCでの作業中は `~/.dotfiles/home/`、新PCで `chezmoi init zerebom` 後は `~/.local/share/chezmoi/home/`。`.chezmoiroot` (= "home") で `home/` 配下のみが管理対象。

---

## 新PCセットアップ（30分タイマー）

> 想定: 仕事PC `CMPC0397` または個人 Mac。Apple Silicon。

### 0:00 — 前準備（事前にUSB/AirDropで持ち込む）

1. シークレット投入用メモ（後述の `secret-bootstrap.sh`）
2. App Store サインイン状態を整えておく（mas で再投入のため）

### 0:00–0:05 — 素の macOS から chezmoi まで

```bash
# Xcode CLT
xcode-select --install

# Homebrew (Apple Silicon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# chezmoi
brew install chezmoi
```

### 0:05 — keychain に必要なシークレットを投入

```bash
security add-generic-password -s github-token       -a zerebom -w <new-token>
security add-generic-password -s gemini-api-key     -a zerebom -w <key>
security add-generic-password -s anthropic-api-key  -a zerebom -w <key>
```

> 投入が無いキーは `secrets.zsh.tmpl` で空文字に fallback するため、最低限 GITHUB_TOKEN だけでもOK。

### 0:06 — chezmoi 一発展開

```bash
chezmoi init zerebom --apply
# = git clone git@github.com:zerebom/dotfiles.git ~/.local/share/chezmoi
#   その後 ~/ 直下に dotfile を展開
#   run_onchange_before_install-packages-darwin.sh が実行され brew bundle が走る
```

ホスト分岐は `scutil --get ComputerName` の結果で自動判定（`CMPC0397` → `work-new`、`CMPC0113` → `work-old`、それ以外 → `personal`）。

### 0:10–0:25 — パッケージ install（ネット次第）

`run_onchange_before_install-packages-darwin.sh` は init 内で走るが、初回はキャッシュなしで時間がかかる。中断したら手動で：

```bash
~/.local/share/chezmoi/home/run_onchange_before_install-packages-darwin.sh.tmpl  # 直接は走らせない
chezmoi apply --force                                                            # スクリプト再実行
# もしくは brew bundle install を生 Brewfile を吐かせて単体実行
```

### 0:25 — 拡張機能と nvim

```bash
# Cursor / VS Code を起動して CLI を有効化（"Shell Command: Install 'cursor' command in PATH"）
# その後 chezmoi apply を再実行すると run_onchange_install-{cursor,vscode}-extensions.sh が走り
# 137 + 125 個の拡張機能が再インストールされる
chezmoi apply

# nvim: ~/.config/nvim → ~/.local/share/chezmoi/nvim を symlink
# run_once_after_setup-nvim-symlink.sh.tmpl が初回 apply 後に実行
nvim     # 起動して Lazy が plugin を解決
```

### 0:30 — 動作確認

- `ghostty` を起動 → starship プロンプト表示
- `git config --get user.email` → 仕事PCなら `higuchi.kokoro@commune.co.jp`
- `mas list` → AppStore 6個揃う
- `cursor --list-extensions | wc -l` → 137 程度

---

## 日常運用

### 既存ファイルの編集

```bash
# 直接 ~/ 配下を編集 → re-add で source-state に取り込む
vim ~/.zshrc
chezmoi re-add ~/.zshrc

# あるいは source-state 側を直接編集
chezmoi edit ~/.zshrc        # = $EDITOR ~/.local/share/chezmoi/home/dot_zshrc
chezmoi diff
chezmoi apply
```

### 新しい dotfile を取り込む

```bash
chezmoi add ~/.foo                          # 通常ファイル
chezmoi add --template ~/.foo               # template 化（中で {{ }} を使えるよう）
chezmoi add --encrypt ~/.foo                # gpg 暗号化（今回は未使用）
```

### パッケージを追加する

`home/.chezmoidata/packages.yaml` を編集 → コミット → 次回 `chezmoi apply` で hash が変わり `run_onchange_before_install-packages-darwin.sh` が再実行される。

```yaml
packages:
  darwin:
    common:
      brews:
        - <new-formula>
```

### 新しいホストを追加する

`home/.chezmoi.toml.tmpl` の host 判定に分岐を追加。`scutil --get ComputerName` で取得した名前を使う。

### Cursor / VS Code 拡張機能の差分を取り込む

```bash
cursor --list-extensions > home/.assets/cursor-extensions.txt
code   --list-extensions > home/.assets/vscode-extensions.txt
```

ファイル内容が変われば `run_onchange_install-*-extensions.sh` の hash が変わり、次回 apply で再実行。

### CI

`feat/*` または `master` への push / PR で `.github/workflows/chezmoi-test.yml` が ubuntu + macos の matrix で走る。`env.CI=true` で `secrets.zsh.tmpl` は fake 値。

---

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `chezmoi apply` が TTY を要求 | `--force` を付ける（自動判断 = 上書き） |
| `run_onchange_*` が再実行されない | hash 変化が無い。スクリプト冒頭の `# packages hash:` 行を確認、または `chezmoi state delete-bucket --bucket=scriptState` |
| `keyring` / `security` が値を返さない | `secrets.zsh.tmpl` は空文字 fallback で展開されるが、実行時 `echo $GITHUB_TOKEN` が空。投入し直し |
| `scutil --get ComputerName` が想定と違う | `sudo scutil --set ComputerName <name>` で設定。`HostName` / `LocalHostName` は別物だが今回は触らない |
| Apple Silicon で `/usr/local/bin/brew` が混在 | 旧 Intel brew を `/usr/local/bin/brew uninstall` してから新規セットアップ |
| `brew bundle` が手動 .dmg を「未インストール」と判定 | 既存 .dmg を一度ゴミ箱に → `brew install --cask <name>` で再投入。新PCではフレッシュなので問題化しない |

---

## 関連ドキュメント

- 設計: `.steering/20260428-chezmoi-migration/design.md`
- 実装タスク: `.steering/20260428-chezmoi-migration/tasklist.md`
- 棚卸し: `.steering/20260428-chezmoi-migration/app-inventory.md`
- chezmoi 公式: https://www.chezmoi.io/
