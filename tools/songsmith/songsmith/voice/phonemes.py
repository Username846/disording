"""ARPAbet phoneme inventory with formant targets for a reference adult male voice.

Formants (Hz) are averages from Peterson & Barney (1952) / Hillenbrand et al. (1995),
nudged for sung vowels. Personas scale them with ``formant_scale``.
"""

from __future__ import annotations

from dataclasses import dataclass

VOWELS = {"AA", "AE", "AH", "AO", "AW", "AY", "EH", "ER", "EY", "IH", "IY", "OW", "OY", "UH", "UW"}

# F1, F2, F3 for steady vowels (diphthongs: start target; see DIPHTHONG_END).
VOWEL_FORMANTS: dict[str, tuple[float, float, float]] = {
    "IY": (300.0, 2280.0, 2950.0),
    "IH": (420.0, 1980.0, 2600.0),
    "EY": (470.0, 2020.0, 2620.0),
    "EH": (560.0, 1800.0, 2560.0),
    "AE": (660.0, 1720.0, 2410.0),
    "AA": (720.0, 1100.0, 2450.0),
    "AO": (580.0, 860.0, 2420.0),
    "OW": (500.0, 900.0, 2400.0),
    "UH": (450.0, 1050.0, 2250.0),
    "UW": (330.0, 880.0, 2240.0),
    "AH": (630.0, 1200.0, 2400.0),
    "ER": (490.0, 1350.0, 1690.0),
    "AY": (720.0, 1150.0, 2450.0),
    "AW": (720.0, 1150.0, 2450.0),
    "OY": (570.0, 860.0, 2420.0),
}
SCHWA = (500.0, 1450.0, 2480.0)  # unstressed AH0
DIPHTHONG_END: dict[str, tuple[float, float, float]] = {
    "AY": (380.0, 2050.0, 2650.0),
    "AW": (420.0, 900.0, 2300.0),
    "OY": (400.0, 1950.0, 2600.0),
    "EY": (330.0, 2250.0, 2900.0),
    "OW": (380.0, 860.0, 2300.0),
}


@dataclass(frozen=True)
class Consonant:
    kind: str  # sonorant | nasal | fricative | stop | affricate | aspirate
    formants: tuple[float, float, float]  # locus / steady targets
    dur: float  # seconds (sung, moderate tempo)
    av: float = 0.0  # voicing amplitude while held
    af: float = 0.0  # frication amplitude
    fric_hz: float = 5000.0
    fric_bw: float = 3000.0
    burst_hz: float = 2000.0
    aspiration: float = 0.0  # seconds of aspiration after a voiceless stop release


