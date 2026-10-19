"""Render a song spec: arrangement → instrument stems + singing → mix → master.

The music file loops: the game plays it with ``loop_offset = loop_start``. We render
up to ``loop_end`` plus a decay tail, then fold that tail back onto ``loop_start`` so the
wrap from the end of the file to the loop point is seamless.
"""

from __future__ import annotations

import math
import zlib
from dataclasses import dataclass, field

import numpy as np
from scipy import signal

from . import dsp, mixer
from . import patches as patch_registry
from .dsp import SR
from .melody import Melody, parse_melody
from .patterns import generate
from .spec import Section, Sfx, Song
from .theory import ChordSpan, note_to_midi, parse_chord_line
from .voice import personas
from .voice.g2p import align_word
from .voice.harmony import harmonize
from .voice.singer import SungNote, SungSyllable
from .voice.singer import render as sing

STEM_RMS_DB = -24.0
VOICE_RMS_DB = -19.0
TAIL_SECONDS = 6.0


def _seed(*parts: object) -> int:
    return zlib.crc32(repr(parts).encode()) & 0x7FFFFFFF


class Timeline:
    def __init__(self, bpm: float, swing: float) -> None:
        self.bpm = bpm
        self.swing = swing
        self.spb = 60.0 / bpm

    def time(self, beat: float) -> float:
        frac = beat % 1.0
        b = beat
        if self.swing:
            if abs(frac - 0.5) < 1e-6:
                b += self.swing * 0.5
            elif abs(frac - 0.25) < 1e-6 or abs(frac - 0.75) < 1e-6:
                b += self.swing * 0.25
        return b * self.spb


@dataclass
class Instance:
    label: str  # unique: "chorus", "chorus@2", …
    name: str
    start: float  # beats
    beats: float
    section: Section
    spans: list[ChordSpan]

    @property
    def end(self) -> float:
        return self.start + self.beats

    def chord_at(self, rel_beat: float):
        for span in self.spans:
            if span.start - 1e-6 <= rel_beat < span.start + span.length - 1e-6:
                return span.chord
        return self.spans[-1].chord if self.spans else None


@dataclass
class Arrangement:
    mix: np.ndarray  # stereo, pre-master, includes reverb
    voice_by_section: dict[str, float]
    lyrics: list[dict]
    beats: list[float]
    bars: list[float]
    sections: list[dict]
    loop_start: float
    loop_end: float


@dataclass
class Rendered:
    music: np.ndarray
    loop_start: float
    loop_end: float
    lufs: float
    true_peak: float
    lyrics: list[dict]
    beats: dict
    voice_by_section: dict[str, float]
    stingers: dict[str, np.ndarray] = field(default_factory=dict)
    sfx: dict[str, np.ndarray] = field(default_factory=dict)
    persona: str = ""


def _tile_spans(spans: list[ChordSpan], beats: float) -> list[ChordSpan]:
    if not spans:
        return spans
    length = spans[-1].start + spans[-1].length
    out: list[ChordSpan] = []
    offset = 0.0
    while offset < beats - 1e-6:
        for s in spans:
            if offset + s.start >= beats - 1e-6:
                break
            out.append(ChordSpan(offset + s.start, min(s.length, beats - offset - s.start), s.chord))
        offset += length
    return out


def _instances(song: Song, names: list[str], sections: dict[str, Section]) -> list[Instance]:
    out: list[Instance] = []
    counts: dict[str, int] = {}
    beat = 0.0
    for name in names:
        sec = sections[name]
        counts[name] = counts.get(name, 0) + 1
        label = name if counts[name] == 1 else f"{name}@{counts[name]}"
        beats = sec.bars * sec.beats_per_bar
        spans = _tile_spans(parse_chord_line(sec.chords, sec.beats_per_bar), beats)
        out.append(Instance(label, name, beat, beats, sec, spans))
        beat += beats
    return out


