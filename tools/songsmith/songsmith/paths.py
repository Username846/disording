"""Repository paths."""

from __future__ import annotations

from pathlib import Path

PACKAGE_DIR = Path(__file__).resolve().parent
VENDOR_DIR = PACKAGE_DIR.parent / "vendor"


def find_repo_root(start: Path | None = None) -> Path:
    """Walk up from ``start`` (default: cwd) to the folder holding project.godot or PLAN.md."""
    candidates = [Path.cwd() if start is None else Path(start).resolve(), PACKAGE_DIR]
    for origin in candidates:
        for folder in [origin, *origin.parents]:
            if (folder / "project.godot").exists() or (folder / "PLAN.md").exists():
                return folder
    raise FileNotFoundError("Could not find the repository root (no project.godot or PLAN.md above)")


def all_specs(root: Path) -> list[Path]:
    """The menu song plus every day's song.yaml, in a stable order."""
    specs: list[Path] = []
    menu = root / "music" / "menu" / "song.yaml"
    if menu.exists():
        specs.append(menu)
    specs.extend(sorted((root / "days").glob("day_*/song.yaml")))
    return specs


def bundle_id_for(spec_path: Path) -> str:
    """``music/menu/song.yaml`` → ``menu``; ``days/day_007/song.yaml`` → ``day_007``."""
    parent = spec_path.resolve().parent
    if parent.name == "menu" and parent.parent.name == "music":
        return "menu"
    return parent.name
