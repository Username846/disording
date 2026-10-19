"""Accompaniment patterns: turn a part spec + chords into note events.

Every pattern returns ``PatternNote``s with beats relative to the section start.
Common part options: ``octave``, ``vel``, ``legato`` (fraction of the slot a note
lasts), ``rate`` (beats per note for arpeggios), ``humanize`` (random velocity spread),
``bars`` (list of 1-based bars to play in; default all).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import numpy as np

from .melody import Melody, parse_line
from .theory import ChordSpan, Key

GRID_VEL = {"x": 0.8, "X": 1.0, "o": 0.45, "*": 0.65}


@dataclass
class PatternNote:
    beat: float
    beats: float
    midi: float | None
    vel: float
    piece: str | None = None
    overrides: dict[str, Any] = field(default_factory=dict)


def _note(pc: int, octave: int) -> int:
    return 12 * (octave + 1) + pc


def _near(pc: int, around: int) -> int:
    """MIDI note with pitch class ``pc`` closest to ``around``."""
    base = around - 6
    return base + ((pc - base) % 12)


def _bars_filter(part: dict[str, Any], beat: float, bpb: int) -> bool:
    bars = part.get("bars")
    if not bars:
        return True
    return int(beat // bpb) + 1 in set(bars)


def generate(
    part: dict[str, Any],
    octave: int,
    spans: list[ChordSpan],
    total_beats: float,
    bpb: int,
    key: Key,
    melody: Melody | None,
    melodies: dict[str, Melody],
    rng: np.random.Generator,
) -> list[PatternNote]:
    octave = int(part.get("octave", octave))
    vel = float(part.get("vel", 0.8))
    legato = float(part.get("legato", 0.95))
    notes: list[PatternNote] = []
    pattern = part.get("pattern")

    if "grid" in part:
        grids = part["grid"] if isinstance(part["grid"], dict) else {None: part["grid"]}
        bars = int(round(total_beats / bpb))
        for piece, grid in grids.items():
            bar_grids = [g.strip() for g in str(grid).split("|") if g.strip()]
            for bar in range(bars):
                g = bar_grids[bar % len(bar_grids)]
                steps = len(g)
                for s, ch in enumerate(g):
                    if ch in GRID_VEL:
                        beat = bar * bpb + s * bpb / steps
                        notes.append(PatternNote(beat, bpb / steps, None, GRID_VEL[ch] * vel, piece))
    elif "line" in part:
        line = parse_line(part["line"])
        length = sum(n.beats for n in line) or total_beats
        reps = max(1, int(np.ceil(total_beats / length - 1e-6))) if part.get("repeat", True) else 1
        shift = 12 * int(part.get("shift", 0))
        for r in range(reps):
            for ln in line:
                for m in ln.midis:
                    notes.append(PatternNote(r * length + ln.start, ln.beats * legato, m + shift, vel))
    elif "melody_of" in part or part.get("melody_double"):
        src = melodies.get(part["melody_of"]) if "melody_of" in part else melody
        if src is None:
            raise ValueError(f"melody_of: unknown section {part.get('melody_of')!r}")
        shift = 12 * int(part.get("octave_shift", 0))
        for n in src.notes:
            if n.midi is not None:
                notes.append(PatternNote(n.start, n.beats * legato, n.midi + shift, vel))
    elif pattern in ("root", "root_fifth_2feel", "walking", "pedal"):
        center = _note(0, octave) + 7
        for i, span in enumerate(spans):
            root = _near(span.chord.bass, center)
            fifth = _near((span.chord.root + 7) % 12, root + 4)
            if pattern in ("root", "pedal"):
                notes.append(PatternNote(span.start, span.length * legato, root, vel))
            elif pattern == "root_fifth_2feel":
                half = 2.0
                k = 0
                b = span.start
                while b < span.start + span.length - 1e-6:
                    length = min(half, span.start + span.length - b)
                    notes.append(PatternNote(b, length * legato, root if k % 2 == 0 else fifth, vel * (1.0 if k % 2 == 0 else 0.85)))
                    b += half
                    k += 1
            else:  # walking: root, chord tone, chord tone, approach to the next root
                nxt = spans[(i + 1) % len(spans)].chord.bass
                tones = [(span.chord.root + iv) % 12 for iv in span.chord.intervals]
                beats = int(round(span.length))
                for k in range(beats):
                    if k == 0:
                        m = root
                    elif k == beats - 1 and beats > 1:
                        target = _near(nxt, root)
                        m = target - 1 if rng.random() < 0.6 else target + 1
                    else:
                        m = _near(tones[k % len(tones)], root + 5)
                    notes.append(PatternNote(span.start + k, 0.9, m, vel * (1.0 if k == 0 else 0.82)))
    elif pattern in ("block", "pad_sustain", "comp_offbeat", "chord_bells"):
        center = _note(int(part.get("center_pc", 6)), octave)
        for span in spans:
            voicing = span.chord.voicing(center)
            if pattern == "pad_sustain":
                for m in voicing:
                    notes.append(PatternNote(span.start, span.length * 1.0, m, vel))
            elif pattern == "block":
                b = span.start
                while b < span.start + span.length - 1e-6:
                    length = min(bpb, span.start + span.length - b)
                    for m in voicing:
                        notes.append(PatternNote(b, length * legato, m, vel))
                    b += bpb
            elif pattern == "comp_offbeat":
                b = span.start + 0.5
                while b < span.start + span.length - 1e-6:
                    for m in voicing:
                        notes.append(PatternNote(b, 0.3, m, vel * (0.9 + 0.1 * rng.random())))
                    b += 1.0
            else:  # chord_bells: tones rung one after another, low to high
                step = float(part.get("rate", 0.5))
                for k, m in enumerate(voicing + [voicing[0] + 12]):
                    if span.start + k * step < span.start + span.length:
                        notes.append(PatternNote(span.start + k * step, span.length - k * step, m, vel * (1.0 - 0.06 * k)))
    elif pattern in ("arp_up", "arp_updown", "arp_down"):
        rate = float(part.get("rate", 0.5))
        center = _note(int(part.get("center_pc", 0)), octave)
        for span in spans:
            tones = span.chord.voicing(center)
            tones = tones + [t + 12 for t in tones]
            if pattern == "arp_down":
                seq = tones[::-1]
            elif pattern == "arp_updown":
                seq = tones + tones[-2:0:-1]
            else:
                seq = tones
            k = 0
            b = span.start
            while b < span.start + span.length - 1e-6:
                notes.append(PatternNote(b, rate * float(part.get("ring", 1.6)), seq[k % len(seq)], vel * (1.0 if k % 4 == 0 else 0.85)))
                b += rate
                k += 1
    elif pattern == "rounds":
        # Change-ringing "rounds": the scale rung top to bottom, over and over.
        rate = float(part.get("rate", 0.5))
        count = int(part.get("bells", 8))
        scale = key.scale_notes(_note(key.tonic, octave), _note(key.tonic, octave + 1))
        bells = sorted(scale)[-count:][::-1]
        k = 0
        b = 0.0
        while b < total_beats - 1e-6:
            notes.append(PatternNote(b, rate * 3, bells[k % len(bells)], vel * (1.0 if k % len(bells) == 0 else 0.85)))
            b += rate
            k += 1
    elif pattern in ("hold", "none", None):
        pass
    else:
        raise ValueError(f"Unknown pattern {pattern!r}")

    hum = float(part.get("humanize", 0.0))
    out = []
    for n in notes:
        if n.beat >= total_beats - 1e-6 or not _bars_filter(part, n.beat, bpb):
            continue
        if hum > 0:
            n.vel *= 1.0 + rng.uniform(-hum, hum)
        out.append(n)
    return out
