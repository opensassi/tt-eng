#!/usr/bin/env python3
"""parse-tt-npe.py — Parse tt-npe CSV output to structured JSON.

Usage:
    python3 parse-tt-npe.py <tt-npe.csv> [--output metrics.json]

Reads tt-npe profiler CSV output and produces a JSON object
with key performance metrics suitable for comparison and archiving.
"""

import csv
import json
import sys
import argparse


def parse_tt_npe(csv_path: str) -> dict:
    """Parse tt-npe profiler CSV and extract performance metrics."""
    metrics = {
        "dram_bw_util_pct": None,
        "noc_util_pct": None,
        "arithmetic_intensity": None,
        "total_cycles": None,
        "total_bytes_read": None,
        "total_bytes_written": None,
        "rows": [],
    }

    with open(csv_path, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            metrics["rows"].append(row)

            # Try to extract standard columns
            for col, key in [
                ("DRAM BW UTIL", "dram_bw_util_pct"),
                ("NOC UTIL", "noc_util_pct"),
                ("Arithmetic Intensity", "arithmetic_intensity"),
                ("Total Cycles", "total_cycles"),
                ("Total Bytes Read", "total_bytes_read"),
                ("Total Bytes Written", "total_bytes_written"),
            ]:
                if col in row and row[col]:
                    try:
                        metrics[key] = float(row[col])
                    except ValueError:
                        pass

    return metrics


def main():
    parser = argparse.ArgumentParser(description="Parse tt-npe CSV to JSON")
    parser.add_argument("csv_path", help="Path to tt-npe CSV file")
    parser.add_argument("--output", "-o", default=None, help="Output JSON path")
    args = parser.parse_args()

    metrics = parse_tt_npe(args.csv_path)

    if args.output:
        with open(args.output, "w") as f:
            json.dump(metrics, f, indent=2)
        print(f"Wrote metrics to {args.output}")
    else:
        print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