def _stem_level(buf: np.ndarray, target_db: float) -> np.ndarray:
    rms = mixer.active_rms(buf)
    return buf * (dsp.db(target_db) / rms) if rms > 0 else buf


def _render_instruments(song: Song, instances: list[Instance], timeline: Timeline, melodies: dict[str, Melody], n: int, dry: np.ndarray, wet_bus: np.ndarray) -> None:
    events: dict[str, list[tuple[float, float, float | None, float, str | None]]] = {}
    for inst in instances:
        for inst_name, part in inst.section.parts.items():
            instrument = song.instruments[inst_name]
            patch = patch_registry.get(instrument.patch)
            octave = instrument.octave if instrument.octave is not None else patch.octave
            rng = np.random.default_rng(_seed(song.seed, inst_name, inst.label))
            notes = generate(part or {}, int(octave), inst.spans, inst.beats, inst.section.beats_per_bar, song.key, melodies.get(inst.name), melodies, rng)
            for pn in notes:
                events.setdefault(inst_name, []).append((inst.start + pn.beat, pn.beats, pn.midi, pn.vel, pn.piece))
    for inst_name in sorted(events):
        instrument = song.instruments[inst_name]
        patch = patch_registry.get(instrument.patch)
        buf = np.zeros(n)
        for beat, beats, midi, vel, piece in events[inst_name]:
            name = instrument.patch
            overrides = dict(instrument.params)
            if patch.kind == "kit":
                if piece not in patch.pieces:
                    raise ValueError(f"Kit {instrument.patch} has no piece {piece!r} (pieces: {', '.join(patch.pieces)})")
                name = patch.pieces[piece]
                overrides = dict(instrument.params.get(piece, {}))
                midi = None
            dur = beats * timeline.spb
            audio = patch_registry.render_note(name, midi, dur, min(vel, 1.2), song.seed, overrides)
            dsp.place(buf, audio, dsp.samples(timeline.time(beat)))
        buf = _stem_level(buf, STEM_RMS_DB + instrument.gain_db)
        dsp.add_panned(dry, buf, instrument.pan)
        dsp.add_panned(wet_bus, buf, instrument.pan, instrument.reverb)


