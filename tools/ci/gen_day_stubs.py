#!/usr/bin/env python3
"""Generate days/day_NNN/info.tres stubs for all 100 days from docs/GAMES.md.

A day that already has its game.tscn owns its info.tres, so it is left alone
(unless --force). Run after editing a brief's title, genre, pitch or target.
"""
from __future__ import annotations

import argparse
import colorsys
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAMES = ROOT / "docs" / "GAMES.md"

TEMPLATE = """[gd_resource type="Resource" script_class="DayInfo" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/day/day_info.gd" id="1_info"]

[resource]
script = ExtResource("1_info")
day = {day}
title = {title}
genre = {genre}
pitch = {pitch}
hints = PackedStringArray()
est_minutes = {minutes}
scene_path = "res://days/day_{day:03d}/game.tscn"
bundle_id = "day_{day:03d}"
palette = PackedColorArray({palette})
"""


def godot_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def palette_for(day: int) -> str:
    hue = (day * 0.618033988749895) % 1.0
    colors = [
        colorsys.hsv_to_rgb(hue, 0.55, 0.85),
        colorsys.hsv_to_rgb((hue + 0.5) % 1.0, 0.25, 0.98),
        colorsys.hsv_to_rgb(hue, 0.6, 0.3),
    ]
    return ", ".join(f"{r:.4f}, {g:.4f}, {b:.4f}, 1" for r, g, b in colors)


def first_sentences(text: str, limit: int = 220) -> str:
    sentences = re.split(r"(?<=[.!?])\s+", text.strip())
    out = ""
    for s in sentences:
        if out and len(out) + len(s) + 1 > limit:
            break
        out = f"{out} {s}".strip()
    return out


def parse_games() -> list[dict]:
    text = GAMES.read_text(encoding="utf-8")
    blocks = re.split(r"^### Day ", text, flags=re.M)[1:]
    days = []
    for block in blocks:
        head = re.match(r"(\d+): (.+)", block)
        genre = re.search(r"\*\*Rare genre:\*\* (.+?) · \*\*Target", block)
        target = re.search(r"\*\*Target:\*\* ~(\d+) min", block)
        pitch = re.search(r"- \*\*Pitch:\*\* (.+?)(?=\n- \*\*)", block, re.S)
        if not (head and genre and target and pitch):
            raise SystemExit(f"Could not parse brief: {block[:60]!r}")
        days.append(
            {
                "day": int(head.group(1)),
                "title": head.group(2).strip(),
                "genre": genre.group(1).strip(),
                "minutes": int(target.group(1)),
                "pitch": first_sentences(" ".join(pitch.group(1).replace("*", "").split())),
            }
        )
    return days


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="also rewrite implemented days")
    args = parser.parse_args()
    days = parse_games()
    if [d["day"] for d in days] != list(range(1, 101)):
        raise SystemExit("docs/GAMES.md must list days 1..100 in order")
    written = 0
    for d in days:
        folder = ROOT / "days" / f"day_{d['day']:03d}"
        if (folder / "game.tscn").exists() and not args.force:
            continue
        folder.mkdir(parents=True, exist_ok=True)
        content = TEMPLATE.format(
            day=d["day"],
            title=godot_string(d["title"]),
            genre=godot_string(d["genre"]),
            pitch=godot_string(d["pitch"]),
            minutes=d["minutes"],
            palette=palette_for(d["day"]),
        )
        path = folder / "info.tres"
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            path.write_text(content, encoding="utf-8")
            written += 1
    print(f"{written} info.tres file(s) written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
