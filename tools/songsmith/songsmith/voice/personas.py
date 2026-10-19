"""Voice personas: parameter presets for the singer plus ensemble layout."""

from __future__ import annotations

import copy
import math
from dataclasses import fields
from typing import Any

import numpy as np

from .. import dsp
from ..theory import note_to_midi
from .singer import VoiceParams

PERSONAS: dict[str, dict[str, Any]] = {
    "warm_choir": {
        "doc": "SATB carol choir: melody + three derived harmony parts, doubled.",
        "parts": [
            {"name": "soprano", "line": "melody", "formant_scale": 1.13, "pan": -0.15, "gain_db": 0.0},
            {"name": "alto", "line": "alto", "formant_scale": 1.08, "pan": 0.25, "gain_db": -3.5, "consonant_boost": 0.5},
            {"name": "tenor", "line": "tenor", "formant_scale": 1.0, "pan": -0.3, "gain_db": -4.0, "consonant_boost": 0.5},
            {"name": "bass", "line": "bass", "formant_scale": 0.94, "pan": 0.1, "gain_db": -3.0, "consonant_boost": 0.4},
        ],
        "range": ["A3", "F5"],
        "unison": 2,
        "detune_cents": 8.0,
        "breath": 0.16,
        "tilt_hz": 3000.0,
        "vibrato_rate": 5.0,
        "vibrato_cents": 22.0,
        "portamento": 0.07,
        "reverb": 0.38,
    },
    "child_choir": {
        "doc": "Children's unison choir (scaled-up formants, little vibrato).",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.27, "pan": 0.0}],
        "range": ["C4", "A5"],
        "unison": 4,
        "detune_cents": 10.0,
        "breath": 0.18,
        "tilt_hz": 3000.0,
        "vibrato_cents": 12.0,
        "jitter": 0.006,
        "reverb": 0.3,
    },
    "female_solo": {
        "doc": "Plain solo female voice.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.15, "pan": 0.0}],
        "range": ["G3", "E5"],
        "unison": 1,
        "breath": 0.12,
        "tilt_hz": 3000.0,
        "vibrato_rate": 5.6,
        "vibrato_cents": 38.0,
        "reverb": 0.25,
    },
    "male_crooner": {
        "doc": "Warm male crooner: wide slow vibrato, scooped portamento.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 0.97, "pan": 0.0}],
        "range": ["G2", "E4"],
        "unison": 1,
        "breath": 0.1,
        "tilt_hz": 2300.0,
        "vibrato_rate": 5.0,
        "vibrato_cents": 45.0,
        "vibrato_delay": 0.35,
        "portamento": 0.1,
        "reverb": 0.3,
    },
    "robot_vocoder": {
        "doc": "Vocoder robot: saw source, pitch quantised, no vibrato.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.0, "pan": 0.0}],
        "range": ["C3", "C5"],
        "unison": 2,
        "detune_cents": 12.0,
        "saw_source": True,
        "quantize_pitch": True,
        "breath": 0.02,
        "tilt_hz": 6000.0,
        "vibrato_cents": 0.0,
        "drift_cents": 0.0,
        "jitter": 0.0,
        "shimmer": 0.0,
        "bandwidth_scale": 0.8,
        "reverb": 0.2,
    },
    "whisper": {
        "doc": "Unvoiced whisper (noise source only).",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.1, "pan": 0.0}],
        "range": ["G3", "E5"],
        "unison": 1,
        "whisper": True,
        "consonant_boost": 1.5,
        "reverb": 0.45,
    },
    # ---------------------------------------------------------------- Day 1–10 voices
    "wind_up_child_choir": {
        "doc": "Day 1: wind-up toy child choir — 6-voice unison, crisp consonants, a slow clockwork wobble and long notes that droop as the spring runs down.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.25, "pan": 0.0}],
        "range": ["C4", "A5"],
        "unison": 6,
        "detune_cents": 9.0,
        "breath": 0.14,
        "tilt_hz": 3300.0,
        "vibrato_rate": 5.8,
        "vibrato_cents": 8.0,
        "jitter": 0.005,
        "portamento": 0.05,
        "consonant_boost": 1.7,
        "wobble_rate": 3.0,
        "wobble_cents": 8.0,
        "wobble_amp": 0.12,
        "winddown_cents": 28.0,
        "reverb": 0.26,
    },
    "close_harmony_trio": {
        "doc": "Day 2: 1940s female close-harmony trio — melody plus the two chord tones just below it.",
        "parts": [
            {"name": "top", "line": "melody", "formant_scale": 1.15, "pan": 0.0},
            {"name": "middle", "line": "close1", "formant_scale": 1.12, "pan": -0.35, "gain_db": -2.5, "consonant_boost": 0.7},
            {"name": "low", "line": "close2", "formant_scale": 1.09, "pan": 0.35, "gain_db": -3.0, "consonant_boost": 0.6},
        ],
        "range": ["A3", "F5"],
        "unison": 1,
        "breath": 0.1,
        "tilt_hz": 3200.0,
        "vibrato_rate": 5.8,
        "vibrato_cents": 30.0,
        "portamento": 0.05,
        "reverb": 0.3,
    },
    "city_pop_crooner": {
        "doc": "Day 3: smooth city-pop male lead, double-tracked, light vibrato.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 0.98, "pan": 0.0}],
        "range": ["A2", "F4"],
        "unison": 2,
        "detune_cents": 6.0,
        "breath": 0.12,
        "tilt_hz": 2700.0,
        "vibrato_rate": 4.8,
        "vibrato_cents": 28.0,
        "vibrato_delay": 0.4,
        "portamento": 0.08,
        "reverb": 0.32,
    },
    "breathy_folk_female": {
        "doc": "Day 4: close-mic breathy folk solo — lots of air, small vibrato, dry.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.15, "pan": 0.0}],
        "range": ["F3", "C5"],
        "unison": 1,
        "breath": 0.32,
        "air": 0.28,
        "tilt_hz": 2600.0,
        "vibrato_rate": 5.2,
        "vibrato_cents": 18.0,
        "jitter": 0.006,
        "reverb": 0.15,
    },
    "whisper_female": {
        "doc": "Day 5: whispered female voice (noise source, female formants).",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.17, "pan": 0.0}],
        "range": ["G3", "E5"],
        "unison": 1,
        "whisper": True,
        "consonant_boost": 1.4,
        "reverb": 0.45,
    },
    "pop_female_hype": {
        "doc": "Day 6: bright double-tracked female pop lead with a male 'hype' voice an octave below.",
        "parts": [
            {"name": "lead", "line": "melody", "formant_scale": 1.16, "pan": 0.0},
            {"name": "hype", "line": "melody", "octave": -1, "formant_scale": 0.96, "pan": 0.3, "gain_db": -9.0, "consonant_boost": 1.4},
        ],
        "range": ["A3", "F5"],
        "unison": 2,
        "detune_cents": 7.0,
        "breath": 0.1,
        "tilt_hz": 3600.0,
        "vibrato_rate": 5.6,
        "vibrato_cents": 25.0,
        "reverb": 0.25,
    },
    "ring_mod_duet": {
        "doc": "Day 8: two male voices (melody + close harmony below) through ring modulators.",
        "parts": [
            {"name": "lead", "line": "melody", "formant_scale": 0.97, "pan": -0.3, "ring_mod_hz": 55.0},
            {"name": "second", "line": "close1", "formant_scale": 0.94, "pan": 0.3, "gain_db": -2.0, "ring_mod_hz": 73.0},
        ],
        "range": ["A2", "E4"],
        "unison": 1,
        "ring_mod_mix": 0.45,
        "breath": 0.08,
        "tilt_hz": 2800.0,
        "vibrato_cents": 0.0,
        "drift_cents": 2.0,
        "reverb": 0.22,
    },
    "trance_female": {
        "doc": "Day 9: ethereal trance female — airy, slow late vibrato, wide doubled, long reverb send.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.16, "pan": 0.0}],
        "range": ["C4", "A5"],
        "unison": 2,
        "detune_cents": 14.0,
        "breath": 0.16,
        "air": 0.22,
        "tilt_hz": 3400.0,
        "vibrato_rate": 4.8,
        "vibrato_cents": 26.0,
        "vibrato_delay": 0.45,
        "portamento": 0.1,
        "reverb": 0.6,
    },
    "folk_tenor": {
        "doc": "Day 10: light folk tenor, natural vibrato.",
        "parts": [{"name": "melody", "line": "melody", "formant_scale": 1.0, "pan": 0.0}],
        "range": ["C3", "A4"],
        "unison": 1,
        "breath": 0.12,
        "tilt_hz": 2700.0,
        "vibrato_rate": 5.3,
        "vibrato_cents": 30.0,
        "reverb": 0.25,
    },
}

