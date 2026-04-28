# 旧仕事PC（CMPC0113）アプリ棚卸し

> Brewfile.tmpl 作成のための原資。実機 `/Applications` 等から自動抽出した結果を分類済み。
> 各項目末尾の `要確認` は cask 名や移行可否が確定していないもの。

## 棚卸しに使ったコマンド（再現用）

```bash
# 1. /Applications 配下のGUIアプリ
ls /Applications

# 2. Homebrew 管理下（既にCask化されているもの）
brew list --cask
brew list --formula

# 3. App Store 経由かどうか（_MASReceipt の有無で判定）
for app in /Applications/*.app; do
  [ -d "$app/Contents/_MASReceipt" ] && \
    echo "$(basename "$app" .app) → $(defaults read "$app/Contents/Info.plist" CFBundleIdentifier)"
done

# 4. App Store ID 取得（mas導入後）
brew install mas
mas list

# 5. Dock ピン留め（=日常使用の指標）
defaults read com.apple.dock persistent-apps | grep file-label

# 6. 一括dump（最終確認用、masも入れた状態で）
brew bundle dump --describe --file=Brewfile.draft
```

## 集計サマリ

- `/Applications` 配下: **73 アプリ**
- Homebrew Cask 管理済み: **12**
- App Store 経由: **11**
- **手動 .dmg インストール疑い: 約 50** ← Brewfile に取り込みたい主対象

---

## A. すでに Brew Cask 管理済み（そのまま Brewfile.tmpl へ転記）

```ruby
cask "amical"
cask "drawio"
cask "figma"
cask "monitorcontrol"
cask "showyedge"
cask "skitch"
cask "warp"
cask "font-plemol-jp-nf"
cask "mactex-no-gui"
cask "wkhtmltopdf"
```

**除外**: miniconda（uv/pyenv に統一）, kiro

## B. App Store 経由 → `mas` で管理（ID採番済み）

`mas list`（旧仕事PC `CMPC0113` で実行）で取得した ID。

```ruby
mas "Bitwarden",       id: 1352778147
mas "Keynote",         id: 409183694
mas "Microsoft Excel", id: 462058435
mas "RunCat",          id: 1429033973
mas "Sequel Ace",      id: 1518036000
mas "Tailscale",       id: 1475387142
```

**除外**: Amazon Kindle (302584613), CapCut (1500855883), iMovie (408981434), Steep (1591224909), TweetShot (1227057295)

## C. 手動 .dmg → Cask に移行する候補（**主作業**）

### C-1. ブラウザ・コミュニケーション

```ruby
cask "google-chrome"
cask "slack"
cask "discord"
cask "zoom"
cask "linear-linear"     # 確定（brew search 済み）
cask "notion"
cask "miro"
cask "todoist"
```

**除外確定**: arc, notion-calendar

### C-2. AI / エディタ / IDE

```ruby
cask "cursor"
cask "visual-studio-code"
cask "claude"            # Claude Desktop
cask "chatgpt"
```

**除外確定**:
- Antigravity（Google AI IDE）
- ChatGPT Atlas
- Codex GUI
- Aqua Voice
- Kiro
- Windsurf
- cmux（自前ビルド前提のためBrewfile管轄外。必要なら `run_once_install-cmux.sh` で個別対応）

### C-3. ターミナル・開発ツール

```ruby
cask "ghostty"
cask "docker-desktop"
cask "tableplus"
cask "postman"
```

**除外確定**: cmux（自前ビルド、別経路で対応）, termius, dash, CMake.app（cask 不在、CLI使うなら `brew "cmake"`）

### C-4. 生産性・ユーティリティ

```ruby
cask "raycast"
cask "karabiner-elements"
cask "cleanshot"
cask "obsidian"
cask "autoraise"
cask "spotify"
```

**除外確定**: deepl, superwhisper, rewind, tldv

### C-5. 移行対象外（一括除外）

新仕事PCには持ち込まない。理由まとめ：

| アプリ | 除外理由 |
|---|---|
| CASETiFY Colab | 用途終了 |
| EdrawMind | 不要 |
| EMEETLINK | 会議室ハード用ドライバ、必要時に再導入 |
| Falcon | 不要 |
| macOS InstantView | OS同梱／不要 |
| Nani | 不要 |
| Self Service Commune | 会社Jamfが新PCに自動配布 |
| ATOK35 (JustSystems) | 不要 |
| Nudge | IT配布、新PCで自動配布される |
| Python 3.11 | uv/pyenv に統一 |
| Google Docs/Sheets/Slides/Drive | Webアプリのショートカット、不要 |
| Karabiner-EventViewer | Karabiner-Elements 同梱で自動付属 |
| ChatGPT Atlas | C-2で除外済み |
| Antigravity | C-2で除外済み |
| Codex GUI | C-2で除外済み |
| Aqua Voice | C-2で除外済み |
| cmux | 自前ビルド、Brewfile管轄外 |
| arc | 不要 |
| notion-calendar | 不要 |
| deepl | 不要 |
| superwhisper | 不要 |
| Amazon Kindle (App Store) | 不要 |
| CapCut (App Store) | 不要 |
| iMovie (App Store) | 不要 |
| TweetShot (App Store) | 不要 |
| Steep (App Store) | 不要 |
| 旧バージョン残骸 (CleanShot ×2, DeepL ×2, ChatGPT/Atlas) | 旧PCのゴミ、移行対象外 |

