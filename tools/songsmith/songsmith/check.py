"""Automated QA for rendered bundles (``python -m songsmith check``)."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np

from . import dsp, mixer, ogg
from .bundle import read_bundle
from .dsp import SR
from .paths import bundle_id_for
from .spec import load_song

MAX_BUNDLE_BYTES = int(3.5 * 1024 * 1024)
EXEMPT_FROM_SIGNATURE = {"day_000"}  # debug fixtures: no signature/verse-count rules


@dataclass
class Report:
    bundle_id: str
    ok: bool = True
    lines: list[str] = field(default_factory=list)

    def check(self, passed: bool, label: str, detail: str) -> None:
        self.lines.append(f"  [{'ok' if passed else 'FAIL'}] {label}: {detail}")
        self.ok &= passed


def seam_metrics(audio: np.ndarray, loop_start: float) -> tuple[float, float]:
    """(jump ratio, flux ratio) at the wrap point from the file end back to loop_start.

    jump ratio: |sample step across the seam| / 99.9th percentile of |sample steps|.
    flux ratio: spectral flux across the seam / flux at the same musical position when the
    file plays through from the start (the natural transition into loop_start)."""
    mono = audio.mean(axis=0)
    s0 = int(round(loop_start * SR))
    steps = np.abs(np.diff(mono))
    ref_step = float(np.percentile(steps, 99.9)) + 1e-9
    jump = abs(mono[s0] - mono[-1]) / ref_step

    win = 2048

    def spec(x: np.ndarray) -> np.ndarray:
        return np.abs(np.fft.rfft(x * np.hanning(len(x))))

    def flux(a: np.ndarray, b: np.ndarray) -> float:
        return float(np.sum(np.maximum(spec(b) - spec(a), 0)))

    before_wrap = mono[-win:]
    after_wrap = mono[s0 : s0 + win]
    wrap_flux = flux(before_wrap, after_wrap)
    if s0 >= win:
        natural = flux(mono[s0 - win : s0], after_wrap)
    else:
        natural = float(np.median([flux(mono[k : k + win], mono[k + win : k + 2 * win]) for k in range(0, len(mono) - 2 * win, len(mono) // 50)]))
    return jump, wrap_flux / (natural + 1e-9)


def check_spec(spec_path: Path, out_dir: Path, signature_owners: dict[str, list[str]]) -> Report:
    song = load_song(spec_path)
    bundle_id = bundle_id_for(spec_path)
    report = Report(bundle_id)
    found = read_bundle(out_dir, bundle_id)
    if found is None:
        report.check(False, "bundle", "not rendered (run `songsmith render`)")
        return report
    zf, entry = found
    names = set(zf.namelist())
    required = {"meta.json", "music.ogg", "lyrics.json", "beats.json"}
    required |= {f"{n}.ogg" for n in song.stingers} | {f"sfx/{n}.ogg" for n in song.sfx}
    missing = sorted(required - names)
    report.check(not missing, "contents", "complete" if not missing else f"missing {missing}")
    meta = json.loads(zf.read("meta.json"))
    report.check(entry["bytes"] <= MAX_BUNDLE_BYTES, "size", f"{entry['bytes'] / 1e6:.2f} MB (max {MAX_BUNDLE_BYTES / 1e6:.2f})")

    audio, sr = ogg.decode(zf.read("music.ogg"))
    report.check(sr == SR and audio.shape[0] == 2, "format", f"{audio.shape[0]} ch @ {sr} Hz")
    minutes = audio.shape[1] / SR / 60
    lo, hi = song.target_minutes * 0.85, song.target_minutes * 1.15
    report.check(lo <= minutes <= hi, "duration", f"{minutes:.2f} min (target {song.target_minutes:.2f} ±15%)")
    lufs = mixer.loudness(audio)
    report.check(abs(lufs + 16.0) <= 1.0, "loudness", f"{lufs:.2f} LUFS (target -16 ±1)")
    tp = mixer.true_peak_db(audio)
    report.check(tp <= -1.0 + 0.15, "true peak", f"{tp:.2f} dBTP (max -1.0)")

    frame = dsp.samples(0.05)
    k = audio.shape[1] // frame
    rms = np.sqrt(np.mean(audio[:, : k * frame].reshape(2, k, frame) ** 2, axis=(0, 2)))
    silent = rms < dsp.db(-60.0)
    longest = run = 0
    for s in silent:
        run = run + 1 if s else 0
        longest = max(longest, run)
    report.check(longest * 0.05 <= 2.0, "silence", f"longest gap {longest * 0.05:.2f} s (max 2.0)")

    jump, flux_ratio = seam_metrics(audio, meta["loop_start"])
    report.check(jump <= 1.5 and flux_ratio <= 2.0, "loop seam", f"jump ×{jump:.2f} of p99.9 step, flux ×{flux_ratio:.2f} of natural")

    vocal = meta.get("vocal_db_by_section", {})
    verses = [name for name, level in vocal.items() if name.split("@")[0].startswith("verse") and level > -45.0]
    distinct = {name.split("@")[0] for name in verses}
    if bundle_id in EXEMPT_FROM_SIGNATURE:  # debug fixtures only need to sing something
        sung = [name for name, level in vocal.items() if level > -45.0]
        report.check(bool(sung), "vocals", f"sung sections: {sorted(sung) or 'none'}")
    else:
        report.check(len(distinct) >= 2, "vocals", f"sung verse sections: {sorted(distinct) or 'none'}")
    lyrics = json.loads(zf.read("lyrics.json"))["lines"]
    report.check(len(lyrics) > 0, "lyrics", f"{len(lyrics)} caption lines")

    if bundle_id not in EXEMPT_FROM_SIGNATURE:
        sig = [i.patch for i in song.instruments.values() if i.signature]
        report.check(len(sig) == 1, "signature", sig[0] if sig else "no instrument marked signature: true")
        for patch in sig:
            owners = [o for o in signature_owners.get(patch, []) if o != bundle_id]
            report.check(not owners, "signature unique", f"{patch} also signature of {owners}" if owners else f"{patch} unique")
    for name in song.stingers:
        st, _ = ogg.decode(zf.read(f"{name}.ogg"))
        report.check(0.5 <= st.shape[1] / SR <= 12.0, f"stinger {name}", f"{st.shape[1] / SR:.2f} s")
    for name in song.sfx:
        sx, _ = ogg.decode(zf.read(f"sfx/{name}.ogg"))
        peak = float(np.max(np.abs(sx))) if sx.size else 0.0
        report.check(sx.shape[1] > 0 and peak > 0.05, f"sfx {name}", f"{sx.shape[1] / SR:.2f} s, peak {dsp.to_db(peak):.1f} dB")
    return report


def signature_owners(specs: list[Path]) -> dict[str, list[str]]:
    owners: dict[str, list[str]] = {}
    for spec in specs:
        bid = bundle_id_for(spec)
        if bid in EXEMPT_FROM_SIGNATURE:
            continue
        for inst in load_song(spec).instruments.values():
            if inst.signature:
                owners.setdefault(inst.patch, []).append(bid)
    return owners
