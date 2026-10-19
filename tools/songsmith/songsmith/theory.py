"""Pitch names, chords and keys."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

_PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
_NOTE_RE = re.compile(r"^([A-Ga-g])([#b]*)(-?\d+)$")
_ROOT_RE = re.compile(r"^([A-G])([#b]?)")

CHORD_QUALITIES: dict[str, tuple[int, ...]] = {
    "": (0, 4, 7),
    "maj": (0, 4, 7),
    "M": (0, 4, 7),
    "m": (0, 3, 7),
    "min": (0, 3, 7),
    "-": (0, 3, 7),
    "7": (0, 4, 7, 10),
    "maj7": (0, 4, 7, 11),
    "M7": (0, 4, 7, 11),
    "m7": (0, 3, 7, 10),
    "min7": (0, 3, 7, 10),
    "m7b5": (0, 3, 6, 10),
    "dim": (0, 3, 6),
    "dim7": (0, 3, 6, 9),
    "aug": (0, 4, 8),
    "+": (0, 4, 8),
    "sus2": (0, 2, 7),
    "sus4": (0, 5, 7),
    "sus": (0, 5, 7),
    "7sus4": (0, 5, 7, 10),
    "add9": (0, 4, 7, 14),
    "madd9": (0, 3, 7, 14),
    "6": (0, 4, 7, 9),
    "m6": (0, 3, 7, 9),
    "9": (0, 4, 7, 10, 14),
    "maj9": (0, 4, 7, 11, 14),
    "m9": (0, 3, 7, 10, 14),
    "5": (0, 7),
}

SCALES: dict[str, tuple[int, ...]] = {
    "major": (0, 2, 4, 5, 7, 9, 11),
    "minor": (0, 2, 3, 5, 7, 8, 10),
    "dorian": (0, 2, 3, 5, 7, 9, 10),
    "mixolydian": (0, 2, 4, 5, 7, 9, 10),
    "harmonic_minor": (0, 2, 3, 5, 7, 8, 11),
    "pentatonic": (0, 2, 4, 7, 9),
    "minor_pentatonic": (0, 3, 5, 7, 10),
}


def _accidental(acc: str) -> int:
    return acc.count("#") - acc.count("b")


def note_to_midi(name: str) -> int:
    """``"C4"`` → 60, ``"Bb3"`` → 58, ``"F#5"`` → 78."""
    m = _NOTE_RE.match(name.strip())
    if not m:
        raise ValueError(f"Bad note name: {name!r}")
    letter, acc, octave = m.groups()
    return 12 * (int(octave) + 1) + _PC[letter.upper()] + _accidental(acc)


def pitch_class(name: str) -> int:
    m = _ROOT_RE.match(name.strip())
    if not m:
        raise ValueError(f"Bad pitch class: {name!r}")
    return (_PC[m.group(1)] + _accidental(m.group(2))) % 12


def midi_to_hz(midi: float) -> float:
    return 440.0 * 2.0 ** ((midi - 69.0) / 12.0)


@dataclass(frozen=True)
class Chord:
    root: int  # pitch class
    intervals: tuple[int, ...]
    bass: int  # pitch class of the bass note (slash chords)
    symbol: str = ""

    @property
    def pitch_classes(self) -> tuple[int, ...]:
        return tuple(sorted({(self.root + i) % 12 for i in self.intervals}))

    def tones_in_range(self, low: int, high: int) -> list[int]:
        """Every MIDI note between low and high (inclusive) that belongs to the chord."""
        pcs = set(self.pitch_classes)
        return [m for m in range(low, high + 1) if m % 12 in pcs]

    def voicing(self, center: int = 60, spread: int = 0) -> list[int]:
        """Close voicing of the chord tones nearest ``center`` (plus extensions above)."""
        base = center - 6
        notes = []
        for interval in self.intervals:
            pc = (self.root + interval) % 12
            note = base + ((pc - base) % 12)
            if interval >= 12:
                note += 12 if note < center else 0
            notes.append(note + (12 * spread if interval >= 12 else 0))
        return sorted(set(notes))


def parse_chord(symbol: str) -> Chord:
    s = symbol.strip()
    bass_pc = None
    if "/" in s:
        s, bass = s.split("/", 1)
        bass_pc = pitch_class(bass)
    m = _ROOT_RE.match(s)
    if not m:
        raise ValueError(f"Bad chord: {symbol!r}")
    root = pitch_class(m.group(0))
    quality = s[m.end():]
    if quality not in CHORD_QUALITIES:
        raise ValueError(f"Unknown chord quality {quality!r} in {symbol!r}")
    return Chord(root, CHORD_QUALITIES[quality], root if bass_pc is None else bass_pc, symbol.strip())


@dataclass(frozen=True)
class ChordSpan:
    start: float  # beats from section start
    length: float  # beats
    chord: Chord


def parse_chord_line(line: str, beats_per_bar: int = 4) -> list[ChordSpan]:
    """``"F | Dm | Gm7 C7 | F"`` → spans. Chords inside one bar split it evenly.

    ``%`` repeats the previous chord; a bar may hold 1–4 chords.
    """
    spans: list[ChordSpan] = []
    bars = [b.strip() for b in line.replace("\n", " ").split("|")]
    bars = [b for b in bars if b]
    previous: Chord | None = None
    for index, bar in enumerate(bars):
        symbols = bar.split()
        per = beats_per_bar / len(symbols)
        for j, sym in enumerate(symbols):
            if sym == "%":
                if previous is None:
                    raise ValueError("'%' with no previous chord")
                chord = previous
            else:
                chord = parse_chord(sym)
            previous = chord
            spans.append(ChordSpan(index * beats_per_bar + j * per, per, chord))
    return spans


@dataclass(frozen=True)
class Key:
    tonic: int
    mode: str = "major"
    scale: tuple[int, ...] = field(default=SCALES["major"])

    def degree_pc(self, degree: int) -> int:
        return (self.tonic + self.scale[degree % len(self.scale)]) % 12

    def scale_notes(self, low: int, high: int) -> list[int]:
        pcs = {(self.tonic + i) % 12 for i in self.scale}
        return [m for m in range(low, high + 1) if m % 12 in pcs]


def parse_key(text: str) -> Key:
    """``"F major"``, ``"D minor"``, ``"Bb mixolydian"``."""
    parts = text.split()
    tonic = pitch_class(parts[0])
    mode = parts[1].lower() if len(parts) > 1 else "major"
    if mode not in SCALES:
        raise ValueError(f"Unknown mode {mode!r}")
    return Key(tonic, mode, SCALES[mode])
