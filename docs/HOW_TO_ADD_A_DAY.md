# How to add a day

This is the per-day recipe (PLAN.md §9) with code pointers. Each step from 2 to 101 builds one day.

## 0. Before you start

- Read the day's brief in [`GAMES.md`](GAMES.md): pitch, controls, run, win/lose, secret, song.
- Read [`../PLAN.md`](../PLAN.md) §4.3 (no easier mode), §5 (one-pointer rule) and §8 (design rules).
- Copy `days/_template/` to `days/day_NNN/` (Step 2 creates the template from Day 1; until then
  `days/day_000/` shows the contract in use).

## 1. Song: `days/day_NNN/song.yaml`

Spec format: [`tools/songsmith/README.md`](../tools/songsmith/README.md). Requirements:

- Original lyrics with at least 2 sung verses and a chorus. Use the brief's hook line. Write for the synth: open vowels
  on long notes, simple words, the hook repeated.
- Mark exactly one instrument `signature: true`. Its patch must be new and used by no other day; add it under
  `tools/songsmith/songsmith/patches/`.
- Pick or add a voice persona (`tools/songsmith/songsmith/voice/personas.py`).
- Add `win` and `lose` stingers and the day's SFX names.

```bash
PYTHONPATH=tools/songsmith python -m songsmith render days/day_NNN/song.yaml
PYTHONPATH=tools/songsmith python -m songsmith check days/day_NNN/song.yaml
# --debug-wav writes listenable WAVs to generated/debug/
```

## 2. Door info: `days/day_NNN/info.tres`

The stub already has the title, genre, pitch, estimate, palette, `scene_path` and `bundle_id`. Add three
`hints` as `"icon|Text"` pairs. Icons are `tap`, `double_tap`, `hold`, `drag`, `flick`, `swipe`, `draw`, `pinch` and
`timer`. Once `game.tscn` exists, `tools/ci/gen_day_stubs.py` stops touching this file.

## 3. The game: `days/day_NNN/game.tscn` + `game.gd`

The root node's script `extends DayGame` (`core/day/day_game.gd`). Use only `ctx`:

| Need | Use |
|---|---|
| Start / restore | override `_day_start()`, `_day_restore(checkpoint)` |
| End the run | `succeed(stats)` once, or `fail(reason, "Player-facing why")` |
| Gestures | `ctx.input` signals: `tapped`, `double_tapped`, `long_pressed`, `pressed`, `released`, `drag_started`, `dragged`, `drag_ended`, `swiped`, `pinched` |
| HUD | `ctx.hud.set_lives()`, `set_timer()`, `set_score()`, `set_label()`, `toast()` |
| Sound | `ctx.audio.play_sfx(&"name", {pitch_jitter = 0.05})`, `ctx.audio.beat` / `bar` signals, `music_time()`, `beat_length()` |
| Randomness | `ctx.rng` (seeded per attempt) |
| Settings | `ctx.settings.reduce_motion()`, `left_handed()` |
| Secret | `ctx.award_star(screen_pos)`: wordless twinkle and chime, saved immediately |
| Checkpoint | `checkpoint({...})` at phase boundaries (runs longer than 8 min) |
| Haptics | `ctx.haptic(ms)` |

Rules:

- Code under `days/day_NNN/` may use `core/**` but never another day's folder. When a second day needs the same
  code, move it to `core/kits/`.
- Draw art procedurally or keep it tiny. The whole day should add 150 KB or less to the main pack.
- Override `_qa_force(&"star")` so it performs the **real** secret trigger, the way Day 0 taps its moon.

## 4. Test it

```bash
GODOT=godot tools/ci/godot_tests.sh          # compile check, unit tests, smoke (fuzz + forced outcomes on every built day)
GODOT=godot tools/ci/build_web.sh && python3 tools/ci/check_budgets.py
cd tests/web && node smoke.mjs ../../build/site --shots ../../build/shots
```

Add `tests/unit/test_day_NNN.gd` for any non-trivial rules (scoring, AI decisions, recognizers).

## 5. Tune and ship

- Play the preview build (`/preview/`). The 🛠 dev panel can jump to the day, fake the date and show the perf
  HUD and telemetry. Aim for a first-clear median of 8–12 min, never under 5 or over 15.
- Worst phase in Chrome with 4× CPU throttle and Pixel emulation: ≥ 30 fps on real hardware and ≤ 150 draw calls.
- Update the day's row in [`STATUS.md`](STATUS.md), then commit and push. Check the deployed preview.
