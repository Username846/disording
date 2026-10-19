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


# Godot's PWA service worker serves the cached build first and only switches to a new deploy once
# every tab of the site has closed, so a plain reload kept players on a stale build. These edits make
# a new deploy's worker fetch fresh files and take over at once (the game then reloads into it from
# the title or calendar), and keep the unlisted /preview/ build, which sits inside its scope, uncached.
SW_PATCHES = [
    (
        "event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));",
        "event.waitUntil(caches.open(CACHE_NAME)"
        ".then((cache) => cache.addAll(CACHED_FILES.map((f) => new Request(f, { cache: 'no-cache' }))))"
        ".then(() => self.skipWaiting()));",
    ),
    (
        "response = await self.fetch(event.request);",
        "response = await self.fetch(event.request, { cache: 'no-cache' });",
    ),
    (
        "const isNavigate = event.request.mode === 'navigate';",
        "if (new URL(event.request.url).pathname.includes('/preview/')) {\n"
        "\t\t\treturn;\n"
        "\t\t}\n"
        "\t\tconst isNavigate = event.request.mode === 'navigate';",
    ),
]


def patch_service_worker() -> None:
    worker = SITE / "index.service.worker.js"
    if not worker.exists():
        return
    text = worker.read_text(encoding="utf-8")
    if "self.skipWaiting()));" in text:
        return
    for old, new in SW_PATCHES:
        if text.count(old) != 1:
            raise SystemExit(f"service worker patch no longer applies (Godot template changed?): {old}")
        text = text.replace(old, new)
    worker.write_text(text, encoding="utf-8")
    print("patched index.service.worker.js (fresh fetches, skip waiting, /preview/ uncached)")


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
    patch_service_worker()
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
