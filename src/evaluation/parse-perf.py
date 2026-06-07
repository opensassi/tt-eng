#!/usr/bin/env python3
"""parse-perf.py — Parse perf stat output to structured JSON.

Usage:
    python3 parse-perf.py <perf.stat> [--output metrics.json]

Reads perf stat text output and extracts hardware counter values
into a structured JSON object suitable for comparison and archiving.
"""

import re
import json
import argparse


def parse_perf_stat(stat_path: str) -> dict:
    """Parse perf stat output and extract hardware counter values."""
    counters = {}

    # Patterns for perf stat output
    patterns = [
        (r"([\d,]+)\s+cycles", "cycles"),
        (r"([\d,]+)\s+instructions", "instructions"),
        (r"([\d,]+)\s+cache-misses", "cache_misses"),
        (r"([\d,]+)\s+cache-references", "cache_references"),
        (r"([\d,]+)\s+branch-misses", "branch_misses"),
        (r"([\d,]+)\s+branches", "branches"),
        (r"([\d,]+)\s+page-faults", "page_faults"),
        (r"([\d,]+)\s+context-switches", "context_switches"),
        (r"([\d,]+)\s+cpu-migrations", "cpu_migrations"),
        (r"([\d,]+)\s+stalled-cycles-frontend", "stalled_cycles_frontend"),
        (r"([\d,]+)\s+stalled-cycles-backend", "stalled_cycles_backend"),
        (r"([\d,]+)\s+L1-dcache-load-misses", "l1_dcache_load_misses"),
        (r"([\d,]+)\s+L1-dcache-loads", "l1_dcache_loads"),
        (r"([\d,]+)\s+LLC-load-misses", "llc_load_misses"),
        (r"([\d,]+)\s+LLC-loads", "llc_loads"),
        (r"([\d,]+)\s+seconds time elapsed", "wall_time_sec"),
    ]

    with open(stat_path, "r") as f:
        content = f.read()

    for pattern, key in patterns:
        match = re.search(pattern, content)
        if match:
            val = match.group(1).replace(",", "")
            try:
                counters[key] = float(val)
            except ValueError:
                counters[key] = val

    # Derived metrics
    if "instructions" in counters and "cycles" in counters and counters["cycles"] > 0:
        counters["ipc"] = round(counters["instructions"] / counters["cycles"], 2)

    if "branches" in counters and "branch_misses" in counters and counters["branches"] > 0:
        counters["branch_miss_rate"] = round(
            counters["branch_misses"] / counters["branches"], 4
        )

    return counters


def main():
    parser = argparse.ArgumentParser(description="Parse perf stat output to JSON")
    parser.add_argument("stat_path", help="Path to perf stat file")
    parser.add_argument("--output", "-o", default=None, help="Output JSON path")
    args = parser.parse_args()

    counters = parse_perf_stat(args.stat_path)

    if args.output:
        with open(args.output, "w") as f:
            json.dump(counters, f, indent=2)
        print(f"Wrote metrics to {args.output}")
    else:
        print(json.dumps(counters, indent=2))


if __name__ == "__main__":
    main()
