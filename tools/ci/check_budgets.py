#!/usr/bin/env python3
"""Fail the deploy when the site breaks the size budgets in PLAN.md §2."""
from __future__ import annotations

import gzip
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "build" / "site"
MB = 1_000_000

BUDGETS = {
    "main_pck": 12 * MB,  # index.pck: all code + art for 100 days
    "wasm_gzip": 11 * MB,  # engine, as typically served compressed
    "first_load": 20 * MB,  # wasm(gz) + pck(gz) + js(gz) + menu bundle
    "bundle": int(3.5 * 1024 * 1024),  # each day's audio bundle (matches songsmith check)
}


def gz_size(path: Path) -> int:
    return len(gzip.compress(path.read_bytes(), compresslevel=6))


def main() -> int:
    problems = []
    report = {}
    pck = SITE / "index.pck"
    wasm = SITE / "index.wasm"
    js = SITE / "index.js"
    for p in (pck, wasm, js):
        if not p.exists():
            print(f"missing {p}")
            return 1
    report["main_pck"] = pck.stat().st_size
    report["wasm_gzip"] = gz_size(wasm)
    manifest_path = SITE / "generated" / "manifest.json"
    bundles = json.loads(manifest_path.read_text())["bundles"] if manifest_path.exists() else {}
    menu = bundles.get("menu", {}).get("bytes", 0)
    report["first_load"] = report["wasm_gzip"] + gz_size(pck) + gz_size(js) + menu
    for name, entry in sorted(bundles.items()):
        report[f"bundle:{name}"] = entry["bytes"]
        if entry["bytes"] > BUDGETS["bundle"]:
            problems.append(f"bundle {name} is {entry['bytes'] / MB:.2f} MB")
    for key in ("main_pck", "wasm_gzip", "first_load"):
        if report[key] > BUDGETS[key]:
            problems.append(f"{key} is {report[key] / MB:.2f} MB (budget {BUDGETS[key] / MB:.2f} MB)")
    width = max(len(k) for k in report)
    for key, value in report.items():
        print(f"{key:<{width}}  {value / MB:7.2f} MB")
    if problems:
        print("\nBudget exceeded:\n- " + "\n- ".join(problems))
        return 1
    print("\nAll size budgets met.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
