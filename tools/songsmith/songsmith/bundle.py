"""Write per-song bundles (zip) and the generated/manifest.json index."""

from __future__ import annotations

import hashlib
import io
import json
import zipfile
from pathlib import Path
from typing import Any

from . import SAMPLE_RATE, SONGSMITH_VERSION, ogg
from .render import Rendered
from .spec import Song

MUSIC_QUALITY = 0.8  # libsndfile compression_level for music (≈ 85 kbps stereo)
SFX_QUALITY = 0.5
_ZIP_DATE = (1980, 1, 1, 0, 0, 0)


def _json(data: Any) -> bytes:
    return json.dumps(data, indent=1, sort_keys=False, ensure_ascii=False).encode("utf-8")


def _add(zf: zipfile.ZipFile, name: str, data: bytes, stored: bool) -> None:
    info = zipfile.ZipInfo(name, _ZIP_DATE)
    info.compress_type = zipfile.ZIP_STORED if stored else zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    zf.writestr(info, data)


def build_bundle(song: Song, bundle_id: str, rendered: Rendered, spec_hash: str) -> tuple[bytes, dict[str, Any]]:
    meta = {
        "id": bundle_id,
        "title": song.title,
        "bpm": song.bpm,
        "beats_per_bar": song.beats_per_bar,
        "sample_rate": SAMPLE_RATE,
        "duration": round(rendered.music.shape[1] / SAMPLE_RATE, 4),
        "loop_start": round(rendered.loop_start, 4),
        "loop_end": round(rendered.loop_end, 4),
        "signature": song.signature,
        "voice": rendered.persona,
        "sfx": sorted(rendered.sfx),
        "stingers": sorted(rendered.stingers),
        "songsmith_version": SONGSMITH_VERSION,
        "spec_hash": spec_hash,
        "target_minutes": song.target_minutes,
        "lufs": round(rendered.lufs, 2),
        "true_peak_db": round(rendered.true_peak, 2),
        "vocal_db_by_section": rendered.voice_by_section,
    }
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w") as zf:
        _add(zf, "meta.json", _json(meta), stored=False)
        _add(zf, "music.ogg", ogg.encode(rendered.music, MUSIC_QUALITY), stored=True)
        for name in sorted(rendered.stingers):
            _add(zf, f"{name}.ogg", ogg.encode(rendered.stingers[name], MUSIC_QUALITY), stored=True)
        for name in sorted(rendered.sfx):
            _add(zf, f"sfx/{name}.ogg", ogg.encode(rendered.sfx[name], SFX_QUALITY), stored=True)
        _add(zf, "lyrics.json", _json({"lines": rendered.lyrics}), stored=False)
        _add(zf, "beats.json", _json(rendered.beats), stored=False)
    return out.getvalue(), meta


def manifest_path(out_dir: Path) -> Path:
    return out_dir / "manifest.json"


def load_manifest(out_dir: Path) -> dict[str, Any]:
    path = manifest_path(out_dir)
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"version": 1, "bundles": {}}


def write_bundle(out_dir: Path, bundle_id: str, data: bytes, spec_hash: str) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / ".gdignore").touch()
    digest = hashlib.sha256(data).hexdigest()
    name = f"{bundle_id}.{digest[:8]}.bundle.zip"
    for old in out_dir.glob(f"{bundle_id}.*.bundle.zip"):
        if old.name != name:
            old.unlink()
    (out_dir / name).write_bytes(data)
    manifest = load_manifest(out_dir)
    entry = {"file": name, "bytes": len(data), "sha256": digest, "spec_hash": spec_hash}
    manifest.setdefault("bundles", {})[bundle_id] = entry
    manifest["version"] = 1
    manifest["bundles"] = dict(sorted(manifest["bundles"].items()))
    manifest_path(out_dir).write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    return entry


def read_bundle(out_dir: Path, bundle_id: str) -> tuple[zipfile.ZipFile, dict[str, Any]] | None:
    entry = load_manifest(out_dir).get("bundles", {}).get(bundle_id)
    if not entry:
        return None
    path = out_dir / entry["file"]
    if not path.exists():
        return None
    return zipfile.ZipFile(path), entry
