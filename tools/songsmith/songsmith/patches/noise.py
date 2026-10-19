"""Noise-based utility sounds used mostly for SFX: whooshes, creaks, rattles."""

from __future__ import annotations

import math

import numpy as np
from scipy import signal

from .. import dsp
from ..dsp import SR
from . import register


def whoosh(freq, dur, vel, rng, *, tail=0.0, f_start=400.0, f_end=3000.0, q=1.5):
    n = dsp.samples(dur)
    t = np.arange(n) / SR
    env = np.sin(np.pi * np.clip(t / max(dur, 1e-3), 0, 1)) ** 1.5
    x = rng.standard_normal(n)
    # Time-varying band-pass, processed in short blocks.
    out = np.zeros(n)
    block = 256
    zi = np.zeros(2)
    for s in range(0, n, block):
        frac = s / max(n - 1, 1)
        fc = f_start * (f_end / f_start) ** frac
        b, a = dsp.biquad("bandpass", fc, q)
        y, zi = signal.lfilter(b, a, x[s : s + block], zi=zi)
        out[s : s + block] = y
    return out * env * vel


def creak(freq, dur, vel, rng, *, tail=0.0, rate_start=18.0, rate_end=45.0, resonances=((320.0, 9.0), (740.0, 12.0), (1650.0, 10.0))):
    """Stick-slip friction: an irregular impulse train exciting wooden resonances."""
    n = dsp.samples(dur)
    impulses = np.zeros(n)
    pos = 0.0
    while True:
        frac = pos / max(n, 1)
        rate = rate_start + (rate_end - rate_start) * math.sin(math.pi * frac)
        pos += SR / rate * rng.uniform(0.7, 1.3)
        if pos >= n:
            break
        impulses[int(pos)] = rng.uniform(0.5, 1.0)
    out = np.zeros(n)
    for fc, q in resonances:
        out += dsp.filt(impulses, "bandpass", fc * rng.uniform(0.97, 1.03), q)
    env = np.sin(np.pi * np.clip(np.arange(n) / max(n - 1, 1), 0, 1)) ** 0.5
    return np.tanh(out * 3) * env * vel


def rattle(freq, dur, vel, rng, *, tail=0.0, clicks=7):
    """Loose metal: a burst of tiny metallic clicks."""
    n = dsp.samples(dur + 0.1)
    out = np.zeros(n)
    times = np.sort(rng.uniform(0, dur, clicks))
    for k, tc in enumerate(times):
        s = dsp.samples(tc)
        m = min(n - s, dsp.samples(0.05))
        t = np.arange(m) / SR
        base = rng.uniform(2200, 4200)
        c = sum(a * np.sin(2 * math.pi * base * r * t) for r, a in ((1.0, 1.0), (1.71, 0.6), (2.9, 0.3)))
        c *= np.exp(-t / 0.008) * rng.uniform(0.5, 1.0)
        out[s : s + m] += c
    return out * vel * 0.6


register("noise.whoosh", whoosh, kind="perc", tail=0.0)
register("noise.creak", creak, kind="perc", tail=0.0)
register("noise.rattle", rattle, kind="perc", tail=0.0)
