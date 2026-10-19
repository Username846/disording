# Status

A living tracker: update the row for a step when you finish it (PLAN.md §9 step 9).
Fill in **clear median** from the preview build's dev-panel telemetry, **fps** from a real low-reference phone (or
note "CI only"), and **bundle** from `python3 tools/ci/check_budgets.py`.

Legend: ✅ done · 🟡 in progress · ⬜ todo

## Step 1: Platform ✅

| Area | Result |
|---|---|
| Godot | 4.7.2-stable (`ed1daf0bf`), Compatibility renderer, single-threaded web export, PWA on the release build |
| Systems | App, SaveService (atomic JSON, save codes, migrations), Clock (monotonic, fake date in dev), Settings, DayRegistry, Calendar, Telemetry (local), Haptics, Gestures, Bundles, Audio, Router |
| Day contract | `DayGame` / `DayContext` / `DayHost` with HUD, pause, results, checkpoints and the wordless star twinkle. Day 0 "Test Room" fixture (debug builds only) |
| Menu | Title ("Tap to open"), custom-drawn 100-door calendar (all states, Today button, countdown toasts), intro card, settings, credits, dev panel, perf HUD |
| Stubs | `tools/ci/gen_day_stubs.py` writes 100 `info.tres` from `docs/GAMES.md`. CI fails if they drift |
| Audio | Songsmith v1: 8 synth engines, a Klatt-style formant singer with 6 personas, CMUdict, seamless loops, −16 LUFS masters. Menu theme "One More Door" (4.17 min, 2.76 MB) plus 10 UI SFX. Day 0 jingle (1.1 min, 0.90 MB) with win/lose stingers |
| Tests | 19 Godot unit tests, a headless platform smoke test (fuzzed input plus forced success/fail/star on every built day), a compile check of every script, 28 Songsmith pytest tests, and a Playwright browser smoke test (release desktop, preview Day 0, phone touch with 4× CPU throttle) |
| Sizes | Main pack 0.30 MB · engine wasm 10.1 MB gzipped · first load ≈ 13.1 MB (target ≤ 15, limit 20) |
| CI/CD | `ci.yml` (lint, stub drift, Godot tests, pytest) and `deploy.yml` (render → test → export → budgets → browser smoke → Pages) |

**Still open from Step 1 (needs a real device or the repo owner):**

- Enable Pages: *Settings → Pages → Source: GitHub Actions* (owner action).
- Measure fps and boot time on real phones (low reference: 2020 Moto G / Snapdragon 665; mid: iPhone 11 or a 2021
  Android). CI's Chromium uses software WebGL (SwiftShader), so its fps numbers (~9 fps desktop, ~6 fps at 4×
  throttle) are recorded but not gated.
- Benchmark music **Stream vs Sample** playback on the low-reference phone (PLAN.md §6.1). It's Stream for now.
- Check whether GitHub Pages serves `index.wasm`/`index.pck` gzip-compressed (`curl -sI -H "Accept-Encoding: gzip"`).
- Pick a licence for the repository's code (none is set yet).

## Days

