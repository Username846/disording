# Day template

Copy this folder to `days/day_NNN/` and follow [`docs/HOW_TO_ADD_A_DAY.md`](../../docs/HOW_TO_ADD_A_DAY.md).
Day 1 (`days/day_001/`) is the full reference implementation.

Checklist (PLAN.md §10):

- [ ] `info.tres`: three `hints` plus `door_art = ExtResource(...)` pointing at `door_art.gd`
- [ ] `song.yaml`: ≥ 2 sung verses + chorus, one unique `signature: true` instrument, win/lose stingers,
      every SFX name the game plays. Run `songsmith render` + `songsmith check`
- [ ] `game.gd`: phases, one success path, kind fail messages, checkpoints for runs > 8 min
- [ ] Mouse only and touch only, one pointer; HUD strip (top ~120 px) kept clear
- [ ] Secret: `ctx.award_star(at)` on the real trigger, `_qa_force(&"star")` performs it
- [ ] `_qa_jump` (dev panel) and `_qa_autoplay` (scripted win bot) implemented
- [ ] Tuned with a headless sim (see `dev/day1_sim.gd`) to a 5–15 min clear; `docs/STATUS.md` row filled
