"""Small DSP toolkit shared by the engines, the singer and the mixer."""

from __future__ import annotations

import math

import numpy as np
from numba import njit

from . import SAMPLE_RATE

SR = SAMPLE_RATE


def db(x: float) -> float:
    return 10.0 ** (x / 20.0)


def to_db(x: float) -> float:
    return 20.0 * math.log10(max(x, 1e-12))


def seconds(n: int) -> float:
    return n / SR


def samples(t: float) -> int:
    return max(0, int(round(t * SR)))


# --------------------------------------------------------------------------- envelopes
def adsr(total: int, attack: float, decay: float, sustain: float, release: float, gate: int) -> np.ndarray:
    """Linear-attack, exponential decay/release envelope. ``gate`` = samples until release."""
    env = np.zeros(total, dtype=np.float64)
    a = max(1, samples(attack))
    gate = max(1, min(gate, total))
    t = np.arange(total, dtype=np.float64)
    # Attack.
    env[: min(a, total)] = t[: min(a, total)] / a
    # Decay toward sustain.
    if total > a:
        k = max(decay, 1e-4) * SR
        dec = sustain + (1.0 - sustain) * np.exp(-(t[a:] - a) / k)
        env[a:] = dec
    # Release from the level at the gate.
    if gate < total:
        level = env[gate - 1]
        k = max(release, 1e-4) * SR
        env[gate:] = level * np.exp(-(t[gate:] - gate) / (k / 4.6))  # ~-40 dB at `release`
    return env


def exp_decay(total: int, t60: float) -> np.ndarray:
    """Exponential decay reaching -60 dB after ``t60`` seconds."""
    t = np.arange(total, dtype=np.float64) / SR
    return np.exp(-6.907755 * t / max(t60, 1e-4))


def fade_tail(x: np.ndarray, length: float = 0.01) -> np.ndarray:
    n = min(len(x), samples(length))
    if n > 1:
        x[-n:] *= np.linspace(1.0, 0.0, n)
    return x


# --------------------------------------------------------------------------- filters
def biquad(kind: str, freq: float, q: float = 0.707, gain_db: float = 0.0) -> tuple[np.ndarray, np.ndarray]:
    """RBJ cookbook biquads: lowpass, highpass, bandpass, peak, lowshelf, highshelf."""
    freq = min(max(freq, 10.0), SR * 0.49)
    w0 = 2 * math.pi * freq / SR
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2 * q)
    A = 10 ** (gain_db / 40)
    if kind == "lowpass":
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
        a = [1 + alpha, -2 * cw, 1 - alpha]
    elif kind == "highpass":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
        a = [1 + alpha, -2 * cw, 1 - alpha]
    elif kind == "bandpass":
        b = [alpha, 0.0, -alpha]
        a = [1 + alpha, -2 * cw, 1 - alpha]
    elif kind == "peak":
        b = [1 + alpha * A, -2 * cw, 1 - alpha * A]
        a = [1 + alpha / A, -2 * cw, 1 - alpha / A]
    elif kind in ("lowshelf", "highshelf"):
        sq = 2 * math.sqrt(A) * alpha
        if kind == "lowshelf":
            b = [A * ((A + 1) - (A - 1) * cw + sq), 2 * A * ((A - 1) - (A + 1) * cw), A * ((A + 1) - (A - 1) * cw - sq)]
            a = [(A + 1) + (A - 1) * cw + sq, -2 * ((A - 1) + (A + 1) * cw), (A + 1) + (A - 1) * cw - sq]
        else:
            b = [A * ((A + 1) + (A - 1) * cw + sq), -2 * A * ((A - 1) + (A + 1) * cw), A * ((A + 1) + (A - 1) * cw - sq)]
            a = [(A + 1) - (A - 1) * cw + sq, 2 * ((A - 1) - (A + 1) * cw), (A + 1) - (A - 1) * cw - sq]
    else:
        raise ValueError(kind)
    b = np.array(b) / a[0]
    a = np.array(a) / a[0]
    return b, a


