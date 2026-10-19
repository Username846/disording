import pytest

from songsmith.theory import note_to_midi, parse_chord, parse_chord_line, parse_key


def test_note_names():
    assert note_to_midi("C4") == 60
    assert note_to_midi("A4") == 69
    assert note_to_midi("Bb3") == 58
    assert note_to_midi("F#5") == 78
    with pytest.raises(ValueError):
        note_to_midi("H2")


@pytest.mark.parametrize(
    "symbol, pcs, bass",
    [
        ("C", (0, 4, 7), 0),
        ("Dm", (2, 5, 9), 2),
        ("G7", (2, 5, 7, 11), 7),
        ("Fmaj7", (0, 4, 5, 9), 5),
        ("Am7", (0, 4, 7, 9), 9),
        ("Bdim", (2, 5, 11), 11),
        ("Dsus2", (2, 4, 9), 2),
        ("Gsus4", (0, 2, 7), 7),
        ("Cadd9", (0, 2, 4, 7), 0),
        ("C/E", (0, 4, 7), 4),
        ("Bb", (2, 5, 10), 10),
    ],
)
def test_chords(symbol, pcs, bass):
    chord = parse_chord(symbol)
    assert chord.pitch_classes == tuple(sorted(pcs))
    assert chord.bass == bass


def test_chord_line_splits_bars():
    spans = parse_chord_line("F | Gm7 C7 | %")
    assert [(s.start, s.length, s.chord.symbol) for s in spans] == [
        (0.0, 4.0, "F"),
        (4.0, 2.0, "Gm7"),
        (6.0, 2.0, "C7"),
        (8.0, 4.0, "C7"),
    ]


def test_key_scale():
    key = parse_key("F major")
    assert [n % 12 for n in key.scale_notes(65, 77)] == [5, 7, 9, 10, 0, 2, 4, 5]
