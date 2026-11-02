"""Summarise the snapshots written by mac-diag-recorder.

Called by `mac-diag-recorder --status`, which pipes in the Sleep/Wake/Start lines
of `pmset -g log` so that gaps between snapshots can be explained.
"""
from __future__ import annotations

import argparse
import gzip
import os
import re
import statistics
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

GAP = timedelta(seconds=150)      # snapshots are 60 s apart; longer than this is a gap
IN_PROGRESS = timedelta(seconds=70)
LOW_SNR = 20                      # dB
MAX_CHANGES = 10                  # most recent changes shown per category


@dataclass
class Snapshot:
    ts: datetime
    load1: float | None = None
    sections: dict[str, list[str]] = field(default_factory=dict)
    last_section: str = ""
    done_ms: int | None = None
    timeouts: list[str] = field(default_factory=list)
    source: str = ""


def read_lines(path: str) -> list[str]:
    opener = gzip.open if path.endswith(".gz") else open
    with opener(path, "rt", errors="replace") as f:
        return f.read().splitlines()


def parse(path: str) -> list[Snapshot]:
    snaps: list[Snapshot] = []
    cur: Snapshot | None = None
    for line in read_lines(path):
        if line.startswith("=== "):
            m = re.match(r"=== (\S+) load=\{ ([\d.]+)", line)
            if not m:
                continue
            cur = Snapshot(ts=datetime.strptime(m.group(1), "%Y-%m-%dT%H:%M:%S%z"),
                           load1=float(m.group(2)), source=os.path.basename(path))
            snaps.append(cur)
        elif cur is None:
            continue
        elif line.startswith("## done in "):
            cur.done_ms = int(re.sub(r"\D", "", line))
        elif line.startswith("## "):
            cur.last_section = line[3:].split(" (")[0]
            cur.sections[cur.last_section] = []
        elif line.startswith("!! "):
            cur.timeouts.append(line[3:])
        elif cur.last_section:
            cur.sections[cur.last_section].append(line)
    return snaps


def hm(ts: datetime, ref: datetime) -> str:
    return ts.strftime("%H:%M:%S" if ts.date() == ref.date() else "%a %d %b %H:%M:%S")


