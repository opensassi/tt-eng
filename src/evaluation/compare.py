#!/usr/bin/env python3
"""compare.py — Side-by-side experiment comparison.

Usage:
    python3 compare.py <baseline-dir> <candidate-dir> [--output comparison.json]

Reads two experiment directories containing metrics.json files,
computes deltas between all shared numeric fields, and produces
a structured comparison JSON with regression flags.
"""

import json
import os
import sys
import argparse


def load_metrics(experiment_dir: str) -> dict:
    """Load metrics.json from an experiment directory."""
    path = os.path.join(experiment_dir, "metrics.json")
    if not os.path.exists(path):
        print(f"Warning: metrics.json not found in {experiment_dir}", file=sys.stderr)
        return {}
    with open(path, "r") as f:
        return json.load(f)


def flatten_dict(d: dict, parent_key: str = "") -> dict:
    """Flatten nested dict into dot-separated key: value pairs."""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}.{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key).items())
        elif isinstance(v, (int, float)):
            items.append((new_key, v))
    return dict(items)


def compute_deltas(baseline: dict, candidate: dict) -> dict:
    """Compute deltas between two flattened metric dicts."""
    b_flat = flatten_dict(baseline)
    c_flat = flatten_dict(candidate)

    deltas = {}
    for key in set(list(b_flat.keys()) + list(c_flat.keys())):
        b_val = b_flat.get(key)
        c_val = c_flat.get(key)

        if b_val is None and c_val is None:
            continue

        entry = {
            "baseline": b_val,
            "candidate": c_val,
            "delta_pct": None,
        }

        if b_val is not None and c_val is not None and b_val != 0:
            entry["delta_pct"] = round((c_val - b_val) / abs(b_val) * 100, 2)
        elif b_val is None:
            entry["delta_pct"] = None  # new metric
        elif c_val is None:
            entry["delta_pct"] = None  # removed metric

        deltas[key] = entry

    return deltas


def check_regression(deltas: dict, thresholds: dict = None) -> tuple:
    """Check if any delta exceeds regression thresholds.

    Returns (is_regression: bool, regressions: list).
    """
    if thresholds is None:
        thresholds = {
            "wall_time_ms": 2.0,
            "benchmark.noc_util_pct": 5.0,
            "benchmark.dram_bw_util_pct": 5.0,
        }

    regressions = []
    for key, delta in deltas.items():
        if delta["delta_pct"] is None:
            continue
        threshold = None
        for t_key, t_val in thresholds.items():
            if t_key in key:
                threshold = t_val
                break
        if threshold is not None and delta["delta_pct"] > threshold:
            regressions.append({
                "metric": key,
                "delta_pct": delta["delta_pct"],
                "threshold": threshold,
            })

    return len(regressions) > 0, regressions


def main():
    parser = argparse.ArgumentParser(
        description="Compare two experiment directories"
    )
    parser.add_argument("baseline", help="Baseline experiment directory")
    parser.add_argument("candidate", help="Candidate experiment directory")
    parser.add_argument("--output", "-o", default=None, help="Output JSON path")
    args = parser.parse_args()

    baseline = load_metrics(args.baseline)
    candidate = load_metrics(args.candidate)
    deltas = compute_deltas(baseline, candidate)
    is_regression, regressions = check_regression(deltas)

    comparison = {
        "baseline": args.baseline,
        "candidate": args.candidate,
        "deltas": deltas,
        "regression": is_regression,
        "regressions_detail": regressions,
    }

    if args.output:
        with open(args.output, "w") as f:
            json.dump(comparison, f, indent=2)
        print(f"Wrote comparison to {args.output}")
    else:
        print(json.dumps(comparison, indent=2))

    if is_regression:
        print(f"\nREGRESSION DETECTED: {len(regressions)} metric(s) exceeded threshold",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
