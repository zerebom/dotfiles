"""Claude Code のセッションログから、指定日（または期間）のユーザー発言を集めて Markdown で出す。

使い方:
    uv run python extract.py 2026-11-09
    uv run python extract.py 2026-11-03 2026-11-09
    uv run python extract.py 2026-11-09 --exclude 0efc676b
"""

import argparse
import glob
import json
import os
import re
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone

JST = timezone(timedelta(hours=9))

SKIP_PREFIXES = (
    "<task-notification",
    "<hc from=",
    "<local-command",
    "<command-stdout",
    "<command-stderr",
    "This session is being continued",
    "[Request interrupted",
    "Caveat:",
    "Another Claude session sent a message",
    "Background (from the session that started this one)",
    "Reply with the single word",
)
# 画面操作だけのスラッシュコマンドは発言として数えない
SKIP_COMMANDS = {"/clear", "/exit", "/compact", "/resume", "/model", "/config", "/status", "/cost"}
WORKER_PREFIXES = ("目的:", "目的：", "指示書:", "指示書：")

APPROVAL_RE = re.compile(
    r"^(ok|okay|おk|おけ|おっけー?|いいよ|いいね|いいです|はい|うん|了解|りょ|りょうかい|"
    r"お願い(します|しまーす|しますー)?|おねがい(します)?|よろしく(です|お願いします)?|"
    r"進めて|続けて|やって|それで|それでいい(よ)?|yes|y|go|lgtm|\d{1,2})$"
)
APPROVAL_TRAIL = re.compile(r"[\s。、．.!！?？〜~ー\-]+$")

STUCK_WORDS = (
    "わかんな", "分かんな", "わからな", "分からな", "訳わか", "わけわか", "意味わか",
    "理解できな", "どういうこと", "びっくり", "なんで", "なぜ", "それでいいのか", "おかしい",
)

STUCK_MAX_LEN = 300


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            x.get("text", "") for x in content if isinstance(x, dict) and x.get("type") == "text"
        )
    return ""


def normalize_user(text):
    """ユーザー発言として扱う文字列を返す。発言でなければ None。"""
    s = re.sub(r"^(\s*<system-reminder>.*?</system-reminder>)+", "", text, flags=re.S)
    s = strip_paste(s).strip()
    if not s or s.startswith(SKIP_PREFIXES):
        return None
    m = re.search(r"<command-name>(/[^<]+)</command-name>", s)
    if not m and re.match(r"<[A-Za-z][\w-]*[\s/>]", s):
        # 通知や連携の状態など、ハーネスが差し込んだ行
        return None
    if m:
        cmd = m.group(1).strip()
        if cmd in SKIP_COMMANDS:
            return None
        a = re.search(r"<command-args>(.*?)</command-args>", s, re.S)
        args = a.group(1).strip() if a else ""
        return f"{cmd} {args}".strip()
    if s.split()[0] in SKIP_COMMANDS:
        return None
    return s


def strip_paste(s):
    # オーケストレーターの指示は pasted_content に包まれて届くので、外してから先頭を見る
    return re.sub(r"^\s*<pasted_content[^>]*>\s*", "", s)


def is_approval(s):
    t = APPROVAL_TRAIL.sub("", s.strip().lower())
    return len(t) <= 15 and bool(APPROVAL_RE.match(t))


def is_stuck(s):
    # 貼り付けた議事録やログの中の「なんで」を拾わないよう、本人が打った部分だけを見る
    own = re.sub(r"<pasted_content[^>]*>.*?</pasted_content>", "", s, flags=re.S)
    return len(own) <= STUCK_MAX_LEN and any(w in own for w in STUCK_WORDS)


def short(s, n):
    s = re.sub(r"\s+", " ", s).strip()
    return s if len(s) <= n else s[: n - 1] + "…"


def tail(s, n):
    s = re.sub(r"\s+", " ", s).strip()
    return s if len(s) <= n else "…" + s[-(n - 1):]


def parse_ts(ts):
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(JST)


