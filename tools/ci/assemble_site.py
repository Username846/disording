#!/usr/bin/env python3
"""Assemble the GitHub Pages site after the Godot web exports.

build/site/            release build (index.html …)
build/site/preview/    debug build with dev tools (unlisted)
build/site/generated/  Songsmith audio bundles + manifest, shared by both builds

Writes build.json next to each index.html so the game can find the bundles.
Also usable before export with --build-info to write res://build_info.json.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "build" / "site"
GENERATED = ROOT / "generated"


def commit() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return "dev"


def implemented_days() -> list[int]:
    return sorted(int(p.parent.name[4:]) for p in ROOT.glob("days/day_*/game.tscn") if p.parent.name != "day_000")


def write_build_info() -> None:
    info = {"commit": commit(), "date": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d")}
    (ROOT / "build_info.json").write_text(json.dumps(info) + "\n", encoding="utf-8")
    print(f"build_info.json: {info}")


def assemble() -> None:
    if not (SITE / "index.html").exists():
        raise SystemExit("build/site/index.html missing: export the Web preset first")
    target = SITE / "generated"
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    manifest = GENERATED / "manifest.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8"))
        shutil.copy2(manifest, target / "manifest.json")
        for entry in data.get("bundles", {}).values():
            shutil.copy2(GENERATED / entry["file"], target / entry["file"])
        print(f"copied {len(data.get('bundles', {}))} audio bundle(s)")
    else:
        (target / "manifest.json").write_text('{"version": 1, "bundles": {}}\n', encoding="utf-8")
        print("warning: no generated/manifest.json; the site will run without music")
    common = {"commit": commit(), "built": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "days": implemented_days()}
    (SITE / "build.json").write_text(json.dumps({**common, "assets_base": "generated/"}, indent=1), encoding="utf-8")
    if (SITE / "preview" / "index.html").exists():
        (SITE / "preview" / "build.json").write_text(
            json.dumps({**common, "assets_base": "../generated/"}, indent=1), encoding="utf-8")
    (SITE / ".nojekyll").write_text("", encoding="utf-8")
    for stray in SITE.rglob("*.import"):
        stray.unlink()
    print(f"site assembled in {SITE}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--build-info", action="store_true", help="only write res://build_info.json")
    args = parser.parse_args()
    if args.build_info:
        write_build_info()
    else:
        assemble()
    return 0


if __name__ == "__main__":
    sys.exit(main())
