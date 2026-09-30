#!/usr/bin/env python3
"""Read-only /proc CPU sampling. No command lines, RPC, or wallet data."""
import collections
import json
import os
from pathlib import Path
import time

NAMES = {'CheetahDEX', 'PirateWallet', 'P2Pirate', 'kdf', 'tor'}
HZ = os.sysconf('SC_CLK_TCK')
PAGE = os.sysconf('SC_PAGE_SIZE')


def snapshot():
    result = {}
    for process in Path('/proc').iterdir():
        if not process.name.isdigit():
            continue
        try:
            name = (process / 'comm').read_text().strip()
            if name not in NAMES:
                continue
            paths = [process] + list((process / 'task').iterdir())
            for path in paths:
                try:
                    fields = (path / 'stat').read_text().rsplit(')', 1)[1].split()
                    key = (process.name, path.name, path == process, fields[19])
                    result[key] = (
                        name, (path / 'comm').read_text().strip(),
                        int(fields[11]) + int(fields[12]),
                        int(fields[21]) * PAGE / 1048576,
                    )
                except (OSError, ValueError):
                    continue
        except OSError:
            continue
    return result


def main():
    samples = collections.defaultdict(list)
    previous = snapshot()
    if not previous:
        raise SystemExit('No accessible P2Pirate/KDF/Tor processes; monitoring unavailable.')
    started = time.monotonic()
    last_time = started
    current = previous
    for _ in range(6):
        time.sleep(5)
        current = snapshot()
        now = time.monotonic()
        for key in previous.keys() & current.keys():
            samples[key].append(
                (current[key][2] - previous[key][2]) / HZ / (now - last_time) * 100
            )
        previous = current
        last_time = now
    rows = []
    for key, values in samples.items():
        if key not in current:
            continue
        name, thread, _, memory = current[key]
        if not key[2] and max(values) < 1:
            continue
        rows.append({
            'process': name, 'scope': 'process' if key[2] else 'thread',
            'thread': thread if not key[2] else None,
            'cpu_samples_percent_one_core': [round(v, 1) for v in values],
            'cpu_mean': round(sum(values) / len(values), 1),
            'rss_mib': round(memory) if key[2] else None,
        })
    print(json.dumps({'duration_seconds': round(time.monotonic() - started),
                      'logical_cpus': os.cpu_count(),
                      'rows': sorted(rows, key=lambda r: -r['cpu_mean'])}))


if __name__ == '__main__':
    main()
