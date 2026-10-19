# Disording: The 100-Door Calendar · Master Plan

A Godot **4.7.2** game, playable straight from GitHub Pages on PC (mouse) and phones (touch). It's built like an
advent calendar: 100 doors, each hiding a small, complete game in a rare genre, each with its own song: its own
instruments, plus verses sung by a synthesized voice. Only Door 1 is open at the start. Finishing a door's game
unlocks the next door **the following calendar day**. Every game also hides a secret that earns a **gold star** on
its door, and nothing in the game ever tells the player that stars exist.

| Document | What it holds |
|---|---|
| `PLAN.md` (this file) | Decisions, architecture, systems spec, conventions, roadmap, definition of done |
| [`docs/GAMES.md`](docs/GAMES.md) | The 100 game design briefs plus the calendar menu song (contains spoilers) |
| [`game_list.txt`](game_list.txt) | The source list each day riffs on. The player sees it as an "Inspired by …" line |

Working title: **Disording** (the repo name). Change it in `project.godot` → `application/config/name` whenever you like.

---

## 0. TL;DR

- **Step 1** builds the whole platform: the Godot project, the calendar menu, save and unlock logic, the input and
  audio systems, the offline music and singing-voice renderer ("Songsmith"), the web shell, CI and Pages deploy,
  and the test harness. It ships with all 100 doors visible and Door 1 showing "being painted".
- **Step 2** builds Day 1 (*Toybox Ring-Out*). It becomes the reference implementation every later day copies.
- **Steps 3–101** each build exactly one day (Day 2 … Day 100) from its brief in `docs/GAMES.md`, using the same
  per-day checklist (§9) and the same definition of done (§10).
