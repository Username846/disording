"""Additive synthesis: drawbar organs, harmonic pads."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def additive(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.3,
    harmonics: list[float] = (0.5, 1.0, 1.5, 2.0, 3.0, 4.0),
    levels: list[float] = (0.6, 1.0, 0.4, 0.5, 0.3, 0.2),
    aenv: tuple[float, float, float, float] = (0.01, 0.1, 1.0, 0.08),
    leslie_hz: float = 0.0,
    leslie_depth: float = 0.0,
    detune_cents: float = 0.0,
    click: float = 0.0,
) -> np.ndarray:
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for h, lv in zip(harmonics, levels):
        f = freq * h * 2 ** (rng.uniform(-1, 1) * detune_cents / 1200)
        if f >= SR * 0.45 or lv <= 0:
            continue
        out += lv * np.sin(2 * math.pi * f * t + rng.uniform(0, 2 * math.pi))
    out /= max(1.0, sum(levels))
    if leslie_hz > 0:
        lfo = np.sin(2 * math.pi * leslie_hz * t)
        out = dsp.modulated_delay(out, 1.5, 0.6 * leslie_depth, leslie_hz) * (1 + 0.3 * leslie_depth * lfo)
    if click > 0:
        m = dsp.samples(0.004)
        out[:m] += click * rng.standard_normal(m) * np.linspace(1, 0, m)
    out *= dsp.adsr(n, *aenv[:3], aenv[3], gate) * vel
    return dsp.fade_tail(out, 0.02)


register(
    "add.organ",
    additive,
    octave=4,
    tail=0.15,
    harmonics=[0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0],
    levels=[0.8, 1.0, 0.6, 0.6, 0.0, 0.3, 0.0, 0.0, 0.2],
    leslie_hz=6.2,
    leslie_depth=0.6,
    click=0.15,
)
register(
    "add.choir_pad",
    additive,
    octave=4,
    tail=1.2,
    harmonics=[1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
    levels=[1.0, 0.35, 0.25, 0.12, 0.06, 0.03],
    aenv=(0.4, 0.5, 0.9, 1.0),
    detune_cents=6.0,
)
