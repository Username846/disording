"""Virtual-analog subtractive synthesis: band-limited oscillators → ladder filter → ADSR."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def va(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.5,
    shape: str = "saw",
    voices: int = 1,
    detune_cents: float = 0.0,
    pw: float = 0.5,
    sub: float = 0.0,
    noise: float = 0.0,
    cutoff: float = 2500.0,
    keytrack: float = 0.5,
    resonance: float = 0.1,
    env_amt: float = 0.0,
    fenv: tuple[float, float, float, float] = (0.01, 0.3, 0.0, 0.3),
    aenv: tuple[float, float, float, float] = (0.01, 0.2, 0.8, 0.3),
    vibrato: tuple[float, float, float] = (0.0, 0.0, 0.0),
    drift_cents: float = 0.0,
    vel_cutoff: float = 0.5,
) -> np.ndarray:
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    rate, cents, delay = vibrato
    pitch = np.ones(n)
    if cents > 0:
        ramp = np.clip((t - delay) / 0.3, 0, 1)
        pitch *= 2 ** (cents * ramp * np.sin(2 * math.pi * rate * t) / 1200)
    if drift_cents > 0:
        walk = np.cumsum(rng.standard_normal(n // 512 + 2))
        walk = np.interp(np.arange(n) / 512, np.arange(len(walk)), walk)
        pitch *= 2 ** (drift_cents * walk / (np.max(np.abs(walk)) + 1e-9) / 1200)
    out = np.zeros(n)
    for v in range(voices):
        spread = 0.0 if voices == 1 else (v / (voices - 1) - 0.5) * 2
        f = freq * 2 ** (spread * detune_cents / 1200) * pitch
        out += dsp.osc(f, n, shape, pw, phase=rng.uniform(0, 1))
    out /= math.sqrt(voices)
    if sub > 0:
        out += sub * dsp.osc(freq * 0.5 * pitch, n, "sine")
    if noise > 0:
        out += noise * rng.standard_normal(n)
    fe = dsp.adsr(n, *fenv[:3], fenv[3], gate)
    base = cutoff * (freq / 261.6) ** keytrack * (1.0 - vel_cutoff + vel_cutoff * vel)
    cut = np.clip(base * (1 + env_amt * fe), 30, SR * 0.45)
    out = dsp.ladder(out * 0.7, cut, resonance)
    out *= dsp.adsr(n, aenv[0], aenv[1], aenv[2], aenv[3], gate) * vel
    out = dsp.dc_block(out)
    return dsp.fade_tail(out, 0.02)


register(
    "va.string_pad",
    va,
    octave=4,
    tail=1.6,
    doc="Soft warm string-machine pad.",
    shape="saw",
    voices=5,
    detune_cents=14.0,
    cutoff=1500.0,
    keytrack=0.3,
    resonance=0.05,
    aenv=(0.55, 0.6, 0.85, 1.4),
    vibrato=(4.8, 4.0, 0.4),
    vel_cutoff=0.3,
)
register(
    "va.sub_bass",
    va,
    octave=2,
    tail=0.3,
    shape="triangle",
    cutoff=600.0,
    keytrack=0.2,
    aenv=(0.005, 0.3, 0.7, 0.15),
    sub=0.4,
)
register(
    "va.square_lead",
    va,
    octave=5,
    tail=0.3,
    shape="pulse",
    pw=0.35,
    cutoff=3500.0,
    env_amt=1.0,
    fenv=(0.005, 0.2, 0.2, 0.2),
    aenv=(0.005, 0.15, 0.7, 0.15),
    vibrato=(5.5, 12.0, 0.25),
)
register(
    "va.soft_saw",
    va,
    octave=4,
    tail=0.6,
    shape="saw",
    voices=2,
    detune_cents=8.0,
    cutoff=1800.0,
    env_amt=1.5,
    fenv=(0.01, 0.4, 0.3, 0.4),
    aenv=(0.02, 0.4, 0.6, 0.5),
)
register(
    "va.blip",
    va,
    octave=5,
    tail=0.2,
    doc="Short synth blip for SFX.",
    shape="pulse",
    pw=0.5,
    cutoff=4000.0,
    aenv=(0.002, 0.08, 0.0, 0.05),
)
