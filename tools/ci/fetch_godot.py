#!/usr/bin/env python3
"""Fetch the pinned Godot editor binary and the web export templates.

The official export-template archive is ~1.3 GB, but the web build only needs a few
small files from it. This script reads the archive's central directory with HTTP
range requests and downloads just the entries it needs.

Usage: python tools/ci/fetch_godot.py [--dest DIR] [--templates-only]
"""
from __future__ import annotations

import argparse
import io
import os
import stat
import struct
import sys
import urllib.request
import zipfile
import zlib
from pathlib import Path

VERSION = "4.7.2"
FLAVOR = "stable"
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}-{FLAVOR}"
EDITOR_ZIP = f"Godot_v{VERSION}-{FLAVOR}_linux.x86_64.zip"
TEMPLATES_TPZ = f"Godot_v{VERSION}-{FLAVOR}_export_templates.tpz"
WANTED_TEMPLATES = ("web_nothreads_release.zip", "web_nothreads_debug.zip", "version.txt")


def _get(url: str, start: int | None = None, end: int | None = None) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "disording-ci"})
    if start is not None:
        req.add_header("Range", f"bytes={start}-{'' if end is None else end}")
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read()


def _size(url: str) -> int:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "disording-ci"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return int(resp.headers["Content-Length"])


def _central_directory(url: str, total: int) -> list[tuple[str, int, int, int, int]]:
    """Return (name, method, compressed_size, uncompressed_size, local_header_offset)."""
    tail_len = min(total, 128 * 1024)
    tail = _get(url, total - tail_len)
    eocd = tail.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise RuntimeError("End of central directory not found")
    cd_size, cd_offset = struct.unpack("<II", tail[eocd + 12 : eocd + 20])
    loc64 = tail.rfind(b"PK\x06\x07", 0, eocd)
    if loc64 >= 0:  # ZIP64
        (eocd64_offset,) = struct.unpack("<Q", tail[loc64 + 8 : loc64 + 16])
        eocd64 = _get(url, eocd64_offset, eocd64_offset + 56 - 1)
        cd_size, cd_offset = struct.unpack("<QQ", eocd64[40:56])
    cd = _get(url, cd_offset, cd_offset + cd_size - 1)
    entries = []
    pos = 0
    while pos < len(cd) and cd[pos : pos + 4] == b"PK\x01\x02":
        method = struct.unpack("<H", cd[pos + 10 : pos + 12])[0]
        csize, usize = struct.unpack("<II", cd[pos + 20 : pos + 28])
        nlen, xlen, clen = struct.unpack("<HHH", cd[pos + 28 : pos + 34])
        (offset,) = struct.unpack("<I", cd[pos + 42 : pos + 46])
        name = cd[pos + 46 : pos + 46 + nlen].decode("utf-8")
        extra = cd[pos + 46 + nlen : pos + 46 + nlen + xlen]
        # ZIP64 extended information extra field.
        epos = 0
        while epos + 4 <= len(extra):
            tag, size = struct.unpack("<HH", extra[epos : epos + 4])
            if tag == 0x0001:
                vals = list(struct.unpack("<" + "Q" * (size // 8), extra[epos + 4 : epos + 4 + size]))
                if usize == 0xFFFFFFFF:
                    usize = vals.pop(0)
                if csize == 0xFFFFFFFF:
                    csize = vals.pop(0)
                if offset == 0xFFFFFFFF:
                    offset = vals.pop(0)
            epos += 4 + size
        entries.append((name, method, csize, usize, offset))
        pos += 46 + nlen + xlen + clen
    return entries


def _extract_remote(url: str, entry: tuple[str, int, int, int, int]) -> bytes:
    name, method, csize, usize, offset = entry
    header = _get(url, offset, offset + 30 - 1)
    nlen, xlen = struct.unpack("<HH", header[26:30])
    data_start = offset + 30 + nlen + xlen
    raw = _get(url, data_start, data_start + csize - 1)
    if method == 0:
        data = raw
    elif method == 8:
        data = zlib.decompress(raw, -15)
    else:
        raise RuntimeError(f"Unsupported compression method {method} for {name}")
    if len(data) != usize:
        raise RuntimeError(f"Size mismatch for {name}")
    return data


def fetch_templates(dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    if all((dest / n).exists() for n in WANTED_TEMPLATES):
        print(f"templates already present in {dest}")
        return
    url = f"{BASE}/{TEMPLATES_TPZ}"
    entries = _central_directory(url, _size(url))
    for entry in entries:
        base = entry[0].rsplit("/", 1)[-1]
        if base in WANTED_TEMPLATES:
            print(f"fetching {entry[0]} ({entry[2] / 1e6:.1f} MB)")
            (dest / base).write_bytes(_extract_remote(url, entry))
    missing = [n for n in WANTED_TEMPLATES if not (dest / n).exists()]
    if missing:
        raise SystemExit(f"missing templates: {missing}")


def fetch_editor(dest: Path) -> Path:
    dest.mkdir(parents=True, exist_ok=True)
    binary = dest / "godot"
    if binary.exists():
        print(f"editor already present: {binary}")
        return binary
    print(f"fetching {EDITOR_ZIP}")
    with zipfile.ZipFile(io.BytesIO(_get(f"{BASE}/{EDITOR_ZIP}"))) as zf:
        member = next(n for n in zf.namelist() if n.endswith("linux.x86_64"))
        binary.write_bytes(zf.read(member))
    binary.chmod(binary.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return binary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dest", default=os.path.expanduser("~/.local/bin"), help="editor install dir")
    parser.add_argument("--templates-only", action="store_true")
    parser.add_argument("--editor-only", action="store_true")
    args = parser.parse_args()
    templates_dir = Path(os.path.expanduser(f"~/.local/share/godot/export_templates/{VERSION}.{FLAVOR}"))
    if not args.templates_only:
        print(fetch_editor(Path(args.dest)))
    if not args.editor_only:
        fetch_templates(templates_dir)
        print(templates_dir)


if __name__ == "__main__":
    sys.exit(main())
