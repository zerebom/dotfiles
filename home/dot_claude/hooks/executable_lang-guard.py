#!/usr/bin/env python3
"""lang-guard: Claude Code の最終応答が英語なら日本語で書き直させる hook。

  stop   : Stop hook。英語判定なら decision=block を返す
  prompt : UserPromptSubmit hook。日本語で答える指示を注入
  eval   : ~/.claude/projects の過去ログで ratio 分布を出す / ラベルで閾値評価
  test   : fixtures で判定を検証

fail-open: 例外は握りつぶして exit 0。
"""
import glob
import json
import os
import re
import sys
import time

# 閾値は `eval dump` → 目視ラベル → `eval score` で見直す。
# MIN_LATIN を下げると短い英語も拾えるが、識別子だけの日本語短文を誤検知しやすくなる
MIN_LATIN = 80   # 除去後のラテン文字がこれ未満なら判定しない（日本語扱い）
RATIO = 0.10     # kana/(kana+latin) がこれ未満なら英語

HOME = os.path.expanduser("~")
LOG_PATH = os.path.join(HOME, ".claude", "logs", "lang-guard.jsonl")
HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURES = os.path.join(HERE, "lang-guard-fixtures")

BLOCK_REASON = ("直前の応答が英語でした。同じ内容を日本語で書き直して回答し直してください。"
                "コード・コマンド・識別子・固有名詞は原文のままで構いません。"
                "ユーザーが英語での出力を明示的に求めていた場合は書き直さず、その旨を日本語で一言添えて終えてください。")
PROMPT_CONTEXT = "ユーザーへの応答（本文・質問・報告）は必ず日本語で書くこと。コードや識別子は原文のままでよい。"

_FENCE = re.compile(r"```.*?(?:```|\Z)", re.S)
_INLINE = re.compile(r"`[^`\n]*`")
_URL = re.compile(r"https?://\S+")
_PATHTOK = re.compile(r"\S*/\S*")
_QUOTE = re.compile(r"^[ \t]*>.*$", re.M)
_TABLESEP = re.compile(r"^[ \t]*\|?[ \t]*:?-{2,}:?[ \t]*(\|[ \t]*:?-{2,}:?[ \t]*)*\|?[ \t]*$", re.M)
_KANA = re.compile(r"[぀-ゟ゠-ヿ]")
_LATIN = re.compile(r"[A-Za-z]")


def strip_text(t):
    t = _FENCE.sub(" ", t)
    t = _INLINE.sub(" ", t)
    t = _URL.sub(" ", t)
    t = _QUOTE.sub(" ", t)
    t = _TABLESEP.sub(" ", t)
    t = _PATHTOK.sub(" ", t)
    return t


def analyze(text):
    """(kana, latin, ratio, is_english). latin<MIN_LATIN は判定対象外(None ではなく is_english=False)。"""
    s = strip_text(text)
    kana = len(_KANA.findall(s))
    latin = len(_LATIN.findall(s))
    ratio = kana / (kana + latin) if (kana + latin) else 1.0
    return kana, latin, ratio, (latin >= MIN_LATIN and ratio < RATIO)


# ---- transcript ----
def _entry_texts(d):
    c = d.get("message", {}).get("content")
    if isinstance(c, str):
        return [c]
    return [b.get("text", "") for b in c or [] if isinstance(b, dict) and b.get("type") == "text"]


# ---- subcommands ----
def cmd_stop():
    payload = json.loads(sys.stdin.read() or "{}")
    if payload.get("stop_hook_active") or os.environ.get("LANG_GUARD_DISABLE"):
        return
    text = payload.get("last_assistant_message")
    if not isinstance(text, str) or not text.strip():
        return
    kana, latin, ratio, english = analyze(text)
    if latin >= MIN_LATIN:
        try:
            os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
            with open(LOG_PATH, "a", encoding="utf-8") as f:
                f.write(json.dumps({
                    "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                    "session_id": payload.get("session_id"),
                    "kana": kana, "latin": latin, "ratio": round(ratio, 4),
                    "blocked": english, "head": text[:120],
                }, ensure_ascii=False) + "\n")
        except Exception:
            pass
    if english:
        sys.stdout.write(json.dumps({"decision": "block", "reason": BLOCK_REASON}, ensure_ascii=False))