@njit(cache=True)
def _biquad_kernel(x: np.ndarray, b0: float, b1: float, b2: float, a1: float, a2: float) -> np.ndarray:
    """Direct form I biquad. A tiny dither keeps the recursion out of denormals
    (which are ~50× slower on x86) during silence."""
    out = np.empty_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(x.shape[0]):
        xi = x[i] + (1e-18 if i & 1 else 3e-19)
        y = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1
        x1 = xi
        y2 = y1
        y1 = y
        out[i] = y
    return out


def apply_biquad(x: np.ndarray, b: np.ndarray, a: np.ndarray) -> np.ndarray:
    """Filter along the last axis (mono or stereo) with normalised coefficients."""
    b = np.asarray(b, dtype=np.float64) / a[0]
    a = np.asarray(a, dtype=np.float64) / a[0]
    b = np.concatenate([b, np.zeros(3 - len(b))])
    a = np.concatenate([a, np.zeros(3 - len(a))])
    x = np.ascontiguousarray(x, dtype=np.float64)
    if x.ndim == 1:
        return _biquad_kernel(x, b[0], b[1], b[2], a[1], a[2])
    return np.vstack([_biquad_kernel(ch, b[0], b[1], b[2], a[1], a[2]) for ch in x])


def filt(x: np.ndarray, kind: str, freq: float, q: float = 0.707, gain_db: float = 0.0) -> np.ndarray:
    b, a = biquad(kind, freq, q, gain_db)
    return apply_biquad(x, b, a)


def onepole_lp(x: np.ndarray, freq: float) -> np.ndarray:
    c = math.exp(-2 * math.pi * min(freq, SR * 0.49) / SR)
    return apply_biquad(x, np.array([1 - c]), np.array([1.0, -c]))


def dc_block(x: np.ndarray, r: float = 0.995) -> np.ndarray:
    return apply_biquad(x, np.array([1.0, -1.0]), np.array([1.0, -r]))


# --------------------------------------------------------------------------- oscillators
@njit(cache=True)
def _poly_blep(t: float, dt: float) -> float:
    if t < dt:
        t /= dt
        return t + t - t * t - 1.0
    if t > 1.0 - dt:
        t = (t - 1.0) / dt
        return t * t + t + t + 1.0
    return 0.0


@njit(cache=True)
def osc_kernel(freq: np.ndarray, shape: int, pw: np.ndarray, phase0: float, sr: float) -> np.ndarray:
    """Band-limited oscillator. shape: 0 saw, 1 pulse, 2 triangle, 3 sine."""
    n = freq.shape[0]
    out = np.empty(n)
    phase = phase0
    tri = 0.0
    for i in range(n):
        dt = freq[i] / sr
        if shape == 0:
            v = 2.0 * phase - 1.0 - _poly_blep(phase, dt)
        elif shape == 1 or shape == 2:
            w = pw[i]
            v = 1.0 if phase < w else -1.0
            v += _poly_blep(phase, dt)
            p2 = phase - w
            if p2 < 0.0:
                p2 += 1.0
            v -= _poly_blep(p2, dt)
            if shape == 2:
                # Leaky integration of a square gives a band-limited triangle.
                tri = dt * 4.0 * v + (1.0 - dt * 0.05) * tri
                v = tri
        else:
            v = math.sin(2.0 * math.pi * phase)
        out[i] = v
        phase += dt
        if phase >= 1.0:
            phase -= 1.0
    return out


def osc(freq: np.ndarray | float, n: int, shape: str = "saw", pw: float | np.ndarray = 0.5, phase: float = 0.0) -> np.ndarray:
    shapes = {"saw": 0, "pulse": 1, "square": 1, "triangle": 2, "sine": 3}
    f = np.full(n, float(freq)) if np.isscalar(freq) else np.asarray(freq, dtype=np.float64)
    p = np.full(n, float(pw)) if np.isscalar(pw) else np.asarray(pw, dtype=np.float64)
    return osc_kernel(f, shapes[shape], p, phase, float(SR))


