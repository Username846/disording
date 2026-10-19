"""Song spec (YAML) → typed model. See README.md for the format."""

from __future__ import annotations

import copy
import hashlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

from . import SONGSMITH_VERSION
from .paths import PACKAGE_DIR
from .theory import Key, parse_key


@dataclass
class Instrument:
    name: str
    patch: str
    signature: bool = False
    pan: float = 0.0
    gain_db: float = 0.0
    reverb: float = 0.2  # send amount 0..1
    octave: int | None = None
    params: dict[str, Any] = field(default_factory=dict)


@dataclass
class Section:
    name: str
    bars: int
    chords: str
    parts: dict[str, dict[str, Any]]
    melody: str | None = None
    beats_per_bar: int = 4
    bpm: float | None = None  # optional per-section tempo (stingers)
    vocal_gain_db: float = 0.0


@dataclass
class SfxEvent:
    patch: str
    t: float = 0.0
    note: str | None = None
    dur: float = 0.3
    vel: float = 0.8
    params: dict[str, Any] = field(default_factory=dict)


@dataclass
class Sfx:
    name: str
    events: list[SfxEvent]
    length: float | None = None
    reverb: float = 0.12
    gain_db: float = 0.0


@dataclass
class Song:
    path: Path
    title: str
    bpm: float
    key: Key
    beats_per_bar: int
    swing: float
    seed: int
    form: list[str]
    loop_from: str | None
    loop_to: str | None
    target_minutes: float
    voice: dict[str, Any]
    instruments: dict[str, Instrument]
    sections: dict[str, Section]
    sfx: dict[str, Sfx]
    stingers: dict[str, Section]
    reverb: dict[str, Any]
    raw: dict[str, Any]

    @property
    def signature(self) -> str:
        sigs = [i.patch for i in self.instruments.values() if i.signature]
        return sigs[0] if sigs else ""


def _merge_extends(name: str, data: dict[str, Any], defs: dict[str, Any], seen: tuple[str, ...] = ()) -> dict[str, Any]:
    """Resolve ``extends:`` chains. Child keys win; ``parts`` merge per instrument
    unless the child sets ``replace_parts: true``."""
    parent_name = data["extends"]
    if parent_name in seen or parent_name == name:
        raise ValueError(f"Section inheritance loop at {name!r}")
    if parent_name not in defs:
        raise ValueError(f"Section {name!r} extends unknown section {parent_name!r}")
    parent = copy.deepcopy(defs[parent_name])
    if "extends" in parent:
        parent = _merge_extends(parent_name, parent, defs, seen + (name,))
    merged = {**parent, **{k: v for k, v in data.items() if k != "extends"}}
    if "parts" in data and "parts" in parent and data.get("replace_parts") is not True:
        merged["parts"] = {**parent["parts"], **data["parts"]}
    return merged


def _section(name: str, data: dict[str, Any], defs: dict[str, Any], bpb: int) -> Section:
    if "extends" in data:
        data = _merge_extends(name, data, defs)
    if "bars" not in data or "chords" not in data:
        raise ValueError(f"Section {name!r} needs bars and chords")
    return Section(
        name=name,
        bars=int(data["bars"]),
        chords=str(data["chords"]),
        parts=dict(data.get("parts") or {}),
        melody=data.get("melody"),
        beats_per_bar=int(data.get("beats_per_bar", bpb)),
        bpm=float(data["bpm"]) if "bpm" in data else None,
        vocal_gain_db=float(data.get("vocal_gain_db", 0.0)),
    )


def source_hash() -> str:
    """Hash of every songsmith source file, so engine changes invalidate renders."""
    digest = hashlib.sha256()
    for path in sorted(PACKAGE_DIR.rglob("*.py")):
        digest.update(path.relative_to(PACKAGE_DIR).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def spec_hash(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(Path(path).read_bytes())
    digest.update(SONGSMITH_VERSION.encode())
    digest.update(source_hash().encode())
    return digest.hexdigest()


def load_song(path: Path) -> Song:
    path = Path(path)
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError(f"{path}: spec must be a mapping")
    bpb = int(raw.get("beats_per_bar", 4))
    instruments = {}
    for name, data in (raw.get("instruments") or {}).items():
        data = dict(data)
        instruments[name] = Instrument(
            name=name,
            patch=data.pop("patch"),
            signature=bool(data.pop("signature", False)),
            pan=float(data.pop("pan", 0.0)),
            gain_db=float(data.pop("gain_db", 0.0)),
            reverb=float(data.pop("reverb", 0.2)),
            octave=data.pop("octave", None),
            params=data,
        )
    defs = raw.get("sections") or {}
    sections = {name: _section(name, data, defs, bpb) for name, data in defs.items()}
    form = list(raw.get("form") or [])
    for entry in form:
        if entry not in sections:
            raise ValueError(f"{path}: form entry {entry!r} has no section")
    stingers = {name: _section(name, data, defs, bpb) for name, data in (raw.get("stingers") or {}).items()}
    sfx = {}
    for name, data in (raw.get("sfx") or {}).items():
        events = []
        for ev in data.get("events", []):
            ev = dict(ev)
            events.append(
                SfxEvent(
                    patch=ev.pop("patch"),
                    t=float(ev.pop("t", 0.0)),
                    note=ev.pop("note", None),
                    dur=float(ev.pop("dur", 0.3)),
                    vel=float(ev.pop("vel", 0.8)),
                    params=ev,
                )
            )
        sfx[name] = Sfx(name, events, data.get("length"), float(data.get("reverb", 0.12)), float(data.get("gain_db", 0.0)))
    loop = raw.get("loop") or {}
    song = Song(
        path=path,
        title=str(raw.get("title", path.parent.name)),
        bpm=float(raw["bpm"]),
        key=parse_key(str(raw.get("key", "C major"))),
        beats_per_bar=bpb,
        swing=float(raw.get("swing", 0.0)),
        seed=int(raw.get("seed", 1)),
        form=form,
        loop_from=loop.get("from"),
        loop_to=loop.get("to"),
        target_minutes=float(raw.get("target_minutes", 4.5)),
        voice=dict(raw.get("voice") or {}),
        instruments=instruments,
        sections=sections,
        sfx=sfx,
        stingers=stingers,
        reverb=dict(raw.get("reverb") or {}),
        raw=raw,
    )
    for section in [*song.sections.values(), *song.stingers.values()]:
        for inst in section.parts:
            if inst not in instruments:
                raise ValueError(f"{path}: section {section.name!r} uses unknown instrument {inst!r}")
    return song