def _render_voice(song: Song, instances: list[Instance], timeline: Timeline, melodies: dict[str, Melody], n: int) -> tuple[np.ndarray, list[dict], float]:
    persona = personas.resolve(song.voice)
    lyrics: list[dict] = []
    # Gather every sung syllable in time order.
    syl_notes: list[tuple[object, list[tuple[float, float, int, float]], list]] = []
    for inst in instances:
        mel = melodies.get(inst.name)
        if mel is None or not mel.notes:
            continue
        phones = [None] * len(mel.syllables)
        for word in mel.words:
            overrides = [mel.syllables[s].override for s in word.syllables]
            aligned = align_word(word.text, len(word.syllables), overrides if any(o is not None for o in overrides) else None)
            for si, ph in zip(word.syllables, aligned):
                phones[si] = ph
        gain = dsp.db(inst.section.vocal_gain_db)
        for si, syl in enumerate(mel.syllables):
            notes = []
            chords = []
            for k in syl.notes:
                note = mel.notes[k]
                t0 = timeline.time(inst.start + note.start)
                t1 = t0 + note.beats * timeline.spb
                notes.append((t0, t1, note.midi, gain))
                chords.append(inst.chord_at(note.start))
            syl_notes.append((phones[si], notes, chords))
        for line in mel.lines:
            lyrics.append({
                "t": round(timeline.time(inst.start + line.start), 3),
                "end": round(timeline.time(inst.start + line.end), 3),
                "text": line.text(mel),
                "section": inst.label,
            })
    lyrics.sort(key=lambda x: x["t"])
    if not syl_notes:
        return np.zeros((2, n)), lyrics, 0.0

    lead = [m for _, notes, _ in syl_notes for (_, _, m, _) in notes]
    shift = personas.range_shift(persona, lead)
    flat_chords = [c for _, _, chords in syl_notes for c in chords]
    lines: dict[str, list[int | None]] = {"melody": [m + shift for m in lead]}
    if any(p["line"] != "melody" for p in persona["parts"]):
        lines.update(harmonize(lines["melody"], flat_chords))
    total_seconds = n / SR
    voice = np.zeros((2, n))
    for pi, part in enumerate(persona["parts"]):
        line = lines[part["line"]]
        sylls: list[SungSyllable] = []
        k = 0
        for ph, notes, _ in syl_notes:
            sung = []
            for t0, t1, _, vel in notes:
                midi = line[k]
                k += 1
                if midi is not None:
                    sung.append(SungNote(t0, t1, float(midi), vel))
            if sung:
                sylls.append(SungSyllable(ph, sung))
        params = personas.params_for(persona, part)
        mono = sing(sylls, params, total_seconds, seed=_seed(song.seed, "voice", pi), n_samples=n)
        mono = _stem_level(mono, VOICE_RMS_DB + part.get("gain_db", 0.0))
        personas.ensemble(mono, int(persona.get("unison", 1)), float(persona.get("detune_cents", 0.0)), float(part.get("pan", 0.0)), _seed(song.seed, "ens", pi), out=voice)
    voice = _stem_level(voice, VOICE_RMS_DB + float(song.voice.get("gain_db", 0.0)))
    # Voice EQ: a little presence, less mud.
    voice = dsp.filt(voice, "peak", 3000.0, 0.9, 2.5)
    voice = dsp.filt(voice, "lowshelf", 220.0, 0.7, -2.0)
    return voice, lyrics, float(persona.get("reverb", 0.3))