def load_session(path, start, end):
    """1 セッションを読む。期間外の行は捨てる。"""
    sid = os.path.basename(path)[:-6]
    cwd = None
    first_any = None  # 期間に関係なく最初のユーザー発言（作業者や定期実行の判定用）
    scheduled = False
    msgs = []
    briefs = 0
    head = None  # 期間内で最初の発言（指示書も含む）
    last_ai = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            typ = d.get("type")
            if typ not in ("user", "assistant") or d.get("isSidechain"):
                continue
            # 再開や分岐で作られたファイルには、元のセッションの行が元の sessionId のまま写っている。数え直さない
            if d.get("sessionId", sid) != sid:
                continue
            ts = d.get("timestamp")
            if not ts:
                continue
            cwd = cwd or d.get("cwd")
            content = (d.get("message") or {}).get("content")
            if typ == "user":
                if d.get("isMeta"):
                    continue
                raw = text_of(content)
                # 定期実行のプロンプトはタグなので normalize_user で消える。消える前に見ておく
                if first_any is None and raw.lstrip().startswith("<scheduled-task"):
                    scheduled = True
                s = normalize_user(raw)
                if s is None:
                    continue
                if first_any is None:
                    first_any = s
                t = parse_ts(ts)
                if not start <= t.date() <= end:
                    continue
                if head is None:
                    head = (t, s)
                if s.startswith(WORKER_PREFIXES):
                    briefs += 1
                else:
                    msgs.append((t, s))
            else:
                tx = text_of(content).strip()
                if tx:
                    t = parse_ts(ts)
                    if start <= t.date() <= end:
                        last_ai = (t, tx)
    if (not msgs and not briefs) or first_any is None:
        return None
    if scheduled:
        return None
    worker = first_any.startswith(WORKER_PREFIXES)
    if not cwd:
        cwd = os.path.basename(os.path.dirname(path))
    return {
        "id": sid,
        "sid8": sid[:8],
        "cwd": cwd,
        "msgs": msgs,
        "last_ai": last_ai,
        "worker": worker,
        "head": head,
    }


