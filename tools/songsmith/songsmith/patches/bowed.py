"""Bowed strings (source-filter): band-limited saw + bow noise through body resonances."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def bowed(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.4,
    body: list[tuple[float, float, float]] = ((280.0, 3.0, 6.0), (460.0, 3.0, 4.0), (2600.0, 2.0, 5.0)),
    bow_noise: float = 0.04,
    lowpass: float = 6000.0,
    aenv: tuple[float, float, float, float] = (0.12, 0.3, 0.9, 0.3),
    vibrato: tuple[float, float, float] = (5.5, 18.0, 0.25),
) -> np.ndarray:
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    rate, cents, delay = vibrato
    ramp = np.clip((t - delay) / 0.4, 0, 1)
    f = freq * 2 ** (cents * ramp * np.sin(2 * math.pi * rate * t + rng.uniform(0, 6.28)) / 1200)
    out = dsp.osc(f, n, "saw")
    out += bow_noise * dsp.filt(rng.standard_normal(n), "highpass", 2000)
    shaped = np.zeros(n)
    for fc, q, g in body:
        shaped += dsp.filt(out, "peak", fc, q, g)
    out = dsp.onepole_lp(shaped / len(body), lowpass * (0.5 + 0.5 * vel))
    out *= dsp.adsr(n, *aenv[:3], aenv[3], gate) * vel
    return dsp.fade_tail(out, 0.02)


register("bowed.violin", bowed, octave=5)
register(
    "bowed.cello",
    bowed,
    octave=3,
    body=[(110.0, 2.0, 6.0), (220.0, 3.0, 4.0), (1500.0, 2.0, 3.0)],
    lowpass=4000.0,
)
