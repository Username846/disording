"""Reverb, dynamics, loudness and true-peak handling. All effects are baked into the
rendered files (the game plays them without bus effects)."""

from __future__ import annotations

import math

import numpy as np
import pyloudnorm
from numba import njit
from scipy import signal
from scipy.ndimage import minimum_filter1d, uniform_filter1d

from . import dsp
from .dsp import SR


def make_ir(rt60: float = 2.0, predelay: float = 0.02, damping_hz: float = 6000.0, seed: int = 7, early: int = 8) -> np.ndarray:
    """Synthetic stereo reverb impulse response (decorrelated decaying noise + early taps)."""
    rng = np.random.default_rng(seed)
    n = dsp.samples(rt60 * 1.2 + predelay)
    t = np.arange(n) / SR
    ir = np.zeros((2, n))
    pd = dsp.samples(predelay)
    for ch in range(2):
        noise = rng.standard_normal(n)
        env = np.exp(-6.907755 * np.maximum(t - predelay, 0) / rt60)
        env[:pd] = 0
        late = noise * env
        # Darken over time: blend a low-passed copy in as the tail ages.
        dark = dsp.onepole_lp(late, damping_hz * 0.35)
        mix = np.clip((t - predelay) / max(rt60 * 0.6, 1e-3), 0, 1)
        late = dsp.onepole_lp(late * (1 - mix) + dark * mix * 1.6, damping_hz)
        for _ in range(early):
            tap = pd + dsp.samples(rng.uniform(0.003, 0.06))
            if tap < n:
                late[tap] += rng.uniform(0.3, 0.8) * (1 if rng.random() > 0.5 else -1) * 6
        ir[ch] = late
    ir /= np.sqrt(np.sum(ir**2) / 2)
    return ir


