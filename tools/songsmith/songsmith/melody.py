"""Melody and note-line notation.

Melody tokens (sung):  ``syllable:pitch:beats``
  * ``_:beats`` (or ``_:x:beats``) is a rest.
  * ``-:pitch:beats`` continues the previous syllable on a new pitch (melisma).
  * A trailing hyphen joins a word across notes: ``o-:C5:1 pen:D5:1`` sings "open".
  * ``text{PH ON EMES}`` overrides the pronunciation of that syllable (ARPAbet).
  * Lyric lines are separated by `` / `` or newlines (they become caption lines).

Instrument lines (unsung): ``pitch:beats`` tokens, ``_:beats`` rests, ``C4+E4:1`` dyads.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from fractions import Fraction

from .theory import note_to_midi

_OVERRIDE_RE = re.compile(r"^(.*?)\{([^}]*)\}(-?)$")
_TOKEN_RE = re.compile(r"(?:[^\s{]|\{[^}]*\})+")  # whitespace-separated, but {AH0 N} stays whole


def parse_beats(text: str) -> float:
    text = text.strip()
    if "/" in text:
        return float(Fraction(text))
    return float(text)


@dataclass
class MelodyNote:
    start: float  # beats from the melody start
    beats: float
    midi: int | None  # None = rest
    syllable: int = -1  # index into Melody.syllables, -1 for rests


@dataclass
class Syllable:
    text: str  # display text without the joining hyphen
    word: int
    notes: list[int] = field(default_factory=list)
    override: list[str] | None = None


@dataclass
class Word:
    text: str
    syllables: list[int]
    line: int


@dataclass
class LyricLine:
    words: list[int]
    start: float = 0.0
    end: float = 0.0

    def text(self, melody: "Melody") -> str:
        return " ".join(melody.words[w].text for w in self.words)


@dataclass
class Melody:
    notes: list[MelodyNote] = field(default_factory=list)
    syllables: list[Syllable] = field(default_factory=list)
    words: list[Word] = field(default_factory=list)
    lines: list[LyricLine] = field(default_factory=list)

    @property
    def length(self) -> float:
        return max((n.start + n.beats for n in self.notes), default=0.0)

    def sung_notes(self) -> list[MelodyNote]:
        return [n for n in self.notes if n.midi is not None]


def _split_lines(text: str) -> list[str]:
    raw = re.split(r"\s/\s|\n", text.strip())
    return [r.strip() for r in raw if r.strip()]


def parse_melody(text: str | None) -> Melody:
    melody = Melody()
    if not text:
        return melody
    position = 0.0
    joining = False  # previous syllable ended with "-": next one belongs to the same word
    for line_index, line_text in enumerate(_split_lines(text)):
        line = LyricLine(words=[])
        line_started = False
        for token in _TOKEN_RE.findall(line_text):
            parts = token.split(":")
            if parts[0] == "_":
                if len(parts) not in (2, 3):
                    raise ValueError(f"Bad rest token {token!r}")
                beats = parse_beats(parts[-1])
                melody.notes.append(MelodyNote(position, beats, None))
                position += beats
                continue
            if len(parts) != 3:
                raise ValueError(f"Bad melody token {token!r} (want syllable:pitch:beats)")
            syl_text, pitch, beats_text = parts
            beats = parse_beats(beats_text)
            midi = note_to_midi(pitch)
            if syl_text == "-":
                if not melody.syllables:
                    raise ValueError("Melisma '-' with no previous syllable")
                index = len(melody.notes)
                melody.notes.append(MelodyNote(position, beats, midi, len(melody.syllables) - 1))
                melody.syllables[-1].notes.append(index)
                position += beats
                if line_started:
                    line.end = position
                continue
            override = None
            m = _OVERRIDE_RE.match(syl_text)
            if m:
                syl_text = m.group(1) + m.group(3)
                override = m.group(2).split()
            continues = syl_text.endswith("-") and len(syl_text) > 1
            display = syl_text[:-1] if continues else syl_text
            if joining and melody.words:
                word_index = len(melody.words) - 1
                melody.words[word_index].text += display
            else:
                word_index = len(melody.words)
                melody.words.append(Word(display, [], line_index))
                line.words.append(word_index)
            syllable_index = len(melody.syllables)
            melody.syllables.append(Syllable(display, word_index, [len(melody.notes)], override))
            melody.words[word_index].syllables.append(syllable_index)
            if not line_started:
                line.start = position
                line_started = True
            melody.notes.append(MelodyNote(position, beats, midi, syllable_index))
            position += beats
            line.end = position
            joining = continues
        if line.words:
            melody.lines.append(line)
    return melody


@dataclass
class LineNote:
    start: float
    beats: float
    midis: tuple[int, ...]  # empty = rest


def parse_line(text: str | None) -> list[LineNote]:
    """Instrument line: ``C5:1 D5:0.5 _:1 C4+E4:2``."""
    notes: list[LineNote] = []
    if not text:
        return notes
    position = 0.0
    for token in text.replace("/", " ").split():
        pitch, _, beats_text = token.rpartition(":")
        beats = parse_beats(beats_text)
        if pitch in ("_", ""):
            notes.append(LineNote(position, beats, ()))
        else:
            notes.append(LineNote(position, beats, tuple(note_to_midi(p) for p in pitch.split("+"))))
        position += beats
    return notes
