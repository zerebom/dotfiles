---
name: herdr
description: Herdr アプリ（herdr-core の `hc` と、画面を操作する `herdr-app`）で、作業者の Claude Code を space ごとに立てて指示・完了待ち・レビューするスキル。「作業者に回して」「並列で進めて」「別ブランチで任せたい」「Herdr で space を作って」「エージェントの状態を見て」などのリクエスト時、並列開発のために worktree と space を立てるとき、Herdr のペインで Web ページ（localhost の動作確認など）を開いて見せるときに使用する。どのリポジトリでも有効（commune-voice 内では worktree の作成に commune-worktree スキルを使う）。
---

# Herdr アプリで作業者を立てる

## 大原則: help を読む。記憶に頼らない

`hc` と `herdr-app` は更新が速い。コマンドやオプションは記憶で書かず、次で現物を確かめる。

- `hc --skill`（エージェントとプログラムの起動、送信、待機、片付け）と `hc <cmd> --help`
- `herdr-app --skill`（画面の space、tab、pane の操作）と `herdr-app commands`（引数の一覧）

このスキルに書くのは、help では分からない環境固有の事実と、動作を確かめたレシピだけ。

## 道具の分担

| 道具 | 使う場面 |
|---|---|
| `herdr-app do ...` | ユーザーに見せる space、tab、pane を作る、閉じる |
| `hc ...` | 作業者の状態を見る、指示を送る、完了を待つ、画面を読む |
| `wtp add` / `wtp remove` | worktree の作成と削除（hc と herdr-app には worktree の機能がない） |

- ターミナル版 herdr（`herdr` コマンド）は Herdr アプリとは別のプログラムで、エージェントを共有しない。ターミナル版で立てた作業者はアプリに表示されない。`herdr` コマンドは使わない
- 自分の terminal の ID は `$HC_TERMINAL_ID`（例 `t9`）に入っている。pane の ID とは別物
- ユーザーへの報告では、space を `sp7937...` や `t10` のような ID で呼ばない。space の名前で呼ぶ

## オーケストレーターと作業者に分けて進める

### 役割

- **オーケストレーター**: ユーザーと話している今のセッション。タスクの分解、作業者への指示、完了待ち、レビュー、ユーザーへの報告を担う。作業者の worktree のコードは書き換えない
- **作業者**: 1タスクにつき worktree 1つ、space 1つ、Claude Code 1つ。space の名前は `└ <種類>: <中身>` にし、PR ができたら末尾に ` #<PR番号>` を足す（例 `└ アプリ: セッションをValkeyへ #1539`）。種類はアプリ、インフラ、整理、テスト、調査など。作った space は親 space の直後に移す。Herdr の space には親子の機能がなく、名前と並び順しか使えない。先頭の `└ ` で子だと分かり、並び順でどの親の子かが分かる。サイドバーでは名前の先頭しか見えないので、ブランチ名は名前に入れない

| 任せる先 | 向いているタスク |
|---|---|
| Herdr の作業者 | ファイルの書き換えを伴う、数十分以上かかる、ブランチを分けたい、ユーザーが画面で様子を見たい |
| サブエージェント（Agent ツール） | 読むだけの調査、数分で終わる作業 |

- 承認は計画に1回もらう。作業者の一覧（タスク、ブランチ、触るファイル、push や draft PR まで進めるか）を出して承認を得たら、その範囲の space 作成、ペイン分割、作業者への指示、片付けは聞かずに進める。範囲外の操作（マージ、本番への操作、計画になかった push）は都度聞く
- 並列は3つまで。上限はユーザーとオーケストレーターがレビューできる量と、利用枠の消費で決まる
- 同じファイルを触るタスクは同時に走らせない。コンフリクトしたら、後の側を新しい worktree でやり直す

### 手順（2026-11-06 に space の作成から片付けまで動作確認済み）

