"""Brass: a lip-buzz saw through a dynamic low-pass and bell formants, with a pitch scoop."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def brass(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.2,
    cutoff: float = 520.0,
    keytrack: float = 0.7,
    env_amt: float = 1.6,
    resonance: float = 0.12,
    fenv: tuple[float, float, float, float] = (0.035, 0.16, 0.35, 0.1),
    aenv: tuple[float, float, float, float] = (0.03, 0.12, 0.82, 0.1),
    scoop_cents: float = -30.0,
    scoop_time: float = 0.05,
    vibrato: tuple[float, float, float] = (4.6, 7.0, 0.35),
    growl: float = 0.12,
    breath: float = 0.03,
    formants: list[tuple[float, float, float]] = ((230.0, 1.4, 5.0), (650.0, 1.8, 2.5)),
) -> np.ndarray:
    """Brighter (more harmonics) the harder it is played; notes scoop up into pitch."""
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    rate, cents, delay = vibrato
    ramp = np.clip((t - delay) / 0.3, 0, 1)
    pitch_cents = scoop_cents * np.exp(-t / max(scoop_time, 1e-3)) + cents * ramp * np.sin(2 * math.pi * rate * t + rng.uniform(0, 6.28))
    f = freq * 2 ** (pitch_cents / 1200)
    src = dsp.osc(f, n, "saw", phase=rng.uniform(0, 1))
    if growl > 0:
        src = np.tanh(src * (1 + 3 * growl * vel)) / np.tanh(1 + 3 * growl * vel)
    fe = dsp.adsr(n, fenv[0], fenv[1], fenv[2], fenv[3], gate)
    cut = cutoff * (freq / 65.4) ** keytrack * (0.55 + 0.45 * vel) * (1 + env_amt * vel * fe)
    out = dsp.ladder(src * 0.7, np.clip(cut, 30.0, SR * 0.45), resonance)
    if breath > 0:
        out += breath * dsp.filt(rng.standard_normal(n), "bandpass", min(freq * 6, 4000.0), 0.8) * fe
    shaped = np.zeros(n)
    for fc, q, g in formants:
        shaped += dsp.filt(out, "peak", fc, q, g)
    out = shaped / max(1, len(formants))
    out *= dsp.adsr(n, aenv[0], aenv[1], aenv[2], aenv[3], gate) * vel
    out = dsp.dc_block(out)
    return dsp.fade_tail(out, 0.02)


register(
    "brass.tuba",
    brass,
    octave=2,
    tail=0.2,
    doc="Warm, round tuba: soft scoop into pitch, opens up when played hard (oom-pah bass).",
)