def arrange(song: Song, names: list[str], *, bpm: float | None = None, loop_from: str | None = None, loop_to: str | None = None, wrap: bool = True, tail: float = TAIL_SECONDS, sections: dict[str, Section] | None = None) -> Arrangement:
    sections = sections or song.sections
    timeline = Timeline(bpm or song.bpm, song.swing)
    instances = _instances(song, names, sections)
    loop_start_beat = 0.0
    loop_end_beat = instances[-1].end if instances else 0.0
    if loop_from:
        loop_start_beat = next(i.start for i in instances if i.name == loop_from)
    if loop_to:
        last = [i for i in instances if i.name == loop_to][-1]
        loop_end_beat = last.end
        instances = [i for i in instances if i.start < loop_end_beat]
    loop_start = loop_start_beat * timeline.spb
    loop_end = loop_end_beat * timeline.spb
    n = dsp.samples(loop_end + tail)
    melodies = {name: parse_melody(sec.melody) for name, sec in {**song.sections, **sections}.items()}

    dry = np.zeros((2, n))
    wet_bus = np.zeros((2, n))
    _render_instruments(song, instances, timeline, melodies, n, dry, wet_bus)
    voice, lyrics, voice_send = _render_voice(song, instances, timeline, melodies, n)
    if wrap and loop_start > 0:
        # Sung onsets anticipate the beat, so the first syllable of the loop starts a
        # little before loop_start. Copy that pickup to the end of the loop too, or every
        # repeat would lose it ("Snow" → "ow").
        s0, s1 = dsp.samples(loop_start), dsp.samples(loop_end)
        pre = min(dsp.samples(0.35), s0)
        voice[:, s1 - pre : s1] += voice[:, s0 - pre : s0]

    voice_by_section = {}
    for inst in instances:
        a, b = dsp.samples(inst.start * timeline.spb), dsp.samples(inst.end * timeline.spb)
        seg = voice[:, a:b]
        rms = math.sqrt(float(np.mean(seg**2))) if seg.size else 0.0
        voice_by_section[inst.label] = round(dsp.to_db(rms), 1)

    for ch in range(2):
        dsp._axpy(dry[ch], voice[ch], 1.0)
        dsp._axpy(wet_bus[ch], voice[ch], voice_send)
    rv = song.reverb
    ir = mixer.make_ir(float(rv.get("rt60", 2.2)), float(rv.get("predelay", 0.025)), float(rv.get("damping_hz", 6500.0)), _seed(song.seed, "ir"))
    mix = dry + mixer.reverb(wet_bus, ir) * dsp.db(float(rv.get("wet_db", -4.0)))

    if wrap:
        s0, s1 = dsp.samples(loop_start), dsp.samples(loop_end)
        tail_audio = mix[:, s1:].copy()
        mix = mix[:, :s1].copy()
        m = min(tail_audio.shape[1], s1 - s0)
        mix[:, s0 : s0 + m] += tail_audio[:, :m]

    beats = [round(timeline.time(b), 4) for b in np.arange(0, loop_end_beat - 1e-6, 1.0)]
    bars = []
    for inst in instances:
        bpb = inst.section.beats_per_bar
        bars += [round(timeline.time(inst.start + k * bpb), 4) for k in range(int(inst.beats // bpb))]
    sec_list = [{"name": inst.label, "t": round(inst.start * timeline.spb, 4)} for inst in instances]
    return Arrangement(mix, voice_by_section, lyrics, beats, bars, sec_list, loop_start, loop_end)


def render_sfx(song: Song, sfx: Sfx) -> np.ndarray:
    pieces = []
    end = 0.0
    for k, ev in enumerate(sfx.events):
        midi = note_to_midi(ev.note) if ev.note is not None else None
        audio = patch_registry.render_note(ev.patch, midi, ev.dur, ev.vel, _seed(song.seed, sfx.name, k), ev.params)
        pieces.append((ev.t, audio))
        end = max(end, ev.t + len(audio) / SR)
    length = float(sfx.length) if sfx.length else end + 0.05
    buf = np.zeros(dsp.samples(length))
    for t, audio in pieces:
        dsp.place(buf, audio, dsp.samples(t))
    if sfx.reverb > 0:
        ir = mixer.make_ir(0.7, 0.008, 7000.0, _seed(song.seed, "sfx_ir"), early=4)[0]
        buf = buf + sfx.reverb * signal.oaconvolve(buf, ir)[: len(buf)] * 0.3
    peak = np.max(np.abs(buf))
    if peak > 0:
        buf *= dsp.db(-3.0 + sfx.gain_db) / peak
    return dsp.fade_tail(buf, 0.03)


def render_song(song: Song, *, with_sfx: bool = True) -> Rendered:
    patch_registry.clear_cache()
    arr = arrange(song, song.form, loop_from=song.loop_from, loop_to=song.loop_to, wrap=True)
    music, lufs, tp = mixer.master(arr.mix)
    rendered = Rendered(
        music=music,
        loop_start=arr.loop_start,
        loop_end=arr.loop_end,
        lufs=lufs,
        true_peak=tp,
        lyrics=arr.lyrics,
        beats={
            "bpm": song.bpm,
            "beats_per_bar": song.beats_per_bar,
            "beats": arr.beats,
            "bars": arr.bars,
            "sections": arr.sections,
        },
        voice_by_section=arr.voice_by_section,
        persona=personas.resolve(song.voice)["persona"],
    )
    for name, sec in song.stingers.items():
        st = arrange(song, [name], bpm=sec.bpm, wrap=False, tail=1.0, sections={**song.sections, name: sec})
        audio = st.mix
        fade = dsp.samples(0.6)
        audio[:, -fade:] *= np.linspace(1, 0, fade)
        rendered.stingers[name], _, _ = mixer.master(audio, glue=False)
    if with_sfx:
        for name, sfx in song.sfx.items():
            rendered.sfx[name] = render_sfx(song, sfx)
    return rendered