def short_cwd(cwd):
    home = os.path.expanduser("~")
    cwd = cwd.replace(home, "~")
    for marker in ("/ghq/github.com/", "/worktrees/"):
        if marker in cwd:
            cwd = cwd.split(marker, 1)[1]
    return cwd


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("start", nargs="?", help="開始日 YYYY-MM-DD（省略すると今日）")
    ap.add_argument("end", nargs="?", help="終了日 YYYY-MM-DD（省略すると開始日と同じ）")
    ap.add_argument("--exclude", action="append", default=[], help="除くセッション ID（前方一致、複数可）。今の会話は CLAUDE_CODE_SESSION_ID で自動的に除く")
    ap.add_argument("--projects-dir", default=os.path.expanduser("~/.claude/projects"))
    a = ap.parse_args()

    start = date.fromisoformat(a.start) if a.start else datetime.now(JST).date()
    end = date.fromisoformat(a.end) if a.end else start
    if end < start:
        start, end = end, start
    # 振り返りを走らせている会話そのものは材料にしない
    own = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if own:
        a.exclude.append(own)

    # フォルダ名が "-" で始まるので、シェルに渡さず glob で拾う。subagents/ の下は対象外
    paths = glob.glob(os.path.join(a.projects_dir, "*", "*.jsonl"))
    # 更新時刻では日付を絞れない（古い行だけのファイルも更新される）。開始日より前に更新されたものだけ除く
    floor = datetime(start.year, start.month, start.day, tzinfo=JST).timestamp()
    sessions = []
    for p in paths:
        if os.path.getmtime(p) < floor:
            continue
        if any(os.path.basename(p).startswith(x) for x in a.exclude):
            continue
        s = load_session(p, start, end)
        if s:
            sessions.append(s)
    sessions.sort(key=lambda s: s["head"][0])

    human = [s for s in sessions if s["msgs"]]
    events = sorted((t, s["sid8"], m) for s in human for t, m in s["msgs"])

    period = start.isoformat() if start == end else f"{start.isoformat()} 〜 {end.isoformat()}"
    out = [f"# AI セッションの材料（{period}、JST）", ""]
    n_worker = sum(1 for s in sessions if s["worker"])
    out.append(f"- セッション: {len(sessions)} 件（うち作業者のセッション {n_worker} 件）")
    out.append(f"- 本人の発言: {len(events)} 件")
    out.append(
        "- 作業者のセッションは、最初の発言が「目的:」「指示書:」で始まるもの。"
        "指示書とオーケストレーターからの指示（`<hc from=`）は数えず、本人が作業者に直接打った発言だけを数える"
    )
    out.append("")

    # 1. セッションの一覧
    out += ["## 1. セッションの一覧", ""]
    out += ["| 開始 | ID | 作業フォルダ | 本人の発言数 | 最初の発言 | 最後の AI 応答 |", "|---|---|---|---|---|---|"]
    multi_day = start != end
    fmt = "%m/%d %H:%M" if multi_day else "%H:%M"
    for s in sessions:
        t0, m0 = s["head"]
        last = tail(s["last_ai"][1], 160) if s["last_ai"] else ""
        kind = "（作業者）" if s["worker"] else ""
        cells = [
            t0.strftime(fmt),
            s["sid8"] + kind,
            short_cwd(s["cwd"]),
            str(len(s["msgs"])),
            short(m0, 80),
            last,
        ]
        out.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    out.append("")

    # 2. 時間帯ごとの表
    out += ["## 2. 時間帯ごとの発言数とセッション", ""]
    out += ["| 時間帯 | 発言数 | セッション数 | セッション ID（発言数） |", "|---|---|---|---|"]
    byh = defaultdict(lambda: defaultdict(int))
    for t, sid, _ in events:
        byh[t.strftime("%m/%d %H時" if multi_day else "%H時")][sid] += 1
    for h in sorted(byh):
        d = byh[h]
        ids = ", ".join(f"{k}({v})" for k, v in sorted(d.items(), key=lambda kv: -kv[1]))
        out.append(f"| {h} | {sum(d.values())} | {len(d)} | {ids} |")
    out.append("")

    # 3. 切り替えの回数
    out += ["## 3. セッションの切り替え", ""]
    per_day = defaultdict(int)
    prev = None
    for t, sid, _ in events:
        if prev and prev[1] == t.date() and sid != prev[0]:
            per_day[t.date()] += 1
        prev = (sid, t.date())
    days = sorted({t.date() for t, _, _ in events})
    for d in days:
        n = sum(1 for t, _, _ in events if t.date() == d)
        out.append(f"- {d.isoformat()}: 発言 {n} 件、切り替え {per_day[d]} 回")
    out.append("")
    out.append("発言の並び（同じセッションが続く所は 1 つにまとめた。テーマ名を付けた後、同じテーマ同士の移動を数え直すのに使う）:")
    out.append("")
    runs = []
    for t, sid, _ in events:
        if runs and runs[-1][1] == sid and runs[-1][0].date() == t.date():
            runs[-1][2] += 1
        else:
            runs.append([t, sid, 1])
    line_day = None
    buf = []
    for t, sid, n in runs:
        if t.date() != line_day:
            if buf:
                out.append(f"- {line_day.isoformat()}: " + " → ".join(buf))
            line_day, buf = t.date(), []
        buf.append(f"{t.strftime('%H:%M')} {sid}×{n}")
    if buf:
        out.append(f"- {line_day.isoformat()}: " + " → ".join(buf))
    out.append("")

    # 4. 承認だけの発言
    out += ["## 4. 承認だけの発言", ""]
    out += ["| ID | 承認だけ / 発言数 | 例 |", "|---|---|---|"]
    total_ok = 0
    for s in human:
        oks = [m for _, m in s["msgs"] if is_approval(m)]
        if not oks:
            continue
        total_ok += len(oks)
        ex = "、".join(sorted(set(short(m, 12) for m in oks))[:5])
        out.append(f"| {s['sid8']} | {len(oks)} / {len(s['msgs'])} | {ex} |")
    out.append("")
    out.append(f"合計 {total_ok} 件 / {len(events)} 件")
    out.append("")

    # 5. 詰まりの合図
    out += ["## 5. 詰まりの合図", ""]
    hits = [(t, sid, m) for t, sid, m in events if is_stuck(m)]
    if not hits:
        out.append("該当なし")
    for t, sid, m in hits:
        out.append(f"- {t.strftime(fmt)} {sid}: {short(m, 140)}")
    out.append("")

    print("\n".join(out))


if __name__ == "__main__":
    main()
