import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

FIXTURE_SPEC = """
title: "Fixture"
bpm: 160
key: C major
seed: 3
target_minutes: 0.125
form: [intro, verse1, verse2, chorus]
loop: { from: verse1 }
voice: { persona: female_solo }
instruments:
  bells: { patch: modal.celesta, signature: true, pan: -0.2 }
  bass: { patch: pluck.upright_bass }
  kit: { patch: drums.kit, gain_db: -6 }
sections:
  intro:
    bars: 1
    chords: "C"
    parts:
      bells: { pattern: arp_up, rate: 0.5 }
  verse1:
    bars: 1
    chords: "C G"
    parts:
      bells: { pattern: block }
      bass: { pattern: root }
      kit: { grid: { kick: "x...x...", hat: "x.x.x.x." } }
    melody: "Hel-:E4:1 lo:G4:1 snow:A4:2"
  verse2:
    extends: verse1
    melody: "O-:E4:1 pen:G4:1 door:C5:2"
  chorus:
    bars: 2
    chords: "F | G C"
    parts:
      bells: { pattern: chord_bells }
      bass: { pattern: walking }
    melody: "One:C5:1 more:D5:1 day:C5:2 / come:A4:1 and:G4:1 play:C5:2"
stingers:
  win:
    bars: 1
    chords: "C"
    parts:
      bells: { pattern: chord_bells, rate: 0.25 }
    melody: "Yay!:C5:2 _:2"
sfx:
  tap: { events: [{ patch: modal.handbells, note: C6, dur: 0.1, damp: 0.1, tail: 0.3 }], length: 0.3 }
"""


@pytest.fixture()
def fixture_repo(tmp_path, monkeypatch):
    """A throwaway repo root holding one tiny day spec."""
    (tmp_path / "PLAN.md").write_text("fixture\n")
    day = tmp_path / "days" / "day_001"
    day.mkdir(parents=True)
    (day / "song.yaml").write_text(FIXTURE_SPEC)
    monkeypatch.chdir(tmp_path)
    return tmp_path
