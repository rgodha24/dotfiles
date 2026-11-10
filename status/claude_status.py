#!/usr/bin/env python3
"""Pool view of the Claude subscription quota behind CLIProxyAPI.

Polls each subscription's weekly usage every few minutes, keeps the snapshots, and serves a
chart of the pooled remaining quota. Time before the first snapshot is estimated from the proxy's
journal (which account served each request), scaled so each account's current window lands on its
real utilization.
"""

import gzip
import json
import os
import re
import subprocess
import threading
import time
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOME = Path.home()
AUTH_DIR = Path(os.environ.get("CPA_AUTH_DIR", HOME / ".cli-proxy-api"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "claude-status"
SNAPSHOTS = STATE_DIR / "snapshots.jsonl"
STATIC = Path(os.environ.get("STATUS_STATIC", Path(__file__).parent))
HOST = os.environ.get("STATUS_HOST", "127.0.0.1")
PORT = int(os.environ.get("STATUS_PORT", "8319"))
POLL_SECONDS = 300
HISTORY_DAYS = 14
STEP = 600  # chart resolution, seconds
WEEK = 7 * 86400
JOURNAL_UNIT = "cliproxyapi"

USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
ROUTE_RE = re.compile(
    r"^\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)\].*session-affinity: ([^|]+?) \| session=(\S+)"
    r".* (?:failover_)?auth=(\S+) .*model=(\S+)"
)
CLAUDE_AUTH_RE = re.compile(r"^claude-[0-9a-f]+-(\S+)\.json$")
THREAD_HOURS = 12  # how far back the recent threads list reaches
THREAD_LIMIT = 15

lock = threading.Lock()
refresh_lock = threading.Lock()
journal_cache = {"at": 0.0, "counts": {}, "threads": {}, "cursor": None}
journal_lock = threading.Lock()


def parse_ts(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def accounts():
    """Claude subscription auth files the proxy can route to, keyed by email."""
    found = {}
    for path in sorted(AUTH_DIR.glob("claude-*.json")):
        try:
            data = json.loads(path.read_text())
        except (OSError, ValueError):
            continue
        if data.get("type") != "claude" or data.get("disabled"):
            continue
        found[data["email"]] = {
            "token": data.get("access_token"),
            "reserve": data.get("weekly_reserve_percent", 0),
        }
    return found


def fetch_usage(token):
    req = urllib.request.Request(
        USAGE_URL,
        headers={
            "Authorization": f"Bearer {token}",
            "anthropic-beta": "oauth-2025-04-20",
            "User-Agent": "claude-status",
        },
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)


def snapshot_from(email, usage, now):
    week = usage.get("seven_day") or {}
    five = usage.get("five_hour") or {}
    extra = usage.get("extra_usage") or {}
    breakdown = usage.get("seven_day_breakdown") or {}
    return {
        "t": now,
        "email": email,
        "util": week.get("utilization"),
        "reset": parse_ts(week.get("resets_at")),
        "window_start": parse_ts(breakdown.get("window_started_at")),
        "five_util": five.get("utilization"),
        "five_reset": parse_ts(five.get("resets_at")),
        "extra": {
            "enabled": extra.get("is_enabled"),
            "used": extra.get("used_credits"),
            "limit": extra.get("monthly_limit"),
            "disabled_reason": extra.get("disabled_reason"),
            "decimals": extra.get("decimal_places") or 2,
        },
    }


def poll_once():
    now = time.time()
    rows = []
    for email, acct in accounts().items():
        if not acct["token"]:
            continue
        try:
            rows.append(snapshot_from(email, fetch_usage(acct["token"]), now))
        except Exception as exc:  # one bad account must not stop the others
            print(f"poll {email}: {exc}", flush=True)
    if rows:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with lock, SNAPSHOTS.open("a") as f:
            for row in rows:
                f.write(json.dumps(row) + "\n")


def poll_forever():
    while True:
        try:
            poll_once()
            refresh()
        except Exception as exc:
            print(f"poll: {exc}", flush=True)
        time.sleep(POLL_SECONDS)


def load_snapshots(since):
    if not SNAPSHOTS.exists():
        return []
    with lock:
        lines = SNAPSHOTS.read_text().splitlines()
    rows = []
    for line in lines:
        try:
            row = json.loads(line)
        except ValueError:
            continue
        if row["t"] >= since and row.get("util") is not None:
            rows.append(row)
    return rows


def read_journal():
    """Fold new proxy routing log lines into per-account request counts and per-thread state.

    The first call reads the whole history window; later calls only read entries after the saved
    journal cursor, so a refresh costs milliseconds instead of re-parsing two weeks of logs.
    """
    with journal_lock:
        if time.time() - journal_cache["at"] < 2:
            return
        start = journal_cache["cursor"]
        start = [f"--after-cursor={start}"] if start else ["--since", f"-{HISTORY_DAYS + 1}d"]
        try:
            out = subprocess.run(
                ["journalctl", "--user", "-u", JOURNAL_UNIT, *start, "--show-cursor",
                 "--no-pager", "-o", "cat", "--grep", "selector.go.*session-affinity"],
                capture_output=True, text=True, timeout=120,
            ).stdout
        except (OSError, subprocess.TimeoutExpired) as exc:
            print(f"journal: {exc}", flush=True)
            out = ""
        ingest(out.splitlines(), journal_cache)
        journal_cache["at"] = time.time()


def ingest(lines, cache):
    counts, threads = cache["counts"], cache["threads"]
    stamps = {}  # one strptime per distinct minute instead of per line
    for line in lines:
        if line.startswith("-- cursor: "):
            cache["cursor"] = line[11:]
            continue
        m = ROUTE_RE.match(line)
        if not m:
            continue
        stamp, event, session, auth, model = m.groups()
        minute = stamp[:16]
        base = stamps.get(minute)
        if base is None:
            base = stamps[minute] = datetime.strptime(minute, "%Y-%m-%d %H:%M").astimezone().timestamp()
        ts = base + int(stamp[17:])
        email = CLAUDE_AUTH_RE.match(auth)
        if email:
            bucket = int(ts // STEP * STEP)
            per = counts.setdefault(email.group(1), {})
            per[bucket] = per.get(bucket, 0) + 1
        if session.endswith("...") and len(session.split(":", 1)[-1]) < 8:
            continue  # pre-patch logs keep 1 char of the id, which can't tell threads apart
        account = account_label(auth)
        t = threads.get(session)
        if t is None:
            t = threads[session] = {"id": session.rstrip("."), "first": ts, "n": 0, "moves": []}
        elif t["account"] != account:
            t["moves"].append({"t": ts, "from": t["account"], "to": account, "why": event})
        t.update(last=ts, account=account, model=model)
        t["n"] += 1
    floor = time.time() - (HISTORY_DAYS + 1) * 86400
    for per in counts.values():
        for b in [b for b in per if b < floor]:
            del per[b]
    floor = time.time() - THREAD_HOURS * 3600
    for key in [k for k, t in threads.items() if t["last"] < floor]:
        del threads[key]


def account_label(auth):
    """Email for subscription auth files, "API key" for console keys, otherwise the raw id."""
    if ":apikey:" in auth:
        return "API key"
    m = re.match(r"^(?:claude-[0-9a-f]+-|codex-)?(.+?)\.json$", auth)
    return m.group(1) if m else auth


def journal_counts():
    read_journal()
    return journal_cache["counts"]


def recent_threads():
    read_journal()
    with journal_lock:
        rows = sorted(journal_cache["threads"].values(), key=lambda t: -t["last"])
        return [dict(t, moves=list(t["moves"])) for t in rows[:THREAD_LIMIT]]


DRAIN_GAP = 3 * 3600  # an account idle this long while others serve traffic is at its reserve
DRAIN_OTHERS = 50  # requests other accounts must serve in that gap to count as "traffic moved"


def next_reset(ws, t):
    """Next weekly reset after t for a window schedule anchored at ws."""
    return ws + (int((t - ws) // WEEK) + 1) * WEEK


def drain_points(email, counts, schedules, now):
    """Times this account went idle for DRAIN_GAP while traffic moved to later-resetting accounts.

    soonest-reset routing prefers the account whose window resets first, and only passes it over
    for one that resets later once it is down to its weekly reserve. Those moments pin its
    utilization at 100 - reserve.
    """
    own = counts.get(email, {})
    mine = schedules[email]
    points = []
    busy = sorted(own)
    for a, b in zip(busy, busy[1:] + [float("inf")]):
        if b - a < DRAIN_GAP or a + DRAIN_GAP > now:
            continue
        later = earlier = 0
        for other, per in counts.items():
            if other == email or other not in schedules:
                continue
            n = sum(c for t, c in per.items() if a < t <= a + DRAIN_GAP)
            if next_reset(schedules[other], a) > next_reset(mine, a):
                later += n
            else:
                earlier += n
        if later >= DRAIN_OTHERS and later > earlier:
            points.append(a + STEP)
    return points


def estimate(grid, counts, drains, latest, ratio, reserve):
    """Estimated utilization (0-100) on grid for one account from its journal request counts.

    Windows run back to back, 7 days each, from the current window start. Inside each window,
    utilization is pinned at known points (0 at the start, 100 - reserve wherever routing
    moved off the account, the real value now; a past window that saw heavy use ends at its
    reserve too) and spread between them in proportion to the requests served.
    """
    ws = latest.get("window_start") or (latest["reset"] - WEEK)
    floor = 100.0 - reserve

    def cum(a, b):
        return sum(c for t, c in counts.items() if a <= t < b)

    windows = {}
    for t in grid:
        windows.setdefault(int((t - ws) // WEEK), []).append(t)

    out = []
    for idx, ts in sorted(windows.items()):
        start, end = ws + idx * WEEK, ws + (idx + 1) * WEEK
        anchors = [(start, 0.0)]
        if idx >= 0:
            # current window: the real value bounds every earlier anchor
            for d in drains:
                if start < d < latest["t"]:
                    anchors.append((d, min(floor, latest["util"])))
            anchors.append((latest["t"], latest["util"]))
        else:
            anchors += [(d, floor) for d in drains if start < d < end - 3600]
            if len(anchors) == 1 and cum(start, end) * ratio >= 50:
                anchors.append((end, floor))
        for t in ts:
            prev = max((a for a in anchors if a[0] <= t), key=lambda a: a[0])
            nxt = [a for a in anchors if a[0] > t]
            if nxt:
                tb, ub = nxt[0]
                total = cum(prev[0], tb)
                share = cum(prev[0], t + STEP) / total if total else 0.0
                u = prev[1] + (ub - prev[1]) * min(1.0, share)
            else:
                u = prev[1] + ratio * cum(prev[0], t + STEP)
            out.append(min(100.0, max(0.0, u)))
    return out


def build():
    now = time.time()
    since = now - HISTORY_DAYS * 86400
    grid = list(range(int(since // STEP * STEP), int(now), STEP)) + [now]
    snaps = load_snapshots(since)
    live = accounts()
    by_email = {}
    for row in snaps:
        by_email.setdefault(row["email"], []).append(row)
    emails = sorted(set(live) | set(by_email))
    counts = journal_counts()

    # the log estimate covers the time before each account's first snapshot, so that snapshot
    # anchors it: a later reset (scheduled or manual) must not leak back into the estimate
    ratios = {}
    for email in emails:
        rows = by_email.get(email)
        if not rows:
            continue
        latest = rows[0]
        ws = latest.get("window_start") or (latest["reset"] - WEEK)
        n = sum(c for b, c in counts.get(email, {}).items() if ws <= b <= latest["t"])
        if n >= 200 and latest["util"] >= 10:
            ratios[email] = latest["util"] / n
    pooled = sum(ratios.values()) / len(ratios) if ratios else 0.0

    schedules = {}
    for email, rows in by_email.items():
        latest = rows[0]
        schedules[email] = latest.get("window_start") or (latest["reset"] - WEEK)

    series = {}
    for email in emails:
        rows = by_email.get(email, [])
        acct_counts = counts.get(email, {})
        first_seen = min(acct_counts) if acct_counts else (rows[0]["t"] if rows else now)
        # an account counts toward the pool from its first request (or the start of history)
        joined = since if first_seen - since < 86400 else first_seen
        reserve = live.get(email, {}).get("reserve", 0)
        drains = drain_points(email, counts, schedules, now) if rows else []
        est = (estimate(grid, acct_counts, drains, rows[0], ratios.get(email, pooled), reserve)
               if rows else None)
        vals, kinds, j = [], [], 0
        for i, t in enumerate(grid):
            if t < joined:
                vals.append(None)
                kinds.append(None)
                continue
            while j + 1 < len(rows) and rows[j + 1]["t"] <= t:
                j += 1
            if rows and rows[0]["t"] <= t:
                r = rows[j]
                # a recorded value is stale once its window has reset
                util = 0.0 if r["reset"] and t >= r["reset"] else r["util"]
                vals.append(round(100 - util, 2))
                kinds.append("rec")
            elif est is not None:
                vals.append(round(100 - est[i], 2))
                kinds.append("est")
            else:
                vals.append(None)
                kinds.append(None)
        series[email] = {"remaining": vals, "kind": kinds}

    pool, pool_kind = [], []
    for i in range(len(grid)):
        present = [s for s in series.values() if s["remaining"][i] is not None]
        pool.append(round(sum(s["remaining"][i] for s in present), 2) if present else None)
        pool_kind.append("rec" if present and all(s["kind"][i] == "rec" for s in present) else "est")

    cards = []
    for email in emails:
        rows = by_email.get(email)
        latest = rows[-1] if rows else None
        cards.append({
            "email": email,
            "reserve": live.get(email, {}).get("reserve", 0),
            "active": email in live,
            "latest": latest,
            "estimated_ratio": email not in ratios,
        })

    projection = project(now, cards, pool, grid)
    return {
        "now": now,
        "step": STEP,
        "grid": grid,
        "pool": pool,
        "pool_kind": pool_kind,
        "capacity": 100 * len([c for c in cards if c["active"]]),
        "series": series,
        "accounts": cards,
        "projection": projection,
    }


def project(now, cards, pool, grid):
    """Spend the recent burn rate account by account, soonest reset first, refilling at resets."""
    state = []
    for c in cards:
        latest = c["latest"]
        if not c["active"] or not latest or latest.get("reset") is None:
            continue
        reset = latest["reset"]
        remaining = 100.0 if now >= reset else 100 - latest["util"]
        while reset <= now:
            reset += WEEK
        state.append({"email": c["email"], "remaining": remaining, "reset": reset,
                      "floor": c["reserve"]})
    if not state:
        return None

    # burn per hour over the last 3 days: total of every drop in the pool
    window = int(3 * 86400 / STEP)
    recent = [p for p in pool[-window:] if p is not None]
    burned = sum(max(0.0, a - b) for a, b in zip(recent, recent[1:]))
    hours = max(1.0, len(recent) * STEP / 3600)
    rate = burned / hours

    times, values = [now], [sum(s["remaining"] for s in state)]
    per = {s["email"]: [s["remaining"]] for s in state}
    t = now
    end = now + 7 * 86400
    while t < end:
        t += STEP
        for s in state:
            if t >= s["reset"]:
                s["remaining"] = 100.0
                s["reset"] += WEEK
        need = rate * STEP / 3600
        for s in sorted(state, key=lambda s: s["reset"]):
            take = min(need, max(0.0, s["remaining"] - s["floor"]))
            s["remaining"] -= take
            need -= take
            if need <= 0:
                break
        times.append(t)
        values.append(round(sum(s["remaining"] for s in state), 2))
        for s in state:
            per[s["email"]].append(round(s["remaining"], 2))
    return {"t": times, "pool": values, "accounts": per, "rate_per_hour": round(rate, 3)}


REFRESH_SECONDS = 60
payload = {"json": b"", "gzip": b""}


def refresh():
    """Precompute the API response so requests never wait on journal parsing or estimation."""
    with refresh_lock:
        body = json.dumps(build(), separators=(",", ":")).encode()
        payload.update(json=body, gzip=gzip.compress(body, 6))


def refresh_forever():
    while True:
        try:
            refresh()
        except Exception as exc:
            print(f"refresh: {exc}", flush=True)
        time.sleep(REFRESH_SECONDS)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/api/threads"):
            body = json.dumps({"now": time.time(), "threads": recent_threads()}).encode()
            zipped = False
            ctype = "application/json"
        elif self.path.startswith("/api/data"):
            if not payload["json"]:
                refresh()
            zipped = "gzip" in self.headers.get("Accept-Encoding", "")
            body = payload["gzip" if zipped else "json"]
            ctype = "application/json"
        elif self.path in ("/", "/index.html"):
            body = (STATIC / "index.html").read_bytes()
            zipped = False
            ctype = "text/html; charset=utf-8"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        if zipped:
            self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def main():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    threading.Thread(target=poll_forever, daemon=True).start()
    threading.Thread(target=refresh_forever, daemon=True).start()
    print(f"claude-status on http://{HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
