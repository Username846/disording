"""Lyrics → ARPAbet: CMUdict lookup, a small letter-to-sound fallback, and alignment of
pronunciations to the melody's sung syllables."""

from __future__ import annotations

import gzip
import re
from dataclasses import dataclass, field
from functools import lru_cache

from ..paths import VENDOR_DIR
from .phonemes import LEGAL_ONSETS, base, is_vowel, stress


@lru_cache(maxsize=1)
def cmudict() -> dict[str, list[list[str]]]:
    words: dict[str, list[list[str]]] = {}
    with gzip.open(VENDOR_DIR / "cmudict.dict.gz", "rt", encoding="utf-8") as handle:
        for line in handle:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            head, *phones = line.split()
            word = re.sub(r"\(\d+\)$", "", head)
            words.setdefault(word, []).append(phones)
    return words


def normalize(word: str) -> str:
    return re.sub(r"[^a-z']", "", word.lower()).strip("'")


# --------------------------------------------------------------------------- fallback
_DIGRAPHS = [
    ("tch", ["CH"]), ("igh", ["AY1"]), ("th", ["TH"]), ("sh", ["SH"]), ("ch", ["CH"]), ("ph", ["F"]),
    ("ng", ["NG"]), ("ck", ["K"]), ("qu", ["K", "W"]), ("wh", ["W"]), ("ee", ["IY1"]), ("ea", ["IY1"]),
    ("oo", ["UW1"]), ("ai", ["EY1"]), ("ay", ["EY1"]), ("oa", ["OW1"]), ("ow", ["OW1"]), ("ou", ["AW1"]),
    ("oi", ["OY1"]), ("oy", ["OY1"]), ("ew", ["UW1"]), ("ie", ["IY1"]), ("au", ["AO1"]), ("aw", ["AO1"]),
    ("er", ["ER0"]), ("ir", ["ER1"]), ("ur", ["ER1"]), ("ar", ["AA1", "R"]), ("or", ["AO1", "R"]),
]
_SINGLE = {
    "a": ["AE1"], "e": ["EH1"], "i": ["IH1"], "o": ["AA1"], "u": ["AH1"], "b": ["B"], "c": ["K"], "d": ["D"],
    "f": ["F"], "g": ["G"], "h": ["HH"], "j": ["JH"], "k": ["K"], "l": ["L"], "m": ["M"], "n": ["N"],
    "p": ["P"], "q": ["K"], "r": ["R"], "s": ["S"], "t": ["T"], "v": ["V"], "w": ["W"], "x": ["K", "S"],
    "y": ["Y"], "z": ["Z"],
}
_LONG = {"a": "EY1", "e": "IY1", "i": "AY1", "o": "OW1", "u": "UW1"}


def letter_to_sound(word: str) -> list[str]:
    """Crude English letter-to-sound rules for words missing from CMUdict."""
    w = normalize(word).replace("'", "")
    if not w:
        return []
    magic_e = len(w) >= 3 and w.endswith("e") and w[-2] not in "aeiou" and w[-3] in "aeiou"
    if magic_e:
        w = w[:-1]
    phones: list[str] = []
    i = 0
    while i < len(w):
        for graph, ph in _DIGRAPHS:
            if w.startswith(graph, i):
                phones.extend(ph)
                i += len(graph)
                break
        else:
            ch = w[i]
            nxt = w[i + 1] if i + 1 < len(w) else ""
            if magic_e and i == len(w) - 2 and ch in _LONG:
                phones.append(_LONG[ch])
            elif ch == "c" and nxt in ("e", "i", "y"):
                phones.append("S")
            elif ch == "g" and nxt in ("e", "i"):
                phones.append("JH")
            elif ch == "y":
                phones.append("Y" if i == 0 else ("IY0" if i == len(w) - 1 else "IH1"))
            elif ch == "e" and i == len(w) - 1 and phones:
                pass  # silent final e
            elif nxt == ch and ch not in "aeiou":
                pass  # double consonant
            else:
                phones.extend(_SINGLE.get(ch, []))
            i += 1
    if not any(is_vowel(p) for p in phones):
        phones.append("AH0")
    return phones