def duration(d: timedelta) -> str:
    s = int(d.total_seconds())
    if s < 120:
        return "%ds" % s
    if s < 7200:
        return "%dm" % (s // 60)
    return "%dh%02dm" % (s // 3600, s % 3600 // 60)


def changes(snaps: list[Snapshot], key) -> list[tuple[datetime, str]]:
    out: list[tuple[datetime, str]] = []
    for s in snaps:
        v = key(s)
        if v is None:
            continue
        if not out or out[-1][1] != v:
            out.append((s.ts, v))
    return out


def show_changes(title: str, rows: list[tuple[datetime, str]], now: datetime) -> None:
    if not rows:
        print("  %-13s no data" % title)
        return
    if len(rows) == 1:
        print("  %-13s %s (unchanged)" % (title, rows[0][1]))
        return
    print("  %-13s %d change(s)" % (title, len(rows) - 1))
    skipped = len(rows) - MAX_CHANGES
    if skipped > 0:
        print("                ... %d earlier" % skipped)
    for ts, v in rows[-MAX_CHANGES:]:
        print("                %s  %s" % (hm(ts, now), v))


# --- per-section keys -------------------------------------------------------

def route_key(s: Snapshot) -> str | None:
    lines = s.sections.get("default routes")
    if lines is None:
        return None
    routes = []
    for line in lines:
        f = line.split()
        if len(f) < 4 or f[1].startswith("fe80::%utun"):
            continue          # macOS's own utun0-3 each carry a link-local default
        routes.append("%s via %s on %s" % (f[0], f[1], f[-1]))
    return "; ".join(routes) or "none"


def dns_key(s: Snapshot) -> str | None:
    lines = s.sections.get("dns resolvers")
    if lines is None:
        return None
    for line in lines:
        if line.startswith("default"):
            return " ".join(line.split()[2:])
    return "none"


def tunnel_key(s: Snapshot) -> str | None:
    lines = s.sections.get("interfaces")
    if lines is None:
        return None
    tunnels = []
    for line in lines:
        f = line.split()
        if f and f[0].startswith("utun"):
            addrs = [a for a in f[4:] if not a.startswith("fe80")]
            if addrs:
                tunnels.append("%s %s" % (f[0], " ".join(addrs)))
    return "; ".join(tunnels) or "none"


def vpn_key(s: Snapshot) -> str | None:
    lines = s.sections.get("vpn")
    if lines is None:
        return None
    items = []
    for line in lines:
        if line.startswith("proc "):
            items.append("process " + os.path.basename(line.split(None, 2)[2]))
        else:
            m = re.search(r"\((\w+)\).*\"([^\"]+)\"", line)
            if m:
                items.append("%s %s" % (m.group(2), m.group(1).lower()))
    return "; ".join(sorted(items)) or "none"


@dataclass
class Wifi:
    ts: datetime
    rssi: int
    noise: int
    snr: int
    channel: str


def wifi_of(s: Snapshot) -> Wifi | None:
    for line in s.sections.get("wifi", []):
        m = re.search(r"rssi=(-?\d+).*noise=(-?\d+).*snr=(-?\d+).*channel=(\S+)", line)
        if m:
            return Wifi(s.ts, int(m.group(1)), int(m.group(2)), int(m.group(3)), m.group(4))
    return None


def channel_key(s: Snapshot) -> str | None:
    w = wifi_of(s)
    return "channel " + w.channel if w else None


# --- report -----------------------------------------------------------------

def power_events(lines: list[str]) -> list[tuple[datetime, str]]:
    events = []
    for line in lines:
        m = re.match(r"(\S+ \S+ [+-]\d{4}) (\w+)", line)
        if m:
            events.append((datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S %z"), m.group(2)))
    return events


def gap_cause(a: datetime, b: datetime, events: list[tuple[datetime, str]]) -> str:
    kinds = {k for ts, k in events if a < ts <= b}
    if "Start" in kinds:
        return "restart"
    if "Sleep" in kinds:
        return "sleep"
    return "UNEXPLAINED - no sleep or restart recorded; a possible freeze"


def panics(since: datetime) -> list[tuple[datetime, str]]:
    found = []
    for d in ("/Library/Logs/DiagnosticReports", os.path.expanduser("~/Library/Logs/DiagnosticReports")):
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for n in names:
            if "panic" not in n.lower():
                continue
            p = os.path.join(d, n)
            try:
                mtime = datetime.fromtimestamp(os.path.getmtime(p), timezone.utc).astimezone()
            except OSError:
                continue
            if mtime >= since:
                found.append((mtime, p))
    return sorted(found)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=float, default=1)
    ap.add_argument("--data", required=True)
    ap.add_argument("--running", type=int, default=0)
    ap.add_argument("--power", type=argparse.FileType("r"))
    args = ap.parse_args()

    now = datetime.now().astimezone()
    since = now - timedelta(days=args.days)
    events = power_events(args.power.read().splitlines()) if args.power else []

    snaps: list[Snapshot] = []
    try:
        files = sorted(f for f in os.listdir(args.data) if f.startswith("snap-"))
    except OSError:
        files = []
    for f in files:
        snaps.extend(parse(os.path.join(args.data, f)))
    snaps = sorted((s for s in snaps if s.ts >= since), key=lambda s: s.ts)

    # The snapshot being written right now has no "done" line yet; leave it out.
    if snaps and snaps[-1].done_ms is None and (args.running or now - snaps[-1].ts < IN_PROGRESS):
        snaps.pop()

    print("window         %s - now (%s)" % (hm(since, now), duration(now - since)))
    if not snaps:
        print("snapshots      none recorded in this window")
        return 0
    print("snapshots      %d, first %s, last %s (%s ago)"
          % (len(snaps), hm(snaps[0].ts, now), hm(snaps[-1].ts, now), duration(now - snaps[-1].ts)))
    if now - snaps[-1].ts > GAP:
        print("               the recorder has not written a snapshot recently - check the agent")
    print()

    # Problems first: these are what the recorder is for.
    print("problems")
    problems: list[tuple[datetime, str]] = []
    for s in snaps:
        if s.done_ms is None:
            problems.append((s.ts, "snapshot never finished; stuck at '%s'" % (s.last_section or "start")))
        for t in s.timeouts:
            problems.append((s.ts, t))
    for a, b in zip(snaps, snaps[1:]):
        # Sleep explains a gap, and a restart is reported below from the power log.
        if b.ts - a.ts > GAP and gap_cause(a.ts, b.ts, events).startswith("UNEXPLAINED"):
            problems.append((a.ts, "no snapshots for %s: %s" % (duration(b.ts - a.ts), gap_cause(a.ts, b.ts, events))))
    for ts, kind in events:
        if kind == "Start" and ts > snaps[0].ts:   # restarts before recording began are not its business
            before = [s for s in snaps if s.ts < ts]
            last = "; last snapshot before it %s" % hm(before[-1].ts, now) if before else ""
            problems.append((ts, "macOS started (restart, panic or power-on)%s" % last))
    for ts, p in panics(since):
        problems.append((ts, "panic report %s" % p))
    for ts, text in sorted(problems):
        print("  %s  %s" % (hm(ts, now), text))
    if not problems:
        print("  none")
    sleeps = sum(1 for a, b in zip(snaps, snaps[1:])
                 if b.ts - a.ts > GAP and gap_cause(a.ts, b.ts, events) == "sleep")
    if sleeps:
        print("  (%d gap(s) explained by sleep not shown)" % sleeps)
    print()

    print("load and threads")
    timed = [s.done_ms for s in snaps if s.done_ms is not None]
    if timed:
        worst = max((s for s in snaps if s.done_ms is not None), key=lambda s: s.done_ms)
        print("  snapshot time  median %d ms, slowest %d ms at %s"
              % (statistics.median(timed), worst.done_ms, hm(worst.ts, now)))
    peak = max((s for s in snaps if s.load1 is not None), key=lambda s: s.load1)
    print("  load (1 min)   median %.1f, peak %.1f at %s"
          % (statistics.median(s.load1 for s in snaps if s.load1 is not None), peak.load1, hm(peak.ts, now)))
    peaks: dict[str, tuple[int, datetime]] = {}
    latest: dict[str, int] = {}
    for s in snaps:
        for line in s.sections.get("threads", []):
            f = line.split(None, 2)
            if len(f) == 3 and f[0].isdigit():
                n, name = int(f[0]), f[2]
                if name not in peaks or n > peaks[name][0]:
                    peaks[name] = (n, s.ts)
    for line in snaps[-1].sections.get("threads", []):
        f = line.split(None, 2)
        if len(f) == 3 and f[0].isdigit():
            latest[f[2]] = max(latest.get(f[2], 0), int(f[0]))
    print("  most threads   (peak, at, latest)")
    for name, (n, ts) in sorted(peaks.items(), key=lambda kv: -kv[1][0])[:8]:
        print("    %5d  %s  %5s  %s" % (n, hm(ts, now), latest.get(name, "-"), name))
    print()

    print("network")
    show_changes("default route", changes(snaps, route_key), now)
    show_changes("dns", changes(snaps, dns_key), now)
    show_changes("tunnels", changes(snaps, tunnel_key), now)
    show_changes("vpn", changes(snaps, vpn_key), now)
    print()

    print("wifi")
    wifi = [w for w in (wifi_of(s) for s in snaps) if w]
    if not wifi:
        print("  no readings")
    else:
        snrs = [w.snr for w in wifi]
        worst_w = min(wifi, key=lambda w: w.snr)
        low = sum(1 for x in snrs if x < LOW_SNR)
        print("  snr            median %d dB, min %d dB at %s (rssi %d, noise %d, channel %s)"
              % (statistics.median(snrs), worst_w.snr, hm(worst_w.ts, now), worst_w.rssi, worst_w.noise, worst_w.channel))
        print("  below %d dB    %d of %d readings (%.0f%%)" % (LOW_SNR, low, len(snrs), 100 * low / len(snrs)))
        show_changes("channel", changes(snaps, channel_key), now)
    print()

    print("pfctl")
    seen = []
    for s in snaps:
        for line in s.sections.get("pfctl", []):
            if "running_now=no" not in line or "rule_files_changed_last_60s=none" not in line:
                seen.append((s.ts, line))
    if not seen:
        print("  not seen (sampled once a minute, so short runs can be missed)")
    for ts, line in seen[-MAX_CHANGES:]:
        print("  %s  %s" % (hm(ts, now), line))
    return 0


if __name__ == "__main__":
    sys.exit(main())
