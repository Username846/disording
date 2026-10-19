"""Klatt-style formant singer.

Input: a list of sung syllables (phonemes + notes with absolute times). Output: a mono
voice track. Control parameters (formants, bandwidths, amplitudes, f0) are built as
piecewise-constant tracks at a control rate, smoothed (that smoothing *is* the
coarticulation), turned into resonator coefficients, and run through a per-sample
kernel: glottal pulse (Rosenberg) + aspiration → 5 cascaded formant resonators, plus a
parallel frication branch.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np
from numba import njit

from .. import dsp
from ..dsp import SR
from .g2p import PhoneSyllable
from .phonemes import CONSONANTS, base, is_vowel, vowel_formants

HOP = 32  # control-rate hop (samples)
CR = SR / HOP


@dataclass
class SungNote:
    t0: float
    t1: float
    midi: float
    vel: float = 1.0


@dataclass
class SungSyllable:
    phones: PhoneSyllable
    notes: list[SungNote]

    @property
    def start(self) -> float:
        return self.notes[0].t0

    @property
    def end(self) -> float:
        return self.notes[-1].t1


@dataclass
class VoiceParams:
    formant_scale: float = 1.0
    breath: float = 0.1
    tilt_hz: float = 3200.0
    open_quotient: float = 0.6
    vibrato_rate: float = 5.4
    vibrato_cents: float = 35.0
    vibrato_delay: float = 0.28
    jitter: float = 0.004
    shimmer: float = 0.03
    portamento: float = 0.06
    drift_cents: float = 4.0
    saw_source: bool = False
    whisper: bool = False
    quantize_pitch: bool = False
    consonant_boost: float = 1.25
    bandwidth_scale: float = 1.0
    air: float = 0.12  # high-frequency source energy above the formant cascade (breathy "air")
    # Clockwork character (wind-up toys): a slow periodic pitch/level wobble, and long
    # notes that droop in pitch at their end as if the spring were running down.
    wobble_rate: float = 0.0
    wobble_cents: float = 0.0
    wobble_amp: float = 0.0
    winddown_cents: float = 0.0
    extra: dict = field(default_factory=dict)


@dataclass
class _Seg:
    t0: float
    t1: float
    kind: str
    formants: tuple[float, float, float] | None = None
    formants_end: tuple[float, float, float] | None = None
    av: float = 0.0
    ah: float = 0.0
    af: float = 0.0
    fric_hz: float = 5000.0
    fric_bw: float = 3000.0
    nasal: bool = False
    vel: float = 1.0


# --------------------------------------------------------------------------- timing
def _cons_dur(phone: str) -> float:
    c = CONSONANTS.get(base(phone))
    if c is None:  # a folded vowel inside a coda
        return 0.09
    return c.dur + (0.012 + c.aspiration if c.kind == "stop" else 0.0) + (0.06 if c.kind == "affricate" else 0.0)


def _merge_melismas(sylls: list[SungSyllable]) -> list[SungSyllable]:
    out: list[SungSyllable] = []
    for s in sylls:
        if not s.phones.nucleus and out:
            prev = out[-1]
            out[-1] = SungSyllable(
                PhoneSyllable(prev.phones.onset, prev.phones.nucleus, s.phones.coda),
                prev.notes + s.notes,
            )
        else:
            out.append(s)
    return out


def _consonant_segs(phone: str, t0: float, t1: float, next_vowel: tuple[float, float, float] | None, boost: float) -> list[_Seg]:
    b = base(phone)
    if is_vowel(phone):
        f, _ = vowel_formants(phone)
        return [_Seg(t0, t1, "vowel", f, av=0.85)]
    c = CONSONANTS[b]
    d = t1 - t0
    if c.kind in ("sonorant", "nasal"):
        return [_Seg(t0, t1, c.kind, c.formants, av=c.av, nasal=c.kind == "nasal")]
    if c.kind == "fricative":
        return [_Seg(t0, t1, "fric", c.formants, av=c.av, af=c.af * boost, fric_hz=c.fric_hz, fric_bw=c.fric_bw)]
    if c.kind == "aspirate":
        return [_Seg(t0, t1, "asp", next_vowel, ah=0.6 * boost)]
    total = c.dur + 0.012 + c.aspiration + (0.06 if c.kind == "affricate" else 0.0)
    k = d / total
    closure = c.dur * k
    burst = 0.012 * k
    segs = [_Seg(t0, t0 + closure, "closure", c.formants, av=c.av)]
    tb = t0 + closure
    segs.append(_Seg(tb, tb + burst, "burst", c.formants, av=c.av, af=0.9 * boost, fric_hz=c.burst_hz, fric_bw=2500.0))
    tb += burst
    if c.kind == "affricate":
        segs.append(_Seg(tb, t1, "fric", c.formants, av=c.av, af=c.af * boost, fric_hz=c.fric_hz, fric_bw=c.fric_bw))
    elif c.aspiration > 0 and t1 > tb:
        segs.append(_Seg(tb, t1, "asp", next_vowel or c.formants, ah=0.5 * boost))
    return segs


def build_segments(sylls: list[SungSyllable], params: VoiceParams) -> tuple[list[_Seg], list[tuple[float, float, SungNote]]]:
    """Place phonemes in time. Onsets anticipate the beat; codas finish before the next
    onset; vowels keep at least ~40% of each note. Returns (segments, vowel note spans)."""
    sylls = _merge_melismas(sylls)
    onset_tot = [sum(_cons_dur(p) for p in s.phones.onset) for s in sylls]
    coda_tot = [sum(_cons_dur(p) for p in s.phones.coda) for s in sylls]
    onset_scale = [1.0] * len(sylls)
    coda_scale = [1.0] * len(sylls)
    for i, s in enumerate(sylls):
        span = s.end - s.start
        nxt_adjacent = i + 1 < len(sylls) and sylls[i + 1].start - s.end < 0.03
        need = coda_tot[i] + (onset_tot[i + 1] if nxt_adjacent else 0.0)
        min_vowel = max(0.05, 0.4 * span)
        if need > 0 and span - need < min_vowel:
            k = max(0.25, (span - min_vowel) / need)
            coda_scale[i] = k
            if nxt_adjacent:
                onset_scale[i + 1] = k
        if i == 0 or not (s.start - sylls[i - 1].end < 0.03):
            gap = s.start - (sylls[i - 1].end if i > 0 else -10.0)
            if onset_tot[i] > gap and onset_tot[i] > 0:
                onset_scale[i] = max(0.25, gap / onset_tot[i])

    segs: list[_Seg] = []
    spans: list[tuple[float, float, SungNote]] = []
    for i, s in enumerate(sylls):
        vf, vf_end = vowel_formants(s.phones.nucleus)
        # Onset.
        t = s.start - onset_tot[i] * onset_scale[i]
        for p in s.phones.onset:
            d = _cons_dur(p) * onset_scale[i]
            segs.extend(_consonant_segs(p, t, t + d, vf, params.consonant_boost))
            t += d
        # Vowel (all notes of the syllable).
        nxt_adjacent = i + 1 < len(sylls) and sylls[i + 1].start - s.end < 0.03
        boundary = s.end - (onset_tot[i + 1] * onset_scale[i + 1] if nxt_adjacent else 0.0)
        coda_d = coda_tot[i] * coda_scale[i]
        v0, v1 = s.start, max(s.start + 0.03, boundary - coda_d)
        if vf_end is not None:
            glide = min(0.15, max(0.05, 0.25 * (v1 - v0)))
            segs.append(_Seg(v0, v1 - glide, "vowel", vf, av=1.0))
            segs.append(_Seg(v1 - glide, v1, "vowel", vf_end, av=1.0))
        else:
            segs.append(_Seg(v0, v1, "vowel", vf, av=1.0))
        for note in s.notes:
            spans.append((max(note.t0, v0), min(note.t1, v1) if note is s.notes[-1] else note.t1, note))
        # Coda.
        t = v1
        for j, p in enumerate(s.phones.coda):
            d = _cons_dur(p) * coda_scale[i]
            segs.extend(_consonant_segs(p, t, t + d, None, params.consonant_boost))
            t += d
    return segs, spans


# --------------------------------------------------------------------------- tracks
def _smooth(x: np.ndarray, seconds: float) -> np.ndarray:
    w = max(1, int(seconds * CR))
    if w <= 1:
        return x
    kernel = np.hanning(w + 2)[1:-1]
    kernel /= kernel.sum()
    pad = np.pad(x, (w, w), mode="edge")
    return np.convolve(pad, kernel, mode="same")[w:-w]


def _ffill(x: np.ndarray) -> np.ndarray:
    """Forward-fill NaNs (back-fill the start)."""
    mask = np.isnan(x)
    if mask.all():
        return np.zeros_like(x)
    idx = np.where(~mask, np.arange(len(x)), 0)
    np.maximum.accumulate(idx, out=idx)
    out = x[idx]
    first = np.argmax(~mask)
    out[:first] = x[first]
    return out


def _frames(t0: float, t1: float, nf: int) -> slice:
    return slice(max(0, int(round(t0 * CR))), min(nf, int(round(t1 * CR))))


def _resonator_coeffs(f: np.ndarray, bw: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    T = 1.0 / SR
    c = -np.exp(-2 * math.pi * bw * T)
    b = 2 * np.exp(-math.pi * bw * T) * np.cos(2 * math.pi * f * T)
    a = 1 - b - c
    return a, b, c


@njit(cache=True)
def _kernel(
    n: int,
    hop: int,
    f0: np.ndarray,
    av: np.ndarray,
    ah: np.ndarray,
    af: np.ndarray,
    ra: np.ndarray,
    rb: np.ndarray,
    rc: np.ndarray,
    fb0: np.ndarray,
    fa1: np.ndarray,
    fa2: np.ndarray,
    tilt: float,
    oq: float,
    jitter: float,
    shimmer: float,
    saw: bool,
    seed: int,
    sr: float,
    air: float,
) -> np.ndarray:
    out = np.zeros(n)
    air_lp = 0.0
    air_c = 1.0 - math.exp(-2.0 * math.pi * 3500.0 / sr)
    nf = f0.shape[0]
    y1 = np.zeros(5)
    y2 = np.zeros(5)
    fx1 = 0.0
    fx2 = 0.0
    fy1 = 0.0
    fy2 = 0.0
    phase = 0.0
    jit = 1.0
    shim = 1.0
    tilt_state = 0.0
    hp_prev = 0.0
    state = np.uint64(seed * 2654435761 + 1)
    tp = 0.4 * oq / 0.6
    for i in range(n):
        fi = i / hop
        k = int(fi)
        if k >= nf - 1:
            k = nf - 2
            fr = 1.0
        else:
            fr = fi - k
        f = f0[k] + (f0[k + 1] - f0[k]) * fr
        a_v = av[k] + (av[k + 1] - av[k]) * fr
        a_h = ah[k] + (ah[k + 1] - ah[k]) * fr
        a_f = af[k] + (af[k + 1] - af[k]) * fr
        # xorshift noise, two uniform draws
        state ^= state << np.uint64(13)
        state ^= state >> np.uint64(7)
        state ^= state << np.uint64(17)
        u1 = (state >> np.uint64(11)) * (1.0 / 9007199254740992.0) - 0.5
        state ^= state << np.uint64(13)
        state ^= state >> np.uint64(7)
        state ^= state << np.uint64(17)
        u2 = (state >> np.uint64(11)) * (1.0 / 9007199254740992.0) - 0.5
        phase += f * jit / sr
        if phase >= 1.0:
            phase -= 1.0
            jit = 1.0 + jitter * u1 * 3.4
            shim = 1.0 + shimmer * u2 * 3.4
        if saw:
            dt = f / sr
            p = phase
            v = 2.0 * p - 1.0
            if p < dt:
                t = p / dt
                v -= t + t - t * t - 1.0
            elif p > 1.0 - dt:
                t = (p - 1.0) / dt
                v -= t * t + t + t + 1.0
            src = v * 0.5
            g = 0.5
        else:
            p = phase
            if p < tp:
                g = 0.5 * (1.0 - math.cos(math.pi * p / tp))
                src = 0.5 * math.pi / tp * math.sin(math.pi * p / tp)
            elif p < oq:
                x = 0.5 * math.pi * (p - tp) / (oq - tp)
                g = math.cos(x)
                src = -0.5 * math.pi / (oq - tp) * math.sin(x)
            else:
                g = 0.0
                src = 0.0
            src *= 0.125
        voiced = src * a_v * shim
        tilt_state += tilt * (voiced - tilt_state)
        asp = u1 * a_h * (0.35 + 0.65 * g)
        x = tilt_state + asp * 0.6 + (1e-18 if i & 1 else 3e-19)
        for j in range(5):
            idx = j * nf + k
            A = ra[idx] + (ra[idx + 1] - ra[idx]) * fr
            B = rb[idx] + (rb[idx + 1] - rb[idx]) * fr
            C = rc[idx] + (rc[idx + 1] - rc[idx]) * fr
            y = A * x + B * y1[j] + C * y2[j]
            y2[j] = y1[j]
            y1[j] = y
            x = y
        # Frication: high-passed noise through a band-pass.
        nz = u2 - 0.9 * hp_prev
        hp_prev = u2
        b0 = fb0[k] + (fb0[k + 1] - fb0[k]) * fr
        a1 = fa1[k] + (fa1[k + 1] - fa1[k]) * fr
        a2 = fa2[k] + (fa2[k + 1] - fa2[k]) * fr
        fin = nz * a_f + (1e-18 if i & 1 else 3e-19)
        fy = b0 * fin - b0 * fx2 - a1 * fy1 - a2 * fy2
        fx2 = fx1
        fx1 = fin
        fy2 = fy1
        fy1 = fy
        # "Air": the cascade rolls off steeply above F5; real voices keep some energy up
        # there, so add a little high-passed source back in.
        air_lp += air_c * (tilt_state - air_lp)
        out[i] = x + fy * 2.0 + air * (tilt_state - air_lp) * 6.0
    return out


def render(sylls: list[SungSyllable], params: VoiceParams, total_seconds: float, seed: int = 1, n_samples: int | None = None) -> np.ndarray:
    """Render the syllables to a mono track of ``total_seconds`` (or exactly ``n_samples``)."""
    n = n_samples if n_samples is not None else int(round(total_seconds * SR))
    nf = n // HOP + 2
    if not sylls:
        return np.zeros(n)
    segs, spans = build_segments(sylls, params)
    rng = np.random.default_rng(seed)

    nan = np.full(nf, np.nan)
    F = [nan.copy() for _ in range(3)]
    Bw = [np.full(nf, v) for v in (80.0, 100.0, 160.0)]
    av = np.zeros(nf)
    ah = np.zeros(nf)
    af = np.zeros(nf)
    fric_hz = nan.copy()
    fric_bw = nan.copy()
    for s in segs:
        sl = _frames(s.t0, s.t1, nf)
        if sl.stop <= sl.start:
            continue
        if s.formants is not None:
            for j in range(3):
                F[j][sl] = s.formants[j]
        if s.nasal:
            Bw[0][sl] = 170.0
            Bw[1][sl] = 220.0
            Bw[2][sl] = 260.0
        av[sl] = s.av
        ah[sl] = s.ah
        af[sl] = s.af
        if s.af > 0:
            fric_hz[sl] = s.fric_hz
            fric_bw[sl] = s.fric_bw

    # Pitch (semitones), vibrato depth and per-note dynamics.
    semis = nan.copy()
    vib = np.zeros(nf)
    dyn = np.ones(nf)
    for v0, v1, note in spans:
        sl = _frames(note.t0, note.t1, nf)
        midi = round(note.midi) if params.quantize_pitch else note.midi
        semis[sl] = midi
        length = v1 - v0
        if length > 0.3 and not params.quantize_pitch:
            t = np.arange(sl.start, sl.stop) / CR - note.t0
            vib[sl] = np.clip((t - params.vibrato_delay) / 0.3, 0.0, 1.0)
        if length > 0.6:
            t = (np.arange(sl.start, sl.stop) / CR - note.t0) / max(length, 1e-3)
            dyn[sl] = note.vel * (0.86 + 0.14 * np.sin(np.pi * np.clip(t * 1.1, 0, 1)))
        else:
            dyn[sl] = note.vel
    # Gaps (onset consonants, rests) take the pitch of the note that follows them.
    semis = _ffill(semis[::-1])[::-1]
    if not params.quantize_pitch:
        semis = _smooth(semis, params.portamento)
    t = np.arange(nf) / CR
    walk = np.cumsum(rng.standard_normal(nf // 64 + 2))
    walk = np.interp(np.arange(nf) / 64, np.arange(len(walk)), walk)
    walk = (walk - _smooth(walk, 1.5)) / 6.0
    rate = params.vibrato_rate * (1 + 0.03 * np.sin(2 * math.pi * 0.23 * t))
    vib_phase = 2 * math.pi * np.cumsum(rate) / CR
    cents = params.vibrato_cents * _smooth(vib, 0.05) * np.sin(vib_phase) + params.drift_cents * walk
    if params.wobble_rate > 0 and (params.wobble_cents > 0 or params.wobble_amp > 0):
        wob_phase = 2 * math.pi * params.wobble_rate * t
        cents = cents + params.wobble_cents * np.sin(wob_phase)
        dyn = dyn * (1.0 - params.wobble_amp * 0.5 * (1.0 + np.cos(wob_phase)))
    if params.winddown_cents > 0:
        droop = np.zeros(nf)
        for v0, v1, _note in spans:
            length = v1 - v0
            if length > 0.45:
                sl = _frames(v0 + 0.55 * length, v1, nf)
                if sl.stop > sl.start:
                    k = np.linspace(0.0, 1.0, sl.stop - sl.start)
                    droop[sl] = np.minimum(droop[sl], -params.winddown_cents * k**2)
        cents = cents + _smooth(droop, 0.03)
    f0 = 440.0 * 2 ** ((semis - 69 + cents / 100.0) / 12)

    scale = params.formant_scale
    Fs = [_smooth(_ffill(F[j]), 0.035) * scale for j in range(3)]
    # Sopranos open F1 to sit above the pitch on high notes (formant tuning).
    Fs[0] = np.maximum(Fs[0], f0 * 1.1)
    Fs[1] = np.maximum(Fs[1], Fs[0] + 250.0)
    Fs[2] = np.maximum(Fs[2], Fs[1] + 300.0)
    F4 = np.full(nf, 3350.0 * scale)
    F5 = np.full(nf, 3900.0 * scale)
    Fs += [np.maximum(F4, Fs[2] + 300.0), np.maximum(F5, Fs[2] + 700.0)]
    bws = [_smooth(Bw[0], 0.02), _smooth(Bw[1], 0.02), _smooth(Bw[2], 0.02), np.full(nf, 250.0), np.full(nf, 320.0)]
    bws = [b * params.bandwidth_scale * (0.85 + 0.15 * scale) for b in bws]
    ra = np.empty((5, nf))
    rb = np.empty((5, nf))
    rc = np.empty((5, nf))
    for j in range(5):
        fj = np.minimum(Fs[j], SR * 0.45)
        ra[j], rb[j], rc[j] = _resonator_coeffs(fj, bws[j])

    av_s = _smooth(av, 0.014) * dyn
    if params.whisper:
        ah_s = _smooth(np.maximum(ah, av * 0.9), 0.014) * dyn
        av_s = av_s * 0.0
    else:
        ah_s = _smooth(ah + av * params.breath, 0.014)
    af_s = _smooth(af, 0.005)
    fhz = _smooth(_ffill(fric_hz), 0.005) * min(scale, 1.15)
    fbw = _smooth(_ffill(fric_bw), 0.005)
    w0 = 2 * math.pi * np.minimum(fhz, SR * 0.45) / SR
    q = np.maximum(fhz / np.maximum(fbw, 50.0), 0.5)
    alpha = np.sin(w0) / (2 * q)
    fb0 = alpha / (1 + alpha)
    fa1 = -2 * np.cos(w0) / (1 + alpha)
    fa2 = (1 - alpha) / (1 + alpha)

    tilt = 1.0 - math.exp(-2 * math.pi * params.tilt_hz / SR)
    out = _kernel(
        n,
        HOP,
        f0.astype(np.float64),
        av_s,
        ah_s,
        af_s,
        ra.ravel(),
        rb.ravel(),
        rc.ravel(),
        fb0,
        fa1,
        fa2,
        tilt,
        params.open_quotient,
        params.jitter,
        params.shimmer,
        params.saw_source,
        int(seed),
        float(SR),
        float(params.air),
    )
    return dsp.filt(out, "highpass", 90.0, 0.7)