# Aliases (same preset under the name a day's brief uses).
PERSONAS["vocoder_robot"] = {**copy.deepcopy(PERSONAS["robot_vocoder"]), "doc": "Day 7: alias of robot_vocoder."}

_PARAM_FIELDS = {f.name for f in fields(VoiceParams)}


def resolve(spec_voice: dict[str, Any]) -> dict[str, Any]:
    """Persona preset merged with the spec's ``voice:`` overrides."""
    name = spec_voice.get("persona", "female_solo")
    if name not in PERSONAS:
        raise KeyError(f"Unknown persona {name!r}. Known: {', '.join(sorted(PERSONAS))}")
    out = copy.deepcopy(PERSONAS[name])
    out["persona"] = name
    for k, v in spec_voice.items():
        if k == "vibrato" and isinstance(v, dict):
            out["vibrato_rate"] = v.get("rate", out.get("vibrato_rate", 5.4))
            out["vibrato_cents"] = v.get("depth_cents", out.get("vibrato_cents", 35.0))
            out["vibrato_delay"] = v.get("delay", out.get("vibrato_delay", 0.28))
        elif k != "persona":
            out[k] = v
    return out


def params_for(persona: dict[str, Any], part: dict[str, Any]) -> VoiceParams:
    """Singer parameters for one ensemble part. A spec-level ``formant_scale`` sets the
    lead part's scale; the other parts keep their ratio to it."""
    values = {k: v for k, v in persona.items() if k in _PARAM_FIELDS and k != "formant_scale"}
    lead = persona["parts"][0].get("formant_scale", 1.0)
    factor = persona["formant_scale"] / lead if "formant_scale" in persona else 1.0
    values["formant_scale"] = part.get("formant_scale", 1.0) * factor
    for key in ("consonant_boost", "breath", "tilt_hz"):
        if key in part:
            values[key] = part[key]
    return VoiceParams(**values)