def cmd_prompt():
    sys.stdout.write(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit", "additionalContext": PROMPT_CONTEXT}}, ensure_ascii=False))


def iter_turn_finals():
    """過去ログから「ターン末の最終テキスト」を (path, text) で列挙。tool_use を含むセグメントは中間なので除外。"""
    pat = os.path.join(HOME, ".claude", "projects", "**", "*.jsonl")
    for p in glob.glob(pat, recursive=True):
        if "/subagents/" in p:
            continue
        try:
            texts, has_tool = [], False
            with open(p, encoding="utf-8") as f:
                for line in f:
                    if '"type":"user"' not in line and '"type":"assistant"' not in line \
                            and '"type": "user"' not in line and '"type": "assistant"' not in line:
                        continue
                    try:
                        d = json.loads(line)
                    except Exception:
                        continue
                    if d.get("isSidechain"):
                        continue
                    t = d.get("type")
                    if t == "user":
                        if texts and not has_tool:
                            yield p, "\n".join(texts)
                        texts, has_tool = [], False
                    elif t == "assistant":
                        if d.get("isApiErrorMessage") or d.get("message", {}).get("model") == "<synthetic>":
                            continue
                        c = d.get("message", {}).get("content")
                        if isinstance(c, list) and any(isinstance(b, dict) and b.get("type") == "tool_use" for b in c):
                            has_tool = True
                        texts += [x for x in _entry_texts(d) if x]
                if texts and not has_tool:
                    yield p, "\n".join(texts)
        except Exception:
            continue


def cmd_eval(args):
    """eval            : ratio 分布
       eval dump N     : 境界付近(ratio<0.4, latin>=40)から N 件を /tmp 用 JSON に出力（ラベル付け用）
       eval score FILE : {id,label}付き JSON(dump 出力にlabel追記)で P/R/F1 を候補閾値ごとに出す"""
    sub = args[0] if args else "hist"
    if sub == "hist":
        bins = [0, 0.01, 0.02, 0.05, 0.1, 0.2, 0.4, 1.01]
        cnt = [0] * (len(bins) - 1)
        total = skipped = 0
        for _, t in iter_turn_finals():
            total += 1
            k, l, r, _ = analyze(t)
            if l < 40:
                skipped += 1
                continue
            for i in range(len(bins) - 1):
                if bins[i] <= r < bins[i + 1]:
                    cnt[i] += 1
        print("turn finals: %d, latin<40 (skipped): %d" % (total, skipped))
        for i in range(len(cnt)):
            print("ratio %.2f-%.2f : %d" % (bins[i], min(bins[i + 1], 1.0), cnt[i]))
    elif sub == "dump":
        import random
        n = int(args[1]); out = args[2]
        random.seed(1)
        pool = []
        for p, t in iter_turn_finals():
            k, l, r, _ = analyze(t)
            if l >= 40 and r < 0.4:
                pool.append({"ratio": round(r, 4), "kana": k, "latin": l, "text": t[:1500]})
        # ratio 帯ごとに層化抽出
        bands = [(0, 0.01), (0.01, 0.03), (0.03, 0.05), (0.05, 0.08), (0.08, 0.15), (0.15, 0.4)]
        picked = []
        for lo, hi in bands:
            g = [x for x in pool if lo <= x["ratio"] < hi]
            random.shuffle(g)
            picked += g[: n // len(bands)]
        for i, x in enumerate(picked):
            x["id"] = i
        json.dump(picked, open(out, "w"), ensure_ascii=False, indent=1)
        print("pool=%d picked=%d" % (len(pool), len(picked)))
    elif sub == "score":
        data = json.load(open(args[1]))
        data = [x for x in data if x.get("label") in ("en", "ja")]
        print("labeled: %d (en=%d)" % (len(data), sum(x["label"] == "en" for x in data)))
        best = None
        for ml in (40, 60, 80, 120, 160, 250):
            for rt in (0.01, 0.02, 0.03, 0.05, 0.08, 0.1, 0.15):
                tp = fp = fn = 0
                for x in data:
                    pred = x["latin"] >= ml and x["ratio"] < rt
                    gold = x["label"] == "en"
                    tp += pred and gold; fp += pred and not gold; fn += (not pred) and gold
                p = tp / (tp + fp) if tp + fp else 0.0
                r = tp / (tp + fn) if tp + fn else 0.0
                f = 2 * p * r / (p + r) if p + r else 0.0
                print("MIN_LATIN=%3d RATIO=%.2f  P=%.3f R=%.3f F1=%.3f (tp=%d fp=%d fn=%d)" % (ml, rt, p, r, f, tp, fp, fn))
                if best is None or (f, p) > (best[0], best[1]):
                    best = (f, p, ml, rt)
        print("best:", best)


def cmd_test():
    bad = 0
    files = sorted(glob.glob(os.path.join(FIXTURES, "*.txt")))
    for p in files:
        name = os.path.basename(p)
        want = name.startswith("en_")
        got = analyze(open(p, encoding="utf-8").read())
        if got[3] != want:
            bad += 1
            print("MISMATCH %s want_en=%s kana=%d latin=%d ratio=%.3f" % (name, want, got[0], got[1], got[2]))
    print("%d fixtures, %d mismatches" % (len(files), bad))
    sys.exit(1 if bad else 0)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        if cmd == "stop":
            cmd_stop()
        elif cmd == "prompt":
            cmd_prompt()
        elif cmd == "eval":
            cmd_eval(sys.argv[2:])
        elif cmd == "test":
            cmd_test()
    except SystemExit:
        raise
    except BaseException:
        pass  # fail-open
    sys.exit(0)


if __name__ == "__main__":
    main()
