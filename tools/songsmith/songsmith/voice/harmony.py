"""Derive alto, tenor and bass lines from a melody and its chords (hymn-style
homophony with simple voice-leading)."""

from __future__ import annotations

from ..theory import Chord

RANGES = {"alto": (55, 74), "tenor": (48, 67), "bass": (40, 60)}  # G3–D5, C3–G4, E2–C4


def harmonize(melody: list[int | None], chords: list[Chord | None]) -> dict[str, list[int | None]]:
    """``melody``: soprano MIDI per sung note (None = rest). Returns per-part MIDI lists."""
    parts: dict[str, list[int | None]] = {"alto": [], "tenor": [], "bass": []}
    prev = {"alto": None, "tenor": None, "bass": None}
    for s, chord in zip(melody, chords):
        if s is None or chord is None:
            for p in parts:
                parts[p].append(None)
            continue
        used = {s % 12}
        upper = s
        for part in ("alto", "tenor", "bass"):
            lo, hi = RANGES[part]
            if part == "bass":
                cands = [m for m in range(lo, hi + 1) if m % 12 == chord.bass]
                cands = [m for m in cands if m <= upper - 3] or cands
            else:
                cands = [m for m in chord.tones_in_range(lo, min(hi, upper - 2))]
                if not cands:
                    cands = chord.tones_in_range(lo, hi)
            target = prev[part] if prev[part] is not None else (upper - 4 if part != "bass" else (lo + hi) // 2)

            def score(m: int) -> float:
                penalty = 0.0
                if part != "bass" and m % 12 in used:
                    penalty += 3.5
                if upper - m < 3:
                    penalty += 4.0
                if part != "bass" and (m % 12) == chord.root and len(used) == 1:
                    penalty -= 0.5
                return abs(m - target) + penalty

            choice = min(cands, key=score)
            parts[part].append(choice)
            prev[part] = choice
            used.add(choice % 12)
            upper = choice
    return parts
