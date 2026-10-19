"""Modal synthesis: sums of exponentially decaying sinusoids (bells, bars, tines)."""

from __future__ import annotations

import math

import numpy as np
from numba import njit

from .. import dsp
from ..dsp import SR
from . import register


@njit(cache=True)
def _bank(n: int, freqs: np.ndarray, levels: np.ndarray, t60s: np.ndarray, phases: np.ndarray, gate: int, damp_t60: float, sr: float) -> np.ndarray:
    """Sum of exponentially decaying sinusoids via complex rotation (no per-sample trig)."""
    out = np.zeros(n)
    for p in range(freqs.shape[0]):
        w = 2.0 * math.pi * freqs[p] / sr
        r = math.exp(-6.907755 / (t60s[p] * sr))
        rd = math.exp(-6.907755 / (damp_t60 * sr)) if damp_t60 > 0 else 1.0
        c = math.cos(w)
        s = math.sin(w)
        re = levels[p] * math.cos(phases[p])
        im = levels[p] * math.sin(phases[p])
        for i in range(n):
            out[i] += im
            if i >= gate:
                re *= rd
                im *= rd
            re, im = r * (re * c - im * s), r * (re * s + im * c)
            if abs(im) + abs(re) < 1e-12:
                break
    return out


def modal(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    ratios: list[float],
    amps: list[float],
    t60s: list[float],
    tail: float = 2.0,
    bright: float = 0.6,
    strike: float = 0.15,
    strike_freq: float = 3000.0,
    strike_q: float = 1.2,
    beat_hz: float = 0.0,
    damp: float | None = None,
    t60_ref_hz: float = 523.0,
    t60_scale: float = 0.35,
    attack: float = 0.0015,
    stretch: float = 1.0,
) -> np.ndarray:
    """``damp``: if set, the note is damped after ``dur`` with that t60 (handbell players
    stop the bell against their chest). Lower notes ring longer (``t60_scale``)."""
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    pitch_factor = (t60_ref_hz / freq) ** t60_scale
    freqs, levels, decays, phases = [], [], [], []
    for k, (ratio, amp, t60) in enumerate(zip(ratios, amps, t60s)):
        f = freq * ratio**stretch
        if f >= SR * 0.45:
            continue
        level = amp * vel ** (1.0 + bright * k)
        phase = rng.uniform(0, 2 * math.pi)
        if beat_hz > 0 and k < 3:
            # Doublet: real bells split modes slightly, which gives the slow "wow".
            freqs += [f, f + beat_hz * (k + 1)]
            levels += [0.5 * level, 0.5 * level]
            decays += [t60 * pitch_factor] * 2
            phases += [phase, phase * 1.7]
        else:
            freqs.append(f)
            levels.append(level)
            decays.append(t60 * pitch_factor)
            phases.append(phase)
    out = _bank(n, np.array(freqs, dtype=np.float64), np.array(levels, dtype=np.float64), np.array(decays, dtype=np.float64), np.array(phases, dtype=np.float64), gate if damp is not None else n + 1, float(damp or 0.0), float(SR))
    if strike > 0:
        m = dsp.samples(0.006)
        burst = rng.standard_normal(m) * np.linspace(1, 0, m) ** 2
        burst = dsp.filt(burst, "bandpass", strike_freq * (0.6 + 0.6 * vel), strike_q)
        out[:m] += strike * vel * burst / (np.max(np.abs(burst)) + 1e-9)
    a = max(1, dsp.samples(attack))
    out[:a] *= np.linspace(0, 1, a)
    return dsp.fade_tail(out, 0.02)


register(
    "modal.handbells",
    modal,
    octave=5,
    tail=3.5,
    doc="English handbells: strong prime and twelfth, slow beating, leather clapper.",
    ratios=[1.0, 2.0, 3.0, 4.2, 5.43, 6.8, 8.2],
    amps=[1.0, 0.06, 0.5, 0.1, 0.16, 0.07, 0.04],
    t60s=[5.5, 2.0, 3.0, 1.2, 0.9, 0.6, 0.45],
    bright=0.5,
    strike=0.08,
    strike_freq=2200.0,
    beat_hz=0.35,
    damp=None,
)
register(
    "modal.glockenspiel",
    modal,
    octave=6,
    tail=2.0,
    doc="Steel glockenspiel bars with a hard mallet.",
    ratios=[1.0, 2.756, 5.404, 8.933],
    amps=[1.0, 0.22, 0.1, 0.04],
    t60s=[2.4, 0.9, 0.4, 0.25],
    bright=0.8,
    strike=0.25,
    strike_freq=6000.0,
)
register(
    "modal.celesta",
    modal,
    octave=5,
    tail=1.6,
    ratios=[1.0, 2.0, 3.98, 6.1],
    amps=[1.0, 0.12, 0.08, 0.02],
    t60s=[1.8, 0.8, 0.35, 0.2],
    bright=0.6,
    strike=0.06,
    strike_freq=4000.0,
)
register(
    "modal.toy_piano",
    modal,
    octave=5,
    tail=1.4,
    ratios=[1.0, 6.267, 17.55],
    amps=[1.0, 0.3, 0.08],
    t60s=[1.3, 0.45, 0.18],
    bright=0.7,
    strike=0.35,
    strike_freq=3500.0,
)
register(
    "modal.kalimba",
    modal,
    octave=5,
    tail=1.8,
    ratios=[1.0, 5.93, 13.0],
    amps=[1.0, 0.14, 0.04],
    t60s=[1.7, 0.35, 0.12],
    bright=0.6,
    strike=0.12,
    strike_freq=2500.0,
)
register(
    "modal.marimba",
    modal,
    octave=4,
    tail=1.2,
    ratios=[1.0, 3.932, 9.24],
    amps=[1.0, 0.16, 0.05],
    t60s=[0.9, 0.28, 0.1],
    bright=0.6,
    strike=0.1,
    strike_freq=1500.0,
)
register(
    "modal.chime",
    modal,
    octave=6,
    tail=1.5,
    doc="Small bright chime for UI sparkle.",
    ratios=[1.0, 2.76, 5.4],
    amps=[1.0, 0.3, 0.12],
    t60s=[1.2, 0.6, 0.3],
    bright=0.5,
    strike=0.1,
    strike_freq=7000.0,
)
register(
    "modal.music_box",
    modal,
    octave=6,
    tail=1.6,
    ratios=[1.0, 5.4, 11.0],
    amps=[1.0, 0.2, 0.05],
    t60s=[1.6, 0.4, 0.15],
    bright=0.5,
    strike=0.2,
    strike_freq=5000.0,
)
