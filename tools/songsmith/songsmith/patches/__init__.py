"""Patch registry.

A *patch* is a named parameter set on one of the synthesis engines. Instruments in a
song spec refer to patches by name (``modal.handbells``, ``pluck.upright_bass`` …), and
can override any engine parameter from the spec.

Adding an instrument for a new day: write a ``register(...)`` call in the engine module
that fits (or a new ``patches/day_NNN_<name>.py`` that imports an engine), then import
the module at the bottom of this file.
"""

from __future__ import annotations

import zlib
from dataclasses import dataclass, field
from typing import Any, Callable

import numpy as np

from ..theory import midi_to_hz


@dataclass
class Patch:
    name: str
    engine: Callable[..., np.ndarray]
    defaults: dict[str, Any] = field(default_factory=dict)
    octave: int = 4  # default octave used by patterns
    tail: float = 1.0  # seconds rendered after the note ends
    kind: str = "pitched"  # pitched | perc | kit
    default_note: int = 60  # for unpitched/perc use
    pieces: dict[str, str] = field(default_factory=dict)  # kit piece → patch name
    doc: str = ""


REGISTRY: dict[str, Patch] = {}


def register(
    name: str,
    engine: Callable[..., np.ndarray],
    *,
    octave: int = 4,
    tail: float = 1.0,
    kind: str = "pitched",
    default_note: int = 60,
    pieces: dict[str, str] | None = None,
    doc: str = "",
    **defaults: Any,
) -> Patch:
    if name in REGISTRY:
        raise ValueError(f"Patch {name} registered twice")
    patch = Patch(name, engine, defaults, octave, tail, kind, default_note, pieces or {}, doc)
    REGISTRY[name] = patch
    return patch


def get(name: str) -> Patch:
    try:
        return REGISTRY[name]
    except KeyError:
        raise KeyError(f"Unknown patch {name!r}. Known: {', '.join(sorted(REGISTRY))}") from None


_CACHE: dict[str, np.ndarray] = {}


def clear_cache() -> None:
    _CACHE.clear()


def render_note(
    patch_name: str, midi: float | None, dur: float, vel: float, seed: int, overrides: dict[str, Any] | None = None
) -> np.ndarray:
    """Render one note (mono float64, includes the release tail). Results are memoised;
    the note's RNG is derived from its own parameters, so caching never changes output."""
    patch = get(patch_name)
    params = {**patch.defaults, **(overrides or {})}
    if midi is None:
        midi = patch.default_note
    key = repr((patch_name, round(float(midi), 3), round(dur, 3), round(vel, 3), sorted(params.items()), seed))
    cached = _CACHE.get(key)
    if cached is not None:
        return cached
    rng = np.random.default_rng(zlib.crc32(key.encode()))
    tail = float(params.pop("tail", patch.tail))
    audio = patch.engine(midi_to_hz(midi), dur, vel, rng, tail=tail, **params)
    audio = np.asarray(audio, dtype=np.float64)
    if len(_CACHE) < 6000:
        _CACHE[key] = audio
    return audio


# Engine modules register their patches on import.
from . import additive, bowed, brass, drums, fm, fx, modal, noise, pluck, reed, subtractive  # noqa: E402,F401
