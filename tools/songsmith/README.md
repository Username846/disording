# Songsmith

Disording's offline renderer for music, singing voices and SFX (PLAN.md §6). Everything the
game hears comes out of here as a small per-song bundle. The game never synthesizes audio at
runtime. Rendering is deterministic: the same spec always produces the same bytes.

## Run it

```sh
pip install -r tools/songsmith/requirements.txt
export PYTHONPATH=tools/songsmith            # or cd tools/songsmith

python -m songsmith render --all --changed   # menu + every days/day_*/song.yaml, skipping up-to-date bundles
python -m songsmith render days/day_007/song.yaml --debug-wav   # also writes WAVs to generated/debug/ for listening
python -m songsmith check --all              # QA gate (non-zero exit on failure)
python -m songsmith list                     # patches and voice personas
pytest tools/songsmith/tests
```

## Output (the contract the game reads)

`generated/<id>.<hash8>.bundle.zip` (`id` = `menu` or `day_NNN`) and `generated/manifest.json`
(`{"version":1,"bundles":{"<id>":{"file","bytes","sha256","spec_hash"}}}`). `generated/` has a
`.gdignore`, so Godot never imports it. Inside a bundle:

| Entry | What |
|---|---|
| `meta.json` | id, title, bpm, beats_per_bar, sample_rate, duration, loop_start, loop_end, signature, voice, sfx[], stingers[], songsmith_version, spec_hash (+ lufs, true_peak_db, vocal_db_by_section) |
| `music.ogg` | stereo 44.1 kHz Vorbis (~85 kbps). Play with `loop = true`, `loop_offset = loop_start`; the decay tail is already folded back onto the loop point, so the wrap is seamless |
| `win.ogg`, `lose.ogg` | stingers, when the spec has them |
| `sfx/<name>.ogg` | mono SFX, peak −3 dBFS (+ the spec's `gain_db`) |
| `lyrics.json` | `{"lines":[{"t","end","text","section"}]}` caption lines (seconds into `music.ogg`) |
| `beats.json` | `{"bpm","beats_per_bar","beats":[s],"bars":[s],"sections":[{"name","t"}]}` |

## Spec format (`song.yaml`)

```yaml
title: "Off the Edge"
bpm: 132
key: F major                 # tonic + major/minor/dorian/mixolydian/harmonic_minor/pentatonic
beats_per_bar: 4
swing: 0.12                  # beats an off-beat 8th is delayed by (0.167 ≈ triplet feel)
seed: 1001
target_minutes: 4.5          # `check` enforces ±15%
form: [intro, verse1, chorus, verse2, chorus, bridge, chorus, outro]
loop: { from: verse1 }       # optional `to:`; sections after `to` are not rendered
voice:                       # persona + overrides (see personas below)
  persona: child_choir
  formant_scale: 1.25
  breath: 0.12
  vibrato: { rate: 5.6, depth_cents: 35, delay: 0.25 }
  unison: 6
  detune_cents: 9
  gain_db: 0
reverb: { rt60: 2.2, predelay: 0.025, damping_hz: 6500, wet_db: -4 }
instruments:
  toy_piano: { patch: modal.toy_piano, signature: true, pan: -0.2, gain_db: 0, reverb: 0.3 }
  tuba:      { patch: fm.brass, octave: 2 }                 # any other key overrides an engine param
  kit:       { patch: drums.kit, snare: { decay: 0.12 } }   # kit params are per piece
sections:
  verse1:
    bars: 8
    chords: "F | Dm | Bb | C7 | F | Dm | Gm7 C7 | F"   # chords in a bar split it evenly; % repeats
    parts:
      tuba:  { pattern: root_fifth_2feel }
      kit:   { grid: { kick: "x...x...", snare: "..x...x." } }   # x=hit X=accent o=ghost; "|" separates bars
      toy_piano: { pattern: comp_offbeat, vel: 0.6 }
    melody: |                                # syllable:pitch:beats, one lyric line per row (or " / ")
      Wind:C5:1 me:D5:0.5 up:F5:0.5 and:E5:1 watch:D5:1 me:C5:1 go:A4:3
      o-:C5:1 pen:D5:1 _:2                    # trailing hyphen joins a word; _ is a rest
      Glo-:G4:1 -:A4:1 ri{R IY0}-:B4:1 a:C5:1   # "-" holds the syllable (melisma); {…} overrides phonemes
  verse2: { extends: verse1, melody: "…" }   # inherits bars/chords/parts; parts merge per instrument
stingers:
  win:  { bars: 2, chords: "F | C F", parts: {...}, melody: "…", bpm: 140 }
sfx:
  ringout: { events: [{ patch: noise.whoosh, dur: 0.6, f_start: 3000, f_end: 300 },
                      { patch: modal.handbells, note: C6, t: 0.1, dur: 0.2, damp: 0.1 }],
             length: 1.0, reverb: 0.15, gain_db: -2 }
```

**Patterns:**
- bass: `root`, `root_fifth_2feel`, `walking`, `pedal`
- comping: `block`, `pad_sustain`, `comp_offbeat`, `chord_bells`, `arp_up`, `arp_down`, `arp_updown`
- bells: `rounds` (change-ringing scale)
- `grid` for drums or percussion
- `line: "C5:1 _:0.5 C4+E4:2"` for explicit notes
- `melody_double: true` / `melody_of: <section>` to play a melody on an instrument

Common part options: `octave`, `vel`, `legato`, `rate`, `bars: [1, 3]`, `humanize`.

**Engines** (`songsmith/patches/`): modal (bells, bars, tines), extended Karplus-Strong (plucked
strings), virtual-analog subtractive, FM, additive/drawbar, reed/air, bowed (source-filter),
synthesized drums and percussion, noise utilities. Add a day's signature instrument with a
`register("family.name", engine, **params)` call (or a new module imported in
`patches/__init__.py`).

**Voice personas** (`voice/personas.py`):
- `warm_choir` (SATB, with harmony derived from the chords)
- `child_choir`
- `female_solo`
- `male_crooner`
- `robot_vocoder`
- `whisper`

The singer is a Klatt-style formant synthesizer driven by CMUdict pronunciations (`vendor/`,
BSD-2). Write lyrics for it: open vowels on long notes, few consonant clusters. Lyrics are also
shown as captions in the game.

## QA (`check`)

- duration within ±15% of the target
- loudness −16 ±1 LUFS, true peak ≤ −1 dBTP
- no silence > 2 s
- a click-free loop seam
- vocals in ≥ 2 verse sections
- exactly one `signature: true` instrument, unique across all songs
- bundle ≤ 3.5 MiB
- every SFX and stinger present

`day_000` (debug fixture) is exempt from the signature and verse rules.
