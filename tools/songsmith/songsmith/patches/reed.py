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
    voices: int = 1,
    detune_cents: float = 0.0,
    wah: float = 0.0,
    wah_time: float = 0.2,
) -> np.ndarray:
    """``voices``/``detune_cents``: a section of slightly detuned players (kazoo choir).
    ``wah``: the bell opens over ``wah_time`` (a cup-mute "wah"), 0 = off."""
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    rate, cents, delay = vibrato
    ramp = np.clip((t - delay) / 0.4, 0, 1)
    f = freq * 2 ** (cents * ramp * np.sin(2 * math.pi * rate * t + rng.uniform(0, 6.28)) / 1200)
    if voices > 1:
        out = np.zeros(n)
        for v in range(voices):
            spread = (v / (voices - 1) - 0.5) * 2
            fv = f * 2 ** (spread * detune_cents / 1200)
            out += dsp.osc(fv, n, shape, pw, phase=rng.uniform(0, 1)) if shape != "sine" else np.sin(2 * math.pi * np.cumsum(fv) / SR)
        out /= math.sqrt(voices)
    else:
        out = dsp.osc(f, n, shape, pw) if shape != "sine" else np.sin(2 * math.pi * np.cumsum(f) / SR)
    if buzz > 0:
        out = np.tanh(out * (1 + 6 * buzz)) / np.tanh(1 + 6 * buzz)
    env = dsp.adsr(n, *aenv[:3], aenv[3], gate)
    out = out * env + breath * dsp.filt(rng.standard_normal(n), "bandpass", min(freq * 4, 8000), 0.8) * env
    shaped = np.zeros(n)
    for fc, q, g in formants:
        shaped += dsp.filt(out, "peak", fc, q, g)
    if wah > 0:
        opening = np.clip(t / max(wah_time, 1e-3), 0, 1) ** 0.7
        cut = lowpass * (0.5 + 0.5 * vel) * (1.0 - wah * 0.85 * (1.0 - opening))
        out = dsp.ladder(shaped / max(1, len(formants)), np.clip(cut, 60.0, SR * 0.45), 0.35)
    else:
        out = dsp.onepole_lp(shaped / max(1, len(formants)), lowpass * (0.5 + 0.5 * vel))
    out *= vel
    return dsp.fade_tail(out, 0.02)


def slide_whistle(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.06,
    glide_from: float = 0.0,
    glide_in: float = 0.12,
    glide_to: float = 0.0,
    glide_out: float = 0.0,
    breath: float = 0.12,
    harmonics: float = 0.06,
    vibrato: tuple[float, float, float] = (5.5, 14.0, 0.15),
    trill_hz: float = 0.0,
    trill_cents: float = 0.0,
    aenv: tuple[float, float, float, float] = (0.012, 0.05, 0.9, 0.05),
    lowpass: float = 9000.0,
) -> np.ndarray:
    """Slide whistle: a near-sine air tone whose pitch slides. ``glide_from`` (semitones,
    e.g. -12) slides up into the note over ``glide_in`` seconds; ``glide_to`` slides away
    over the last ``glide_out`` seconds (default: most of the note). ``trill_hz`` and
    ``trill_cents`` add the rattling pea of a referee's whistle."""
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR
    semis = np.zeros(n)
    if glide_from:
        k = np.clip(t / max(glide_in, 1e-3), 0, 1)
        semis += glide_from * (1.0 - k) ** 2
    if glide_to:
        span = glide_out if glide_out > 0 else max(dur * 0.85, 1e-3)
        start = max(dur - span, 0.0)
        k = np.clip((t - start) / span, 0, 1)
        semis += glide_to * k**1.5
    rate, cents, delay = vibrato
    ramp = np.clip((t - delay) / 0.2, 0, 1)
    cents_curve = cents * ramp * np.sin(2 * math.pi * rate * t + rng.uniform(0, 6.28))
    if trill_hz > 0:
        cents_curve = cents_curve + trill_cents * 0.5 * np.tanh(4.0 * np.sin(2 * math.pi * trill_hz * t))
    f = np.minimum(freq * 2 ** (semis / 12 + cents_curve / 1200), SR * 0.45)
    phase = 2 * math.pi * np.cumsum(f) / SR + rng.uniform(0, 6.28)
    tone = np.sin(phase) + harmonics * np.sin(2 * phase) + 0.4 * harmonics * np.sin(3 * phase)
    noise = dsp.filt(rng.standard_normal(n), "bandpass", min(freq * 1.2, 9000.0), 1.0)
    noise *= 0.35 / (np.std(noise) + 1e-9)
    env = dsp.adsr(n, aenv[0], aenv[1], aenv[2], aenv[3], gate)
    out = dsp.onepole_lp((tone + breath * noise) * env, lowpass) * vel
    return dsp.fade_tail(out, 0.01)


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
register(
    "reed.kazoo_section",
    reed,
    octave=4,
    doc="Three detuned kazoos buzzing in unison (a tin-toy horn section).",
    shape="saw",
    breath=0.12,
    buzz=0.7,
    formants=[(500.0, 4.0, 9.0), (1500.0, 5.0, 6.0), (2600.0, 5.0, 4.0)],
    lowpass=6000.0,
    vibrato=(6.0, 22.0, 0.1),
    voices=3,
    detune_cents=16.0,
)
register(
    "reed.slide_whistle",
    slide_whistle,
    octave=6,
    tail=0.06,
    doc="Slide whistle with real portamento (glide_from / glide_to in semitones).",
)
register(
    "reed.pea_whistle",
    slide_whistle,
    octave=7,
    tail=0.05,
    doc="Referee's pea whistle: bright tone with a rattling trill.",
    trill_hz=34.0,
    trill_cents=220.0,
    harmonics=0.12,
    breath=0.22,
    vibrato=(0.0, 0.0, 0.0),
    aenv=(0.01, 0.03, 0.95, 0.04),
)
