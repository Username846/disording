from songsmith.voice.g2p import align_word, letter_to_sound, syllabify


def phones(sylls):
    return [s.phones for s in sylls]


def test_dictionary_and_onset_maximal_split():
    assert phones(align_word("open", 2)) == [["OW1"], ["P", "AH0", "N"]]
    assert phones(align_word("window", 2)) == [["W", "IH1", "N"], ["D", "OW0"]]
    assert phones(syllabify(["EH1", "K", "S", "T", "R", "AH0"])) == [["EH1", "K"], ["S", "T", "R", "AH0"]]


def test_prefers_pronunciation_with_matching_syllables():
    assert len(align_word("every", 2)) == 2
    assert len(align_word("every", 3)) == 3


def test_more_notes_than_syllables_becomes_melisma():
    out = align_word("snow", 2)
    assert out[0].nucleus == "OW1" and out[1].nucleus == ""


def test_fewer_notes_folds_syllables():
    out = align_word("tomorrow", 2)
    assert len(out) == 2 and all(s.nucleus for s in out)


def test_override_and_fallback():
    assert phones(align_word("blorp", 1, [["B", "L", "AO1", "R", "P"]])) == [["B", "L", "AO1", "R", "P"]]
    assert any(p[-1].isdigit() for p in letter_to_sound("zibbleflop"))
