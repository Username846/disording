"""Reed and air instruments: band-limited source + breath noise through body formants."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def reed(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.2,
    shape: str = "pulse",
    pw: float = 0.5,
    breath: float = 0.08,
    formants: list[tuple[float, float, float]] = ((800.0, 3.0, 6.0), (2400.0, 4.0, 3.0)),
    lowpass: float = 5000.0,
    aenv: tuple[float, float, float, float] = (0.04, 0.2, 0.85, 0.12),
    vibrato: tuple[float, float, float] = (5.2, 15.0, 0.3),
    buzz: float = 0.0,
) -> np.ndarray:
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    rate, cents, delay = vibrato
    ramp = np.clip((t - delay) / 0.4, 0, 1)
    f = freq * 2 ** (cents * ramp * np.sin(2 * math.pi * rate * t + rng.uniform(0, 6.28)) / 1200)
    out = dsp.osc(f, n, shape, pw) if shape != "sine" else np.sin(2 * math.pi * np.cumsum(f) / SR)
    if buzz > 0:
        out = np.tanh(out * (1 + 6 * buzz)) / np.tanh(1 + 6 * buzz)
    env = dsp.adsr(n, *aenv[:3], aenv[3], gate)
    out = out * env + breath * dsp.filt(rng.standard_normal(n), "bandpass", min(freq * 4, 8000), 0.8) * env
    shaped = np.zeros(n)
    for fc, q, g in formants:
        shaped += dsp.filt(out, "peak", fc, q, g)
    out = dsp.onepole_lp(shaped / max(1, len(formants)), lowpass * (0.5 + 0.5 * vel))
    out *= vel
    return dsp.fade_tail(out, 0.02)


register(
    "reed.clarinet",
    reed,
    octave=4,
    shape="square",
    breath=0.05,
    formants=[(1400.0, 2.0, 4.0), (3000.0, 3.0, 2.0)],
    lowpass=4500.0,
)
register(
    "reed.kazoo",
    reed,
    octave=4,
    shape="saw",
    breath=0.12,
    buzz=0.7,
    formants=[(500.0, 4.0, 9.0), (1500.0, 5.0, 6.0), (2600.0, 5.0, 4.0)],
    lowpass=6000.0,
    vibrato=(6.0, 25.0, 0.1),
)
register(
    "reed.flute",
    reed,
    octave=5,
    shape="sine",
    breath=0.18,
    formants=[(1500.0, 1.0, 1.0)],
    lowpass=7000.0,
    aenv=(0.06, 0.2, 0.9, 0.1),
)
register(
    "reed.whistle",
    reed,
    octave=6,
    shape="sine",
    breath=0.1,
    formants=[(3000.0, 1.0, 0.0)],
    lowpass=9000.0,
    aenv=(0.02, 0.1, 0.9, 0.05),
    vibrato=(5.5, 20.0, 0.15),
)