def reverb(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
    """Stereo in → stereo wet out (same length as x; the tail is truncated)."""
    n = x.shape[-1]
    left = signal.oaconvolve(x[0] + 0.35 * x[1], ir[0])[:n]
    right = signal.oaconvolve(x[1] + 0.35 * x[0], ir[1])[:n]
    return np.vstack([left, right])


@njit(cache=True)
def _comp_gain(level_db: np.ndarray, threshold: float, ratio: float, att: float, rel: float) -> np.ndarray:
    n = level_db.shape[0]
    g = np.zeros(n)
    env = 0.0
    for i in range(n):
        over = level_db[i] - threshold
        target = 0.0 if over <= 0 else -over * (1.0 - 1.0 / ratio)
        coef = att if target < env else rel
        env = target + coef * (env - target) + 1e-30
        g[i] = env
    return g


def compress(x: np.ndarray, threshold_db: float = -18.0, ratio: float = 2.0, attack: float = 0.02, release: float = 0.25, rms_window: float = 0.03) -> np.ndarray:
    mono = np.max(np.abs(x), axis=0) if x.ndim == 2 else np.abs(x)
    power = uniform_filter1d(mono**2, max(1, dsp.samples(rms_window)))
    level = 10 * np.log10(power + 1e-12)
    att = math.exp(-1.0 / max(1.0, attack * SR))
    rel = math.exp(-1.0 / max(1.0, release * SR))
    gain = 10 ** (_comp_gain(level, threshold_db, ratio, att, rel) / 20)
    return x * gain


@njit(cache=True)
def _release(g: np.ndarray, coef: float) -> np.ndarray:
    out = np.empty_like(g)
    env = 1.0
    for i in range(g.shape[0]):
        if g[i] < env:
            env = g[i]
        else:
            env = g[i] + coef * (env - g[i])
        out[i] = env
    return out


def limit(x: np.ndarray, ceiling_db: float = -1.5, lookahead: float = 0.004, release: float = 0.08) -> np.ndarray:
    """Look-ahead brickwall limiter on sample peaks."""
    ceiling = dsp.db(ceiling_db)
    peak = np.max(np.abs(x), axis=0) if x.ndim == 2 else np.abs(x)
    need = np.minimum(1.0, ceiling / np.maximum(peak, 1e-12))
    la = max(1, dsp.samples(lookahead))
    g = minimum_filter1d(need, size=2 * la + 1)
    g = uniform_filter1d(g, size=la)
    g = np.minimum(g, minimum_filter1d(need, size=la | 1))
    g = _release(g, math.exp(-1.0 / (release * SR)))
    return x * g


def true_peak_db(x: np.ndarray, block: int = 4096) -> float:
    """4× oversampled peak. Only the loudest blocks are oversampled (inter-sample peaks
    exceed sample peaks by at most a few dB)."""
    x2 = x if x.ndim == 2 else x[None, :]
    n = x2.shape[1]
    k = max(1, n // block)
    peaks = np.abs(x2[:, : k * block]).reshape(x2.shape[0], k, block).max(axis=(0, 2))
    if n > k * block:
        peaks = np.append(peaks, np.abs(x2[:, k * block :]).max())
    top = float(peaks.max())
    best = top
    for b in np.nonzero(peaks >= top * dsp.db(-3.0))[0]:
        s0 = max(0, b * block - 64)
        s1 = min(n, (b + 1) * block + 64)
        up = signal.resample_poly(x2[:, s0:s1], 4, 1, axis=-1)
        best = max(best, float(np.max(np.abs(up[:, 256:-256]))) if up.shape[1] > 512 else float(np.max(np.abs(up))))
    return dsp.to_db(best)


_K_FILTERS: list[tuple[np.ndarray, np.ndarray]] | None = None


def _k_filters() -> list[tuple[np.ndarray, np.ndarray]]:
    global _K_FILTERS
    if _K_FILTERS is None:
        meter = pyloudnorm.Meter(SR)
        _K_FILTERS = [(np.asarray(f.b), np.asarray(f.a)) for f in meter._filters.values()]
    return _K_FILTERS


def loudness(x: np.ndarray) -> float:
    """BS.1770-4 integrated loudness (LUFS), same filters and gating as pyloudnorm."""
    data = x if x.ndim == 2 else x[None, :]
    if data.shape[1] < SR // 2:
        data = np.concatenate([data, np.zeros((data.shape[0], SR // 2 - data.shape[1]))], axis=1)
    y = data
    for b, a in _k_filters():
        y = dsp.apply_biquad(y, b, a)
    block = int(0.4 * SR)
    hop = block // 4
    power = y**2
    csum = np.concatenate([np.zeros((y.shape[0], 1)), np.cumsum(power, axis=1)], axis=1)
    starts = np.arange(0, y.shape[1] - block + 1, hop)
    z = (csum[:, starts + block] - csum[:, starts]) / block  # mean square per channel per block
    zsum = z.sum(axis=0)
    with np.errstate(divide="ignore"):
        lk = -0.691 + 10 * np.log10(zsum)
    gated = zsum[lk >= -70.0]
    if not len(gated):
        return -100.0
    rel = -0.691 + 10 * np.log10(gated.mean()) - 10.0
    final = zsum[(lk >= -70.0) & (lk >= rel)]
    return float(-0.691 + 10 * np.log10(final.mean()))


def master(x: np.ndarray, target_lufs: float = -16.0, max_tp_db: float = -1.0, glue: bool = True) -> tuple[np.ndarray, float, float]:
    """Glue compression → loudness normalisation → limiting. Returns (audio, LUFS, TP dBTP)."""
    y = compress(x, -20.0, 1.8, 0.03, 0.3) if glue else x.copy()
    ceiling = max_tp_db - 0.4
    lufs = loudness(y)
    y = y * dsp.db(target_lufs - lufs)
    out = y
    for _ in range(5):
        out = limit(y, ceiling)
        tp = true_peak_db(out)
        lufs = loudness(out)
        if tp > max_tp_db:
            ceiling -= (tp - max_tp_db) + 0.1
            continue
        if abs(lufs - target_lufs) > 0.4:
            y = y * dsp.db(target_lufs - lufs)
            continue
        break
    return out, lufs, tp


def active_rms(x: np.ndarray, frame: float = 0.05, floor_db: float = -50.0) -> float:
    """RMS over frames that are actually sounding (relative to the stem's peak)."""
    mono = x if x.ndim == 1 else np.sqrt(np.mean(x**2, axis=0))
    if not np.any(mono):
        return 0.0
    m = dsp.samples(frame)
    k = len(mono) // m
    if k == 0:
        return float(np.sqrt(np.mean(mono**2)))
    frames = np.sqrt(np.mean(mono[: k * m].reshape(k, m) ** 2, axis=1))
    ref = frames.max()
    active = frames[frames > ref * dsp.db(floor_db)]
    return float(np.sqrt(np.mean(active**2))) if len(active) else 0.0