def range_shift(persona: dict[str, Any], midis: list[int]) -> int:
    """Octave shift that centres the melody inside the persona's range."""
    if not midis:
        return 0
    lo, hi = (note_to_midi(x) if isinstance(x, str) else int(x) for x in persona.get("range", ["C3", "C6"]))
    center = (lo + hi) / 2
    median = float(np.median(midis))
    shift = 12 * round((center - median) / 12)
    return int(shift)


def ensemble(mono: np.ndarray, unison: int, detune_cents: float, pan: float, seed: int, out: np.ndarray | None = None) -> np.ndarray:
    """Spread one rendered part into a stereo unison section with chorus-style copies,
    added into ``out`` (allocated if None)."""
    if out is None:
        out = np.zeros((2, len(mono)))
    norm = 1.0 / math.sqrt(max(unison, 1))
    dsp.add_panned(out, mono, pan, norm)
    rng = np.random.default_rng(seed)
    for k in range(1, unison):
        base = 9.0 + 7.0 * k + rng.uniform(-2, 2)
        depth = 0.25 + detune_cents / 40.0
        copy_ = dsp.modulated_delay(mono, base, depth, rng.uniform(0.15, 0.45), rng.uniform(0, 2 * math.pi))
        spread = pan + (0.35 if k % 2 else -0.35) * min(1.0, k / 2)
        dsp.add_panned(out, copy_, max(-1.0, min(1.0, spread)), 0.85 * norm)
    return out