- **Key technical decisions:**
  - 2D only, on the **Compatibility (WebGL 2)** renderer.
  - **Single-threaded** web export, so it runs on GitHub Pages without special headers and on iOS Safari.
  - **GDScript only** (C# can't export to the web).
  - Music, singing voices and SFX are **rendered offline** into small OGG bundles that are downloaded on demand per
    day, so nothing is synthesized at runtime and the first load stays small.
- **To run a step,** start a session with *"Do Step N of PLAN.md"*. The step's brief, the recipe (§9) and the
  definition of done (§10) contain everything needed. Record the outcome in `docs/STATUS.md`.

---

## 1. Reading of the brief and decisions

| Brief says | Decision |
|---|---|
| "Godot 4.7.2" | Pin **exactly 4.7.2-stable** (released Aug 2026) for the editor, the CI binary and the export templates. `project.godot` declares the `4.7` feature. Don't upgrade without a dedicated step. |
| "playable … from the browser from github directly" | Deploy to **GitHub Pages** with GitHub Actions: `https://username846.github.io/disording/`. A release build goes at the root and an unlisted **preview** build (dev tools on) at `/preview/` (§7.6). |
| "touch/mouse … PC and Mobile" | **One-pointer rule** (§5): everything works with one finger or the left mouse button. No hover, right-click, keyboard or required multi-touch. Landscape, 1280×720 reference. |
| "Make it performant" | Budgets in §2. 2D only, Compatibility renderer, typed GDScript, pooling, MultiMesh, no runtime audio synthesis, lazy per-day audio bundles, small main pack. |
| "Plug and Play" | Open the URL and play: no install, account or download step. It's also an installable **PWA** (home-screen icon, landscape, offline after first visit). |
| "100 unique games in rare genres" | Each day riffs on one entry of `game_list.txt`, reimagined as an **original** game in a genre used by no other day (`docs/GAMES.md`). **No characters, logos, music or assets** from those games are used. Each game shows the player its source as a plain-text "Inspired by …" line (intro card, HUD during play, pause menu). |
| "own music … own instruments … verses with simulated voices singing lyrics" | Each day has a ~4–5 min loopable song with ≥ 2 sung verses plus a chorus, a **signature instrument used by no other day**, and its own **voice persona**. Songs are rendered offline by **Songsmith** (§6), a Python synth with a formant-based singing synthesizer. Lyrics show as optional captions. |
| "advent calendar … day 1–100 … only 1 unlocked" | The calendar menu has 100 doors (§4). Door 1 is unlocked on first launch. |
| "complete a game → next unlocks on the following day" | Door N+1 unlocks at **local midnight after** the day Door N was first completed (§4.2). Finished doors can be replayed any time. |
| "success state and fail state, 5–15 min" | The `DayGame` contract (§3.4) has `succeed()` and `fail()` and nothing in between. Each brief targets 8–12 min for a first clear and **never** under 5 or over 15 (§8). |
| "easter egg … gold star … player is not told" | Each day calls `ctx.award_star()` on its secret. There is no UI text, tutorial or counter until the first star is found (§8.4). |
| "menu and systems in step 1, first game in step 2, then one step per game" | The roadmap in §11. |

**Assumptions** (change them before Step 1 if any are wrong):

1. The list is *inspiration*. We make original games, never clones or fan games of the listed titles.
2. English only, landscape only, local-device time for unlocks.
3. An unlisted `/preview/` build with dev tools is acceptable (it's how a human can test Day 57 without waiting 56 days).
4. Day bundles are generated in CI, not committed, so rendered audio is never stored in git.

---

## 2. Hard constraints and performance budgets

| Area | Constraint / budget |
|---|---|
| Engine | Godot **4.7.2-stable**, GDScript with static typing (`untyped_declaration` warning on). No C#, no GDExtension. |
| Renderer | `gl_compatibility` on every platform. 2D only; pseudo-3D only via 2D math or shaders. |
| Web export | **Thread support off** (`variant/thread_support=false`), wasm32 (do **not** use 4.7's wasm64 option: Safari can't run it), PWA on, custom HTML shell. |
| Browsers | Last 2 versions of Chrome/Edge, Firefox, Safari (macOS and **iOS 16.4+**), Android Chrome, Samsung Internet. WebGL 2 required. |
| Frame rate | 60 fps on a mid phone (e.g. 2021 Android, Snapdragon 7-series, or iPhone 11). Must hold ≥ 30 fps on the low reference (2020 Moto G / Snapdragon 665) and in Chrome with 4× CPU throttling. |
| Frame budget | ≤ 4 ms game logic (low reference), ≤ 150 draw calls, ≤ 2,000 nodes in the tree, ≤ 300 active particles, zero per-frame allocations in hot loops. |
| First load | Engine wasm + main `.pck` + menu bundle: **≤ 20 MB** over the wire (target ≤ 15 MB). Boot to "Tap to open" in ≤ 6 s on 4G and a mid phone. |
| Main pack | `index.pck` **≤ 12 MB** with all 100 days' code and art (≈ 100 KB code + art per day on average). |
| Day bundle | `day_NNN.bundle.zip` **≤ 3.5 MB** (music ~2.5 MB, stingers, SFX, lyrics, beat map). It loads behind the door-opening animation. |
| Memory | ≤ 300 MB JS heap on mobile. Only the current day's audio is decoded. Only the current day's scene is alive. |
| Saves | ≤ 64 KB JSON, written atomically, schema-versioned with migrations. |
| Input | Touch targets ≥ **72 px** (primary) and ≥ 56 px (secondary) at 1280×720. Every action works with a single pointer. |

---

## 3. Architecture

### 3.1 Repository layout

```
project.godot               # 4.7.2, Compatibility, canvas_items stretch, 1280×720, autoloads
export_presets.cfg          # "Web" (release) + "Web Preview" (debug, dev tools)
.gitignore .gitattributes   # ignore .godot/, generated/, build/; LF line endings
README.md                   # player-facing: link, how to play, credits, licence

autoload/                   # singletons (see 3.3)
core/
  day/                      # DayGame base, DayContext, DayInfo resource, DayResult
  ui/                       # theme.tres, fonts, Button/Dialog/Toast/HUD/PauseMenu/VirtualStick/Captions
  kits/                     # shared gameplay kits, extracted only once 2+ days need them (3.7)
  util/                     # pool, rng, spatial_hash, tween_presets, draw helpers, fsm
menu/                       # boot, title, calendar, door, day_intro, results, settings, credits, dev_panel
days/
  _template/                # copied for each new day (made in Step 2 from Day 1)
  day_000/                  # "Test Room": debug-only fixture for the contract (excluded from release)
  day_001/ … day_100/       # info.tres, game.tscn, game.gd, parts/, song.yaml, door_art.gd
music/menu/song.yaml        # calendar theme spec
generated/                  # .gdignore'd. Songsmith output: per-day bundles (gitignored)
tools/                      # .gdignore'd (Godot never scans it)
  songsmith/                # Python package: offline music, voice and SFX renderer (section 6)
  ci/                       # fetch_godot.py, godot_tests.sh, build_web.sh, assemble_site.py,
                            #   check_budgets.py, gen_day_stubs.py
dev/                        # Godot-side dev scripts: make_icons.gd, day1_sim.tscn (headless tuning harness)
tests/
  test_runner.tscn          # unit tests + platform smoke (run with --fixed-fps 60 -- --test)
  script_check.tscn         # compiles every script with autoloads active
  unit/                     # calendar, save, gestures, registry
  smoke/                    # every implemented day: fuzz input, forced outcomes, unlock rules
  web/                      # Playwright smoke.mjs: release, preview Day 0, phone + throttle
web/
  shell.html                # custom HTML shell: loader UI, gesture locks, safe areas, rotate hint
  icons/ manifest overrides
docs/
  GAMES.md                  # design briefs (spoilers)
  STATUS.md                 # living tracker: one row per step (created in Step 1)
  HOW_TO_ADD_A_DAY.md       # the per-day recipe (section 9), with code pointers (created in Step 1)
.github/workflows/
  ci.yml                    # lint + unit + smoke + songsmith tests on PRs and pushes
  deploy.yml                # render audio, export, assemble, budget-check, deploy to Pages on main
```

### 3.2 Scene flow

```
Boot (engine loaded) ─► Title "Tap to open" (unlocks audio and fullscreen on mobile)
   └─► Calendar (100 doors, scroll; "Today" button jumps to the newest open door)
         ├─► Settings / Credits / (Dev panel: preview builds only)
         └─► Door tap ─► open animation ─► Day Intro card (title, genre, 3 icon hints, est. time, Play)
                 │           (the day's audio bundle downloads during the animation and intro)
                 └─► Day N (DayGame) ── Pause ─► Resume / Restart / Settings / Leave
                        ├─ succeed() ─► Results: Success (stinger, time, "Door N+1 opens tomorrow")
                        └─ fail()    ─► Results: Fail (stinger, Retry, Retry-from-checkpoint?, Calendar)
```

### 3.3 Autoload services

Each service is a small typed script with one job. Services never reference day code. Days talk to the platform only
through `DayContext`.

| Autoload | Responsibility |
|---|---|
| `App` | Boot order, build info (version, commit, preview flag), feature detection (`OS.has_feature("web")`, `web_android`/`web_ios` tags), quality tier choice. |
| `Clock` | Injectable "now" (system time, or a fake time in tests and the dev panel). `today_local() -> String "YYYY-MM-DD"`, `seconds_until_local_midnight()`. Monotonic guard: `effective_today = max(system_today, save.last_seen_date)`. |
| `SaveService` | Loads and saves `user://disording/save.json` (or `save_preview.json` in preview builds, so the two never collide on the shared `github.io` origin). Atomic write (tmp then rename), schema version and migrations, debounced writes, export/import as a "save code" string. On web, asks for persistent storage via `navigator.storage.persist()` through `JavaScriptBridge`. |
| `Calendar` | Pure unlock rules over the save and `Clock` (§4.2). Emits `door_state_changed`. Fully unit-tested with a fake clock. |
| `DayRegistry` | Loads the 100 `DayInfo` resources (`days/day_NNN/info.tres`). Knows `implemented` from `info.scene_path` existing in the pack. Gives the menu titles, genres, thumbnails and estimated minutes. |
| `Router` | Scene changes with fade/door transitions. Calls `ResourceLoader.load_threaded_request` with progress. Frees the previous scene and waits a frame before showing the next. |
| `Gestures` (InputHub) | Normalizes touch and mouse into one pointer stream and recognizes gestures (§5). |
| `Audio` (AudioDirector) | Music players (A/B crossfade, **Stream** playback), SFX pool (**Sample** playback), stingers, ducking, captions clock, volumes, first-gesture unlock. |
| `Bundles` (RemoteAssets) | Downloads `generated/day_NNN.bundle.zip` with `HTTPRequest` and progress, parses it (`ZIPReader` over a temp file in `user://disording/cache/`), and builds `AudioStreamOggVorbis.load_from_buffer()` streams. Keeps an LRU of the 2 most recent bundles. On desktop/editor it reads from the local `generated/` folder. |
| `Settings` | Music/SFX volume, captions, haptics, reduce motion, left-handed HUD, quality (Auto/Fast/Sharp), fullscreen, reset progress, save-code export/import. |
| `Haptics` | `Input.vibrate_handheld()` where supported. Honours the setting and is a no-op on iOS and desktop. |
| `Telemetry` | **Local only**, no network: per-day attempt count, durations, fail reasons. Shown in the dev panel and used to tune each game to 5–15 min. |

### 3.4 The day contract

Every day is a scene whose root script extends `DayGame`. This is the entire API a day may use:

```gdscript
# core/day/day_game.gd
class_name DayGame
extends Node2D

signal finished(result: DayResult)   # emitted once; Router listens

var ctx: DayContext                  # injected before _day_start()

## --- Overridables --------------------------------------------------------
func _day_start() -> void: pass                   # build the level and start phase 1
func _day_pause(paused: bool) -> void: pass       # stop timers/AI (tree pause handles most)
func _day_restore(checkpoint: Dictionary) -> void: pass  # optional: resume from checkpoint
func _qa_force(outcome: StringName) -> void: pass # tests: &"success", &"fail", &"star"

## --- Calls a day makes ---------------------------------------------------
func succeed(stats: Dictionary = {}) -> void      # → Results: success (idempotent)
func fail(reason: StringName = &"") -> void       # → Results: fail (idempotent)
func checkpoint(data: Dictionary) -> void         # optional "retry from here" data (session only)
# ctx.award_star()              → saves immediately, subtle twinkle + chime, no text
# ctx.audio.play_sfx(&"hit", {pitch_jitter = 0.08})
# ctx.audio.beat_clock          → beats/bars from the song's beat map (rhythm sync)
# ctx.rng                       → seeded RandomNumberGenerator (seed shown in dev panel)
# ctx.input                     → InputHub gesture signals scoped to this day
# ctx.hud                       → shared HUD widgets (lives, timer, score, pause button)
# ctx.settings                  → reduce_motion, left_handed, haptics, quality tier
```

- `DayInfo` (a Resource, one per day) holds: `day:int`, `title`, `genre`, `pitch` (one line), `hints: Array[HintIcon]`
  (three icon and verb pairs such as "drag back → aim"), `est_minutes`, `scene_path`, `bundle_id`, `palette`,
  `thumbnail`, and `implemented:bool`.
- **Isolation rule:** files under `days/day_NNN/` may use `core/**` but never another day's folder. Shared code moves
  into `core/kits/` (§3.7).
- **Pause:** the Router sets `get_tree().paused`. The day root uses `PROCESS_MODE_PAUSABLE` and the HUD and pause menu
  use `PROCESS_MODE_ALWAYS`. The game auto-pauses on focus loss (`NOTIFICATION_APPLICATION_FOCUS_OUT`, plus a JS
  `visibilitychange` callback on web).

### 3.5 Save schema (v1)

```json
{
  "version": 1,
  "first_launch": "2026-11-01",
  "last_seen_date": "2026-11-03",
  "days": {
    "1": { "completed_on": "2026-11-01", "best_seconds": 562, "attempts": 3, "fails": 2,
           "star": true, "last_played": "2026-11-02" }
  },
  "settings": { "music": 0.8, "sfx": 0.9, "captions": true, "haptics": true, "reduce_motion": false,
                "left_handed": false, "quality": "auto" },
  "flags": { "seen_title_tip": true, "first_star_seen": true }
}
```

Migrations are `func migrate_v1_to_v2(d: Dictionary) -> Dictionary` functions in `SaveService`, and each one has a unit
test.

### 3.6 Asset strategy (why the first load stays small)

- **In the main `.pck`:** all code, scenes, the UI theme, two fonts (an OFL font, MSDF), small procedural art
  helpers, and per-day thumbnails (≤ 12 KB WebP each). Art is **procedural or vector first**: `_draw()` cached into
  `ArrayMesh`/`MultiMesh`, `Polygon2D`, `Line2D`, small shaders, and textures generated once at load
  (`Image` → `ImageTexture`). Each day keeps its art and code ≤ 150 KB.
- **Outside the pack, downloaded on demand:** `generated/day_NNN.bundle.zip` holds `music.ogg`, `win.ogg`, `lose.ogg`,
  `sfx/*.ogg`, `lyrics.json`, `beats.json` and `meta.json`. One request per day, browser-cached, and kept in a
  2-entry LRU in `user://` (IDBFS mirrors to RAM on web, so a bounded cache matters).
- **No runtime synthesis.** Every audio file comes out of Songsmith. Reverb, EQ and compression are **baked in**,
  because bus effects can't be relied on for Sample-mode playback on web.
- If a day ever needs large textures, they go into its bundle as WebP and load with
  `Image.load_webp_from_buffer()`. They don't go into the main pack.

### 3.7 Shared gameplay kits (`core/kits/`)

The rule of two: write it inside the day first, and extract it into a kit when a second day needs it. These kits are
expected, with the first day that needs each:

| Kit | First needed by | Contents |
|---|---|---|
| `circle_physics` | Day 1 | Lightweight deterministic circle/segment physics (impulses, friction, restitution, ring-out). Cheaper than `RigidBody2D` for dozens of bodies. |
| `grid` | Day 3 | Grid model, A* on grids, tile picking, fog of war, coordinate helpers |
| `ai_fsm` | Day 1 | Tiny state machine plus utility scoring for opponents |
| `rhythm` | Day 17/51 | Beat clock from `beats.json` plus latency calibration, timing windows, judgement UI |
| `cards` | Day 25/45 | Deck, hand, drag-to-play, flip animations |
| `dialogue` | Day 24/33 | Text boxes, choices, portraits drawn procedurally, typewriter effect |
| `timeline` | Day 18/87 | Scrubbable timeline UI, keyframed playback, rewind |
| `gesture_glyph` | Day 31 | $1/$P-style unistroke recognizer (also used on Days 82, 63) |
| `rope` | Day 20/43 | Verlet rope or line with tension (fishing line, tether) |
| `map_route` | Day 6/27 | Node-graph travel maps, travel time, events |
| `juice` | Day 1 | Screen shake (respects reduce motion), hit-stop, squash/stretch, confetti (CPUParticles2D presets) |

---

## 4. Calendar and unlock system

### 4.1 Door states (menu)

| State | Look | Tap does |
|---|---|---|
| `LOCKED` | Closed door, number, padlock | Shake plus padlock rattle |
| `UNLOCKS_TOMORROW` | Closed, glowing edge, countdown "opens in 5 h 12 m" | Toast with the countdown |
| `OPEN` | Closed, shimmer, gentle knock animation | Opens: intro card |
| `PLAYED` | Door ajar (attempted, not completed) | Intro card |
| `COMPLETED` | Door wide open, showing the day's thumbnail art | Intro card (replay) |
| `COMPLETED + STAR` | As above, plus a gold star stamp | Intro card (replay) |
| `BEING_PAINTED` | "Wet paint" sign (day not built yet, see Step 1) | Toast: "This door is still being painted." |

Layout: a 10-column grid (each door ~112 px at 1280 wide) that scrolls vertically. It's styled as a snowy townhouse
façade with ten floors, and each floor is a seasonal band. A **Today** button scrolls to the newest open door. Stars
and the star tally ("★ 3", found stars only, never "/100") **don't appear anywhere until the first star is found**.

### 4.2 Unlock rules (pure functions, unit-tested)

```gdscript
func is_unlocked(n: int) -> bool:
    if n == 1: return true
    var prev := save.day(n - 1)
    if prev.completed_on == "": return false
    return Clock.effective_today() > prev.completed_on        # ISO dates compare lexicographically

func state(n: int) -> DoorState:
    if not DayRegistry.implemented(n) and _would_be_open(n): return BEING_PAINTED
    ...
```

- "Completed" means `succeed()` was reached at least once. `completed_on` is set **only on the first** success. A
  replay success updates `best_seconds` but never moves the date.
- Completing Door N at 23:59 opens Door N+1 at 00:00 local time. That's literally "the following day".
- **Clock rollback** never re-locks anything (`effective_today` is monotonic). Clock-forward cheating is possible
  offline and accepted; it's a single-player gift box.
- Stars persist the moment they're earned, even if the run then fails, and they can be earned on replays.
- **Dev overrides** exist only in preview and debug builds: unlock all, set the fake date, jump to a day, force
  success/fail/star, and reset.

### 4.3 Difficulty and retries

- **There is no easier mode.** Each day has one fixed difficulty, and the game never offers to lower it after
  failures.
- The daily gate means a player who can't beat a door can't see the rest, so each day is tuned (§8.2) so that a new
  player can clear it within a few attempts. Runs longer than about 8 min may offer **retry from checkpoint**
  (phase-level, session-only). It restarts a phase at the same difficulty.

---

## 5. Input model (touch and mouse as one)

- Project settings: `input_devices/pointing/emulate_touch_from_mouse = true`. All gameplay reads
  `InputEventScreenTouch` and `InputEventScreenDrag` (pointer index 0 is the mouse). UI `Control`s work natively.
- **InputHub gestures** (thresholds are in reference pixels and scale with the stretch factor):

| Gesture | Recognition | Mouse equivalent |
|---|---|---|
| tap / double-tap | ≤ 250 ms, ≤ 12 px travel; double ≤ 300 ms apart | click / double-click |
| long-press | ≥ 450 ms, ≤ 12 px | hold the left button |
| drag (start/move/end) | > 12 px travel | left-drag |
| swipe (dir + velocity) | release velocity > 900 px/s | fast left-drag |
| flick / slingshot | drag-back and release, power = clamp(dist) | same |
| circle (rotation accumulate) | angular delta around the centroid | circular drag |
| pinch / zoom | 2 touches (optional) | mouse wheel **and** on-screen ± buttons (always present) |

- **Never required:** hover, right-click, keyboard, two simultaneous touches. Keyboard and gamepad are optional extras
  on PC (Esc pauses; arrows/space where natural).
- **Godot 4.7's built-in virtual joystick:** Step 1 checks that it works with mouse and touch on web. If it doesn't,
  `core/ui/virtual_stick.tscn` is a floating stick that appears where the thumb lands.
- **Safe areas:** the shell reads the CSS `env(safe-area-inset-*)` values and passes them to `App`, and the HUD keeps
  its margins inside them.
- **Handedness:** a left-handed setting mirrors the HUD anchors, so days must use the HUD anchors rather than hard-coded
  sides.
- Browser gesture suppression lives in the shell (§7.2): no pull-to-refresh, no pinch-zoom of the page, no long-press
  context menu, no text selection, no double-tap zoom.

---

## 6. Audio: runtime and the Songsmith pipeline

### 6.1 Runtime (AudioDirector)

- **Music:** two `AudioStreamPlayer`s with `playback_type = STREAM` (memory-friendly: a 4-min OGG isn't fully decoded
  into Web Audio buffers) and A/B crossfades. `loop = true` with `loop_offset` from `meta.json`, so the intro isn't
  repeated.
- **SFX:** a pool of 12 players with `playback_type = SAMPLE` (low latency on web), per-SFX concurrency caps,
  pitch/volume jitter, and voice stealing.
- **Stingers:** win/lose stingers duck the music by −12 dB.
- **Captions:** `lyrics.json` lines are shown from `playback_position + AudioServer.get_time_since_last_mix() −
  output_latency`. They're on by default (the formant voices are charming, not perfectly intelligible) and can be
  turned off.
- **Beat clock:** `beats.json` (beat and bar times, section markers) drives rhythm games and lets any day pulse its
  visuals to the music.
- **Web audio unlock:** the Title screen's "Tap to open" is the first user gesture, so the AudioContext resumes there.
  On iOS the shell sets `navigator.audioSession.type = 'playback'` (older iOS: a looping silent `<audio>` started on
  the first tap), so sound plays even with the ring/silent switch on silent.
- **Buses:** Master, Music and SFX are defined in `res://default_bus_layout.tres`. Never call `AudioServer.add_bus()`
  at runtime: on web it puts the browser-side sample buses in the wrong order and every Sample-playback sound goes
  silent. A unit test checks the layout and the browser smoke test measures real output for music and an SFX.
- **Web buffer:** single-threaded web builds mix Stream audio on the main thread between frames, so
  `audio/driver/output_latency.web = 150` (≈ 186 ms buffer) keeps music continuous down to ~10 fps. The beat clock
  subtracts `AudioServer.get_output_latency()`, which includes this buffer.
- **Step 1 must benchmark** Stream vs Sample playback for music on the low-reference phone and record the result in
  `docs/STATUS.md`. If Stream stutters under main-thread load, fall back to Sample with mono 32 kHz music.

### 6.2 Songsmith (offline renderer, `tools/songsmith/`)

A deterministic Python 3.12 package (`numpy`, `scipy`, `soundfile`/libsndfile for OGG Vorbis, `pyloudnorm`, `PyYAML`;
optionally `numba`). Run `python -m songsmith render days/day_001/song.yaml`, which writes to
`generated/day_001/` and builds the zip bundle.

**Song spec (`song.yaml`)**, one per day, plus `music/menu/song.yaml`:

```yaml
title: "Off the Edge"
bpm: 132
key: F major
swing: 0.12
seed: 1001
form: [intro, verse1, chorus, verse2, chorus, bridge, chorus, interlude, verse3, chorus, outro]
loop: { from: verse1 }                  # gameplay loops verse1 → end → verse1
target_minutes: 4.5
voice:                                  # persona; see 6.3
  persona: wind_up_child_choir
  range: [C4, A5]
  formant_scale: 1.22
  breath: 0.12
  vibrato: { rate: 5.6, depth_cents: 35, delay: 0.25 }
  unison: 6
  detune_cents: 9
  fx: [plate_small]
instruments:
  toy_piano:  { patch: modal.toy_piano, signature: true, pan: -0.2 }
  kazoo:      { patch: buzz.kazoo, pan: 0.3 }
  tuba:       { patch: brass.tuba_waveguide }
  snare:      { patch: drums.brush_snare }
  slide:      { patch: wind.slide_whistle }
sections:
  verse1:
    bars: 8
    chords: "F | Dm | Bb | C7 | F | Dm | Gm7 C7 | F"
    parts:
      tuba:  { pattern: root_fifth_2feel }
      snare: { grid: "x...x.x.x...x.xx" }
      toy_piano: { pattern: comp_offbeat }
    melody: >                            # syllable:pitch:beats   (- = melisma, _ = rest)
      Wind:C5:1 me:D5:0.5 up:F5:0.5 and:E5:1 watch:D5:1 me:C5:1 go:A4:3 _:1 ...
sfx:
  flick: { patch: sfx.rubber_twang, notes: [F5], dur: 0.25 }
  ringout: { patch: sfx.slide_whistle_down, dur: 0.7 }
stingers:
  win:  { from_section: chorus, bars: 2, lyric: "Crown on the toy box!" }
  lose: { tempo: 0.8, minor: true, lyric: "Wind me up again…" }
```

**Instrument engines** (patches are parameter sets on these. A signature instrument usually adds one new patch file
`tools/songsmith/patches/day_NNN_<name>.py`):

| Engine | Used for |
|---|---|
| Karplus-Strong / extended KS (`scipy.signal.lfilter` comb loops, buzz-bridge and sympathetic options) | lute, ronroco, koto, guzheng, banjo, bouzouki, balalaika, sitar, ukulele, jarana, 12-string, theorbo, pipa, harp |
| Bowed waveguide (stick-slip excitation plus body resonator) | viola da gamba, nyckelharpa, Hardanger fiddle, erhu, cello, saw, hurdy-gurdy (plus drone and wheel buzz), tagelharpa |
| Modal synthesis (decaying sine banks with measured ratios) | bells, handbells, toy piano, celesta, music box, vibraphone, kalimba, steel pan, anvils, glass harmonica, singing bowls, waterphone |
| FM (2–6 operators) | DX7 piano, M1 stabs, clavinet, brass stabs, metallic hits |
| Subtractive / VA (osc → ladder filter → env) | 303, Moog lead, Juno, CS-80, Solina, Reese, supersaw, SID pulse, 2A03 chip |
| Additive / drawbar | pipe organ, Hammond (with Leslie sim), calliope, harmonium, accordion |
| Reed and air (pulse or noise through formant body) | clarinet, sax, shawm, suona, uilleann pipes, harmonica, ocarina, flutes, whistles, kazoo, EWI |
| Drums and percussion (synthesized: noise, pitched sines, transient shaping) | all kits, taiko-style toms, congas, tabla-like, castanets, washboard, found metal |
| Special | theremin and ondes (sine/ribbon with portamento), turntable scratch (granular), reversed textures, tape/radio/BRR lo-fi emulation |

**Mix and master (all baked in):** per-part gain/pan, sends to a synthetic plate or hall IR (convolution), glue
compression, a −1 dBTP limiter, and loudness normalized to **−16 LUFS** so every day sounds equally loud. Output is
stereo OGG Vorbis at about 80 kbps (~2.4 MB for 4.5 min).

### 6.3 The singing voice (formant synthesis)

1. **Lyrics to phonemes:** CMUdict (BSD-licensed, vendored) gives ARPAbet, with letter-to-sound fallback rules and
   inline overrides (`{AH0 N}`) for odd words.
2. **Phonemes to notes:** syllables map 1:1 to melody tokens. The vowel nucleus is sustained over the note. Onset
   consonants start about 60 ms *before* the beat and codas sit at the note end. `-` extends a melisma.
3. **Source:** an LF/Rosenberg glottal pulse train at f0, with vibrato, 0.5% jitter, shimmer, portamento between
   notes, and aspiration noise set by `breath`.
4. **Filter:** a Klatt-style cascade of F1–F5 resonators for vowels and sonorants, and a parallel noise branch for
   fricatives (s, sh, f, th), plosive bursts and nasal pole-zero pairs. Formant targets are averaged
   Hillenbrand/Peterson-Barney data scaled by `formant_scale` (child ≈ 1.2, female ≈ 1.1, male 1.0, giant ≈ 0.8),
   interpolated over 30–60 ms for coarticulation.
5. **Personas** are parameter presets plus effects: choir (unison N, detune, per-voice formant jitter), vocoder,
   talkbox, overtone/throat (narrow resonant F2 sweep), whisper (noise-only source), countertenor, crooner (slow wide
   vibrato), auto-tuned (quantized pitch, zero portamento), radio/megaphone (band-limited), barbershop (4 parts from
   the chord tones), call-and-response.
6. **Lyrics are written for the synth:** open vowels on long notes, few consonant clusters, the hook repeated, short
   lines. Each song has ≥ 2 verses and a chorus. `lyrics.json` holds the line timings for captions.

### 6.4 Automated audio QA (`songsmith check`)

The checks: duration within the target ±15%, integrated loudness −16 ± 1 LUFS, true peak ≤ −1 dBTP, no unintended
silence > 2 s, a click-free loop seam (sample continuity and spectral flux at `loop_offset`), vocals present in ≥ 2
verse sections, signature instrument not used by any other day (registry check), and bundle size ≤ 3.5 MB.

---

## 7. Web delivery, build and deploy

### 7.1 Export presets

- `Web`: release, `variant/thread_support=false`, `html/custom_html_shell=res://web/shell.html`,
  `html/canvas_resize_policy=2` (adaptive), `progressive_web_app/enabled=true`, `orientation=landscape`, icons set,
  `ensure_cross_origin_isolation_headers=false` (not needed without threads), and `exclude_filter` for
  `days/day_000/*, tests/*, dev/*` (`tools/` is `.gdignore`d).
- `Web Preview`: a debug export of the same project with the `preview` feature tag enabled. It includes Day 0, turns on
  the dev panel and uses the separate save file. Its PWA is off, so its service worker can't clash with the release
  build's.

### 7.2 HTML shell (`web/shell.html`)

- A branded loader (a calendar door slowly opening, plus a progress bar and text).
- Viewport meta `width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover`.
- CSS: `touch-action:none; overscroll-behavior:none; user-select:none; -webkit-touch-callout:none`, and a full-bleed
  canvas.
- Suppress `contextmenu`, `gesturestart` and double-tap zoom. Expose `env(safe-area-inset-*)` to Godot.
- A portrait overlay ("Rotate for the best fit"), dismissable, after which the game continues letterboxed.
- A fullscreen button where the Fullscreen API exists (not on iPhone, where the hint suggests Add to Home Screen).
- Resolution policy (as built in Step 1): **Auto** renders phones in `viewport` stretch mode, which is the 2D canvas
  at the 1280×720 reference resolution scaled up (cheap on 3× DPR screens). Desktops use `canvas_items` (native
  resolution). Settings can force **Fast** (viewport) or **Sharp** (canvas_items). It switches at runtime through
  `Window.content_scale_mode`.

### 7.3 CI (`.github/workflows/ci.yml`, on PR and push)

1. `gdtoolkit` 4.5: `gdformat --check --line-length 120` and `gdlint` over `autoload core menu days tests dev`, plus
   a check that `days/*/info.tres` stubs match `docs/GAMES.md`.
2. Godot 4.7.2 headless (binary cached by version), all through `tools/ci/godot_tests.sh`, which also fails on any
   `SCRIPT ERROR`/`ERROR:` log line:
   - `--import`
   - `res://tests/script_check.tscn` compiles every script with the autoloads active.
   - `--fixed-fps 60 res://tests/test_runner.tscn -- --test` runs the unit tests (calendar rules, dates, save
     schema and save codes, gestures, registry), then the platform smoke test. The smoke test takes **every
     implemented day** through the real DayHost: 40 simulated seconds of fuzzed gestures, then
     `_qa_force(&"star"|&"fail"|&"success")`, checking the Save, Results, unlock rules and orphan nodes.
3. Songsmith: `pytest tools/songsmith` (DSP unit tests plus a 10-second render of a fixture song through `songsmith
   check`).

### 7.4 Deploy (`.github/workflows/deploy.yml`, on push to `main`)

1. **Render audio:** run `songsmith render --all --changed` with an `actions/cache` keyed on
   `sha256(song.yaml + songsmith version)`, so only changed songs re-render. CI budget ≤ 60 s render per song.
2. **Get Godot:** `Godot_v4.7.2-stable_linux.x86_64.zip`, plus **only** the `web_nothreads_release.zip`,
   `web_nothreads_debug.zip` and `version.txt` entries from `Godot_v4.7.2-stable_export_templates.tpz` (the full .tpz is
   about 1.3 GB, so extract once and cache the ~40 MB result) into
   `~/.local/share/godot/export_templates/4.7.2.stable/`.
3. **Export:** `--import`, then `--export-release "Web" build/site/index.html` and `--export-debug "Web Preview"
   build/site/preview/index.html`.
4. **Assemble:** `tools/ci/assemble_site.py` copies the `generated/*.bundle.zip` files to `build/site/generated/` (shared
   by root and preview) and writes `build.json` (commit, date, implemented days).
5. **Budget gate:** `tools/ci/check_budgets.py` fails the deploy if the §2 sizes are exceeded.
6. **Browser smoke:** a Playwright job (Chromium, desktop plus Pixel-class emulation with touch and 4× CPU throttle)
   checks that the page boots, Title → Calendar works, the preview build plays Day 0 through the
   `window.__disording` test API (star, success, back to the calendar), and there are no console errors. CI
   runners use software WebGL (SwiftShader), so fps is **recorded, not gated**. The ≥ 30 fps budget is checked on
   real phones and recorded in `docs/STATUS.md`.
7. **Deploy:** `actions/upload-pages-artifact` → `actions/deploy-pages`.

> **One-time manual step for the repo owner:** *Settings → Pages → Build and deployment → Source: **GitHub Actions***.

### 7.5 Caching and updates

GitHub Pages sends `max-age=600`, which is fine. The Godot PWA service worker caches by build version. Bundle
filenames get a content hash (`day_001.3fa9c1.bundle.zip`, referenced from `build.json`), so updated songs are never
served stale.

### 7.6 Preview build and dev panel

At `/preview/`, unlisted, a 🛠 button opens the dev panel. It can set a fake date, unlock all, jump to a day, force
success/fail/star, show the perf HUD (fps, frame ms, draw calls via `Performance.get_monitor`, nodes, memory), show
the telemetry table, toggle captions and beat-pulse debug, and reset the preview save. The release build compiles
none of it (feature-tag gated and stripped).

---

## 8. Design rules for all 100 games

### 8.1 Pillars

1. **Learn by doing in 30 seconds.** The intro card shows three icon hints and the first phase is a safe sandbox. No
   walls of text.
2. **One pointer is enough.** See §5. Every brief in `docs/GAMES.md` was written to this rule.
3. **Readable at phone size.** Big silhouettes, a high-contrast palette (colour-blind-safe, never colour-only
   information), and text ≥ 24 px at 1280×720.
4. **Juice with restraint.** Hit-stop, squash and confetti, all respecting *reduce motion*.
5. **The song is part of the game.** Each day pulses something to the beat (`ctx.audio.beat_clock`), and the win/lose
   stingers reuse the chorus.

### 8.2 Length: 5–15 minutes

- Structure every day into **3–5 escalating phases plus a climax**, as written in each brief's **Run** line.
- The target is a median of 8–12 min for a first successful clear by a new player. **Hard floor:** an expert can't
  finish under 5 min (enforced by structure such as fixed waves, a day clock or a quota, not by padding). **Hard
  ceiling:** the success path for an average player is ≤ 15 min.
- Verify with local telemetry (§3.3) from playtests and the scripted smoke bot, and record it in `docs/STATUS.md`.

### 8.3 Success and fail

- Exactly one `succeed()` path and one or more `fail()` paths, both reachable and both tested through `_qa_force`.
- Fail feedback is kind. It shows *why* ("The fox escaped 3 times") and offers Retry (and Retry from checkpoint when
  provided).
- Leaving via the pause menu is neither a success nor a failure.

### 8.4 Secrets (gold stars)

- **Never hinted** in UI text, intros, tutorials, results or the README. No "0/100" counters.
- **Fair:** discoverable by curiosity in normal play (an odd object, an unusual outcome, a tiny visual tell) and
  doable with one pointer. Never required for success, and never a pure random roll.
- **Feedback:** a 0.6 s golden twinkle where it happened plus a three-note chime from the day's instruments. No words.
  The gold star appears on the door when the player returns to the calendar.
- **Persisted immediately**, even if the run then fails. Works on replays.
- Each secret has a `_qa_force(&"star")` path and one deterministic scripted test that performs the real trigger.

### 8.5 Accessibility and comfort

Captions for lyrics, reduce motion (no shake, no flashes > 3 Hz), the left-handed HUD, pause anywhere, no time-critical text reading, volume sliders, and haptics as an option.

### 8.6 Originality and legal

- No characters, logos, music, sound or art from the listed games or any other IP. Every day has an original title.
- Each day names the game it riffs on, but only as plain text: "Inspired by *Title*" on the intro card, in the HUD
  for the whole run, and in the pause menu (`DayInfo.inspired_by`, synced from `game_list.txt` by
  `tools/ci/gen_day_stubs.py`). It never uses logos or styled wordmarks, and never claims to be official.
- The credits say this is an unofficial, non-commercial homage: not affiliated with or endorsed by the games'
  owners, and all trademarks belong to their owners.
- All code is ours. Fonts are OFL. CMUdict is BSD. Every audio file is generated by Songsmith. Licences are recorded in
  `CREDITS.md` (Step 1).

---

## 9. Per-day recipe (Steps 2–101)

Each day step follows the same nine moves. Step 1 turns this into `docs/HOW_TO_ADD_A_DAY.md` with code pointers.

1. **Read** the brief in `docs/GAMES.md`. Copy `days/_template/` to `days/day_NNN/` (Step 2 creates the template from Day 1).
2. **Write the song:** `days/day_NNN/song.yaml` with original lyrics (≥ 2 verses plus a chorus; the hook from the
   brief), the signature-instrument patch, the voice persona, SFX and stingers. Then run `songsmith render` and
   `songsmith check`.
3. **Fill `info.tres`:** title, genre, one-line pitch, three hint icons, `est_minutes`, palette, `implemented = true`.
4. **Build the game** in `game.tscn`/`game.gd` plus `parts/`. Use `ctx` only. Follow the brief's phases, win/lose and
   controls. Extract a kit (§3.7) if a second day now needs the same code.
5. **Wire the secret:** `ctx.award_star()` on the real trigger, the twinkle and chime, and `_qa_force(&"star")`.
6. **Accessibility pass:** reduce motion, left-handed anchors, captions. (No easier mode: §4.3.)
7. **Tests:** the smoke fuzz passes, all three QA outcomes pass, and the scripted secret test passes. Add unit tests for
   any non-trivial rules (scoring, AI decisions, recognizers).
8. **Perf and length pass:** preview build in Chrome at 4× CPU throttle with Pixel emulation, ≥ 30 fps and ≤ 150 draw
   calls in the worst phase. Bundle ≤ 3.5 MB. Main pack stays within its 12 MB budget. Telemetry shows a 5–15 min clear.
9. **Ship:** add the day's procedural `door_art.gd` (drawn behind its door once completed), update the `docs/STATUS.md` row, commit, push and
   check the deployed preview.

---

## 10. Definition of done

**For every day step:**

- [ ] Plays start to finish with **mouse only** and with **touch only**, using a single pointer.
- [ ] Has a success state and a fail state. Both reachable, both tested.
- [ ] First clear is 5–15 min (telemetry noted in STATUS.md). The expert floor is ≥ 5 min.
- [ ] The secret works, is never hinted, persists immediately, and has a scripted test.
- [ ] Has its own song: ≥ 2 sung verses plus a chorus, a signature instrument unique to this day, a voice persona,
      captions, and win/lose stingers. `songsmith check` is green.
- [ ] Meets the §2 budgets (fps under throttle, draw calls, bundle size, main-pack headroom).
- [ ] CI is green (lint, unit, smoke, songsmith) and the browser smoke passes on the deployed preview.
- [ ] Contains no third-party IP, and the source game's title doesn't appear in the build.
- [ ] `docs/STATUS.md` is updated, including notes and known issues.

**Additional checkpoints:** at Steps 11, 26, 51, 76 and 101, run a **platform audit**:
- re-measure first-load size, main-pack size and boot time on real low-reference devices;
- prune or merge kits;
- refresh the save-migration tests;
- do a full regression sweep of every implemented day in the browser smoke.

---

## 11. Roadmap

### Step 1: Platform: menu, systems, pipeline (no playable day yet)

**Deliverables**

1. **Project bootstrap:**
   - `project.godot` (4.7.2, `gl_compatibility`, 1280×720, `canvas_items` stretch with `expand` aspect, physics 60 Hz,
     `max_physics_steps_per_frame=4`, `emulate_touch_from_mouse`, typed-GDScript warnings);
   - the folder layout from §3.1;
   - `.gitignore` and `.gitattributes`;
   - a player-facing `README.md`, `CREDITS.md`, and a `LICENSE` (the owner picks; MIT suggested for code).
2. **Autoloads** from §3.3, each with unit tests where there's logic (`Clock`, `SaveService` including
   migrations and save codes, `Calendar`, `DayRegistry`, `InputHub` gestures, `Bundles` parsing).
3. **Day contract:**
   - `DayGame`, `DayContext`, `DayInfo`, `DayResult`;
   - the shared HUD (pause button, lives/timer/score widgets, captions bar);
   - pause menu, results screens, the star twinkle and chime;
   - **Day 0 "Test Room"** (debug only): a 90-second toy that exercises tap, drag, swipe, long-press, ±zoom,
     checkpoint, succeed, fail and a hidden star, used by the smoke tests and the browser smoke.
4. **Menu:**
   - the Title "Tap to open" screen;
   - the **Calendar** with all door states from §4.1, the townhouse façade, the Today button and countdown toasts;
   - the Day Intro card, Settings (all of §3.3), Credits, and the Dev panel (preview only);
   - door-open transitions that hide the bundle download.
5. **Registry stubs:**
   - `tools/ci/gen_day_stubs.py` reads `docs/GAMES.md` and writes `days/day_NNN/info.tres` for all 100 days (title,
     genre, `implemented=false`);
   - the calendar shows every door, and doors that would be open but aren't built show "being painted".
6. **Audio:**
   - AudioDirector, Bundles, captions and the beat clock;
   - **Songsmith v1**: engines, mixer/master, the formant singer with 6 starter personas, CLI, `check`, and pytest;
   - the **calendar theme "One More Door"** plus the UI SFX family rendered and wired in;
   - the music playback-mode benchmark recorded in STATUS.md.
7. **Web shell and PWA:** everything in §7.2 (loader, gesture locks, safe areas, rotate hint, fullscreen, resolution
   policy, `navigator.storage.persist()` request, iOS "Add to Home Screen" hint).
8. **CI/CD:**
   - `ci.yml` and `deploy.yml` from §7.3–7.4, with caching, the budget gate and the Playwright smoke (`tests/web/`);
   - Pages enabled (owner action) and the first deploy live at the root and at `/preview/`.
9. **Docs:**
   - `docs/STATUS.md` (one row per step: state, date, clear-time median, fps on the low reference, bundle size, notes);
   - `docs/HOW_TO_ADD_A_DAY.md`.

**Acceptance criteria**

- The deployed site boots on desktop Chrome, Firefox and Safari plus Android Chrome and iOS Safari, and reaches the
  calendar in ≤ 6 s on 4G.
- First load ≤ 20 MB.
- The calendar scrolls at 60 fps on the mid reference phone and holds ≥ 30 fps under 4× throttle.
- On a fresh profile: Door 1 is "being painted" (it's open, but Day 1 doesn't exist yet), and Doors 2–100 are locked.
- In the preview build with a fake date, Day 0 success → Door 1 marked complete → Door 2 "unlocks tomorrow" →
  advancing the fake date opens it. Clock rollback doesn't re-lock. The Day 0 star appears and the tally shows only
  after it.
- The menu theme plays with sung verses and captions, loops seamlessly, and `songsmith check` passes.
- Save survives a reload and works in a private window (with a graceful in-memory fallback). Save codes round-trip.
- CI is green and the deploy job publishes both builds.

### Step 2: Day 1 *Toybox Ring-Out* (reference implementation)

Build Day 1 exactly as in `docs/GAMES.md`, then turn it into the template every later day copies:

- Extract `core/kits/circle_physics`, `ai_fsm` and `juice`.
- Produce `days/_template/` (scene skeleton with phases, the QA hooks, `song.yaml` skeleton, `info.tres`, README
  checklist).
- Add the **Songsmith voice personas** needed by Days 1–10.
- Tune the duration to a ~11 min median with three phases of AI difficulty.
- Write a **scripted secret test** (the referee ring-out) and a **scripted win bot** for the smoke test. This sets the
  pattern for every later day.
- Door art is procedural: each day ships a tiny `door_art.gd` (`func draw(ci, rect)`) that the calendar draws behind
  its completed door. No image files, no capture tool. (Built in Step 2 instead of the thumbnail capture tool.)
- A headless tuning harness (`dev/day1_sim.tscn`) plays whole runs with the autopilot at several skill levels and
  reports bout lengths, win rates and ring-out causes. Later days copy the pattern.

### Steps 3–101: one day each

Every step runs the per-day recipe (§9) against its brief in `docs/GAMES.md` and must meet the definition of done (§10).

| Step | Day | Title | Rare genre | Riff on (list #) | Signature instrument | Target |
|---:|---:|---|---|---|---|---:|
| 1 | n/a | **Platform**: calendar menu and all systems | n/a | n/a | English handbells (menu theme) | n/a |
| 2 | 1 | [Toybox Ring-Out](docs/GAMES.md#day-001-toybox-ring-out) | flick-physics sumo (ring-out brawler) | #1 Super Smash Bros. Brawl | toy piano | ~11 min |
| 3 | 2 | [Switchboard Company](docs/GAMES.md#day-002-switchboard-company) | switchboard-operator sim | #2 Company of Heroes | boogie-woogie piano | ~11 min |
| 4 | 3 | [Graph Paper Grand Prix](docs/GAMES.md#day-003-graph-paper-grand-prix) | vector "Racetrack" (paper-and-pencil momentum racing) | #3 Gran Turismo 2 | Wurlitzer electric piano | ~10 min |
| 5 | 4 | [Downwind](docs/GAMES.md#day-004-downwind) | scent-trail stealth | #4 The Last of Us Part II | ronroco | ~11 min |
| 6 | 5 | [Umbra Courier](docs/GAMES.md#day-005-umbra-courier) | shadow-path light puzzle | #5 Splinter Cell: Pandora Tomorrow | ondes Martenot | ~10 min |
| 7 | 6 | [Lantern Market Hustle](docs/GAMES.md#day-006-lantern-market-hustle) | trading arbitrage sim | #6 Grand Theft Auto: Chinatown Wars | suona | ~11 min |
| 8 | 7 | [Night Shepherds](docs/GAMES.md#day-007-night-shepherds) | pursuit herding (you command the chasers) | #7 Pac-Man Championship Edition DX | SID-style pulse-width arpeggios | ~10 min |
| 9 | 8 | [Pocket Multitool](docs/GAMES.md#day-008-pocket-multitool) | hacking-puzzle anthology | #8 Half-Life: Alyx | bit-crushed granular pad | ~11 min |
| 10 | 9 | [Rim Runner](docs/GAMES.md#day-009-rim-runner) | tube shooter (Tempest-like) | #9 Sektori | TB-303-style acid bass | ~10 min |
| 11 | 10 | [Campfire Cookpot](docs/GAMES.md#day-010-campfire-cookpot) | recipe-discovery cooking | #10 The Legend of Zelda: Breath of the Wild (Switch 2 Edition) | hammered dulcimer | ~10 min |
| 12 | 11 | [Little Lost Bolts](docs/GAMES.md#day-011-little-lost-bolts) | hidden-object search | #11 Astro Bot | clavinet | ~10 min |
| 13 | 12 | [Hot & Cold Hollows](docs/GAMES.md#day-012-hot--cold-hollows) | hot-and-cold proximity treasure digging | #12 Final Fantasy IX | lute | ~10 min |
| 14 | 13 | [Recall](docs/GAMES.md#day-013-recall) | throw-and-recall trajectory puzzle | #13 God of War (2018) | nyckelharpa | ~11 min |
| 15 | 14 | [Shadowtree Duels](docs/GAMES.md#day-014-shadowtree-duels) | parry-timing duel (boss rush) | #14 Elden Ring: Shadow of the Erdtree | viola da gamba | ~10 min |
| 16 | 15 | [Line & Grind](docs/GAMES.md#day-015-line--grind) | line-drawing track rider | #15 Tony Hawk's Pro Skater 4 | overdriven power-chord guitar | ~12 min |
| 17 | 16 | [Crimson Juggle](docs/GAMES.md#day-016-crimson-juggle) | air-juggle keepy-uppy | #16 Devil May Cry | pipe organ | ~10 min |
| 18 | 17 | [Flag on the Play](docs/GAMES.md#day-017-flag-on-the-play) | referee sim | #17 Madden NFL 2002 | sousaphone | ~11 min |
| 19 | 18 | [Gargoyle Detective](docs/GAMES.md#day-018-gargoyle-detective) | forensic crime-scene reconstruction | #18 Batman: Arkham City | tenor saxophone | ~12 min |
| 20 | 19 | [Orb Spelunker Pinball](docs/GAMES.md#day-019-orb-spelunker-pinball) | metroidvania pinball | #19 Metroid Prime Remastered | phaser electric guitar | ~12 min |
| 21 | 20 | [Lunker Pond](docs/GAMES.md#day-020-lunker-pond) | lure fishing (line-tension sim) | #20 The Legend of Zelda: Ocarina of Time 3D | resonator guitar (dobro) | ~10 min |
| 22 | 21 | [Field of Hues](docs/GAMES.md#day-021-field-of-hues) | colour-field elemental duel | #21 Chrono Cross | uilleann pipes | ~11 min |
| 23 | 22 | [Chalkboard Coach](docs/GAMES.md#day-022-chalkboard-coach) | playbook drawing (coach sim) | #22 Madden NFL 2004 | crunk synth brass | ~12 min |
| 24 | 23 | [Burrow Plug](docs/GAMES.md#day-023-burrow-plug) | emergence-hole defence (timed whack-a-mole) | #23 Gears of War | war-drum ensemble (giant toms) | ~10 min |
| 25 | 24 | [Silver Tongue](docs/GAMES.md#day-024-silver-tongue) | persuasion-wheel social game | #24 The Elder Scrolls IV: Oblivion | French horn choir | ~10 min |
| 26 | 25 | [Council of Five](docs/GAMES.md#day-025-council-of-five) | swipe-decision kingdom (Reigns-like) | #25 Sid Meier's Civilization II | harpsichord | ~10 min |
| 27 | 26 | [Rocket Jump Golf](docs/GAMES.md#day-026-rocket-jump-golf) | blast-jump golf | #26 Quake | waterphone | ~11 min |
| 28 | 27 | [Runner Caravan](docs/GAMES.md#day-027-runner-caravan) | caravan travel management (Oregon-Trail-like) | #27 Metaphor: ReFantazio | shawm (rauschpfeife) | ~12 min |
| 29 | 28 | [Long Shot Range](docs/GAMES.md#day-028-long-shot-range) | long-range marksmanship / ballistics (non-violent targets) | #28 Call of Duty 4: Modern Warfare | spiccato cello section | ~10 min |
| 30 | 29 | [Skyline Hopper](docs/GAMES.md#day-029-skyline-hopper) | rail-hopping runner | #29 BioShock Infinite | honky-tonk ragtime piano | ~10 min |
| 31 | 30 | [Theater Mode](docs/GAMES.md#day-030-theater-mode) | live cinematography (camera director) | #30 Halo 3 | concert grand piano | ~11 min |
| 32 | 31 | [Nine Seals](docs/GAMES.md#day-031-nine-seals) | gesture-glyph combat | #31 Ninja Gaiden Black | shakuhachi | ~10 min |
| 33 | 32 | [Just a Box](docs/GAMES.md#day-032-just-a-box) | hide-in-plain-sight (prop stealth) | #32 Metal Gear Solid | low whistle | ~11 min |
| 34 | 33 | [Departures of the Dearly](docs/GAMES.md#day-033-departures-of-the-dearly) | travel-agent itinerary matching (afterlife deduction) | #33 Grim Fandango | jarana | ~12 min |
| 35 | 34 | [Rooftop Spray Crew](docs/GAMES.md#day-034-rooftop-spray-crew) | turf-tagging territory control | #34 Jet Set Radio | turntable scratches | ~10 min |
| 36 | 35 | [Spade Panel Party](docs/GAMES.md#day-035-spade-panel-party) | memory concentration (pairs) | #35 Super Mario Advance 4: Super Mario Bros. 3 | 2A03-style pulse/triangle/noise chip voices | ~9 min |
| 37 | 36 | [Tumbler](docs/GAMES.md#day-036-tumbler) | tactile lockpicking | #36 Tom Clancy's Splinter Cell: Chaos Theory | upright jazz bass (bowed and plucked) | ~10 min |
| 38 | 37 | [Wolfsled](docs/GAMES.md#day-037-wolfsled) | sled-dog mushing (team management racing) | #37 God of War Ragnarök | Hardanger fiddle | ~11 min |
| 39 | 38 | [Ink Ribbons](docs/GAMES.md#day-038-ink-ribbons) | key-and-lock route planning (scarcity) | #38 Resident Evil Code: Veronica | detuned music box | ~12 min |
| 40 | 39 | [Pileup Junction](docs/GAMES.md#day-039-pileup-junction) | crash-junction physics puzzle | #39 Burnout 3: Takedown | M1-style house piano stabs | ~10 min |
| 41 | 40 | [Cursed Curios](docs/GAMES.md#day-040-cursed-curios) | merchant appraisal sim | #40 Diablo | 12-string guitar | ~11 min |
| 42 | 41 | [Camo Index](docs/GAMES.md#day-041-camo-index) | camouflage-matching stealth | #41 Metal Gear Solid 3: Subsistence | growling trombone section | ~11 min |
| 43 | 42 | [Cliffhanger](docs/GAMES.md#day-042-cliffhanger) | two-hand ice-climbing timing | #42 Call of Duty: Modern Warfare 2 | balalaika | ~10 min |
| 44 | 43 | [Tether](docs/GAMES.md#day-043-tether) | tethered-drone piloting | #43 Metal Gear Solid 4: Guns of the Patriots | blues harmonica | ~11 min |
| 45 | 44 | [The Ashen Oath](docs/GAMES.md#day-044-the-ashen-oath) | quick-time cinematic action | #44 God of War (2005) | kithara (lyre) | ~10 min |
| 46 | 45 | [Twenty Cantina](docs/GAMES.md#day-045-twenty-cantina) | side-deck blackjack duel | #45 Star Wars: Knights of the Old Republic | clarinet | ~10 min |
| 47 | 46 | [Hex Hearth](docs/GAMES.md#day-046-hex-hearth) | hex tile-laying | #46 Sid Meier's Civilization IV | kalimba (mbira) | ~11 min |
| 48 | 47 | [Hall of Paintings](docs/GAMES.md#day-047-hall-of-paintings) | sliding-tile puzzle (animated paintings) | #47 Super Mario 64 | vibraphone | ~12 min |
| 49 | 48 | [Yomi Dojo](docs/GAMES.md#day-048-yomi-dojo) | simultaneous-choice mind-game fighter | #48 Virtua Fighter 4 | guzheng | ~10 min |
| 50 | 49 | [Weighted Friend](docs/GAMES.md#day-049-weighted-friend) | virtual pet | #49 Portal: Companion Collection | DX7-style FM electric piano | ~10 min |
| 51 | 50 | [Pause & Plan](docs/GAMES.md#day-050-pause--plan) | real-time-with-pause tactics | #50 Baldur's Gate II: Shadows of Amn | natural-trumpet fanfare | ~12 min |
| 52 | 51 | [Hydraulic Hop](docs/GAMES.md#day-051-hydraulic-hop) | lowrider hydraulics rhythm | #51 Grand Theft Auto: San Andreas | portamento Moog-style lead | ~10 min |
| 53 | 52 | [Glue & Glide](docs/GAMES.md#day-052-glue--glide) | glue-craft vehicle builder | #52 The Legend of Zelda: Tears of the Kingdom (Switch 2 Edition) | koto | ~12 min |
| 54 | 53 | [Neon Bay FM](docs/GAMES.md#day-053-neon-bay-fm) | radio-DJ station sim | #53 Grand Theft Auto: Vice City | gated-reverb LinnDrum-style kit | ~12 min |
| 55 | 54 | [Stitch & Sticker](docs/GAMES.md#day-054-stitch--sticker) | guide-the-walker sticker puzzle | #54 LittleBigPlanet | ukulele | ~11 min |
| 56 | 55 | [The Curator's Vault](docs/GAMES.md#day-055-the-curators-vault) | museum curation sim | #55 The Legend of Zelda: Collector's Edition | string quartet in pizzicato | ~11 min |
| 57 | 56 | [Contain the Bloom](docs/GAMES.md#day-056-contain-the-bloom) | spread-containment puzzle | #56 Halo 2 | shred lead guitar with whammy | ~11 min |
| 58 | 57 | [Pace Notes](docs/GAMES.md#day-057-pace-notes) | rally co-driver (call the corners) | #57 Gran Turismo 3: A-Spec | EWI lead | ~11 min |
| 59 | 58 | [Three Day Moon](docs/GAMES.md#day-058-three-day-moon) | time-loop schedule puzzle | #58 The Legend of Zelda: Majora's Mask | calliope | ~13 min |
| 60 | 59 | [Two Worlds Lantern](docs/GAMES.md#day-059-two-worlds-lantern) | dual-world layer-swap maze | #59 The Legend of Zelda: A Link to the Past / Four Swords | lo-fi SNES-style sampled orchestra (32 kHz | ~11 min |
| 61 | 60 | [Overgrowth](docs/GAMES.md#day-060-overgrowth) | ecological-succession rewilding puzzle | #60 The Last of Us | clawhammer banjo | ~12 min |
| 62 | 61 | [Howling Stones](docs/GAMES.md#day-061-howling-stones) | pitch-contour matching (howling) | #61 The Legend of Zelda: Twilight Princess | reversed piano and breath textures | ~10 min |
| 63 | 62 | [Chalk the Field](docs/GAMES.md#day-062-chalk-the-field) | groundskeeping and line painting | #62 Madden NFL 2003 | pedal steel guitar | ~10 min |
| 64 | 63 | [Moonlit Circles](docs/GAMES.md#day-063-moonlit-circles) | encircle/lasso action roguelite | #63 Hades II | bouzouki | ~12 min |
| 65 | 64 | [Thirty Days of Masks](docs/GAMES.md#day-064-thirty-days-of-masks) | calendar life-sim | #64 Persona 5 Royal | jazz flute | ~11 min |
| 66 | 65 | [Plank & Pallet](docs/GAMES.md#day-065-plank--pallet) | companion-escort logistics puzzle | #65 The Last of Us Remastered | musical saw | ~11 min |
| 67 | 66 | [Liar's Saloon](docs/GAMES.md#day-066-liars-saloon) | liar's-dice bluffing | #66 Red Dead Redemption | jaw harp | ~10 min |
| 68 | 67 | [Goo Lab](docs/GAMES.md#day-067-goo-lab) | gel-painting physics puzzle | #67 Portal 2 | theremin | ~11 min |
| 69 | 68 | [Grabber](docs/GAMES.md#day-068-grabber) | gravity-glove physics flinging | #68 Half-Life 2 | found-metal percussion | ~11 min |
| 70 | 69 | [Undersea Pipes](docs/GAMES.md#day-069-undersea-pipes) | pipe-flow puzzle (Pipe-Mania-like) | #69 BioShock | celesta | ~10 min |
| 71 | 70 | [Four Screens](docs/GAMES.md#day-070-four-screens) | split-screen surveillance deduction | #70 GoldenEye 007 | spring-reverb surf guitar | ~10 min |
| 72 | 71 | [Journal of the Lost City](docs/GAMES.md#day-071-journal-of-the-lost-city) | journal-clue relic puzzles | #71 Uncharted 2: Among Thieves | dungchen horn | ~11 min |
| 73 | 72 | [Attaché](docs/GAMES.md#day-072-attach) | inventory-packing puzzle | #72 Resident Evil 4 (2005) | flamenco guitar | ~10 min |
| 74 | 73 | [Natural Twenty](docs/GAMES.md#day-073-natural-twenty) | dice-check narrative | #73 Baldur's Gate 3 | hurdy-gurdy | ~12 min |
| 75 | 74 | [Payload Pals](docs/GAMES.md#day-074-payload-pals) | lane-push payload escort | #74 The Orange Box | Hammond organ with Leslie | ~12 min |
| 76 | 75 | [Fist Ball](docs/GAMES.md#day-075-fist-ball) | volley-ball fighter | #75 Tekken 3 | Reese bass | ~10 min |
| 77 | 76 | [One Way Mission](docs/GAMES.md#day-076-one-way-mission) | crew-assignment logic (suicide-mission planner) | #76 Mass Effect 2 | CS-80-style brass synth | ~12 min |
| 78 | 77 | [The Mansion of Doors](docs/GAMES.md#day-077-the-mansion-of-doors) | branching gothic visual novel | #77 The House in Fata Morgana | theorbo | ~13 min |
| 79 | 78 | [Ground Messages](docs/GAMES.md#day-078-ground-messages) | message-trust deduction | #78 Elden Ring | concert harp | ~11 min |
| 80 | 79 | [Words of Power](docs/GAMES.md#day-079-words-of-power) | constructed-language deciphering | #79 The Elder Scrolls V: Skyrim | lur horns | ~12 min |
| 81 | 80 | [Cascade Control](docs/GAMES.md#day-080-cascade-control) | control-room instrument sim | #80 Half-Life | TR-909-style kit | ~12 min |
| 82 | 81 | [Rewind Rock](docs/GAMES.md#day-081-rewind-rock) | object time-reversal puzzle | #81 The Legend of Zelda: Tears of the Kingdom | erhu | ~11 min |
| 83 | 82 | [Baton Sails](docs/GAMES.md#day-082-baton-sails) | wind-conducting sailing | #82 The Legend of Zelda: The Wind Waker | concertina | ~12 min |
| 84 | 83 | [Slot Car Stadium](docs/GAMES.md#day-083-slot-car-stadium) | slot-car racing (one-button throttle) | #83 Gran Turismo | electric sitar | ~10 min |
| 85 | 84 | [Coolant](docs/GAMES.md#day-084-coolant) | bomb-disposal search | #84 Metal Gear Solid 2: Sons of Liberty | bass clarinet | ~12 min |
| 86 | 85 | [Twin City Drive](docs/GAMES.md#day-085-twin-city-drive) | dual-lane split-attention driving | #85 Grand Theft Auto Double Pack | bandoneón | ~10 min |
| 87 | 86 | [Starbit Slingshot](docs/GAMES.md#day-086-starbit-slingshot) | orbital gravity slingshot | #86 Super Mario Galaxy | glass harmonica | ~11 min |
| 88 | 87 | [Three-Way Heist](docs/GAMES.md#day-087-three-way-heist) | simultaneous-plan heist (plan, then execute) | #87 Grand Theft Auto V | 808 glide sub-bass | ~12 min |
| 89 | 88 | [Updraft](docs/GAMES.md#day-088-updraft) | thermal-soaring glider | #88 The Legend of Zelda: Breath of the Wild | alto flute | ~11 min |
| 90 | 89 | [Endless Manual](docs/GAMES.md#day-089-endless-manual) | balance-meter endurance (manual combos) | #89 Tony Hawk's Pro Skater 3 | ska trombone skank | ~10 min |
| 91 | 90 | [Sim Trainer](docs/GAMES.md#day-090-sim-trainer) | behaviour-programming auto-arena | #90 Perfect Dark | Stylophone | ~11 min |
| 92 | 91 | [Camp Ledger](docs/GAMES.md#day-091-camp-ledger) | outlaw camp management | #91 Red Dead Redemption 2 | harmonium (pump organ) | ~11 min |
| 93 | 92 | [Logbook](docs/GAMES.md#day-092-logbook) | taxonomy identification (dichotomous key) | #92 Metroid Prime | Solina-style string machine | ~11 min |
| 94 | 93 | [Dispatch 5](docs/GAMES.md#day-093-dispatch-5) | taxi fleet dispatch | #93 Grand Theft Auto III | grunge-distorted guitar | ~12 min |
| 95 | 94 | [Hat Trick](docs/GAMES.md#day-094-hat-trick) | possession puzzle | #94 Super Mario Odyssey | bright trumpet section | ~11 min |
| 96 | 95 | [Ring Cartographer](docs/GAMES.md#day-095-ring-cartographer) | exploration cartography (draw your own map) | #95 Halo: Combat Evolved | congas | ~12 min |
| 97 | 96 | [Booth Call](docs/GAMES.md#day-096-booth-call) | live sports-commentary sim | #96 NFL 2K1 | timpani | ~12 min |
| 98 | 97 | [Soulforge](docs/GAMES.md#day-097-soulforge) | blacksmith forging (rhythm crafting) | #97 SoulCalibur | tuned anvils | ~11 min |
| 99 | 98 | [Tongue Swing](docs/GAMES.md#day-098-tongue-swing) | grapple-swing platformer | #98 Super Mario Galaxy 2 | steel pan | ~10 min |
| 100 | 99 | [Strike It Up](docs/GAMES.md#day-099-strike-it-up) | bowling (relationship comedy) | #99 Grand Theft Auto IV | flugelhorn-led Balkan brass band | ~9 min |
| 101 | 100 | [The Hundredth Song](docs/GAMES.md#day-100-the-hundredth-song) | ocarina song-casting adventure | #100 The Legend of Zelda: Ocarina of Time | ocarina | ~14 min |

---

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Formant singing is hard to understand | Lyrics written for the synth (§6.3), captions on by default, the hook repeated. The persona library improves over the steps. |
| Mobile web performance (single thread, WebGL 2) | Strict budgets (§2), the 4× throttle gate in CI, 2D only, procedural art, no runtime audio DSP, MultiMesh and pooling, quality tiers. |
| Web audio memory and stutter | Stream playback for music (Sample fallback), 2-bundle LRU, stinger ducking, baked effects. The Step 1 benchmark is recorded. |
| iOS Safari quirks (audio unlock, no fullscreen, storage eviction after 7 idle days) | Tap-to-open gesture, PWA install hint, `storage.persist()`, and save-code export/import in Settings. |
| Large first download | Single-threaded official templates first. If the budget gate trips, build a **slim custom web template** (`disable_3d=yes`, unused modules off) in a cached CI job. |
| 100 games is a lot of scope | One brief per step, the `_template/`, the rule-of-two kits, local telemetry for tuning, and audit checkpoints every 25 days. |
| Songs take too long to render in CI | Per-song content-hash cache. Only changed songs render. Each song has a ≤ 60 s budget. Vectorized DSP (`lfilter`) plus optional numba. |
| Players stuck behind a daily gate | Tuning each day so new players clear it within a few attempts (~70% by the third try), and checkpoints on long runs (§4.3). No easier mode. |
| Trademark or copyright | Original names and art only. Source games are named only as plain "Inspired by …" text, with a non-affiliation note in the credits (§8.6). |
| Godot version drift | Pinned 4.7.2 everywhere. Upgrades only in a dedicated step with a full regression sweep. |
