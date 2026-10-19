import pytest

from songsmith.melody import parse_line, parse_melody


def test_tokens_rests_and_lines():
    mel = parse_melody("One:C5:1 more:D5:1 _:1 door,:C5:1 / O-:D5:1 pen:E5:0.5 up:C5:1/2")
    assert [n.midi for n in mel.notes] == [72, 74, None, 72, 74, 76, 72]
    assert [n.start for n in mel.notes] == [0, 1, 2, 3, 4, 5, 5.5]
    assert [w.text for w in mel.words] == ["One", "more", "door,", "Open", "up"]
    assert [line.text(mel) for line in mel.lines] == ["One more door,", "Open up"]
    assert mel.lines[0].start == 0 and mel.lines[0].end == 4
    assert mel.length == 6


def test_melisma_and_override():
    mel = parse_melody("Glo-:G4:1 -:A4:1 ri{R IY0}-:B4:1 a:C5:1")
    assert len(mel.syllables) == 3
    assert mel.syllables[0].notes == [0, 1]
    assert mel.syllables[1].override == ["R", "IY0"]
    assert mel.words[0].text == "Gloria"


def test_bad_tokens():
    with pytest.raises(ValueError):
        parse_melody("oops:C4")
    with pytest.raises(ValueError):
        parse_melody("-:C4:1")


def test_instrument_line():
    line = parse_line("C5:1 _:0.5 C4+E4:2")
    assert [(n.start, n.beats, n.midis) for n in line] == [(0, 1, (72,)), (1, 0.5, ()), (1.5, 2, (60, 64))]
