import json
import zipfile

import numpy as np

from songsmith import cli, mixer, ogg
from songsmith.bundle import load_manifest
from songsmith.check import check_spec, seam_metrics, signature_owners
from songsmith.paths import all_specs


def _bundle(root):
    entry = load_manifest(root / "generated")["bundles"]["day_001"]
    return root / "generated" / entry["file"], entry


def test_render_bundle_contract_and_changed_skip(fixture_repo, capsys):
    assert cli.main(["render", "--all"]) == 0
    path, entry = _bundle(fixture_repo)
    assert (fixture_repo / "generated" / ".gdignore").exists()
    assert path.name.startswith("day_001.") and path.name.endswith(".bundle.zip")
    assert entry["bytes"] == path.stat().st_size
    with zipfile.ZipFile(path) as zf:
        names = set(zf.namelist())
        assert {"meta.json", "music.ogg", "win.ogg", "sfx/tap.ogg", "lyrics.json", "beats.json"} <= names
        assert zf.getinfo("music.ogg").compress_type == zipfile.ZIP_STORED
        meta = json.loads(zf.read("meta.json"))
        for key in ("id", "title", "bpm", "beats_per_bar", "sample_rate", "duration", "loop_start", "loop_end",
                    "signature", "voice", "sfx", "stingers", "songsmith_version", "spec_hash"):
            assert key in meta
        assert meta["id"] == "day_001" and meta["sfx"] == ["tap"] and meta["stingers"] == ["win"]
        assert meta["loop_start"] == 1.5  # one 4/4 bar at 160 BPM
        lyrics = json.loads(zf.read("lyrics.json"))["lines"]
        assert [line["text"] for line in lyrics][:2] == ["Hello snow", "Open door"]
        beats = json.loads(zf.read("beats.json"))
        assert beats["bpm"] == 160 and beats["sections"][1] == {"name": "verse1", "t": 1.5}
        audio, sr = ogg.decode(zf.read("music.ogg"))
        assert sr == 44100 and audio.shape[0] == 2
        assert abs(mixer.loudness(audio) + 16.0) < 1.0
        jump, flux = seam_metrics(audio, meta["loop_start"])
        assert jump < 1.5 and flux < 2.0
    capsys.readouterr()
    mtime = path.stat().st_mtime_ns
    assert cli.main(["render", "--all", "--changed"]) == 0
    assert "unchanged, skipped" in capsys.readouterr().out
    assert path.stat().st_mtime_ns == mtime


def test_render_is_deterministic(fixture_repo):
    cli.main(["render", "--all"])
    first, _ = _bundle(fixture_repo)
    data = first.read_bytes()
    first.unlink()
    (fixture_repo / "generated" / "manifest.json").unlink()
    cli.main(["render", "--all"])
    second, _ = _bundle(fixture_repo)
    assert second.read_bytes() == data


def test_check_passes_on_fixture(fixture_repo):
    cli.main(["render", "--all"])
    spec = all_specs(fixture_repo)[0]
    report = check_spec(spec, fixture_repo / "generated", signature_owners([spec]))
    assert report.ok, "\n".join(report.lines)


def test_master_hits_loudness_and_true_peak():
    rng = np.random.default_rng(1)
    t = np.arange(44100 * 6) / 44100
    x = np.vstack([np.sin(2 * np.pi * 220 * t), np.sin(2 * np.pi * 330 * t)]) * 0.9 + 0.1 * rng.standard_normal((2, len(t)))
    y, lufs, tp = mixer.master(x)
    assert abs(lufs + 16.0) < 0.5
    assert tp <= -1.0 + 1e-6
    assert abs(mixer.loudness(y) - lufs) < 1e-6


def test_ogg_is_byte_deterministic():
    x = np.sin(np.linspace(0, 2000, 44100))[None, :].repeat(2, axis=0) * 0.5
    assert ogg.encode(x) == ogg.encode(x)