def pronunciations(word: str) -> list[list[str]]:
    key = normalize(word)
    found = cmudict().get(key)
    if found:
        return found
    return [letter_to_sound(word)]


# --------------------------------------------------------------------------- syllables
@dataclass
class PhoneSyllable:
    onset: list[str] = field(default_factory=list)
    nucleus: str = ""  # the vowel phone (with stress digit); "" = melisma of previous
    coda: list[str] = field(default_factory=list)

    @property
    def phones(self) -> list[str]:
        return [*self.onset, *([self.nucleus] if self.nucleus else []), *self.coda]


def syllabify(phones: list[str]) -> list[PhoneSyllable]:
    """Split a pronunciation into syllables with maximal legal onsets."""
    vowel_idx = [i for i, p in enumerate(phones) if is_vowel(p)]
    if not vowel_idx:
        return [PhoneSyllable(onset=list(phones), nucleus="AH0")]
    syllables = [PhoneSyllable(nucleus=phones[i]) for i in vowel_idx]
    syllables[0].onset = [base(p) for p in phones[: vowel_idx[0]]]
    syllables[-1].coda = [base(p) for p in phones[vowel_idx[-1] + 1 :]]
    for k in range(len(vowel_idx) - 1):
        cluster = [base(p) for p in phones[vowel_idx[k] + 1 : vowel_idx[k + 1]]]
        split = len(cluster)
        for j in range(len(cluster) + 1):
            if not cluster[j:] or tuple(cluster[j:]) in LEGAL_ONSETS:
                split = j
                break
        syllables[k].coda = cluster[:split]
        syllables[k + 1].onset = cluster[split:]
    return syllables


def _merge(a: PhoneSyllable, b: PhoneSyllable) -> PhoneSyllable:
    """Fold syllable b into a (b's vowel becomes a short coda vowel)."""
    return PhoneSyllable(a.onset, a.nucleus, [*a.coda, *b.onset, b.nucleus, *b.coda])


def fit_syllables(syllables: list[PhoneSyllable], count: int) -> list[PhoneSyllable]:
    """Make the pronunciation's syllables match the number of sung syllables."""
    sylls = list(syllables)
    while len(sylls) > count and len(sylls) > 1:
        # Prefer folding an unstressed syllable into its predecessor.
        candidates = [i for i in range(1, len(sylls)) if stress(sylls[i].nucleus) == 0]
        i = candidates[-1] if candidates else len(sylls) - 1
        sylls[i - 1 : i + 1] = [_merge(sylls[i - 1], sylls[i])]
    while len(sylls) < count:
        # Extra notes on a short word: sustain the last vowel (coda moves to the end).
        last = sylls[-1]
        sylls[-1] = PhoneSyllable(last.onset, last.nucleus, [])
        sylls.append(PhoneSyllable([], "", last.coda))
    return sylls


def align_word(text: str, count: int, overrides: list[list[str] | None] | None = None) -> list[PhoneSyllable]:
    """Phonemes for a word sung over ``count`` syllable tokens."""
    if overrides and all(o is not None for o in overrides) and len(overrides) == count:
        out = []
        for phones in overrides:
            sy = syllabify(phones)
            out.append(sy[0] if len(sy) == 1 else fit_syllables(sy, 1)[0])
        return out
    prons = pronunciations(text)
    best = min(prons, key=lambda p: (abs(sum(is_vowel(x) for x in p) - count), prons.index(p)))
    fitted = fit_syllables(syllabify(best), count)
    if overrides:
        for i, phones in enumerate(overrides):
            if phones is not None:
                fitted[i] = fit_syllables(syllabify(phones), 1)[0]
    return fitted
