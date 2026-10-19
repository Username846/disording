"""Command line: ``python -m songsmith {render,check,list} …``"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

from .bundle import build_bundle, load_manifest, write_bundle
from .render import render_song
from .paths import all_specs, bundle_id_for, find_repo_root
from .spec import load_song, spec_hash


def _specs(args: argparse.Namespace, root: Path) -> list[Path]:
    if args.all:
        return all_specs(root)
    if not args.specs:
        raise SystemExit("Give spec paths or --all")
    return [Path(s).resolve() for s in args.specs]


def cmd_render(args: argparse.Namespace) -> int:
    root = find_repo_root()
    out_dir = Path(args.out).resolve() if args.out else root / "generated"
    manifest = load_manifest(out_dir)
    for spec in _specs(args, root):
        bundle_id = bundle_id_for(spec)
        digest = spec_hash(spec)
        entry = manifest.get("bundles", {}).get(bundle_id)
        if args.changed and entry and entry.get("spec_hash") == digest and (out_dir / entry["file"]).exists():
            print(f"{bundle_id}: unchanged, skipped")
            continue
        start = time.time()
        song = load_song(spec)
        rendered = render_song(song)
        data, meta = build_bundle(song, bundle_id, rendered, digest)
        entry = write_bundle(out_dir, bundle_id, data, digest)
        manifest = load_manifest(out_dir)
        if args.debug_wav:
            import soundfile as sf

            wav_dir = out_dir / "debug" / bundle_id
            wav_dir.mkdir(parents=True, exist_ok=True)
            sf.write(wav_dir / "music.wav", rendered.music.T, 44100)
            for name, audio in rendered.stingers.items():
                sf.write(wav_dir / f"{name}.wav", audio.T, 44100)
            for name, audio in rendered.sfx.items():
                sf.write(wav_dir / f"sfx_{name}.wav", audio, 44100)
        print(
            f"{bundle_id}: {entry['file']} {entry['bytes'] / 1e6:.2f} MB, "
            f"{meta['duration'] / 60:.2f} min, {meta['lufs']:.1f} LUFS, {meta['true_peak_db']:.1f} dBTP, "
            f"rendered in {time.time() - start:.1f} s"
        )
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    from .check import check_spec, signature_owners

    root = find_repo_root()
    out_dir = Path(args.out).resolve() if args.out else root / "generated"
    specs = _specs(args, root)
    owners = signature_owners(all_specs(root) if not args.specs else sorted(set(all_specs(root) + specs)))
    failed = 0
    for spec in specs:
        report = check_spec(spec, out_dir, owners)
        print(f"{report.bundle_id}: {'OK' if report.ok else 'FAILED'}")
        print("\n".join(report.lines))
        failed += not report.ok
    return 1 if failed else 0


def cmd_list(args: argparse.Namespace) -> int:
    from .patches import REGISTRY
    from .voice.personas import PERSONAS

    print("Patches:")
    for name in sorted(REGISTRY):
        doc = REGISTRY[name].doc
        print(f"  {name}" + (f" — {doc}" if doc else ""))
    print("Personas:")
    for name in sorted(PERSONAS):
        print(f"  {name}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="songsmith", description="Disording's offline music renderer")
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("render", "check"):
        p = sub.add_parser(name)
        p.add_argument("specs", nargs="*")
        p.add_argument("--all", action="store_true", help="menu + every days/day_*/song.yaml")
        p.add_argument("--out", help="output folder (default: <repo>/generated)")
        if name == "render":
            p.add_argument("--changed", action="store_true", help="skip specs whose bundle is up to date")
            p.add_argument("--debug-wav", action="store_true", help="also write WAVs to <out>/debug/ for listening")
    sub.add_parser("list")
    args = parser.parse_args(argv)
    return {"render": cmd_render, "check": cmd_check, "list": cmd_list}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
