#!/usr/bin/env python3
"""Prefect Cloud から失敗/クラッシュした flow run を取得し、優先度付きで表示する.

Usage:
    python list_failed_runs.py [--date YYYY-MM-DD] [--env production|staging|all]

デフォルト: 昨日(JST)の失敗ランを取得
"""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from urllib.request import Request, urlopen

JST = timezone(timedelta(hours=9))

# profiles.toml のデフォルトパス
PROFILES_TOML = "~/.prefect/profiles.toml"


def load_credentials() -> tuple[str, str]:
    """~/.prefect/profiles.toml から API URL と API Key を取得."""
    import os

    path = os.path.expanduser(PROFILES_TOML)
    api_url = os.environ.get("PREFECT_API_URL")
    api_key = os.environ.get("PREFECT_API_KEY")

    if api_url and api_key and "prefect.cloud" in api_url:
        return api_url, api_key

    # profiles.toml から読み取り
    with open(path) as f:
        content = f.read()

    for line in content.splitlines():
        line = line.strip()
        if line.startswith("PREFECT_API_URL") and "prefect.cloud" in line:
            api_url = line.split("=", 1)[1].strip().strip('"')
        elif line.startswith("PREFECT_API_KEY"):
            api_key = line.split("=", 1)[1].strip().strip('"')

    if not api_url or not api_key:
        print("ERROR: Prefect Cloud credentials not found", file=sys.stderr)
        sys.exit(1)

    return api_url, api_key


def fetch_failed_runs(
    api_url: str,
    api_key: str,
    start_utc: str,
    end_utc: str,
    env_filter: str,
) -> list[dict]:
    """FAILED/CRASHED の flow run を取得."""
    body: dict = {
        "flow_runs": {
            "state": {"type": {"any_": ["FAILED", "CRASHED"]}},
            "start_time": {"after_": start_utc, "before_": end_utc},
        },
        "sort": "START_TIME_DESC",
        "limit": 100,
    }

    if env_filter in ("production", "staging"):
        body["flow_runs"]["tags"] = {"all_": [env_filter]}

    data = json.dumps(body).encode()
    req = Request(
        f"{api_url}/flow_runs/filter",
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )

    with urlopen(req) as resp:
        return json.loads(resp.read())


def format_run(run: dict) -> dict:
    """flow run を表示用に整形."""
    tags = run.get("tags", [])
    env = "production" if "production" in tags else "staging" if "staging" in tags else "unknown"
    state = run.get("state", {})
    return {
        "id": run["id"],
        "name": run.get("name", ""),
        "flow": run.get("flow_id", ""),
        "state": f"{state.get('type', '')}/{state.get('name', '')}",
        "env": env,
        "tags": tags,
        "start_time": run.get("start_time", ""),
    }


def main():
    parser = argparse.ArgumentParser(description="Prefect Cloud の失敗フローランを一覧表示")
    parser.add_argument("--date", help="対象日 (YYYY-MM-DD, JST). デフォルト: 昨日")
    parser.add_argument("--env", choices=["production", "staging", "all"], default="all")
    args = parser.parse_args()

    # 日付範囲を計算 (JST → UTC)
    if args.date:
        target = datetime.strptime(args.date, "%Y-%m-%d").replace(tzinfo=JST)
    else:
        target = datetime.now(JST) - timedelta(days=1)
        target = target.replace(hour=0, minute=0, second=0, microsecond=0)

    # JST の 00:00 - 23:59 を UTC に変換
    start_utc = (target - timedelta(hours=9)).strftime("%Y-%m-%dT%H:%M:%SZ")
    end_utc = (target + timedelta(hours=24) - timedelta(hours=9)).strftime("%Y-%m-%dT%H:%M:%SZ")

    api_url, api_key = load_credentials()
    runs = fetch_failed_runs(api_url, api_key, start_utc, end_utc, args.env)

    if not runs:
        print(f"No failed/crashed runs found for {target.strftime('%Y-%m-%d')} (JST)")
        return

    # production を先に、その後 staging
    formatted = [format_run(r) for r in runs]
    prod_runs = [r for r in formatted if r["env"] == "production"]
    stg_runs = [r for r in formatted if r["env"] == "staging"]
    other_runs = [r for r in formatted if r["env"] == "unknown"]

    for label, group in [("PRODUCTION", prod_runs), ("STAGING", stg_runs), ("OTHER", other_runs)]:
        if not group:
            continue
        print(f"\n{'='*60}")
        print(f" {label} ({len(group)} runs)")
        print(f"{'='*60}")
        for r in group:
            print(f"  ID:    {r['id']}")
            print(f"  Name:  {r['name']}")
            print(f"  State: {r['state']}")
            print(f"  Start: {r['start_time']}")
            print(f"  Tags:  {', '.join(r['tags'])}")
            print()


if __name__ == "__main__":
    main()