## D. CLI（`brew list --formula` 既出から「常用」だけ抜粋）

毎日使っている主要 CLI のみ Brewfile.tmpl に明示記載する。依存パッケージ（`abseil`, `aom` 等）は brew が自動解決するので不要。

```ruby
brew "git"
brew "gh"
brew "ghq"
brew "fzf"          # 要確認: 入っていない可能性
brew "fd"
brew "ripgrep"
brew "bat"
brew "eza"
brew "jq"
brew "yq"
brew "jnv"
brew "neovim"
brew "tmux"
brew "reattach-to-user-namespace"
brew "starship"     # 要確認: 入っていない可能性
brew "zoxide"
brew "atuin"
brew "direnv"
brew "gnupg"
brew "pinentry-mac" # 要確認
brew "pyenv"
brew "uv"           # 要確認: 個別インストール？
brew "fnm"
brew "deno"
brew "duckdb"
brew "ffmpeg"
brew "graphviz"
brew "pandoc"
brew "tree"
brew "wget"
brew "task"
brew "timewarrior"
brew "terraform"
brew "awscli"
brew "supabase"
brew "tesseract"
brew "the_silver_searcher"
brew "codex"
brew "act"
brew "gcalcli"
brew "gogcli"
brew "wtp"
brew "glow"
brew "mas"          # App Store管理用
```

## E. dotfiles 取り込み済み（Brewfileではなく chezmoi 管理）

- `.zshrc`, `.zshenv`, `.zsh/`
- `.tmux.conf`, `.starship.toml`
- `.config/ghostty/config`
- `nvim/` 全体
- `.claude/global.md`

## F. アプリ個別設定（Brewfile管轄外、chezmoi or 手動移行）

`design.md` の「アプリ設定移行戦略」で扱う。

- **Cursor**: `~/Library/Application Support/Cursor/User/settings.json`, `keybindings.json`, 拡張機能リスト（`code --list-extensions`）
- **Karabiner-Elements**: `~/.config/karabiner/karabiner.json` ← chezmoi 管理可能
- **Raycast**: 設定→「Cloud Sync」推奨（dotfilesでの管理は困難）
- **Ghostty**: 既に dotfiles 管理済み
- **macOS カスタムショートカット**: `defaults find NSUserKeyEquivalents > dot_macos-shortcuts.txt`

---

## 次アクション

- [x] `brew install mas` → `mas list` で App Store ID を採番（B表に転記済み）
- [x] `brew search` で要確認 cask 名を確定（linear-linear / docker-desktop / cmake-app は不在）
- [ ] Brewfile.tmpl のドラフト作成（design.md 完成後）

---

## 確定後の Brewfile 候補（一望）

絞り込み後の暫定リスト。design.md でホスト分岐構造を決めた上で `Brewfile.tmpl` に落とす。

### Cask（GUIアプリ） — 全 32 個

```ruby
# 既に brew 管理（A）
cask "amical"
cask "drawio"
cask "figma"
cask "monitorcontrol"
cask "showyedge"
cask "skitch"
cask "warp"
cask "font-plemol-jp-nf"
cask "mactex-no-gui"
cask "wkhtmltopdf"

# 新規 cask 化（C-1〜C-4）
cask "google-chrome"
cask "slack"
cask "discord"
cask "zoom"
cask "linear-linear"      # 確定（brew search で確認済み）
cask "notion"
cask "miro"
cask "todoist"
cask "cursor"
cask "visual-studio-code"
cask "claude"
cask "chatgpt"
cask "ghostty"
cask "docker-desktop"     # 確定（GUIは docker-desktop。docker は CLI formula）
cask "tableplus"
cask "postman"
cask "raycast"
cask "karabiner-elements"
cask "cleanshot"
cask "obsidian"
cask "autoraise"
cask "spotify"
```

### mas（App Store） — 6 個

```ruby
brew "mas"
mas "Bitwarden",       id: <要採番>
mas "Keynote",         id: <要採番>
mas "Microsoft Excel", id: <要採番>
mas "RunCat",          id: <要採番>
mas "Sequel Ace",      id: <要採番>
mas "Tailscale",       id: <要採番>
```

### Brewfile管轄外（個別対応）

- **cmux**: `run_once_install-cmux.sh` で git clone & build
- **会社配布**: Self Service / Nudge は新PCで Jamf が自動配布
- **Karabiner-EventViewer**: karabiner-elements に同梱

73 → 38 個（Cask 32 + mas 6）に絞り込み完了。
