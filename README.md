# Disording: the 100-door calendar

A hundred tiny games behind a hundred advent-calendar doors. Each one is a rare genre with its own song,
sung by a synthesized voice. Open one door a day.

**Play:** https://username846.github.io/disording/ (works in any modern browser on PC or phone; no install).

- Only door 1 is open at first. Finish a door's game and the next door opens the following day.
- Every game works with one finger or the mouse.
- On a phone, turn it sideways. On iPhone, **Share → Add to Home Screen** plays full screen and keeps your
  progress safe.
- Settings → **Copy save code** moves your calendar to another device.

---

## For developers

The full design is in [`PLAN.md`](PLAN.md), the 100 game briefs (spoilers!) in
[`docs/GAMES.md`](docs/GAMES.md), progress in [`docs/STATUS.md`](docs/STATUS.md) and the recipe for building a
day in [`docs/HOW_TO_ADD_A_DAY.md`](docs/HOW_TO_ADD_A_DAY.md).

| Task | Command |
|---|---|
| Get Godot 4.7.2 + web templates | `python3 tools/ci/fetch_godot.py --dest ~/.local/bin` |
| Python deps (music renderer, linters) | `pip install -r tools/songsmith/requirements.txt gdtoolkit==4.5.0` |
| Render songs (changed only) | `PYTHONPATH=tools/songsmith python -m songsmith render --all --changed` |
| Check songs | `PYTHONPATH=tools/songsmith python -m songsmith check --all` |
| Godot tests (import, compile, unit, smoke) | `GODOT=godot tools/ci/godot_tests.sh` |
| Lint GDScript | `gdformat --check --line-length 120 autoload core menu days tests dev && gdlint autoload core menu days tests dev` |
| Web build into `build/site` | `GODOT=godot tools/ci/build_web.sh` |
| Size budgets | `python3 tools/ci/check_budgets.py` |
| Browser smoke test | `cd tests/web && npm install && node smoke.mjs ../../build/site --shots ../../build/shots` |

Pushing to `main` runs `.github/workflows/deploy.yml`, which renders audio, exports, tests and publishes
to GitHub Pages. The release build is at the site root, and a preview build with developer tools is at
`/preview/`.

**One-time setup:** in *Settings → Pages → Build and deployment*, set the source to **GitHub Actions**.

Credits and third-party licences are listed in [`CREDITS.md`](CREDITS.md).
