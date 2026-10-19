"""Cartoon/toy sound effects: spring boings, clockwork ratchets, rubber squeaks."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def spring(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.0,
    wobble_hz: float = 14.0,
    depth: float = 0.35,
    decay: float = 0.35,
    drop: float = 0.3,
    bright: float = 0.4,
    twang: float = 0.35,
) -> np.ndarray:
    """"Boing": a tone whose pitch wobbles like a released spring and sags as it dies."""
    n = dsp.samples(dur + 0.05)
    t = np.arange(n) / SR
    wob = depth * np.sin(2 * math.pi * wobble_hz * t) * np.exp(-t / max(decay, 1e-3))
    f = freq * (1 - drop * (1 - np.exp(-t / max(dur * 0.6, 1e-3)))) * (1 + wob)
    phase = 2 * math.pi * np.cumsum(f) / SR
    tone = np.sin(phase) + 0.5 * bright * np.sin(2 * phase) + 0.25 * bright * np.sin(3 * phase)
    env = np.exp(-t / max(dur * 0.45, 1e-3)) * np.minimum(t / 0.002, 1.0)
    out = tone * env
    if twang > 0:
        m = dsp.samples(0.012)
        burst = dsp.filt(rng.standard_normal(m), "bandpass", min(freq * 4, 8000.0), 2.0) * np.linspace(1, 0, m)
        out[:m] += twang * burst / (np.max(np.abs(burst)) + 1e-9)
    return dsp.fade_tail(out * vel, 0.01)


def ratchet(freq, dur, vel, rng, *, tail=0.0, clicks=9, jitter=0.12, base_hz=3200.0, body_hz=900.0):
    """Clockwork key being wound: a run of regular metallic clicks on a small wooden body."""
    n = dsp.samples(dur + 0.05)
    out = np.zeros(n)
    spacing = dur / max(clicks, 1)
    for k in range(clicks):
        tc = k * spacing * (1 + rng.uniform(-jitter, jitter) * 0.5)
        s = dsp.samples(tc)
        m = min(n - s, dsp.samples(0.025))
        if m <= 0:
            continue
        t = np.arange(m) / SR
        b = base_hz * rng.uniform(0.92, 1.08)
        c = np.sin(2 * math.pi * b * t) + 0.6 * np.sin(2 * math.pi * b * 1.73 * t) + 0.35 * np.sin(2 * math.pi * b * 2.6 * t)
        c *= np.exp(-t / 0.004)
        tick = 0.5 * np.sin(2 * math.pi * body_hz * t) * np.exp(-t / 0.006)
        out[s : s + m] += (c + tick) * (0.7 + 0.3 * (k % 2))
    return out * vel * 0.5


def squeak(freq, dur, vel, rng, *, tail=0.0, rise=5.0, fall=-3.0, pw=0.25, noise=0.25):
    """Rubber-duck squeak: a narrow pulse that bends up then down through squeaky formants."""
    n = dsp.samples(dur + 0.02)
    t = np.arange(n) / SR
    x = np.clip(t / max(dur, 1e-3), 0, 1)
    semis = rise * np.sin(np.pi * x * 0.75) + fall * np.clip((x - 0.6) / 0.4, 0, 1)
    f = freq * 2 ** (semis / 12)
    src = dsp.osc(f, n, "pulse", pw) + noise * rng.standard_normal(n)
    out = dsp.filt(src, "bandpass", 2200.0, 1.5) + 0.6 * dsp.filt(src, "bandpass", 1100.0, 2.0)
    env = np.sin(np.pi * x) ** 0.6
    return dsp.fade_tail(out * env * vel, 0.01)


register("fx.spring", spring, octave=3, tail=0.0, doc="Spring boing (wobble_hz, depth, drop).")
register("fx.ratchet", ratchet, kind="perc", default_note=84, tail=0.0, doc="Clockwork key ratchet (clicks over dur).")
register("fx.squeak", squeak, octave=6, tail=0.0, doc="Rubber-duck squeak.")
