# 設定の継続移行

dotfile（chezmoi 管理）で完結しない macOS 個別設定 / アプリ独自データを **継続的に同期** するための仕組み。

## カバー範囲

| 種別 | 仕組み | 対応 |
|---|---|---|
| dotfile（`~/.zshrc` 等） | chezmoi で直接ミラー | ✅ 既定 |
| Karabiner | `~/.config/karabiner/karabiner.json` を chezmoi 管理 | ✅ |
| **macOS defaults**（KeyRepeat / Dock / Finder 等の単一値） | **`bin/capture-macos-defaults` → YAML → run_onchange で defaults write** | ✅ |
| **Hot Corners** | macos-defaults.yaml の `wvous-*-corner` で表現 | ✅ |
| **Cursor user settings** | `home/Library/Application Support/Cursor/User/` を chezmoi 直接管理 | ✅ |
| **Claude Code カスタム** | `home/dot_claude/{agents,commands,skills,output-styles,settings.json}` | ✅ |
| **SSH config** | `home/private_dot_ssh/config` で chezmoi 管理（鍵は除外） | ✅ |
| **Dock pinned apps の順序** | `defaults export` で plist、apply で `defaults import` | ✅ |
| **Login Items（自動起動アプリ）** | osascript で list → YAML、apply で再構築 | ✅ |
| **ghq クローン済みリポ一覧** | `ghq list` → txt、apply で `xargs ghq get` | ✅ |
| **Text Replacements / 日本語IMEユーザ辞書** | `plutil -extract NSUserDictionaryReplacementItems` で plist 化、apply で PlistBuddy 経由で書き戻し | ✅ |
| **Raycast** | アプリの Export/Import（`.rayconfig` を commit） | ✅（手動 GUI） |
| 秘密鍵 / GPG / AWS / GCP creds | keychain or 1Password（commit しない） | ❌ 別管理 |
| iCloud 同期物（Cursor account, Obsidian Vault） | 諦める（アプリ任せ） | ❌ |

## 旧PC（設定が最新の PC）での運用

```bash
cd ~/.dotfiles
git checkout feat/chezmoi-migration  # cutover 前なら
git pull

# 全部まとめて吸い上げ
make capture

# 個別なら
make capture-macos       # macOS defaults
make capture-cursor      # Cursor settings.json / keybindings.json / snippets/
make capture-claude      # Claude Code agents/commands/skills/output-styles/settings.json
make capture-ssh         # ~/.ssh/config（鍵は除外）
make capture-dock        # Dock plist
make capture-login-items # Login Items YAML
make capture-ghq         # ghq list
make capture-text-replacements # Text Replacements / 日本語IMEユーザ辞書

# 差分確認 → commit & push
git diff home/
git add home/ bin/
git commit -m "chore: refresh captures from CMPC0113"
git push
```

`capture-macos-defaults` は `home/.chezmoidata/macos-defaults.yaml` に既存リストされた **キーのみ** 読みに行く。新規キーを足すには YAML に空エントリを足してから capture を再実行。

## Raycast の手動 export

CLI で吸い上げられないので GUI 操作:

1. Raycast を起動 → `⌘,` で Settings
2. **Advanced** タブ → **Export** ボタン
3. 出力先を `~/.dotfiles/home/.assets/raycast-settings.rayconfig` に指定
4. `git add home/.assets/raycast-settings.rayconfig && git commit && git push`

## 新PC（設定を取り込む側）での運用

```bash
git pull
chezmoi apply --force

# Raycast だけ GUI Import が必要
make raycast-import
```

`chezmoi apply` で以下が走る:
- macOS defaults（`run_onchange_after_apply-macos-defaults.sh`）
- Dock plist の import（`run_onchange_after_apply-dock.sh`）
- Login Items の再構築（`run_onchange_after_apply-login-items.sh`）
- Text Replacements / ユーザ辞書の再構築（`run_onchange_after_apply-text-replacements.sh`）
- ghq の一括 clone（`run_once_after_clone-ghq-repos.sh`、初回のみ）
- Cursor / Claude のファイルが配置される（chezmoi 直接管理）

## 追加したい設定キーがあるとき

### macOS defaults

`home/.chezmoidata/macos-defaults.yaml` に空項目を足してから `make capture-macos`:

```yaml
- domain: "com.apple.menuextra.battery"
  key: "ShowPercent"
  type: "-bool"
  value: null
```

### 別アプリの設定ファイル

`home/` 以下に直接置けば chezmoi が管理する。例えば `~/Library/Application Support/Foo/Bar.json` なら:

```bash
mkdir -p home/Library/Application\ Support/Foo
cp ~/Library/Application\ Support/Foo/Bar.json home/Library/Application\ Support/Foo/Bar.json
git add home/Library
git commit -m "chore: capture Foo settings"
```

## 制限

- **Spotlight `orderedItems`** など array/dict 型の defaults は YAML key/value で表現できない。`defaults export com.apple.Spotlight home/.assets/spotlight.plist` 方式にした方が良い場合がある（必要時に追加）。
- **Login Items** は **アプリのフルパスがマッチする** 必要あり。新PC で `/Applications/X.app` が無いと skip される。
- **Karabiner-Elements** 等 sudo インストールが必要な cask は `brew bundle` 内で必ず失敗するが apply 全体は止まらない（`run_onchange_before_install-packages-darwin.sh.tmpl` で握り潰し済み）。これらは初回 GUI 操作が必須。

## 関連ドキュメント

- chezmoi の運用全般: `docs/chezmoi.md`
- 設計の経緯: `.steering/20260428-chezmoi-migration/`