```bash
# 1. worktree を wtp で作る（commune-voice では commune-worktree スキルで作り、そのパスを WT に入れる）
#    置き場所は wtp の既定（リポジトリの隣の ../worktrees/<branch>）。.wtp.yml があればその設定に従う
WT=$(cd "$REPO" && wtp add -b "$BR" "$BASE" --quiet)

# 2. 作業者の space を作る。返り値の space と terminal を控える
OUT=$(herdr-app do space.new --name "└ $KIND: $WHAT" --folder "$WT" --argv '["claude"]' --task "$BRIEF")
S=$(echo "$OUT" | jq -r .space)
T=$(echo "$OUT" | jq -r .terminal)

# 2b. 親 space の直後（すでに並んでいる子の後ろ）へ移す
#     space.new の space は末尾ではなく先頭にできることがある（2026-11-09 に確認）。今の位置を見て向きを決める
#     index は「動かす前の一覧で、この位置の前に入れる」。下へ動かすときは 1 足さないと1つ手前に入る
IDX=$(herdr-app ls | jq --arg t "$HC_TERMINAL_ID" --arg sp "$S" '
  .spaces as $s
  | ([$s | to_entries[] | select(.value.id != $sp)] | map(.value)) as $o
  | ($o | to_entries[] | select(any(.value.tabs[].terminals[]; .terminal == $t)) | .key) as $p
  | [range($p + 1; $o | length) | select($o[.].name | startswith("└ "))] as $kids
  | ($p + 1 + ([$kids | to_entries[] | select(.key == .value - $p - 1)] | length)) as $want
  | ($s | to_entries[] | select(.value.id == $sp) | .key) as $cur
  | if $cur < $want then $want + 1 else $want end')
herdr-app do space.move --id "$S" --index "$IDX"

# 3. フォルダの信頼の確認に答え、最初の指示が届いたかを画面で見る
hc read "$T" --lines 0             # 信頼の確認が出ているかを確かめる
hc keys "$T" down enter            # 出ていたときだけ、信頼を選ぶ
hc read "$T" --lines 40            # 指示が入力され、作業が始まったかを確かめる

# 4. 完了を待つ（Bash の run_in_background で走らせ、通知で戻る）
hc wait "$T" --timeout 1800

# 5. 結果を読み、差分を自分で確かめる
hc read "$T" --lines 120
git -C "$WT" log --oneline "$BASE"..HEAD && git -C "$WT" diff "$BASE"...HEAD

# 5b. PR ができたら名前の末尾に PR 番号を足す
herdr-app do space.rename --id "$S" --name "└ $KIND: $WHAT #$PR"

# 6. 片付け（space を閉じると中の terminal も終わる。その後で worktree を消す）
herdr-app do space.close --id "$S" --confirmed true
hc get "$T" --json | jq .state     # finished になってから次へ。閉じた直後は live のことがある
hc rm "$T"
(cd "$REPO" && wtp remove "$BR")   # マージ済みならブランチも消す: --with-branch
```

- `--argv` の中身は login shell で包んで起動される。PATH は login shell のものになる
- 信頼の確認は worktree が毎回新しいフォルダなので必ず出る。`hc read` で画面を見て、その確認であり、かつオーケストレーターが作ったユーザー自身のリポジトリの worktree なら `hc keys "$T" down enter` で信頼を選ぶ。別の確認ならユーザーに見せる
- space.new の `--task` で渡した指示は、`hc get` の `first_message` に記録されない（null のまま。2026-11-06 に確認）。届いたかは `hc read` の画面で判断する。信頼の確認で止まって指示が消えたと画面で分かったときだけ、`hc send "$T" "$BRIEF"` で送り直す。届いたか分からないまま再送しない
- `hc wait "$T"` は Claude Code が done になったところで戻る（2026-11-06 に確認。返り値は `{"status":"done","reason":"status",...}`）
- space.new で作った terminal は親を持たない（`hc get` で `parent: null`）。そのため `hc wait --children` では待てない。`hc wait "$T"` で1つずつ待つ
- `hc wait` の既定の時間切れは180秒。時間切れ（`reason: timeout`）は失敗ではない。画面を読んで進んでいれば待ち直す。指示は再送しない
- Bash の前景実行は最大10分で切れる。数分で終わらないタスクは `hc wait` を `run_in_background` で走らせる
- 状態が `blocked` なら、許可か質問でユーザーの判断が要る。`hc read` で画面を見てユーザーに返す。`hc send --force` で確認を越えない
- `idle` のまま RESULT がない、または状態が出ないときは、完了ではなく要確認として扱う
- オーケストレーターがアプリの外で動いていると `$HC_TERMINAL_ID` が空になる。その場合も `hc wait "$T"` と `hc read "$T"` は使える
- `hc wait "$T" --output <文字>` は待ち始めた後に出た出力だけを見る。先に出ていた文字では時間切れになる

### 作業者への指示の形

```text
目的: <何のためのタスクか>
完了条件: <テストが通る、draft PR を作る、など確かめられる形で>
やってよいこと: この worktree の中の編集とコミット<、push と draft PR の作成>
止まって聞くこと: 設定、migration、lockfile、CI、本番に触る前。完了条件を満たせないと分かったとき
言葉: この指示や議論に出ていない言葉（関数名、状態の呼び名など）を新しく使うなら、PR 本文の「この PR で新しく出てくる言葉」に1行ずつ意味を書く
最後の返答は次の形にする:
RESULT
status: complete | decision_required | blocked
end_state_met: yes | no
evidence: 実行したテストとその結果、コミット、PR の URL
notes: レビューで見てほしい点
```

### レビュー

