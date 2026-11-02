"""Summarise the snapshots written by mac-diag-recorder.

Called by `mac-diag-recorder --status`, which pipes in the Sleep/Wake/Start lines
of `pmset -g log` so that gaps between snapshots can be explained. Reads the
snapshot, event and stall files the recorder's three LaunchAgents write.
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
STALL_PROBLEM = 2.0               # seconds; a stall this long is listed under problems
CONTEXT = timedelta(seconds=120)  # events shown before each problem
REPORT_NAMES = re.compile(r"panic|\.hang$|\.spin$|shutdownStall|stackshot|watchdog|^WindowServer|^configd", re.I)


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


@dataclass
class Event:
    ts: datetime
    kind: str
    text: str


# (kind, pattern, how to describe a match). Lines matching none are kept as "other".
EVENT_KINDS = [
    ("wifi datapath timeout", re.compile(r"Datapath timeout on (\w+)"),
     lambda m: "Wi-Fi datapath timeout on %s" % m.group(1)),
    ("wifi link", re.compile(r"Link (Up|Down) on (\w+)"),
     lambda m: "Wi-Fi link %s on %s" % (m.group(1).lower(), m.group(2))),
    ("primary interface", re.compile(r"primary (physical|wifi) interface changed: (.*)"),
     lambda m: "primary %s interface %s" % (m.group(1), m.group(2))),
    ("vpn/proxy session", re.compile(r"NESM(\w+?)Session\[[^:]*:([^:]+):.*?: status changed to (\w+)"),
     lambda m: "%s (%s) %s" % (m.group(2), m.group(1), m.group(3))),
    ("network changed", re.compile(r"network changed(?:: (.*))?"),
     lambda m: "network changed: %s" % (m.group(1) or "")),
    ("recorder", re.compile(r"-- (event stream started)"), lambda m: m.group(1)),
]
NOISY = {"wifi datapath timeout", "network changed", "other"}   # counted rather than listed


def parse_events(path: str) -> list[Event]:
    out = []
    for line in read_lines(path):
        try:
            ts = datetime.strptime(line[:23], "%Y-%m-%d %H:%M:%S.%f").astimezone()
        except ValueError:
            continue
        if "Entering state" in line:
            continue          # the "status changed" line that accompanies it says the same
        for kind, pattern, describe in EVENT_KINDS:
            m = pattern.search(line)
            if m:
                out.append(Event(ts, kind, describe(m)))
                break
        else:
            out.append(Event(ts, "other", line[24:].strip()[:120]))
    return out


def parse_stalls(path: str) -> list[tuple[datetime, float | None]]:
    """(start, seconds) per stall; seconds is None for a detector start."""
    out = []
    for line in read_lines(path):
        f = line.split()
        if len(f) < 2:
            continue
        try:
            ts = datetime.strptime(f[0], "%Y-%m-%dT%H:%M:%S.%f%z")
        except ValueError:
            continue
        if f[1] == "stall" and len(f) > 2:
            out.append((ts, float(f[2].rstrip("s"))))
        elif f[1] == "started":
            out.append((ts, None))
            m = re.search(r"last alive (\S+?)\)", line)
            if m:
                try:
                    LAST_ALIVE.append((ts, datetime.strptime(m.group(1), "%Y-%m-%dT%H:%M:%S.%f%z")))
                except ValueError:
                    pass
    return out


# (detector start, when the previous run was last alive), filled in by parse_stalls
LAST_ALIVE: list[tuple[datetime, datetime]] = []


def near_power_event(ts: datetime, power: list[tuple[datetime, str]], secs: float) -> bool:
    """Whether a stall overlaps sleep, wake or boot: processes are suspended then."""
    return any(kind in ("Sleep", "Wake", "DarkWake", "Start")
               and ts - timedelta(seconds=10) <= p <= ts + timedelta(seconds=secs + 10)
               for p, kind in power)


def context(events: list[Event], ts: datetime) -> list[str]:
    """The events in the CONTEXT before ts (and up to 10 s after), noisy kinds counted."""
    near = [e for e in events if ts - CONTEXT <= e.ts <= ts + timedelta(seconds=10)]
    lines, counts = [], {}
    for e in near:
        if e.kind in NOISY:
            counts[e.kind] = counts.get(e.kind, 0) + 1
        else:
            lines.append("%s %s" % (e.ts.strftime("%H:%M:%S"), e.text))
    lines += ["%d x %s" % (n, k) for k, n in sorted(counts.items())]
    return lines


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


def extensions_key(s: Snapshot) -> str | None:
    lines = s.sections.get("network extensions")
    if lines is None:
        return None
    return "; ".join(sorted(set(re.sub(r" \(.*?\)", "", l) for l in lines))) or "none"


def thermal_key(s: Snapshot) -> str | None:
    lines = s.sections.get("thermal")
    if lines is None:
        return None
    warnings = [l.strip() for l in lines if not l.startswith("No ")]
    return "; ".join(warnings) or "no warnings"


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


def reports(since: datetime) -> list[tuple[datetime, str]]:
    """Panic, hang, spin, shutdown-stall and watchdog reports written in the window."""
    found = []
    for d in ("/Library/Logs/DiagnosticReports", os.path.expanduser("~/Library/Logs/DiagnosticReports")):
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for n in names:
            if not REPORT_NAMES.search(n):
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

    try:
        files = sorted(os.listdir(args.data))
    except OSError:
        files = []
    snaps: list[Snapshot] = []
    log_events: list[Event] = []
    stalls: list[tuple[datetime, float | None]] = []
    for f in files:
        path = os.path.join(args.data, f)
        if f.startswith("snap-"):
            snaps.extend(parse(path))
        elif f.startswith("events-"):
            log_events.extend(parse_events(path))
        elif f.startswith("stalls-"):
            stalls.extend(parse_stalls(path))
    snaps = sorted((s for s in snaps if s.ts >= since), key=lambda s: s.ts)
    log_events = sorted((e for e in log_events if e.ts >= since), key=lambda e: e.ts)
    stalls = sorted(st for st in stalls if st[0] >= since)

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
            alive = [a for started, a in LAST_ALIVE if started >= ts and a < ts]
            if alive:
                last += "; stall detector last alive %s, so whatever stopped the Mac began after that" % hm(alive[0], now)
            problems.append((ts, "macOS started (restart, panic or power-on)%s" % last))
    for ts, p in reports(snaps[0].ts):   # reports from before recording began are not its business
        name = os.path.basename(p).lower()
        kind = next((label for key, label in (("panic", "panic"), ("shutdown", "shutdown stall"),
                                              (".hang", "hang"), (".spin", "spin"), ("watchdog", "watchdog"))
                     if key in name), "diagnostic")
        problems.append((ts, "%s report %s" % (kind, p)))
    for ts, secs in stalls:
        if secs is not None and secs >= STALL_PROBLEM and not near_power_event(ts, events, secs):
            problems.append((ts, "stall of %.1fs - the stall detector could not run" % secs))
    for ts, text in sorted(problems):
        print("  %s  %s" % (hm(ts, now), text))
        for line in context(log_events, ts):
            print("              %s" % line)
    if not problems:
        print("  none")
    sleeps = sum(1 for a, b in zip(snaps, snaps[1:])
                 if b.ts - a.ts > GAP and gap_cause(a.ts, b.ts, events) == "sleep")
    if sleeps:
        print("  (%d gap(s) explained by sleep not shown)" % sleeps)
    print()

    print("load, threads, cpu, memory")
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

    cpu_peaks: dict[str, tuple[float, datetime]] = {}
    for s in snaps:
        for line in s.sections.get("cpu", []):
            f = line.split(None, 2)
            try:
                pct, name = float(f[0]), f[2]
            except (ValueError, IndexError):
                continue
            if name not in cpu_peaks or pct > cpu_peaks[name][0]:
                cpu_peaks[name] = (pct, s.ts)
    if cpu_peaks:
        print("  most cpu       (peak % of one core, at)")
        for name, (pct, ts) in sorted(cpu_peaks.items(), key=lambda kv: -kv[1][0])[:6]:
            print("    %5.0f  %s  %s" % (pct, hm(ts, now), name))
    mem = []
    for s in snaps:
        for line in s.sections.get("memory", []):
            m = re.search(r"free=(\d+)%.*pressure=(\w+).*swap_used=([\d.]+)M.*compressor=(\d+)M", line)
            if m:
                mem.append((s.ts, int(m.group(1)), m.group(2), float(m.group(3)), int(m.group(4))))
    if mem:
        low = min(mem, key=lambda r: r[1])
        pressured = [r for r in mem if r[2] != "normal"]
        print("  memory         lowest free %d%% at %s, most swap %.0fM, most compressed %dM, pressure above normal in %d snapshot(s)"
              % (low[1], hm(low[0], now), max(r[3] for r in mem), max(r[4] for r in mem), len(pressured)))
    show_changes("thermal", changes(snaps, thermal_key), now)
    print()

    print("stalls (the detector wakes 4 times a second; listed when it could not run for >0.5s)")
    if not stalls:
        print("  no stall data - is %s loaded?" % "com.cage433.mac-diag-stalls")
    else:
        durations = [d for _, d in stalls if d is not None]
        starts = sum(1 for _, d in stalls if d is None)
        if not durations:
            print("  none")
        else:
            buckets = [(0.5, 1), (1, 2), (2, 5), (5, float("inf"))]
            counts = ["%s: %d" % (("%g-%gs" % (a, b)) if b != float("inf") else ">%gs" % a,
                                  sum(1 for d in durations if a <= d < b)) for a, b in buckets]
            longest = max((st for st in stalls if st[1] is not None), key=lambda st: st[1])
            print("  %d stall(s); %s" % (len(durations), ", ".join(counts)))
            asleep = sum(1 for ts, d in stalls if d is not None and near_power_event(ts, events, d))
            if asleep:
                print("  %d of them at sleep, wake or boot, so not listed as problems" % asleep)
            print("  longest        %.2fs at %s" % (longest[1], hm(longest[0], now)))
        if starts > 1:
            print("  the detector started %d times in this window (restarts, or launchd relaunching it)" % starts)
    print()

    print("events")
    if not log_events:
        print("  no event data - is com.cage433.mac-diag-events loaded?")
    else:
        kinds: dict[str, int] = {}
        for e in log_events:
            kinds[e.kind] = kinds.get(e.kind, 0) + 1
        print("  " + ", ".join("%s: %d" % kv for kv in sorted(kinds.items())))
        timeouts = [e.ts for e in log_events if e.kind == "wifi datapath timeout"]
        if timeouts:
            per_hour: dict[datetime, int] = {}
            for ts in timeouts:
                h = ts.replace(minute=0, second=0, microsecond=0)
                per_hour[h] = per_hour.get(h, 0) + 1
            busiest = max(per_hour.items(), key=lambda kv: kv[1])
            print("  Wi-Fi datapath timeouts: busiest hour %s with %d" % (hm(busiest[0], now)[:-3], busiest[1]))
        notable = [e for e in log_events if e.kind not in NOISY]
        if notable:
            print("  recent         (interface, link and VPN/proxy session changes)")
            for e in notable[-MAX_CHANGES:]:
                print("    %s  %s" % (hm(e.ts, now), e.text))
    print()

    print("network")
    show_changes("default route", changes(snaps, route_key), now)
    show_changes("dns", changes(snaps, dns_key), now)
    show_changes("tunnels", changes(snaps, tunnel_key), now)
    show_changes("vpn", changes(snaps, vpn_key), now)
    show_changes("extensions", changes(snaps, extensions_key), now)
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