@njit(cache=True)
def ladder_kernel(x: np.ndarray, cutoff: np.ndarray, resonance: float, sr: float) -> np.ndarray:
    """Huovilainen-style 4-pole ladder low-pass (simplified, tanh on input)."""
    n = x.shape[0]
    out = np.empty(n)
    s1 = s2 = s3 = s4 = 0.0
    for i in range(n):
        fc = cutoff[i]
        if fc > sr * 0.45:
            fc = sr * 0.45
        g = 1.0 - math.exp(-2.0 * math.pi * fc / sr)
        inp = math.tanh(x[i] - resonance * 4.0 * s4) + (1e-18 if i & 1 else 3e-19)
        s1 += g * (inp - s1)
        s2 += g * (s1 - s2)
        s3 += g * (s2 - s3)
        s4 += g * (s3 - s4)
        out[i] = s4
    return out


def ladder(x: np.ndarray, cutoff: np.ndarray | float, resonance: float = 0.1) -> np.ndarray:
    c = np.full(len(x), float(cutoff)) if np.isscalar(cutoff) else np.asarray(cutoff, dtype=np.float64)
    return ladder_kernel(np.asarray(x, dtype=np.float64), c, float(resonance), float(SR))


# --------------------------------------------------------------------------- stereo & delay
def pan_gains(pan: float) -> tuple[float, float]:
    angle = (pan + 1.0) * math.pi / 4.0
    return math.cos(angle), math.sin(angle)


def pan_stereo(x: np.ndarray, pan: float) -> np.ndarray:
    """Constant-power pan, pan in [-1, 1]. Returns shape (2, n)."""
    gl, gr = pan_gains(pan)
    out = np.empty((2, len(x)))
    np.multiply(x, gl, out=out[0])
    np.multiply(x, gr, out=out[1])
    return out


def add_panned(buffer: np.ndarray, x: np.ndarray, pan: float, gain: float = 1.0) -> None:
    """buffer (2, n) += pan(x) * gain, without temporaries."""
    gl, gr = pan_gains(pan)
    _axpy(buffer[0], x, gl * gain)
    _axpy(buffer[1], x, gr * gain)


@njit(cache=True)
def _axpy(y: np.ndarray, x: np.ndarray, a: float) -> None:
    for i in range(min(y.shape[0], x.shape[0])):
        y[i] += a * x[i]


@njit(cache=True)
def _mod_delay_kernel(x: np.ndarray, base: float, depth: float, w: float, phase: float) -> np.ndarray:
    n = x.shape[0]
    out = np.zeros(n)
    for i in range(n):
        pos = i - (base + depth * math.sin(w * i + phase))
        k = int(math.floor(pos))
        if k < 0 or k + 1 >= n:
            continue
        fr = pos - k
        out[i] = x[k] + (x[k + 1] - x[k]) * fr
    return out


def modulated_delay(x: np.ndarray, base_ms: float, depth_ms: float, rate_hz: float, phase: float = 0.0) -> np.ndarray:
    """Fractional delay with a slow sine LFO (chorus / unison doubling)."""
    return _mod_delay_kernel(
        np.ascontiguousarray(x, dtype=np.float64), base_ms * SR / 1000.0, depth_ms * SR / 1000.0, 2 * math.pi * rate_hz / SR, phase
    )


def place(buffer: np.ndarray, x: np.ndarray, start: int) -> None:
    """Add mono or stereo ``x`` into ``buffer`` at ``start`` (clipped to the buffer)."""
    if start >= buffer.shape[-1] or start + x.shape[-1] <= 0:
        return
    s0 = max(0, start)
    x0 = s0 - start
    n = min(buffer.shape[-1] - s0, x.shape[-1] - x0)
    if buffer.ndim == 1:
        buffer[s0 : s0 + n] += x[x0 : x0 + n]
    else:
        buffer[:, s0 : s0 + n] += x[..., x0 : x0 + n]


def ring_mod(x: np.ndarray, hz: float, mix: float = 0.5) -> np.ndarray:
    """Ring modulation (multiply by a sine carrier), blended with the dry signal."""
    t = np.arange(len(x)) / SR
    return x * (1.0 - mix) + x * np.sin(2 * math.pi * hz * t) * mix