CONSONANTS: dict[str, Consonant] = {
    # Sonorants & glides.
    "L": Consonant("sonorant", (360.0, 1100.0, 2700.0), 0.06, av=0.75),
    "R": Consonant("sonorant", (330.0, 1080.0, 1450.0), 0.06, av=0.8),
    "W": Consonant("sonorant", (300.0, 650.0, 2200.0), 0.05, av=0.75),
    "Y": Consonant("sonorant", (280.0, 2100.0, 3000.0), 0.05, av=0.75),
    # Nasals.
    "M": Consonant("nasal", (280.0, 1100.0, 2200.0), 0.07, av=0.5),
    "N": Consonant("nasal", (280.0, 1550.0, 2600.0), 0.065, av=0.5),
    "NG": Consonant("nasal", (280.0, 2000.0, 2700.0), 0.07, av=0.45),
    # Fricatives.
    "S": Consonant("fricative", (320.0, 1450.0, 2600.0), 0.10, af=0.55, fric_hz=6800.0, fric_bw=3000.0),
    "Z": Consonant("fricative", (320.0, 1450.0, 2600.0), 0.08, av=0.35, af=0.35, fric_hz=6500.0, fric_bw=3000.0),
    "SH": Consonant("fricative", (300.0, 1800.0, 2400.0), 0.10, af=0.6, fric_hz=3300.0, fric_bw=1800.0),
    "ZH": Consonant("fricative", (300.0, 1800.0, 2400.0), 0.08, av=0.35, af=0.4, fric_hz=3300.0, fric_bw=1800.0),
    "F": Consonant("fricative", (300.0, 1100.0, 2300.0), 0.09, af=0.28, fric_hz=5500.0, fric_bw=6000.0),
    "V": Consonant("fricative", (300.0, 1100.0, 2300.0), 0.07, av=0.4, af=0.15, fric_hz=5000.0, fric_bw=6000.0),
    "TH": Consonant("fricative", (330.0, 1500.0, 2600.0), 0.09, af=0.24, fric_hz=6000.0, fric_bw=6000.0),
    "DH": Consonant("fricative", (330.0, 1550.0, 2600.0), 0.05, av=0.45, af=0.1, fric_hz=5000.0, fric_bw=6000.0),
    "HH": Consonant("aspirate", (0.0, 0.0, 0.0), 0.06),
    # Stops: dur = closure; burst and aspiration follow.
    "P": Consonant("stop", (300.0, 850.0, 2200.0), 0.06, burst_hz=1100.0, aspiration=0.035),
    "B": Consonant("stop", (300.0, 850.0, 2200.0), 0.05, av=0.15, burst_hz=1100.0),
    "T": Consonant("stop", (320.0, 1700.0, 2600.0), 0.055, burst_hz=4500.0, aspiration=0.04),
    "D": Consonant("stop", (320.0, 1700.0, 2600.0), 0.045, av=0.15, burst_hz=4000.0),
    "K": Consonant("stop", (320.0, 1950.0, 2500.0), 0.06, burst_hz=2200.0, aspiration=0.045),
    "G": Consonant("stop", (320.0, 1950.0, 2500.0), 0.05, av=0.15, burst_hz=2000.0),
    "CH": Consonant("affricate", (300.0, 1800.0, 2400.0), 0.05, af=0.6, fric_hz=3300.0, fric_bw=1800.0, burst_hz=4000.0),
    "JH": Consonant("affricate", (300.0, 1800.0, 2400.0), 0.045, av=0.3, af=0.4, fric_hz=3300.0, fric_bw=1800.0, burst_hz=3500.0),
}

LEGAL_ONSETS: set[tuple[str, ...]] = {
    *((c,) for c in CONSONANTS if c != "NG"),
    ("P", "L"), ("P", "R"), ("B", "L"), ("B", "R"), ("T", "R"), ("D", "R"), ("K", "L"), ("K", "R"),
    ("G", "L"), ("G", "R"), ("F", "L"), ("F", "R"), ("TH", "R"), ("SH", "R"), ("S", "L"), ("S", "M"),
    ("S", "N"), ("S", "W"), ("S", "P"), ("S", "T"), ("S", "K"), ("T", "W"), ("D", "W"), ("K", "W"),
    ("S", "T", "R"), ("S", "P", "R"), ("S", "K", "R"), ("S", "P", "L"), ("S", "K", "W"), ("P", "Y"),
    ("B", "Y"), ("F", "Y"), ("K", "Y"), ("M", "Y"), ("HH", "Y"), ("V", "Y"),
}


def base(phone: str) -> str:
    """Strip the stress digit: ``AH0`` → ``AH``."""
    return phone.rstrip("012")


def is_vowel(phone: str) -> bool:
    return base(phone) in VOWELS


def stress(phone: str) -> int:
    return int(phone[-1]) if phone[-1].isdigit() else 0


def vowel_formants(phone: str) -> tuple[tuple[float, float, float], tuple[float, float, float] | None]:
    """(start target, end target or None) for a vowel phone."""
    b = base(phone)
    start = SCHWA if b == "AH" and stress(phone) == 0 else VOWEL_FORMANTS[b]
    return start, DIPHTHONG_END.get(b)
