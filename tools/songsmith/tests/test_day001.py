"""Day 1 content (Toybox Ring-Out) plus the patches and voice personas added for Days 1–10."""

from pathlib import Path

import numpy as np
import pytest

from songsmith import dsp
from songsmith import patches as P
from songsmith.dsp import SR
from songsmith.melody import parse_line, parse_melody
from songsmith.render import arrange
from songsmith.spec import load_song
from songsmith.theory import parse_chord
from songsmith.voice import g2p
from songsmith.voice.harmony import close_harmony
from songsmith.voice.personas import PERSONAS
from songsmith.voice.singer import SungNote, SungSyllable, VoiceParams
from songsmith.voice.singer import render as sing

REPO = Path(__file__).resolve().parents[3]
DAY1_SFX = {
    "flick", "wind", "ready", "hit_light", "hit_heavy", "ringout", "respawn", "pickup", "whistle",
    "bout_win", "bout_lose", "countdown", "go", "squeak", "train", "spring", "tilt",
}
NEW_PATCHES = [
    ("brass.tuba", 41, 0.5),
    ("reed.kazoo_section", 65, 0.4),
    ("reed.slide_whistle", 84, 0.5),
    ("reed.pea_whistle", 103, 0.4),
    ("fx.spring", 48, 0.4),
    ("fx.ratchet", None, 0.3),
    ("fx.squeak", 84, 0.2),
    ("modal.tin", 76, 0.1),
]


def _pitch(x: np.ndarray) -> float:
    """Rough fundamental from zero crossings (fine for a near-sine whistle)."""
    crossings = np.count_nonzero(np.diff(np.signbit(x)))
    return crossings / 2 / (len(x) / SR)


@pytest.mark.parametrize("name,note,dur", NEW_PATCHES)
def test_new_patches_render(name, note, dur):
    audio = P.render_note(name, note, dur, 0.8, 1)
    assert np.isfinite(audio).all()
    assert len(audio) >= dsp.samples(dur)
    assert np.max(np.abs(audio)) > 0.05


def test_slide_whistle_glides_both_ways():
    up = P.render_note("reed.slide_whistle", 84, 0.6, 0.8, 1, {"glide_from": -12.0, "glide_in": 0.3, "breath": 0.0, "vibrato": [0, 0, 0]})
    down = P.render_note("reed.slide_whistle", 84, 0.6, 0.8, 1, {"glide_to": -12.0, "breath": 0.0, "vibrato": [0, 0, 0]})
    seg = dsp.samples(0.06)
    assert _pitch(up[: seg]) < 0.75 * _pitch(up[dsp.samples(0.4) : dsp.samples(0.4) + seg])
    assert _pitch(down[: seg]) > 1.5 * _pitch(down[dsp.samples(0.55) : dsp.samples(0.55) + seg])


def test_kazoo_section_is_wider_than_one_kazoo():
    one = P.render_note("reed.kazoo", 65, 0.5, 0.8, 1)
    many = P.render_note("reed.kazoo_section", 65, 0.5, 0.8, 1)
    assert not np.allclose(one[: len(many)], many[: len(one)])


def test_close_harmony_stays_below_within_an_octave():
    chords = [parse_chord("F"), parse_chord("C7"), None]
    lines = close_harmony([72, 76, None], chords, count=2)
    assert lines["close1"][2] is None and lines["close2"][2] is None
    for i, top in enumerate([72, 76]):
        a, b = lines["close1"][i], lines["close2"][i]
        assert top - 12 <= b < a < top
    assert lines["close1"][0] % 12 in parse_chord("F").pitch_classes


def test_ring_mod_keeps_length_and_changes_sound():
    x = np.sin(2 * np.pi * 220 * np.arange(SR // 4) / SR)
    y = dsp.ring_mod(x, 55.0, 0.5)
    assert len(y) == len(x) and not np.allclose(x, y)


def test_clockwork_wobble_and_winddown_change_the_voice():
    sylls = [SungSyllable(g2p.align_word("go", 1)[0], [SungNote(0.1, 1.2, 67.0)])]
    plain = sing(sylls, VoiceParams(), 1.4, seed=3)
    toy = sing(sylls, VoiceParams(wobble_rate=3.0, wobble_cents=8.0, wobble_amp=0.12, winddown_cents=28.0), 1.4, seed=3)
    assert np.isfinite(toy).all() and not np.allclose(plain, toy)


PERSONA_SPEC = """
title: "Persona check"
bpm: 120
key: F major
seed: 5
target_minutes: 0.05
form: [verse1]
voice: {{ persona: {persona} }}
instruments: {{}}
sections:
  verse1:
    bars: 1
    chords: "F C7"
    melody: "La:C5:1 la:D5:1 la:F5:2"
"""


@pytest.mark.parametrize("persona", sorted(PERSONAS))
def test_every_persona_sings_a_short_phrase(tmp_path, persona):
    spec = tmp_path / "song.yaml"
    spec.write_text(PERSONA_SPEC.format(persona=persona))
    song = load_song(spec)
    arr = arrange(song, song.form, wrap=False, tail=0.2)
    assert np.isfinite(arr.mix).all()
    assert arr.voice_by_section["verse1"] > -45.0, arr.voice_by_section
    assert PERSONAS[persona].get("doc"), f"{persona} needs a doc string for `songsmith list`"


def test_day001_spec_contract():
    song = load_song(REPO / "days" / "day_001" / "song.yaml")
    assert song.signature == "modal.toy_piano"
    assert song.voice["persona"] == "wind_up_child_choir"
    assert set(song.sfx) == DAY1_SFX
    assert set(song.stingers) == {"win", "lose"}
    assert song.loop_from == "verse1"
    beats = sum(song.sections[n].bars * song.sections[n].beats_per_bar for n in song.form)
    assert 3.4 <= beats * 60 / song.bpm / 60 <= 4.6
    for sec in [*song.sections.values(), *song.stingers.values()]:
        total = sec.bars * sec.beats_per_bar
        if sec.melody:
            mel = parse_melody(sec.melody)
            assert mel.length == total, sec.name
            for word in mel.words:
                if all(mel.syllables[s].override is None for s in word.syllables):
                    assert g2p.pronunciations(g2p.normalize(word.text)), f"{sec.name}: no pronunciation for {word.text!r}"
        for part in sec.parts.values():
            if "line" in part:
                length = sum(n.beats for n in parse_line(part["line"]))
                assert total % length == 0, sec.name
    verses = [n for n in song.sections if n.startswith("verse") and song.sections[n].melody]
    assert len(verses) >= 2