- 作業者の RESULT を信じず、差分とテスト結果を自分で確かめてからユーザーに報告する。独立した目が要るときは code-review のサブエージェントに差分を渡す
- 直しは同じ作業者に `hc send "$T" "<直してほしい点>"` で返す。作業の文脈が残っているので、新しい作業者を立てるより速い
- マージは1本ずつ行う
- ユーザーへの報告は、最後の1行を「ユーザーの番か」にする。判断が要るなら何を決めてほしいかを書き、要らないなら「次の報告まで見なくてよい」と書く。作業者を待っている間、ユーザーが手を出してよいか分からず聞き返すことがあったため

### 作業者を立てるときの注意

- 作業者どうしで取り合うもの（dev サーバーのポート、GPU やメモリ、DB）があるなら、作業者ごとに分けるか、同時に走らせる数を減らす
- `.env` など git に入っていないファイルは worktree にない。リポジトリ専用の worktree スキルがあれば（commune-voice なら commune-worktree）、そちらで worktree を作ってから、そのフォルダで space.new を実行する
- 外部に影響する操作（提出、デプロイ、本番への操作）は作業者にさせず、ユーザーに判断を返す
- 画面に出さなくてよい補助のプログラム（テストやビルド）は `hc run --bg --rm --name <名前> ...` で走らせる。herdr.space のラベルがない terminal はアプリに表示されない

## レシピ: Herdr のペインでブラウザを見る（terminal-browser）

Herdr アプリのペインは terminal-browser を描画できる（2026-11-06 に `herdr-app shot` で表示を確認）。Web ページは自分の pane の右に分割して開く。

```bash
MYPANE=$(herdr-app ls | jq -r --arg t "$HC_TERMINAL_ID" '.spaces[].tabs[].terminals[] | select(.terminal == $t) | .pane')
herdr-app do pane.split --direction right --pane "$MYPANE" --argv '["terminal-browser","open","http://localhost:3000"]'
# 返り値の pane を控える。閉じるときは herdr-app do pane.close --pane <pane>
terminal-browser ls --json         # cdpPort と、開いたタブの targetId を確認
```

- **操作は `terminal-browser action` ではなく agent-browser を CDP に直接つなぐ**。`terminal-browser action` はこの環境では「could not connect agent-browser」で失敗する
- 1つの cdpPort に、ほかの terminal-browser のタブも並ぶことがある。つないだ直後のタブは開いたページとは限らないので、`tab <targetId>` で選んでから操作する
  ```bash
  TID=$(terminal-browser ls --json | jq -r '.browsers[] | select(.cdpPort == <cdpPort>) | .tabs[] | select(.active) | .targetId')
  env -u AGENT_BROWSER_STATE agent-browser --session tb --cdp <cdpPort> batch "tab $TID" "wait 3000" "screenshot <scratchpad>/x.png"
  ```
  `AGENT_BROWSER_STATE` を外さないと Voice のログイン状態が毎回混ざる
- agent-browser の `close` は打たない。接続先の terminal-browser ごと閉じうる
- cookie は `~/Library/Application Support/terminal-browser-*/` に保存され、ログインは残る
- 自分で描画を確かめるときは `herdr-app shot <file.png>` を使う。写るのは表示中の space だけ

### ログイン状態の持ち込み

| 対象 | 方法 |
|---|---|
| Voice の localhost | `voice-agent-login --check` で有効か見てから、`agent-browser --cdp <port> state load ~/.agent-browser/sessions/commune-voice.json` |
| cookie だけで認証するサイト（GitHub / Google / Claude で動作確認済み） | ユーザーに Chrome の `chrome://inspect/#remote-debugging` を有効にしてもらい `tb-import-cookies <domain>...`（`~/.local/bin`）。終わったら無効に戻してもらう |
| localStorage 等で認証するサイト（Linear / Notion / Slack / Prefect で移植失敗） | ユーザーに右ペインで一度手でログインしてもらう |

- Chrome の cookie の書き出しはユーザー承認が要る（auto mode の分類器が認証情報の書き出しとして止める）。cookie 値は出力しない
- `agent-browser --profile <Chrome profile>` は cookie を復号できず 0 件になる。使わない

## 作業者に任せる提案のきっかけ

次のどれかに当たったら、ユーザーに聞かれる前に作業者の一覧を出して承認を求める。

- ファイルの書き換えを伴う独立したタスクが2つ以上ある
- 書き換えを伴うタスクが1つでも、数十分以上かかりそう
- ユーザーが「並列で」「別ブランチで」「任せたい」と言った

Herdr の外のセッション（`$HC_TERMINAL_ID` が空）で、書き換えを伴いそうな相談が始まったら、実装に移る前に Herdr の中で開き直すよう伝える。途中で移すと、引き継ぎ資料を作ってセッションをまたぐことになるため。
