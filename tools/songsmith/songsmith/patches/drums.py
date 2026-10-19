"""Synthesized drums and percussion (no samples)."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def _t(n: int) -> np.ndarray:
    return np.arange(n) / SR


def kick(freq, dur, vel, rng, *, tail=0.0, decay=0.35, start_hz=130.0, end_hz=46.0, click=0.3):
    n = dsp.samples(decay * 1.6)
    t = _t(n)
    f = end_hz + (start_hz - end_hz) * np.exp(-t / 0.035)
    body = np.sin(2 * math.pi * np.cumsum(f) / SR) * np.exp(-t / (decay / 3))
    m = dsp.samples(0.004)
    body[:m] += click * dsp.filt(rng.standard_normal(m), "highpass", 2500) * np.linspace(1, 0, m)
    return np.tanh(1.5 * body) * vel


def snare(freq, dur, vel, rng, *, tail=0.0, decay=0.18, tone=0.5):
    n = dsp.samples(decay * 2)
    t = _t(n)
    body = tone * (np.sin(2 * math.pi * 185 * t) + 0.6 * np.sin(2 * math.pi * 330 * t)) * np.exp(-t / 0.05)
    nz = dsp.filt(rng.standard_normal(n), "bandpass", 4500, 0.6) * np.exp(-t / (decay / 2.5))
    return (body + nz) * vel * 0.7


def brush(freq, dur, vel, rng, *, tail=0.0, decay=0.22, swish=0.06):
    n = dsp.samples(decay + swish)
    t = _t(n)
    env = np.minimum(t / max(swish, 1e-3), 1.0) * np.exp(-np.maximum(t - swish, 0) / (decay / 3))
    nz = dsp.filt(rng.standard_normal(n), "bandpass", 5200, 0.7) * env
    tap = 0.3 * np.sin(2 * math.pi * 200 * t) * np.exp(-t / 0.03)
    return (nz + tap) * vel * 0.6


def hat(freq, dur, vel, rng, *, tail=0.0, decay=0.05):
    n = dsp.samples(max(decay * 3, 0.03))
    t = _t(n)
    metal = sum(np.sign(np.sin(2 * math.pi * f * t)) for f in (205.3, 304.4, 369.6, 522.7, 540.0, 800.0))
    out = dsp.filt(metal / 6 + 0.4 * rng.standard_normal(n), "highpass", 7000, 0.8)
    return out * np.exp(-t / (decay / 2)) * vel * 0.5


def shaker(freq, dur, vel, rng, *, tail=0.0, decay=0.08):
    n = dsp.samples(decay * 3 + 0.02)
    t = _t(n)
    env = np.minimum(t / 0.012, 1.0) * np.exp(-np.maximum(t - 0.012, 0) / (decay / 2))
    return dsp.filt(rng.standard_normal(n), "highpass", 6000, 0.7) * env * vel * 0.45


def sleigh_bells(freq, dur, vel, rng, *, tail=0.0, jingles=10, spread=0.05):
    """A cluster of tiny jingles, each a few high inharmonic modes."""
    n = dsp.samples(0.45)
    out = np.zeros(n)
    count = max(3, int(jingles * (0.5 + 0.5 * vel)))
    for _ in range(count):
        onset = dsp.samples(abs(rng.normal(0, spread)))
        m = n - onset
        if m <= 0:
            continue
        t = _t(m)
        base = rng.uniform(3200, 6200)
        j = np.zeros(m)
        for ratio, amp in ((1.0, 1.0), (1.48, 0.6), (2.31, 0.35)):
            j += amp * np.sin(2 * math.pi * base * ratio * t + rng.uniform(0, 6.28))
        j *= np.exp(-t / rng.uniform(0.03, 0.09))
        out[onset:] += j * rng.uniform(0.4, 1.0)
    sh = shaker(freq, dur, vel, rng)[:n]
    out[: len(sh)] += 0.3 * sh
    out = dsp.filt(out, "highpass", 2500)
    return out / (count ** 0.5) * vel * 0.5


def tom(freq, dur, vel, rng, *, tail=0.0, decay=0.3):
    n = dsp.samples(decay * 1.5)
    t = _t(n)
    f = freq * (1 + 0.6 * np.exp(-t / 0.03))
    body = np.sin(2 * math.pi * np.cumsum(f) / SR) * np.exp(-t / (decay / 3))
    nz = dsp.filt(rng.standard_normal(n), "lowpass", 3000) * np.exp(-t / 0.02) * 0.3
    return (body + nz) * vel


def clap(freq, dur, vel, rng, *, tail=0.0):
    n = dsp.samples(0.25)
    t = _t(n)
    env = np.zeros(n)
    for k, d in enumerate((0.0, 0.011, 0.023, 0.034)):
        s = dsp.samples(d)
        env[s:] += np.exp(-(t[: n - s]) / (0.006 if k < 3 else 0.06))
    return dsp.filt(rng.standard_normal(n), "bandpass", 1300, 1.2) * env * vel * 0.6


def wood(freq, dur, vel, rng, *, tail=0.0, decay=0.09, ratios=(1.0, 2.57, 4.1), amps=(1.0, 0.45, 0.2), noise=0.25):
    """Woodblock / door knock family: a few fast-decaying modes plus a noise tap."""
    n = dsp.samples(decay * 3 + 0.02)
    t = _t(n)
    out = np.zeros(n)
    for r, a in zip(ratios, amps):
        out += a * np.sin(2 * math.pi * freq * r * t + rng.uniform(0, 6.28)) * np.exp(-6.9 * t / (decay * (1.2 - 0.25 * r / ratios[-1])))
    m = dsp.samples(0.006)
    out[:m] += noise * dsp.filt(rng.standard_normal(m), "lowpass", 2500) * np.linspace(1, 0, m)
    return out * vel


PERC = {
    "kick": ("perc.kick", 36),
    "snare": ("perc.snare", 38),
    "brush": ("perc.brush", 38),
    "hat": ("perc.hat", 42),
    "open_hat": ("perc.open_hat", 46),
    "shaker": ("perc.shaker", 70),
    "sleigh": ("perc.sleigh_bells", 81),
    "tom_low": ("perc.tom", 45),
    "tom_mid": ("perc.tom", 48),
    "tom_high": ("perc.tom", 50),
    "clap": ("perc.clap", 39),
    "woodblock": ("perc.woodblock", 76),
}

register("perc.kick", kick, kind="perc", default_note=36, tail=0.0)
register("perc.snare", snare, kind="perc", default_note=38, tail=0.0)
register("perc.brush", brush, kind="perc", default_note=38, tail=0.0)
register("perc.hat", hat, kind="perc", default_note=42, tail=0.0)
register("perc.open_hat", hat, kind="perc", default_note=46, tail=0.0, decay=0.3)
register("perc.shaker", shaker, kind="perc", default_note=70, tail=0.0)
register("perc.sleigh_bells", sleigh_bells, kind="perc", default_note=81, tail=0.0)
register("perc.tom", tom, kind="perc", default_note=45, tail=0.0)
register("perc.clap", clap, kind="perc", default_note=39, tail=0.0)
register("perc.woodblock", wood, kind="perc", default_note=76, tail=0.0)
register(
    "perc.door_knock",
    wood,
    kind="perc",
    default_note=46,  # ~117 Hz: a thick wooden door
    tail=0.0,
    decay=0.12,
    ratios=(1.0, 2.3, 3.9, 6.1),
    amps=(1.0, 0.6, 0.3, 0.12),
    noise=0.6,
)
register("drums.kit", kick, kind="kit", tail=0.0, pieces={k: v[0] for k, v in PERC.items()})
