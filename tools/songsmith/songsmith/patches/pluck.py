"""Extended Karplus-Strong plucked strings."""

from __future__ import annotations

import math

import numpy as np
from numba import njit

from .. import dsp
from ..dsp import SR
from . import register


@njit(cache=True)
def _ks(exc: np.ndarray, n_out: int, delay: int, ap_c: float, feedback: float, damping: float, gate: int, release_fb: float) -> np.ndarray:
    length = delay + 1
    buf = np.zeros(length)
    out = np.empty(n_out)
    idx = 0
    prev = 0.0
    ap_x1 = 0.0
    ap_y1 = 0.0
    fb = feedback
    n_exc = exc.shape[0]
    for i in range(n_out):
        if i == gate:
            fb = release_fb
        y = buf[idx]
        lp = (1.0 - damping) * y + damping * prev
        prev = y
        ap = ap_c * lp + ap_x1 - ap_c * ap_y1
        ap_x1 = lp
        ap_y1 = ap
        x = exc[i] if i < n_exc else (1e-18 if i & 1 else 3e-19)
        new = x + fb * ap
        buf[idx] = new
        idx += 1
        if idx >= length:
            idx = 0
        out[i] = new
    return out


def pluck(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 1.0,
    t60: float = 2.5,
    damping: float = 0.5,
    bright: float = 0.6,
    pick_pos: float = 0.18,
    release_t60: float = 0.25,
    body: list[tuple[float, float, float]] | None = None,
    lowpass: float = 9000.0,
    thump: float = 0.0,
) -> np.ndarray:
    """``t60``: free ring time; ``release_t60``: decay once the note is released;
    ``body``: list of (freq, q, gain_db) peaks for the instrument body."""
    period = SR / freq
    total = period - damping  # the loss filter adds ~damping samples of delay
    delay = int(math.floor(total))
    frac = total - delay
    if frac < 0.1:
        delay -= 1
        frac += 1.0
    ap_c = (1.0 - frac) / (1.0 + frac)
    per_period = 10.0 ** (-3.0 / (t60 * freq))
    rel_period = 10.0 ** (-3.0 / (max(release_t60, 0.01) * freq))
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    exc_len = max(2, int(period))
    exc = rng.uniform(-1, 1, exc_len)
    # Brightness: softer plucks are darker.
    exc = dsp.onepole_lp(exc, 600 + 9000 * bright * vel)
    # Pick position comb.
    d = max(1, int(pick_pos * period))
    exc[d:] -= exc[:-d].copy()
    exc *= vel / (np.max(np.abs(exc)) + 1e-9)
    out = _ks(exc, n, delay, ap_c, per_period, damping, gate, rel_period)
    if body:
        for f, q, g in body:
            out = dsp.filt(out, "peak", f, q, g)
    if thump > 0:
        m = dsp.samples(0.03)
        th = np.sin(2 * math.pi * freq * np.arange(m) / SR) * np.exp(-np.arange(m) / (0.008 * SR))
        out[:m] += thump * vel * th
    out = dsp.onepole_lp(out, lowpass)
    out = dsp.dc_block(out)
    return dsp.fade_tail(out, 0.02)


register(
    "pluck.upright_bass",
    pluck,
    octave=2,
    tail=0.6,
    doc="Upright (double) bass, plucked: dark, round, short release.",
    t60=2.2,
    damping=0.62,
    bright=0.18,
    pick_pos=0.22,
    release_t60=0.18,
    body=[(95.0, 1.5, 5.0), (210.0, 2.0, 2.0), (900.0, 1.0, -4.0)],
    lowpass=2600.0,
    thump=0.35,
)
register(
    "pluck.nylon_guitar",
    pluck,
    octave=4,
    tail=1.2,
    t60=3.0,
    damping=0.5,
    bright=0.45,
    pick_pos=0.14,
    release_t60=0.4,
    body=[(105.0, 1.5, 4.0), (220.0, 2.0, 3.0), (480.0, 2.5, 2.0)],
    lowpass=7000.0,
)
register(
    "pluck.steel_guitar",
    pluck,
    octave=4,
    tail=1.4,
    t60=4.0,
    damping=0.4,
    bright=0.75,
    pick_pos=0.12,
    release_t60=0.5,
    body=[(110.0, 1.5, 3.0), (240.0, 2.0, 2.0), (2500.0, 1.0, 2.0)],
    lowpass=11000.0,
)
register(
    "pluck.harp",
    pluck,
    octave=4,
    tail=2.5,
    t60=5.0,
    damping=0.45,
    bright=0.5,
    pick_pos=0.3,
    release_t60=3.0,
    body=[(200.0, 1.0, 2.0)],
    lowpass=8000.0,
)