| Step | Day | State | Clear median | fps (low ref) | Bundle | Notes |
|---:|---|---|---|---|---|---|
| 2 | Day 1 · Toybox Ring-Out | ⬜ todo | | | | |
| 3 | Day 2 · Switchboard Company | ⬜ todo | | | | |
| 4 | Day 3 · Graph Paper Grand Prix | ⬜ todo | | | | |
| 5 | Day 4 · Downwind | ⬜ todo | | | | |
| 6 | Day 5 · Umbra Courier | ⬜ todo | | | | |
| 7 | Day 6 · Lantern Market Hustle | ⬜ todo | | | | |
| 8 | Day 7 · Night Shepherds | ⬜ todo | | | | |
| 9 | Day 8 · Pocket Multitool | ⬜ todo | | | | |
| 10 | Day 9 · Rim Runner | ⬜ todo | | | | |
| 11 | Day 10 · Campfire Cookpot | ⬜ todo | | | | |
| 12 | Day 11 · Little Lost Bolts | ⬜ todo | | | | |
| 13 | Day 12 · Hot & Cold Hollows | ⬜ todo | | | | |
| 14 | Day 13 · Recall | ⬜ todo | | | | |
| 15 | Day 14 · Shadowtree Duels | ⬜ todo | | | | |
| 16 | Day 15 · Line & Grind | ⬜ todo | | | | |
| 17 | Day 16 · Crimson Juggle | ⬜ todo | | | | |
| 18 | Day 17 · Flag on the Play | ⬜ todo | | | | |
| 19 | Day 18 · Gargoyle Detective | ⬜ todo | | | | |
| 20 | Day 19 · Orb Spelunker Pinball | ⬜ todo | | | | |
| 21 | Day 20 · Lunker Pond | ⬜ todo | | | | |
| 22 | Day 21 · Field of Hues | ⬜ todo | | | | |
| 23 | Day 22 · Chalkboard Coach | ⬜ todo | | | | |
| 24 | Day 23 · Burrow Plug | ⬜ todo | | | | |
| 25 | Day 24 · Silver Tongue | ⬜ todo | | | | |
| 26 | Day 25 · Council of Five | ⬜ todo | | | | |
| 27 | Day 26 · Rocket Jump Golf | ⬜ todo | | | | |
| 28 | Day 27 · Runner Caravan | ⬜ todo | | | | |
| 29 | Day 28 · Long Shot Range | ⬜ todo | | | | |
| 30 | Day 29 · Skyline Hopper | ⬜ todo | | | | |
| 31 | Day 30 · Theater Mode | ⬜ todo | | | | |
| 32 | Day 31 · Nine Seals | ⬜ todo | | | | |
| 33 | Day 32 · Just a Box | ⬜ todo | | | | |
| 34 | Day 33 · Departures of the Dearly | ⬜ todo | | | | |
| 35 | Day 34 · Rooftop Spray Crew | ⬜ todo | | | | |
| 36 | Day 35 · Spade Panel Party | ⬜ todo | | | | |
| 37 | Day 36 · Tumbler | ⬜ todo | | | | |
| 38 | Day 37 · Wolfsled | ⬜ todo | | | | |
| 39 | Day 38 · Ink Ribbons | ⬜ todo | | | | |
| 40 | Day 39 · Pileup Junction | ⬜ todo | | | | |
| 41 | Day 40 · Cursed Curios | ⬜ todo | | | | |
| 42 | Day 41 · Camo Index | ⬜ todo | | | | |
| 43 | Day 42 · Cliffhanger | ⬜ todo | | | | |
| 44 | Day 43 · Tether | ⬜ todo | | | | |
| 45 | Day 44 · The Ashen Oath | ⬜ todo | | | | |
| 46 | Day 45 · Twenty Cantina | ⬜ todo | | | | |
| 47 | Day 46 · Hex Hearth | ⬜ todo | | | | |
| 48 | Day 47 · Hall of Paintings | ⬜ todo | | | | |
| 49 | Day 48 · Yomi Dojo | ⬜ todo | | | | |
| 50 | Day 49 · Weighted Friend | ⬜ todo | | | | |
| 51 | Day 50 · Pause & Plan | ⬜ todo | | | | |
| 52 | Day 51 · Hydraulic Hop | ⬜ todo | | | | |
| 53 | Day 52 · Glue & Glide | ⬜ todo | | | | |
| 54 | Day 53 · Neon Bay FM | ⬜ todo | | | | |
| 55 | Day 54 · Stitch & Sticker | ⬜ todo | | | | |
| 56 | Day 55 · The Curator's Vault | ⬜ todo | | | | |
| 57 | Day 56 · Contain the Bloom | ⬜ todo | | | | |
| 58 | Day 57 · Pace Notes | ⬜ todo | | | | |
| 59 | Day 58 · Three Day Moon | ⬜ todo | | | | |
| 60 | Day 59 · Two Worlds Lantern | ⬜ todo | | | | |
| 61 | Day 60 · Overgrowth | ⬜ todo | | | | |
| 62 | Day 61 · Howling Stones | ⬜ todo | | | | |
| 63 | Day 62 · Chalk the Field | ⬜ todo | | | | |
| 64 | Day 63 · Moonlit Circles | ⬜ todo | | | | |
| 65 | Day 64 · Thirty Days of Masks | ⬜ todo | | | | |
| 66 | Day 65 · Plank & Pallet | ⬜ todo | | | | |
| 67 | Day 66 · Liar's Saloon | ⬜ todo | | | | |
| 68 | Day 67 · Goo Lab | ⬜ todo | | | | |
| 69 | Day 68 · Grabber | ⬜ todo | | | | |
| 70 | Day 69 · Undersea Pipes | ⬜ todo | | | | |
| 71 | Day 70 · Four Screens | ⬜ todo | | | | |
| 72 | Day 71 · Journal of the Lost City | ⬜ todo | | | | |
| 73 | Day 72 · Attaché | ⬜ todo | | | | |
| 74 | Day 73 · Natural Twenty | ⬜ todo | | | | |
| 75 | Day 74 · Payload Pals | ⬜ todo | | | | |
| 76 | Day 75 · Fist Ball | ⬜ todo | | | | |
| 77 | Day 76 · One Way Mission | ⬜ todo | | | | |
| 78 | Day 77 · The Mansion of Doors | ⬜ todo | | | | |
| 79 | Day 78 · Ground Messages | ⬜ todo | | | | |
| 80 | Day 79 · Words of Power | ⬜ todo | | | | |
| 81 | Day 80 · Cascade Control | ⬜ todo | | | | |
| 82 | Day 81 · Rewind Rock | ⬜ todo | | | | |
| 83 | Day 82 · Baton Sails | ⬜ todo | | | | |
| 84 | Day 83 · Slot Car Stadium | ⬜ todo | | | | |
| 85 | Day 84 · Coolant | ⬜ todo | | | | |
| 86 | Day 85 · Twin City Drive | ⬜ todo | | | | |
| 87 | Day 86 · Starbit Slingshot | ⬜ todo | | | | |
| 88 | Day 87 · Three-Way Heist | ⬜ todo | | | | |
| 89 | Day 88 · Updraft | ⬜ todo | | | | |
| 90 | Day 89 · Endless Manual | ⬜ todo | | | | |
| 91 | Day 90 · Sim Trainer | ⬜ todo | | | | |
| 92 | Day 91 · Camp Ledger | ⬜ todo | | | | |
| 93 | Day 92 · Logbook | ⬜ todo | | | | |
| 94 | Day 93 · Dispatch 5 | ⬜ todo | | | | |
| 95 | Day 94 · Hat Trick | ⬜ todo | | | | |
| 96 | Day 95 · Ring Cartographer | ⬜ todo | | | | |
| 97 | Day 96 · Booth Call | ⬜ todo | | | | |
| 98 | Day 97 · Soulforge | ⬜ todo | | | | |
| 99 | Day 98 · Tongue Swing | ⬜ todo | | | | |
| 100 | Day 99 · Strike It Up | ⬜ todo | | | | |
| 101 | Day 100 · The Hundredth Song | ⬜ todo | | | | |
