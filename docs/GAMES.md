# The 100 Doors: Game Design Briefs

> ⚠️ **Spoilers.** This file names every secret (easter egg). Players are never shown anything from it.
> Engineering, conventions and the step-by-step roadmap live in [`../PLAN.md`](../PLAN.md).

Each day takes one entry from [`game_list.txt`](../game_list.txt) as its starting point. The day is an
**original** game in a **rare genre**: it borrows a theme, a mood or one memorable mechanic from the listed game
and builds something new around it. No names, characters, logos, music or art come from the source game. The
in-game title is the one given here, and the source title never appears in the build.

**How to read an entry**

| Field | Meaning |
|---|---|
| **Riff on** | List number and source game: the idea we borrow from (stays in the docs, never shown in the game) |
| **Rare genre** | The genre, unique across the 100 days |
| **Target** | Median time for a first successful clear (always 5–15 min; aim for 8–12) |
| **Controls** | Everything works with **one pointer**: a finger *or* the left mouse button. No hover, right-click, keyboard or multi-touch is ever required |
| **Run** | How the 5–15 minutes are structured |
| **Win / Lose** | The success state (completes the day and starts the next-day unlock) and the fail state |
| **Secret ★** | The hidden easter egg that awards the door's gold star. It is never hinted at in UI text |
| **Song** | Title · style · instruments (★ = signature instrument, used by no other day) · voice persona · chorus hook |

---

## Calendar menu (Step 1)

- **Song: "One More Door"**: cosy winter carol-pop · ★English handbells, glockenspiel, sleigh bells, upright bass, soft
  string pad · voice: warm mixed SATB choir, gentle · hook: *"One more door, one more day, open up and come and play."*
- UI SFX family (door knock, creak, padlock rattle, unlock chime, star twinkle) are rendered from the same handbell patch, so
  the menu sounds like one instrument family.

---

### Day 001: Toybox Ring-Out
**Riff on:** #1 *Super Smash Bros. Brawl* · **Rare genre:** flick-physics sumo (ring-out brawler) · **Target:** ~11 min

- **Pitch:** Wind-up toys brawl on household battlefields. You don't press attack buttons; you *flick* your tin knight like
  a marble. Each hit adds damage %, and the more damage a toy has, the farther it flies. Ring everyone out.
- **Controls:** Press on your toy, drag back to aim (a dotted arc shows power), release to launch. A wind-up key on your toy
  shows when the next flick is ready (about 1.2 s recharge), so the game runs in real time without turns or spam.
- **Run:** A five-bout tournament, 2–2.5 min each: **Pillow Fort** (soft bouncy edges), **Bookshelf** (narrow, books slide),
  **Bathtub** (slippery, a floating rubber duck bumper), **Train Set** (moving platform loop) and **Toy Box Lid** (the final
  bout; the lid tilts toward the heavier side). Rivals: rubber dino (heavy), yo-yo ninja (fast), plush bear (bouncy), dash
  robot, and the jack-in-the-box champion (spring launches). Pickups: marble (heavy hit), balloon (float), magnet.
  Each toy has 3 stocks per bout.
- **Win / Lose:** Win the final bout to take the crown. You start with 3 spare keys: losing a bout costs one and restarts
  that bout. Losing the last key is the fail state.
- **Secret ★:** In the final bout a heavy wind-up **referee** shuffles along the edge. Ring *him* out. It takes a fully
  charged flick or a rival bounced into him.
- **Song: "Off the Edge"**: tin-toy swing, ~132 BPM · ★toy piano, kazoo section, tuba, brushed snare, slide whistle ·
  voice: wind-up child choir (formants scaled up, 6-voice unison) · hook: *"Off the edge, off the edge, wind me up and watch
  me go!"*

### Day 002: Switchboard Company
**Riff on:** #2 *Company of Heroes* · **Rare genre:** switchboard-operator sim · **Target:** ~11 min

- **Pitch:** You run a 1940s field switchboard. The heroes on the line need you to patch squads, medics, supply and HQ
  together while the front shifts on the map above your board.
- **Controls:** Drag a cable from a lit caller jack to the destination jack. Tap a ringing line to answer, tap the crank to
  repair a damaged line, and tap map pins to read locations.
- **Run:** Five shifts (Dawn, Morning, Noon, Dusk, Night) of about 2 min each. Calls overlap. Red calls are priority. Garbled
  callers give landmarks ("the hill with the windmill") that you have to find on the map. Shelling knocks lines out.
- **Win / Lose:** Finish the Night shift with ≥ 80% of priority calls connected. The fail state is the morale meter
  emptying from dropped or misrouted calls.
- **Secret ★:** In a quiet moment, connect the **Field Kitchen** to the **General**. Nobody ever asks for that call, and the
  two swap a soup recipe.
- **Song: "Plug Me Through"**: 1940s boogie swing · ★boogie-woogie piano, muted trumpet, upright bass, brushed snare ·
  voice: female close-harmony trio · hook: *"Operator, operator, plug me through to Company B."*

### Day 003: Graph Paper Grand Prix
**Riff on:** #3 *Gran Turismo 2* · **Rare genre:** vector "Racetrack" (paper-and-pencil momentum racing) · **Target:** ~10 min

- **Pitch:** The classic pen-and-paper racing game, made tactile. Your car's next point is limited to the nine grid points
  around "position + current velocity", so momentum is everything.
- **Controls:** Tap one of the nine highlighted points. Press and hold a point to preview the line. Pinch, the mouse wheel
  or the ± buttons zoom.
- **Run:** A license test (3 tiny tracks: momentum, braking, hairpin), then a 4-race championship against 3 rival pencils.
  The AI follows precomputed racing lines with per-rival personality noise. Leaving the track means a spin and lost turns.
- **Win / Lose:** Win the championship on points. You fail by failing the license test 3 times or by not finishing the
  championship in 1st.
- **Secret ★:** Stop dead (velocity 0,0) exactly on a finish-line square.
- **Song: "Three by Three"**: city pop · ★Wurlitzer electric piano, slap bass, pencil-scratch and eraser-thump
  percussion, sparkle synth · voice: smooth male crooner · hook: *"Three by three, the pencil sets me free."*

### Day 004: Downwind
**Riff on:** #4 *The Last of Us Part II* · **Rare genre:** scent-trail stealth · **Target:** ~11 min

- **Pitch:** A stray cat crosses a flooded, overgrown city. Patrol dogs don't need to *see* you; they follow the scent
  trail you leave. Wind carries scent, while water and rooftops break the trail.
- **Controls:** Tap a tile to walk there (pathfinding). Hold on the cat to crouch (slower, fainter scent). Tap fans,
  puddles and bait to use them. A nose button toggles the scent overlay.
- **Run:** 8 city blocks of about 80 s each. Each block adds a twist: wind gusts, rain that washes scent away, fish bait
  for laying false trails, two dogs that split up, and a final run through a market.
- **Win / Lose:** Reach the harbour boat. Getting caught restarts the block, and the 3rd catch fails the run.
- **Secret ★:** In the music-shop block, pluck the abandoned guitar's strings from lowest to highest.
- **Song: "Keep the Wind in Front of You"**: sparse Americana · ★ronroco, low cello drone, soft kick, rain bed · voice:
  breathy female folk solo, close-mic · hook: *"Keep the wind in front of you, and the past behind."*

### Day 005: Umbra Courier
**Riff on:** #5 *Splinter Cell: Pandora Tomorrow* · **Rare genre:** shadow-path light puzzle · **Target:** ~10 min

- **Pitch:** You guide a shadow creature carrying a sealed box. It can only move through darkness, so you slide lamps,
  close shutters and time patrol flashlights to carve a path of shadow through an embassy.
- **Controls:** Drag lamps along their rails, drag shutters, tap switches. Tap the courier to send it along the current
  dark path.
- **Run:** 15 rooms. Later rooms add guards with sweeping flashlight cones, coloured filters and mirrors.
- **Win / Lose:** Deliver the box to the vault in room 15. The courier can be caught in the light 5 times in total; the
  5th exposure fails the run.
- **Secret ★:** In room 9, keep tapping the moon in the skylight until clouds roll over it. The room goes fully dark.
- **Song: "Where the Light Can't Follow"**: trip-hop · ★ondes Martenot, dusty breakbeat, sub bass, vinyl crackle ·
  voice: whispered female · hook: *"Stay where the light can't follow."*

### Day 006: Lantern Market Hustle
**Riff on:** #6 *Grand Theft Auto: Chinatown Wars* · **Rare genre:** trading arbitrage sim · **Target:** ~11 min

- **Pitch:** It's festival month and you owe Auntie ¥10,000. Trade lanterns, firecrackers, tea, silk, dumplings and paper
  dragons across six districts. News swings the prices, and inspectors confiscate firecrackers.
- **Controls:** Tap a district to travel there (it costs time). Drag the buy and sell sliders. Tap the news ticker to read
  the details.
- **Run:** 30 market days of about 20 s each. Events include a parade (lantern prices spike), a rainstorm, an inspector
  sweep and a rival trader. Interest on the loan accrues daily.
- **Win / Lose:** Repay the loan by day 30. You fail by going bankrupt or by having the loan unpaid at day 30.
- **Secret ★:** Hold exactly **8 of every good** at the same moment (lucky eights).
- **Song: "Lantern Glow"**: festival electro-pop · ★suona, pipa, FM bass, gongs, firecracker-snap percussion ·
  voice: bright female pop lead with male hype call-outs · hook: *"Buy it low by the lantern glow."*

### Day 007: Night Shepherds
**Riff on:** #7 *Pac-Man Championship Edition DX* · **Rare genre:** pursuit herding (you command the chasers) · **Target:** ~10 min

- **Pitch:** The maze chase in reverse. You command four sheepdogs through neon hedge mazes to corner a fox that eats
  glowing berries and speeds up.
- **Controls:** Tap a dog, then tap a junction (it pathfinds there). Or drag from a dog to draw its route. Double-tap the
  board to send every dog to its home corner.
- **Run:** 10 mazes of about 60 s each. The fox gets smarter as you go: it predicts dogs, uses tunnels and drops decoys.
- **Win / Lose:** Corner the fox in all 10 mazes. The 3rd time-out fails the run.
- **Secret ★:** Catch the fox with **all four dogs touching it** in the same frame.
- **Song: "Round the Bend"**: synthwave/eurobeat · ★SID-style pulse-width arpeggios, gated drums, saw pad · voice: vocoder
  robot · hook: *"Round the bend, round the bend, every corner is the end."*

### Day 008: Pocket Multitool
**Riff on:** #8 *Half-Life: Alyx* · **Rare genre:** hacking-puzzle anthology · **Target:** ~11 min

- **Pitch:** A scavenger's multitool cracks alien locks in three styles: rotate concentric rings to line up energy nodes,
  bounce a laser through prisms, and trace live wires hidden behind walls.
- **Controls:** Drag to rotate rings, tap prisms to turn them, drag the probe along walls.
- **Run:** 18 locks across an apartment block, climbing floor by floor. Battery charge is the shared resource. Every
  attempt and mistake costs charge, and spare batteries hide in rooms.
- **Win / Lose:** Open the penthouse vault. The battery reaching 0 is the fail state.
- **Secret ★:** In the lobby, tap the lone bucket three times. It lands on the patrol drone's "head".
- **Song: "Spin the Ring"**: industrial glitch · ★bit-crushed granular pad, metallic clicks, sub bass · voice:
  ring-modulated male duet · hook: *"Spin the ring till the lock sings."*

### Day 009: Rim Runner
**Riff on:** #9 *Sektori* · **Rare genre:** tube shooter (Tempest-like) · **Target:** ~10 min

- **Pitch:** Your ship rides the rim of a geometric tunnel, auto-firing inward at shapes that climb toward you.
- **Controls:** Drag sideways anywhere (or trace a circle) to slide around the rim. Tap to fire the limited "pulse" bomb.
- **Run:** 12 sectors of about 45 s each, with bosses at sectors 6 and 12. Tube shapes change between closed, open and flat.
- **Win / Lose:** Clear sector 12. Losing all 3 lives fails the run; you get one continue from sector 7.
- **Secret ★:** Complete a full lap of the rim in under one second.
- **Song: "Sector by Sector"**: psytrance · ★TB-303-style acid bass, supersaw lead, rolling kick · voice: ethereal female
  trance · hook: *"Sector by sector, light becomes vector."*

### Day 010: Campfire Cookpot
**Riff on:** #10 *The Legend of Zelda: Breath of the Wild (Switch 2 Edition)* · **Rare genre:** recipe-discovery cooking · **Target:** ~10 min

- **Pitch:** You're a wandering forager-chef. Put up to five ingredients in the pot. Their effects combine by hidden rules
  that you learn through experiments logged in your journal.
- **Controls:** Drag ingredients into the pot and tap Cook. While foraging, tap or drag to pick things before animals get
  to them.
- **Run:** Five travellers arrive, each needing a dish with one effect (warming, stamina, sneaky, hearty, glowing).
  Short timed foraging rounds come between them, and a day clock runs throughout.
- **Win / Lose:** Serve all 5 before moonrise. You fail if the moon rises with orders still unmet.
- **Secret ★:** Cook a single **rock** on its own. You get "Dubious Pebble Stew".
- **Song: "Stir It Slow"**: pastoral folk · ★hammered dulcimer, fingerpicked guitar, frame drum · voice: light folk tenor ·
  hook: *"Stir it slow, let the embers glow."*

### Day 011: Little Lost Bolts
**Riff on:** #11 *Astro Bot* · **Rare genre:** hidden-object search · **Target:** ~10 min

- **Pitch:** Pan and zoom across five busy dioramas to spot tiny lost robots hiding in plain sight.
- **Controls:** Drag to pan. Pinch, the mouse wheel or the ± buttons zoom. Tap to rescue a bot. Tapping empty space costs
  2 s.
- **Run:** 5 dioramas of about 2 min each, each with a quota. Bots fidget slightly. Later dioramas switch between day and
  night.
- **Win / Lose:** Meet every quota. The fail state is a timer running out before its quota is met.
- **Secret ★:** One bot is upside down. Tap it three times and it flips itself upright.
- **Song: "Bring Me Home"**: funk · ★clavinet, wah guitar, horn stabs · voice: bit-crushed robot chorus · hook: *"Beep
  beep, bring me home."*

### Day 012: Hot & Cold Hollows
**Riff on:** #12 *Final Fantasy IX* · **Rare genre:** hot-and-cold proximity treasure digging · **Target:** ~10 min

- **Pitch:** Ride a big digging bird through meadows. It senses buried treasure only as warmer or colder, so you have to
  dig in the right place before its stamina runs out.
- **Controls:** Drag to steer the bird, tap to dig, tap the map to study fragments.
- **Run:** 6 fields of 90 s each. Three map fragments together reveal where the legendary chest is.
- **Win / Lose:** Dig up the legendary chest in field 6. The shared greens (stamina) reserve running out is the fail state.
- **Secret ★:** In field 6, dig where the moon's reflection sits in the pond.
- **Song: "Warmer, Warmer"**: renaissance ballad · ★lute, recorder, tabor · voice: boy soprano · hook: *"Warmer,
  warmer, under the moon."*

### Day 013: Recall
**Riff on:** #13 *God of War (2018)* · **Rare genre:** throw-and-recall trajectory puzzle · **Target:** ~11 min

- **Pitch:** A parent and child climb a frozen mountain. Throw an axe that sticks where it lands, then recall it along a
  straight line to smash runes, jam gears and carry the child's arrows.
- **Controls:** Drag and release to throw. Tap the recall button. Tap the child, then a target, to have them shoot.
- **Run:** 20 single-screen puzzles from the forest up to the summit, all drawing on one shared throw budget.
- **Win / Lose:** Reach the summit. Using up the 120-throw budget is the fail state.
- **Secret ★:** Hit all three hidden green-glowing ravens across the climb.
- **Song: "Call It Home"**: Nordic folk · ★nyckelharpa, frame drum, low strings · voice: female Nordic solo, intimate ·
  hook: *"Throw it far, call it home."*

### Day 014: Shadowtree Duels
**Riff on:** #14 *Elden Ring: Shadow of the Erdtree* · **Rare genre:** parry-timing duel (boss rush) · **Target:** ~10 min

- **Pitch:** Seven duels decided by timing. Read the telegraphed attacks, parry on the correct side, and riposte when
  your opponent's posture breaks.
- **Controls:** Tap the left or right half of the screen to parry that side. Swipe up to riposte. Hold anywhere to guard
  (you take chip damage).
- **Run:** 7 duellists of about 80 s each. Patterns escalate with delays, feints and mix-ups.
- **Win / Lose:** Defeat the Shadow of the Tree. You have 5 Resolve. Each lost duel costs one and retries that duel, and
  running out is the fail state.
- **Secret ★:** A small "bow" emote button is always on screen and never explained. Bow before the final duel starts, and
  the final duellist bows back.
- **Song: "The Bough Remembers"**: dark baroque · ★viola da gamba, chamber organ, timpani · voice: countertenor aria ·
  hook: *"Under the shadow, the bough remembers."*

### Day 015: Line & Grind
**Riff on:** #15 *Tony Hawk's Pro Skater 4* · **Rare genre:** line-drawing track rider · **Target:** ~12 min

- **Pitch:** Draw the skatepark with your finger. Your lines become ramps and rails, and a physics skater rides them to
  complete goals.
- **Controls:** Draw strokes, tap the eraser, tap Play/Stop.
- **Run:** 12 goals on one big sketchbook park: collect S-K-A-T-E, clear a gap, grind for 5 s, land in a zone, and more.
- **Win / Lose:** Complete all 12 goals. The ink tank, a global ink budget, emptying is the fail state.
- **Secret ★:** Draw a loop-de-loop that the skater rides all the way round.
- **Song: "Draw the Line"**: skate punk · ★overdriven power-chord guitar, fast drums, pick bass · voice: shouted gang
  vocals · hook: *"Draw the line, ride the line."*

### Day 016: Crimson Juggle
**Riff on:** #16 *Devil May Cry* · **Rare genre:** air-juggle keepy-uppy · **Target:** ~10 min

- **Pitch:** Stylish keepy-uppy. Tap demons to launch them, keep them in the air, and spike them into each other to raise
  your style rank.
- **Controls:** Tap an enemy to strike it upward. Swipe through an airborne enemy to spike it into another.
- **Run:** 7 missions of about 80 s each in a gothic castle. Each mission has a style-rank threshold.
- **Win / Lose:** Reach S rank on the final boss mission. Your health reaching 0 is the fail state; demons that land
  attack you.
- **Secret ★:** Juggle one demon **66 hits** without letting it touch the ground.
- **Song: "Let the Devils Cry"**: gothic metal · ★pipe organ, drop-D guitar, double kick · voice: operatic female with
  growled male responses · hook: *"Keep 'em flying, let the devils cry."*

### Day 017: Flag on the Play
**Riff on:** #17 *Madden NFL 2002* · **Rare genre:** referee sim · **Target:** ~11 min

- **Pitch:** You're the referee. Watch each play, spot the fouls, flag the right player and make the right call.
- **Controls:** Tap a player to throw a flag, pick the foul from a radial wheel, tap where the ball is spotted.
- **Run:** 4 quarters, 16 plays. Coaches challenge your calls with instant replays in the 4th quarter.
- **Win / Lose:** Finish the game with an officiating rating of at least 80%. The rating hitting 0 is the fail state
  (the crowd boos you off).
- **Secret ★:** Flag the dancing mascot for being offside.
- **Song: "Whistle Blows"**: marching band · ★sousaphone, snare line, bell lyre · voice: stadium crowd chant · hook:
  *"Whistle blows, everybody knows."*

### Day 018: Gargoyle Detective
**Riff on:** #18 *Batman: Arkham City* · **Rare genre:** forensic crime-scene reconstruction · **Target:** ~12 min

- **Pitch:** An owl detective perched above a rainy city scans crime scenes, links clues and scrubs through a
  reconstructed timeline of what happened.
- **Controls:** Drag the scanning lens, drag evidence onto the timeline, scrub the slider, tap Accuse.
- **Run:** 4 cases of about 3 min each, with the clue webs getting deeper.
- **Win / Lose:** Solve the final case. The 3rd wrong accusation is the fail state.
- **Secret ★:** In case 2, line the lens up so a lamp post and a puddle form a question mark.
- **Song: "Every Shadow Leaves a Clue"**: noir jazz · ★tenor saxophone, upright bass, brushes · voice: smoky
  contralto · hook: *"Every shadow leaves a clue."*

### Day 019: Orb Spelunker Pinball
**Riff on:** #19 *Metroid Prime Remastered* · **Rare genre:** metroidvania pinball · **Target:** ~12 min

- **Pitch:** A metroidvania built from four linked pinball tables. Earn abilities (bomb, boost, magnet ball) that open
  lanes on the other tables.
- **Controls:** Tap the left or right half for the flippers. Swipe up to nudge. Hold the launcher to charge it.
- **Run:** Explore the 4 tables, collect 3 artifacts, then take on the boss table.
- **Win / Lose:** Beat the boss table. Draining 5 balls is the fail state.
- **Secret ★:** Hit the tiny alien egg behind the upper ramp 3 times and it hatches.
- **Song: "Spark in the Shell"**: space rock · ★phaser electric guitar, analog synth bass, spacey toms · voice: distant
  female choir · hook: *"Roll through the dark, I'm a spark in the shell."*

### Day 020: Lunker Pond
**Riff on:** #20 *The Legend of Zelda: Ocarina of Time 3D* · **Rare genre:** lure fishing (line-tension sim) · **Target:** ~10 min

- **Pitch:** A sleepy old man's fishing pond. Cast lures, read how the fish behave, and manage line tension to land the
  legendary lunker.
- **Controls:** Drag and release to cast. Make small drags to twitch the lure. Drag in circles, or hold the reel button, to
  reel in. A tension meter shows the strain on the line.
- **Run:** A pond day on a clock. Catch fish to meet the weight targets. The lunker appears after your 5th catch.
- **Win / Lose:** Land the lunker (20 lb or more) before closing time. Closing time arriving first, or 3 snapped lines,
  is the fail state.
- **Secret ★:** Hook the sleeping owner's hat with your lure.
- **Song: "Wait for the Big One"**: lazy country blues · ★resonator guitar (dobro), washboard, upright bass · voice:
  sleepy old bass voice · hook: *"Wait for the big one, wait for the big one."*

### Day 021: Field of Hues
**Riff on:** #21 *Chrono Cross* · **Rare genre:** colour-field elemental duel · **Target:** ~11 min

- **Pitch:** An elemental tug-of-war. Play coloured element tiles. The field remembers the last three colours played and
  amplifies matching plays, and a field filled with one colour unlocks a summon.
- **Controls:** Tap a tile, then tap a target. Drag the summon token onto the field.
- **Run:** 8 duels against dragons, each with its own element and quirk.
- **Win / Lose:** Beat the final dragon. Losing 3 duels is the fail state.
- **Secret ★:** In a single duel, fill the field with the opponent's *own* colour three times. The dragon befriends you.
- **Song: "Two Shores, One Sea"**: Celtic-Mediterranean · ★uilleann pipes, nylon guitar, bodhrán · voice: Celtic
  soprano · hook: *"Two shores, one sea."*

### Day 022: Chalkboard Coach
**Riff on:** #22 *Madden NFL 2004* · **Rare genre:** playbook drawing (coach sim) · **Target:** ~12 min

- **Pitch:** Draw plays on a chalkboard: routes for receivers, blocks for linemen. The AI then runs your play against the
  defences you scouted.
- **Controls:** Drag routes, tap a player to assign a role, tap Snap.
- **Run:** A full game, 4 quarters, about 24 plays. Opponent tendencies show up in your scouting notes.
- **Win / Lose:** Win the game. Losing it is the fail state.
- **Secret ★:** Score a touchdown on a fake punt where the punter throws the pass.
- **Song: "Draw It Up"**: crunk · ★crunk synth brass, 808 kit, cowbell · voice: rhythmic rap-chant with hook singers ·
  hook: *"Draw it up, draw it up."*

### Day 023: Burrow Plug
**Riff on:** #23 *Gears of War* · **Rare genre:** emergence-hole defence (timed whack-a-mole) · **Target:** ~10 min

- **Pitch:** Burrowing creatures erupt from holes in a town square. Seal the holes with plugs. Your timing decides how
  strong each plug is, like an active reload.
- **Controls:** Tap a hole to throw a plug, then tap again as the needle crosses the sweet spot. Drag barricades into
  place.
- **Run:** 10 waves of about 60 s each, with new creature types every couple of waves.
- **Win / Lose:** Survive wave 10. The barricade's health reaching 0 is the fail state.
- **Secret ★:** Leave one hole open until a tiny harmless worm peeks out, then tap it. It waves goodbye.
- **Song: "Hold the Line"**: martial · ★war-drum ensemble (giant toms), low brass · voice: gruff baritone work-song
  chorus · hook: *"Hold the line, plug the mine."*

### Day 024: Silver Tongue
**Riff on:** #24 *The Elder Scrolls IV: Oblivion* · **Rare genre:** persuasion-wheel social game · **Target:** ~10 min

- **Pitch:** Win a town election by persuading eight townsfolk with a four-wedge wheel (Admire, Boast, Coerce, Joke).
  Read each face to learn what they like and hate.
- **Controls:** Tap the wedges in order. Tap the coin to bribe.
- **Run:** 8 townsfolk of about 70 s each. They keep daily schedules, so you can miss people.
- **Win / Lose:** By vote day, persuade at least 6 of the 8. Ending with fewer is the fail state.
- **Secret ★:** Persuade the horse.
- **Song: "Speak Sweet, Speak True"**: medieval orchestral · ★French horn choir, string ostinato · voice: town-crier
  baritone · hook: *"Speak sweet, speak true."*

### Day 025: Council of Five
**Riff on:** #25 *Sid Meier's Civilization II* · **Rare genre:** swipe-decision kingdom (Reigns-like) · **Target:** ~10 min

- **Pitch:** Rule from the Stone Age to the Space Age by swiping on your advisors' proposals, keeping Food, Faith, Gold and
  Science in balance.
- **Controls:** Swipe a card left or right (or tap the buttons). Press and hold to preview which meters it affects.
- **Run:** About 60 cards across 6 eras. Advisors remember how you treated them.
- **Win / Lose:** Launch the starship in the final era with every meter in range. Any meter hitting 0 or maxing out is
  the fail state.
- **Secret ★:** Agree with the **Jester** 5 times in a row. The Jester takes the throne for a turn.
- **Song: "One More Turn"**: baroque minuet · ★harpsichord, baroque strings · voice: five-voice madrigal ensemble ·
  hook: *"One more turn, one more turn."*

### Day 026: Rocket Jump Golf
**Riff on:** #26 *Quake* · **Rare genre:** blast-jump golf · **Target:** ~11 min

- **Pitch:** You can't walk; you can only launch yourself with explosions. Fire at floors and walls to blast-jump to each
  hole's flag in as few shots as possible.
- **Controls:** Drag to aim at a surface and release to fire. A ghost arc previews the launch.
- **Run:** 18 holes through a gothic fortress (lava, crushers, jump pads), each with a par.
- **Win / Lose:** Finish all 18 holes at no more than par +18. Going over that is the fail state.
- **Secret ★:** Shoot the cracked wall on hole 13 to open a secret chamber.
- **Song: "Higher into the Dark"**: dark ambient industrial · ★waterphone, bowed cymbal, industrial noise beds ·
  voice: processed whisper-singing male · hook: *"Blast me higher into the dark."*

### Day 027: Runner Caravan
**Riff on:** #27 *Metaphor: ReFantazio* · **Rare genre:** caravan travel management (Oregon-Trail-like) · **Target:** ~12 min

- **Pitch:** Steer a giant walking caravan across a fantasy kingdom. You have to reach the capital before the coronation
  vote while managing supplies, route, party morale and roadside events.
- **Controls:** Tap route nodes, drag the supply sliders, tap event choices.
- **Run:** 12 waypoints with branching roads. Events include bandits, festivals, broken legs on the walker and recruitable
  companions.
- **Win / Lose:** Arrive before day 20 with at least 3 companions. Arriving late, or with the party lost, is the fail state.
- **Secret ★:** Rest at the lonely bard's node and listen to his whole song without tapping anything.
- **Song: "The Road Is Long"**: medieval prog · ★shawm (rauschpfeife), tabor, prog-rock synth · voice: fast-chanting
  mixed choir · hook: *"The road is long, but the song is longer."*

### Day 028: Long Shot Range
**Riff on:** #28 *Call of Duty 4: Modern Warfare* · **Rare genre:** long-range marksmanship / ballistics (non-violent targets) · **Target:** ~10 min

- **Pitch:** Competition shooting at steel plates and balloons. Read the wind flags, allow for bullet drop and hold your
  breath at the right moment.
- **Controls:** Drag to aim. Pinch, the mouse wheel or ± zoom. Hold the breath button and tap Fire.
- **Run:** 5 ranges from 100 m to 1000 m, each with limited rounds. The wind gets more complex as you go.
- **Win / Lose:** Reach the qualification score. Ending below it is the fail state.
- **Secret ★:** On the final range, hit the far-off Ferris wheel cabin.
- **Song: "Hold Your Breath"**: hybrid orchestral · ★spiccato cello section, synth arpeggio · voice: lone low male ·
  hook: *"Hold your breath, the wind will tell."*

### Day 029: Skyline Hopper
**Riff on:** #29 *BioShock Infinite* · **Rare genre:** rail-hopping runner · **Target:** ~10 min

- **Pitch:** Ride sky-rails between floating city blocks, hopping lines to dodge gaps, grab coins and catch rides on
  passing gondolas.
- **Controls:** Tap to hop to the next rail up or down (the side you tap). Hold to brake. Swipe up to hook coins.
- **Run:** 7 districts of about 85 s each. Rails get faster, split more often and start to sway.
- **Win / Lose:** Reach the tower. The 3rd fall is the fail state.
- **Secret ★:** In district 4, tap the shimmering tear in the sky three times to glimpse a 1980s street through it.
- **Song: "Ride the Line"**: ragtime · ★honky-tonk ragtime piano, brass band · voice: barbershop quartet · hook:
  *"Ride the line through the clouds of time."*

### Day 030: Theater Mode
**Riff on:** #30 *Halo 3* · **Rare genre:** live cinematography (camera director) · **Target:** ~11 min

- **Pitch:** A robot war game plays out once, and you're the director. Frame shots, cut between cameras and capture every
  moment on the shot list with good composition.
- **Controls:** Drag the framing box. Pinch, the mouse wheel or ± zoom. Tap camera presets and tap to record a cut.
- **Run:** 4 reels of about 2.5 min each. Shot-list moments are flagged a few seconds before they happen.
- **Win / Lose:** Finish with a film score of B or better. Missing too many key moments is the fail state (the film gets
  rejected).
- **Secret ★:** Catch the rare moment when a tiny critter pops into a burst of party streamers.
- **Song: "Frame by Frame"**: elegiac piano ballad · ★concert grand piano, string pad · voice: soft tenor · hook: *"Frame
  by frame, the legends came."*

### Day 031: Nine Seals
**Riff on:** #31 *Ninja Gaiden Black* · **Rare genre:** gesture-glyph combat · **Target:** ~10 min

- **Pitch:** Draw hand-sign glyphs to cast ninja arts at approaching fiends. Faster, cleaner strokes hit harder.
- **Controls:** Draw glyph strokes anywhere on screen. The recognizer is shape-based and forgiving.
- **Run:** 9 stages, one new seal each, ending with a boss that demands glyph chains.
- **Win / Lose:** Defeat the final fiend. Your health reaching 0 is the fail state.
- **Secret ★:** A torn scroll page shows half of a spiral glyph. Draw the complete spiral.
- **Song: "Nine Signs, One Breath"**: Japanese-electronic fusion · ★shakuhachi, shamisen, electronic beat · voice:
  min'yō-style female with ornamented phrasing · hook: *"Nine signs, one breath."*

### Day 032: Just a Box
**Riff on:** #32 *Metal Gear Solid* · **Rare genre:** hide-in-plain-sight (prop stealth) · **Target:** ~11 min

- **Pitch:** You're a cardboard box in a busy warehouse. Move only when nobody is watching, blend in with the other boxes
  and ride the conveyors to freedom.
- **Controls:** Tap an adjacent tile to shuffle one step. Hold to freeze (you look like an ordinary box).
- **Run:** 10 warehouse floors. Guards count boxes, so new boxes look suspicious. Forklifts move stacks, and scanners
  sweep the floor.
- **Win / Lose:** Escape through the loading bay. Being spotted ("!") 3 times is the fail state.
- **Secret ★:** On floor 1, tune the wall radio to **140.85**. That number is printed on a crate label on floor 3.
- **Song: "Nobody Looks Inside a Box"**: cinematic spy-Celtic · ★low whistle, strings, snare · voice: Gaelic-style
  female (English lyrics) · hook: *"Nobody looks inside a box."*

### Day 033: Departures of the Dearly
**Riff on:** #33 *Grim Fandango* · **Rare genre:** travel-agent itinerary matching (afterlife deduction) · **Target:** ~12 min

- **Pitch:** You're a travel agent for newly departed souls. Read each client's life story, work out how virtuous they
  were and sell them the right journey, from a walking stick to the express train.
- **Controls:** Tap the files to read, tap clues to highlight them, drag a ticket onto a client.
- **Run:** 12 clients spread over 4 "years" (chapters). A rival agent is stealing the good clients.
- **Win / Lose:** Find the true saint and send them on the express. Mis-selling a 4th client gets you fired, the fail state.
- **Secret ★:** Give the paper marigold from your desk to your boss.
- **Song: "Four Years by Foot"**: son jarocho noir · ★jarana, marimba, big-band horns · voice: mariachi tenor with
  grito · hook: *"Four years by foot, or one night by train."*

### Day 034: Rooftop Spray Crew
**Riff on:** #34 *Jet Set Radio* · **Rare genre:** turf-tagging territory control · **Target:** ~10 min

- **Pitch:** Skate a neon city district, tagging spots before rival crews do. Rivals re-tag your spots, and the cops
  close in.
- **Controls:** Drag to steer, or use the virtual joystick. Tap a tag spot, then swipe the arrow sequence to paint it.
- **Run:** 3 districts × 3 min. Rival crew AI and escalating police waves.
- **Win / Lose:** Hold at least 75% of the tags when each district timer ends. Getting busted 3 times, or ending a
  district below the threshold, is the fail state.
- **Secret ★:** Tag the police captain's parked cruiser.
- **Song: "Paint the Town"**: funky breakbeat · ★turntable scratches, funky bass, breaks · voice: pirate-radio DJ hype
  with chopped vocals · hook: *"Paint the town before the sirens come."*

### Day 035: Spade Panel Party
**Riff on:** #35 *Super Mario Advance 4: Super Mario Bros. 3* · **Rare genre:** memory concentration (pairs) · **Target:** ~9 min

- **Pitch:** A theatre-stage memory game. Flip panels to match pairs on boards that grow, shuffle and hide special panels.
- **Controls:** Tap panels. Tap the roulette to stop it.
- **Run:** 6 boards, growing from 3×4 to 6×6. Between boards a slot roulette awards a peek or a shield. Later boards add
  panels that swap places.
- **Win / Lose:** Clear board 6. Three misses on a board cost a life, and losing all 5 lives is the fail state.
- **Secret ★:** Board 4 hides two almost-blank "whistle" panels that look like background. Match them.
- **Song: "Turn Two Over"**: chip vaudeville · ★2A03-style pulse/triangle/noise chip voices, stage brass · voice:
  vaudeville tenor · hook: *"Turn two over, find the clover."*

### Day 036: Tumbler
**Riff on:** #36 *Tom Clancy's Splinter Cell: Chaos Theory* · **Rare genre:** tactile lockpicking · **Target:** ~10 min

- **Pitch:** Pick pin-tumbler locks by feel: the pick wobbles, the pin clicks, and the phone vibrates where supported.
  A guard's patrol timer keeps the pressure on.
- **Controls:** Drag the pick up and down to probe pins. Hold the tension button and release at the set point.
- **Run:** 12 locks inside a lighthouse station, adding more pins, spool pins and false sets as you go.
- **Win / Lose:** Reach the server room. The 3rd alarm (a timer running out) is the fail state.
- **Secret ★:** Pick the lock on the break-room vending machine. It looks like decoration.
- **Song: "Pin by Pin"**: downtempo · ★upright jazz bass (bowed and plucked), granular textures · voice: hushed male ·
  hook: *"Pin by pin, let me in."*

### Day 037: Wolfsled
**Riff on:** #37 *God of War Ragnarök* · **Rare genre:** sled-dog mushing (team management racing) · **Target:** ~11 min

- **Pitch:** Race a wolf sled team across nine frozen realms before the long winter closes in, balancing speed, the team's
  stamina and the trail.
- **Controls:** Tap the left or right side to steer. Hold to brake. Tap the encourage button for a burst (it costs
  stamina). Tap shelters to rest.
- **Run:** 9 legs of about 70 s each, with blizzards, ice bridges and rival sleds.
- **Win / Lose:** Reach the final hall before the winter timer runs out. The timer running out, or the team becoming
  exhausted, is the fail state.
- **Secret ★:** At any shelter, pet every dog in the team once.
- **Song: "Ahead of the Long Winter"**: epic Nordic · ★Hardanger fiddle, frame drums · voice: overtone throat singer ·
  hook: *"Run, wolves, run, ahead of the long winter."*

### Day 038: Ink Ribbons
**Riff on:** #38 *Resident Evil Code: Veronica* · **Rare genre:** key-and-lock route planning (scarcity) · **Target:** ~12 min

- **Pitch:** Escape a snowbound mansion by planning routes across its floor plan. Keys open doors, danger rooms drain
  health, and saves at the typewriter use up scarce ink ribbons.
- **Controls:** Tap rooms to move. Drag items in the inventory to combine them. Tap the typewriter to save a checkpoint.
- **Run:** A 3-floor map with limited inventory slots and item boxes. The clock is counting down to a self-destruct.
- **Win / Lose:** Escape on the plane. Your health reaching 0, or the clock running out, is the fail state.
- **Secret ★:** In the twins' room, wind the music box and play its melody.
- **Song: "The Snow Keeps the Door"**: gothic lullaby · ★detuned music box, bowed glass · voice: eerie child-twin duet ·
  hook: *"Sleep, sister, the snow keeps the door."*

### Day 039: Pileup Junction
**Riff on:** #39 *Burnout 3: Takedown* · **Rare genre:** crash-junction physics puzzle · **Target:** ~10 min

- **Pitch:** Launch your car into busy junctions to cause the most spectacular (and cartoonish) pile-up. Steer the
  tumbling wreck with aftertouch and set off the crash-breaker.
- **Controls:** Drag back to set speed and release. After impact, swipe to steer the wreck (aftertouch) and tap to
  detonate.
- **Run:** 15 junctions with score medals. Traffic patterns repeat, so you can learn them.
- **Win / Lose:** Reach bronze or better on all 15. Failing 3 junctions is the fail state.
- **Secret ★:** Land your car on the roof of the double-decker bus.
- **Song: "Take It Down Tonight"**: Eurodance · ★M1-style house piano stabs, Eurodance bass · voice: diva female with
  male rap verse · hook: *"Take it down, take it down tonight."*

### Day 040: Cursed Curios
**Riff on:** #40 *Diablo* · **Rare genre:** merchant appraisal sim · **Target:** ~11 min

- **Pitch:** You're the town merchant buying loot from heroes who dive deeper each day. Appraise items, spot the cursed
  ones from their clues, and set prices you can profit on.
- **Controls:** Tap an item to inspect it. Drag it to the candle, scale or identify scroll. Drag the offer slider and tap
  Haggle.
- **Run:** 10 market days. The loot gets rarer and the curses subtler.
- **Win / Lose:** Earn enough gold to pay for the town wall. Going bankrupt, or selling a 3rd cursed item, is the fail
  state.
- **Secret ★:** Tap the town cow 10 times.
- **Song: "The Price Is Right"**: dark acoustic ambient · ★12-string guitar, cavern reverb · voice: hooded monk bass ·
  hook: *"Stay a while, the price is right."*

### Day 041: Camo Index
**Riff on:** #41 *Metal Gear Solid 3: Subsistence* · **Rare genre:** camouflage-matching stealth · **Target:** ~11 min

- **Pitch:** Cross a jungle by matching your camouflage to every surface you stop on. The camo index (in %) decides
  whether passing patrols notice you.
- **Controls:** Tap a cover point to move. Open the camo wheel to pick a uniform and face paint.
- **Run:** 10 jungle zones with bark, mud, leaves, water, snow and night variants.
- **Win / Lose:** Reach extraction. Being spotted 3 times is the fail state.
- **Secret ★:** In zone 7, stay still for 90 s until the ancient sniper on the hill nods off.
- **Song: "Hidden in Green"**: 60s spy ballad · ★growling trombone section, string sweeps · voice: brassy female diva ·
  hook: *"Hidden in green, I'm never seen."*

### Day 042: Cliffhanger
**Riff on:** #42 *Call of Duty: Modern Warfare 2* · **Rare genre:** two-hand ice-climbing timing · **Target:** ~10 min

- **Pitch:** Climb an ice wall by alternating ice-axe swings. Bad timing cracks the ice, and storms shake you loose.
- **Controls:** Tap the left half for the left axe and the right half for the right axe, each in its sweet spot. Drag a
  boot onto a hold during rests.
- **Run:** 5 pitches, adding blizzards, cracking ice and an overhang.
- **Win / Lose:** Reach the summit. The 3rd fall (stamina reaching 0) is the fail state.
- **Secret ★:** During the blizzard, tap the heartbeat sensor on your wrist. It reveals a snow hare, and you tap the hare.
- **Song: "Hand Over Hand"**: Slavic folk · ★balalaika, domra, bayan · voice: female "white-voice" folk choir · hook:
  *"Hand over hand to the top of the world."*

### Day 043: Tether
**Riff on:** #43 *Metal Gear Solid 4: Guns of the Patriots* · **Rare genre:** tethered-drone piloting · **Target:** ~11 min

- **Pitch:** Pilot a little robot on a cable through vents and rooms for an old soldier. The cable snags on corners, has
  a fixed length, and the battery drains.
- **Controls:** Use the virtual joystick or tap a path. Tap the reel to retract cable. Tap items to grab them.
- **Run:** 12 rooms of growing complexity, with pulley points, moving fans and guards who trip on the cable.
- **Win / Lose:** Deliver the access chip. A snapped cable or empty battery 3 times is the fail state.
- **Secret ★:** Pick up the music player in room 6 and bring it back to the old soldier.
- **Song: "Cable's Getting Short"**: blues · ★blues harmonica, acoustic slide, stomp box · voice: gravelly old
  baritone · hook: *"Old soldier, cable's getting short."*

### Day 044: The Ashen Oath
**Riff on:** #44 *God of War (2005)* · **Rare genre:** quick-time cinematic action · **Target:** ~10 min

- **Pitch:** A myth-sized interactive film. Every beat is a timed prompt: tap the circle, swipe the direction, mash the
  meter.
- **Controls:** Tap the prompts, swipe the arrows, tap rapidly on mash meters.
- **Run:** 8 set pieces (sea serpent, cyclops, labyrinth, sky chariot, titan and more) of about 75 s each.
- **Win / Lose:** Open the forbidden box and ascend. Each scene allows 3 missed prompts before it restarts, and a 5th
  scene restart is the fail state.
- **Secret ★:** In scene 1, tap the boat captain before the serpent swallows him.
- **Song: "Open the Box"**: epic Greek choral · ★kithara (lyre), war horns, full chorus · voice: big mixed chorus,
  fortissimo · hook: *"Open the box and the world will burn."*

### Day 045: Twenty Cantina
**Riff on:** #45 *Star Wars: Knights of the Old Republic* · **Rare genre:** side-deck blackjack duel · **Target:** ~10 min

- **Pitch:** A space-cantina card game. Get as close to 20 as you can without going over, using a hand of ± side cards
  you draft before each set.
- **Controls:** Tap Draw or Stand. Tap a side card to play it, and tap again to flip its sign.
- **Run:** A tournament of 6 opponents, each best-of-3 with a distinct style (cautious, reckless, cheater).
- **Win / Lose:** Win the tournament. Running out of credits is the fail state.
- **Secret ★:** Win a set by filling the table with nine cards without going over.
- **Song: "Deal Me Plenty"**: space-cantina swing · ★clarinet, upright bass, alien percussion · voice: huge-formant
  alien lounge singer · hook: *"Twenty, twenty, honey, deal me plenty."*

### Day 046: Hex Hearth
**Riff on:** #46 *Sid Meier's Civilization IV* · **Rare genre:** hex tile-laying · **Target:** ~11 min

- **Pitch:** Grow a civilization one hex tile at a time. Fields, forests, rivers and villages score when they match their
  neighbours, and quests ask for specific shapes.
- **Controls:** Tap to rotate the tile and drag to place it. Pinch, the wheel or ± zoom.
- **Run:** A deck of 60 tiles. Finished quests add more tiles to the deck, and a wonder appears at 40 tiles.
- **Win / Lose:** Reach the target score and complete the wonder. Running out of tiles below the target is the fail state.
- **Secret ★:** Close a river loop around a single tile. A temple rises on the island.
- **Song: "Hand in Hand"**: African choral · ★kalimba (mbira), hand drums, shaker · voice: call-and-response choir ·
  hook: *"Lay the land, hand in hand."*

### Day 047: Hall of Paintings
**Riff on:** #47 *Super Mario 64* · **Rare genre:** sliding-tile puzzle (animated paintings) · **Target:** ~12 min

- **Pitch:** A castle hall of living paintings, scrambled into tiles. Slide them back together. Each solved painting
  awards a star.
- **Controls:** Tap or swipe a tile next to the gap. Press and hold for a 2-second peek at the solved picture (limited
  uses).
- **Run:** 10 paintings, from 3×3 up to 5×5. The tiles are animated (waves, clouds, lava), so their edges keep moving.
- **Win / Lose:** Earn 8 stars before the candle burns out. The candle burning out is the fail state.
- **Secret ★:** Catch the rabbit hopping around the hall floor 3 times.
- **Song: "Jump into the Frame"**: bossa lounge · ★vibraphone, nylon guitar, brushed kit · voice: soft bossa female ·
  hook: *"Jump into the frame, nothing stays the same."*

### Day 048: Yomi Dojo
**Riff on:** #48 *Virtua Fighter 4* · **Rare genre:** simultaneous-choice mind-game fighter · **Target:** ~10 min

- **Pitch:** Each exchange is a hidden simultaneous choice: Strike beats Throw, Throw beats Guard, Guard beats Strike, and
  Evade dodges strikes. Read your opponent's habits and push them out of the ring.
- **Controls:** Tap one of four big buttons. Swipe to choose the evade direction.
- **Run:** A kumite ladder of 10 opponents, each with a readable but adaptive pattern.
- **Win / Lose:** Beat the master. Losing 3 matches is the fail state.
- **Secret ★:** Win a round without using Strike once.
- **Song: "Read Me Twice"**: wuxia rock · ★guzheng, rock drums, overdriven bass · voice: heroic wuxia tenor · hook:
  *"Read me once, read me twice."*

### Day 049: Weighted Friend
**Riff on:** #49 *Portal: Companion Collection* · **Rare genre:** virtual pet · **Target:** ~10 min

- **Pitch:** A test lab issues you a weighted cube. Keep it happy through ten test days while a sardonic lab voice keeps
  hinting that you'll have to give it up.
- **Controls:** Tap to pet. Drag toys, blankets and stickers onto the cube. Short chores use taps and drags.
- **Run:** 10 test days of about 1 min each. Its needs (comfort, play, light, quiet) shift each day, and the lab throws in
  surprises.
- **Win / Lose:** Keep the heart meter above zero through day 10, then find the hidden panel and escape together.
  The heart meter reaching 0, or obeying the incinerator, is the fail state.
- **Secret ★:** Find the hidden radio and bring it to the cube.
- **Song: "Only Weighted"**: sardonic synth-pop lullaby · ★DX7-style FM electric piano, drum machine · voice: deadpan AI
  female with quantised pitch · hook: *"Hold me close, I'm only weighted."*

### Day 050: Pause & Plan
**Riff on:** #50 *Baldur's Gate II: Shadows of Amn* · **Rare genre:** real-time-with-pause tactics · **Target:** ~12 min

- **Pitch:** A four-hero party fights through a dungeon. Pause at any moment to queue orders, aim area spells and position
  your party, then unpause and watch it play out.
- **Controls:** Tap the big Pause button. Tap a hero, then a target. Drag a lasso to select several heroes. Hold an
  ability to see its range.
- **Run:** 6 encounters, ending with the exiled mage.
- **Win / Lose:** Defeat the exiled mage. Your whole party falling (a wipe) is the fail state.
- **Secret ★:** In the final fight, send the hamster familiar at the mage and let it land the last hit.
- **Song: "Pause the World"**: heroic fantasy orchestral · ★natural-trumpet fanfare, field snare, strings · voice:
  baritone and tenor duet · hook: *"Pause the world and plan the fight."*

### Day 051: Hydraulic Hop
**Riff on:** #51 *Grand Theft Auto: San Andreas* · **Rare genre:** lowrider hydraulics rhythm · **Target:** ~10 min

- **Pitch:** Cruise-off competitions on the boulevard. Bounce your lowrider's corners to the beat to win the crowd.
- **Controls:** Swipe up, down, left or right on the beat to fire the front, back, left or right hydraulics. Hold for a big
  hop.
- **Run:** 5 cruise-offs of about 2 min each against rival crews. Each song section brings new move patterns, and the
  last cruise-off is a call-and-response battle.
- **Win / Lose:** Win the championship. Losing 2 cruise-offs is the fail state.
- **Secret ★:** Hop so high that the car flips and lands back on its wheels.
- **Song: "Bounce on the Boulevard"**: G-funk · ★portamento Moog-style lead, talkbox, laid-back drums · voice: talkbox
  R&B · hook: *"Bounce, bounce on the boulevard."*

### Day 052: Glue & Glide
**Riff on:** #52 *The Legend of Zelda: Tears of the Kingdom (Switch 2 Edition)* · **Rare genre:** glue-craft vehicle builder · **Target:** ~12 min

- **Pitch:** Glue logs, fans, wheels, balloons and sails into contraptions that carry you between sky islands.
- **Controls:** Drag parts and tap a joint to glue it. Tap a part to rotate it. Tap Launch, and tap the fans in flight to
  toggle them.
- **Run:** 10 challenges (ferry a crate, cross a canyon, climb a waterfall and more). Every part costs charge.
- **Win / Lose:** Reach the final island. Running the shared charge pool dry is the fail state.
- **Secret ★:** A crying leaf-sprite wants to reach its friend on another island. Build something that carries it there.
- **Song: "Stick It Together"**: ambient Japanese · ★koto, sparse strings, wind chimes · voice: gentle high female ·
  hook: *"Stick it together, sail through the weather."*

### Day 053: Neon Bay FM
**Riff on:** #53 *Grand Theft Auto: Vice City* · **Rare genre:** radio-DJ station sim · **Target:** ~12 min

- **Pitch:** Run an 80s night-time radio show. Cue records, beat-match the transitions, slot in ads and caller requests,
  and never let the air go dead.
- **Controls:** Drag records onto the decks, tap Cue, drag the tempo slider and the crossfader, and tap an ad cart.
- **Run:** One night shift (8 hours squeezed into about 12 min). Listener moods shift, callers make demands, and the
  sponsor needs its ads aired.
- **Win / Lose:** Be the #1 station by dawn. Dead air 3 times, or the ratings crashing, is the fail state.
- **Secret ★:** Play the same record on both decks in perfect sync, creating a phasing effect.
- **Song: "Turn It Up on the Bay"**: 80s synth-pop · ★gated-reverb LinnDrum-style kit, Juno-style poly synth · voice:
  big 80s power male · hook: *"Turn it up on the bay tonight."* Also needs **three 30-second in-world "records"** in other
  styles (power ballad, electro, new wave) rendered by the same pipeline.

### Day 054: Stitch & Sticker
**Riff on:** #54 *LittleBigPlanet* · **Rare genre:** guide-the-walker sticker puzzle · **Target:** ~11 min

- **Pitch:** A knitted doll walks on its own through cardboard levels. Place stickers (springs, glue, sponge grabbers,
  arrows) to steer it to the exit.
- **Controls:** Drag a sticker from the tray onto the level. Tap a sticker to remove it. Tap Play.
- **Run:** 12 cardboard levels, each with a limited sticker tray.
- **Win / Lose:** Reach the end of the craft world. Losing all 5 yarn lives is the fail state.
- **Secret ★:** Put a sponge sticker on the cardboard sun to reveal a hidden prize bubble.
- **Song: "Flip the Switch"**: quirky indie folk · ★ukulele, glockenspiel, hand claps, whistling · voice: cheerful
  whistling duo · hook: *"Stick it, stitch it, flip the switch."*

### Day 055: The Curator's Vault
**Riff on:** #55 *The Legend of Zelda: Collector's Edition* · **Rare genre:** museum curation sim · **Target:** ~11 min

- **Pitch:** Restore and exhibit a collection of old game cartridges and artefacts. Clean them, repair them, then arrange
  the halls by era and theme for picky critics.
- **Controls:** Rub to clean, drag to place, tap a tool, drag the glue brush.
- **Run:** 5 halls, each with a critic who has their own tastes. Opening night comes last.
- **Win / Lose:** Earn a 5-star rating on opening night. Breaking 3 artefacts, or missing the rating, is the fail state.
- **Secret ★:** Tap the dusty cartridge slot rapidly (the classic "blow on it" move).
- **Song: "Dust It Off"**: chamber retro · ★string quartet in pizzicato, playing chip-style melodies · voice: elderly
  museum-docent tenor · hook: *"Dust it off, the past is soft."*

### Day 056: Contain the Bloom
**Riff on:** #56 *Halo 2* · **Rare genre:** spread-containment puzzle · **Target:** ~11 min

- **Pitch:** A creeping bloom spreads cell by cell through a ring station. Place barriers in real time to wall it off
  before it reaches the core.
- **Controls:** Tap a cell to drop a barrier (with a cooldown). Drag along cells to draw a wall (costs more). Tap vents to
  vent the bloom out.
- **Run:** 12 sectors with different spread rules (jumpers, fast creepers, spores that cross barriers).
- **Win / Lose:** Contain all 12 sectors. The bloom reaching the core 3 times is the fail state.
- **Secret ★:** Keep the tiny party-hatted critter sealed safely inside your walls for a whole sector.
- **Song: "Close the Room"**: rock choral · ★shred lead guitar with whammy, choir pads · voice: mezzo-soprano choir ·
  hook: *"Hold the bloom, close the room."*

### Day 057: Pace Notes
**Riff on:** #57 *Gran Turismo 3: A-Spec* · **Rare genre:** rally co-driver (call the corners) · **Target:** ~11 min

- **Pitch:** You're the co-driver. Read the stage notes and call the corners in time ("Left 3, over crest…"). The AI driver
  trusts you completely.
- **Controls:** Tap note cards (direction and severity) as corners approach. Swipe down for "caution".
- **Run:** 6 rally stages of about 1.5–2 min each on gravel, snow, tarmac and at night.
- **Win / Lose:** Win the rally on total time. The 3rd wreck is the fail state.
- **Secret ★:** After 3 perfect calls in a row a hidden "Trust me" card appears. Play it just before the big crest.
- **Song: "Left Three, Over Crest"**: J-fusion · ★EWI lead, fusion drums, fretless bass · voice: spoken-sung
  co-driver with female chorus · hook: *"Left three, over crest, keep it flat."*

### Day 058: Three Day Moon
**Riff on:** #58 *The Legend of Zelda: Majora's Mask* · **Rare genre:** time-loop schedule puzzle · **Target:** ~13 min

- **Pitch:** A town has three days before the moon falls, and each loop lasts about 3 minutes. Learn everyone's
  schedules, then step in at exactly the right moments. Your notebook carries over between loops.
- **Controls:** Tap places on the map to travel. Tap the clock to skip an hour. The notebook fills in automatically.
- **Run:** Up to 5 loops. There are 4 key stories to resolve and several side stories.
- **Win / Lose:** Resolve all 4 key stories within the 5 loops. Running out of loops is the fail state.
- **Secret ★:** On the final night, give the postman the priority letter so he can finally flee town.
- **Song: "Three More Dawns"**: carnival waltz · ★calliope, accordion, clock-tick percussion · voice: carnival-barker
  baritone with boys' choir · hook: *"Three more dawns before the moon comes down."*

### Day 059: Two Worlds Lantern
**Riff on:** #59 *The Legend of Zelda: A Link to the Past / Four Swords* · **Rare genre:** dual-world layer-swap maze · **Target:** ~11 min

- **Pitch:** Every room exists in a light world and a dark world. Walls in one are paths in the other. Swap worlds at
  lanterns to get through.
- **Controls:** Tap a tile to walk. Tap the lantern you're standing next to to swap worlds.
- **Run:** 16 rooms across 2 dungeons, adding pushable blocks, enemies that exist in only one world, and four-colour
  gem switches.
- **Win / Lose:** Claim the old sword. Losing all 10 hearts is the fail state.
- **Secret ★:** Tap the hen 20 times, then survive the flock that comes for you.
- **Song: "Light on One Side"**: 16-bit orchestral · ★lo-fi SNES-style sampled orchestra (32 kHz, BRR crunch) ·
  voice: boy and girl duet · hook: *"Light on one side, dark on the other."*

### Day 060: Overgrowth
**Riff on:** #60 *The Last of Us* · **Rare genre:** ecological-succession rewilding puzzle · **Target:** ~12 min

- **Pitch:** Help nature reclaim an empty city. Plant pioneers to crack the concrete, build up soil and food webs, and
  draw the animals back.
- **Controls:** Tap a tile to plant from the palette. Drag the watering can. Tap an animal to see what it needs.
- **Run:** 3 city blocks × 4 seasons. Each season resolves growth, spread and invasions.
- **Win / Lose:** Hit the biodiversity target by the final spring, when giraffes arrive. Ecosystem collapse or an
  invasive species taking over is the fail state.
- **Secret ★:** Plant an acacia on the rooftop tile so the giraffe can eat from it.
- **Song: "Green Comes Back"**: Appalachian folk · ★clawhammer banjo, cello · voice: duet of a weathered man and a
  teenage girl · hook: *"Green comes back to the broken town."*

### Day 061: Howling Stones
**Riff on:** #61 *The Legend of Zelda: Twilight Princess* · **Rare genre:** pitch-contour matching (howling) · **Target:** ~10 min

- **Pitch:** A twilight wolf learns ancient songs at howling stones. Trace each melody's pitch contour by sliding your
  howl up and down, with no microphone needed.
- **Controls:** Drag up and down to set your howl's pitch. Hold to sustain, release to breathe.
- **Run:** 8 stones, each song longer and more ornamented. The ghost wolf duets with you on the last three.
- **Win / Lose:** Learn all 8 songs. Twilight creeping in to full darkness (it grows with every poor howl) is the fail
  state.
- **Secret ★:** While the moon is out, howl at the very top of your range for 5 seconds.
- **Song: "Between the Light and Dark"**: twilight orchestral · ★reversed piano and breath textures, strings · voice:
  impish pitch-shifted female · hook: *"Between the light and the dark I run."*

### Day 062: Chalk the Field
**Riff on:** #62 *Madden NFL 2003* · **Rare genre:** groundskeeping and line painting · **Target:** ~10 min

- **Pitch:** It's game day and the field must be perfect. Paint the yard lines and numbers, mow the patterns, and time the
  sprinklers around the weather.
- **Controls:** Drag the line painter along the guides (accuracy is scored). Tap tools. Drag the mower.
- **Run:** Prepare the field for 5 game days. Each brings a twist: rain, wind, a dog on the field, a logo stencil.
- **Win / Lose:** Pass all 5 inspections. Failing 2 is the fail state.
- **Secret ★:** Switch the sprinklers on while the coach is standing on the field.
- **Song: "Cleanest Field"**: country rock · ★pedal steel guitar, Telecaster twang · voice: twangy male country singer ·
  hook: *"White lines on the green, cleanest field you've seen."*

### Day 063: Moonlit Circles
**Riff on:** #63 *Hades II* · **Rare genre:** encircle/lasso action roguelite · **Target:** ~12 min

- **Pitch:** A young witch binds enemies by drawing circles around them. Bigger loops catch more enemies but bind them
  more weakly. Between rooms, pick boons that change your circles.
- **Controls:** Draw a closed loop around enemies. Tap to dash. Tap one of three boon cards to take it.
- **Run:** 4 regions × 4 rooms, then the Titan of Time.
- **Win / Lose:** Defeat the Titan of Time. Your health reaching 0 is the fail state (you get one revive per run).
- **Secret ★:** Draw a circle around the cat in the hub. It purrs and joins you as a familiar.
- **Song: "Close the Night"**: dark folk rock · ★bouzouki, cello-rock riffs · voice: female dark-folk duet · hook:
  *"Draw the circle, close the night."*

### Day 064: Thirty Days of Masks
**Riff on:** #64 *Persona 5 Royal* · **Rare genre:** calendar life-sim · **Target:** ~11 min

- **Pitch:** Thirty days until the big heist. Split each day between school, part-time jobs and friends to raise five
  social stats and five bonds.
- **Controls:** Tap activity cards on the calendar. Tap dialogue choices in short scenes.
- **Run:** 30 days of about 20 s each, with weather, events and exams.
- **Win / Lose:** On day 30, pass the heist's stat and bond checks. Failing them is the fail state.
- **Secret ★:** On a rainy day, tap the window. A hidden "stare at the rain" option appears; choose it.
- **Song: "Steal the Day"**: acid jazz · ★jazz flute, acid-jazz bass, organ stabs · voice: soulful female ·
  hook: *"Steal the day before it's gone."*

### Day 065: Plank & Pallet
**Riff on:** #65 *The Last of Us Remastered* · **Rare genre:** companion-escort logistics puzzle · **Target:** ~11 min

- **Pitch:** Get your young companion, who can't swim, across a flooded city. Move planks, float pallets and raise
  ladders. You can do things they can't.
- **Controls:** Tap to walk. Drag planks, pallets and ladders when you're next to them. Tap the companion to have them
  wait or follow.
- **Run:** 15 crossings, adding currents, collapsing floors and two-step relay puzzles.
- **Win / Lose:** Reach the dam. The 3rd fall (a bad crossing) is the fail state.
- **Secret ★:** Tap the pun book on the bench 5 times. The companion reads every pun aloud.
- **Song: "I've Got You"**: lonely acoustic · ★musical saw, soft nylon guitar · voice: tender baritone with whistling ·
  hook: *"Hold the plank, I've got you."*

### Day 066: Liar's Saloon
**Riff on:** #66 *Red Dead Redemption* · **Rare genre:** liar's-dice bluffing · **Target:** ~10 min

- **Pitch:** A frontier saloon tournament of liar's dice. Bid on the dice hidden under everyone's cups, call bluffs, and
  read each opponent's tells.
- **Controls:** Use the spinners to pick quantity and face, then tap Bid, or tap "Liar!".
- **Run:** 5 opponents with distinct tells and styles. The final table is three-way.
- **Win / Lose:** Win the final table. Losing your whole bankroll is the fail state.
- **Secret ★:** Tip the piano player by tapping his jar.
- **Song: "Dice in the Dark"**: spaghetti western · ★jaw harp, whistled melody, twang guitar · voice: lone cowboy
  baritone · hook: *"Dice in the dark, truth in the eyes."*

### Day 067: Goo Lab
**Riff on:** #67 *Portal 2* · **Rare genre:** gel-painting physics puzzle · **Target:** ~11 min

- **Pitch:** Paint surfaces with bounce gel, speed gel and sticky gel so a test ball rolls into the exit.
- **Controls:** Pick a gel and drag to paint. Tap the faucet to release the ball, and tap Reset.
- **Run:** 15 test chambers with moving panels, fans and gel that mixes.
- **Win / Lose:** Clear every chamber. Emptying the global gel tanks is the fail state.
- **Secret ★:** Route the ball past the hidden potato battery to charge it.
- **Song: "Bounce Some More"**: electro-swing · ★theremin, drum machine, swing horns · voice: bumbling British-accented
  male robot · hook: *"Paint the floor and bounce some more."*

### Day 068: Grabber
**Riff on:** #68 *Half-Life 2* · **Rare genre:** gravity-glove physics flinging · **Target:** ~11 min

- **Pitch:** Grab any object in the scene and fling it: saw blades at locks, barrels onto switches, crates up as stairs.
  Work your way through a dystopian city to a rocket.
- **Controls:** Tap an object to grab it, drag to aim, release to throw. Tap again to drop it gently.
- **Run:** 12 scenes (rooftops, canals, a junkyard, the launch site).
- **Win / Lose:** Reach the rocket launch. The 3rd death (a fall or hazard) is the fail state.
- **Secret ★:** Carry the garden gnome from scene 1 all the way into the rocket.
- **Song: "Let It Fly"**: industrial rock · ★found-metal percussion, distorted bass · voice: megaphone-filtered male
  rock · hook: *"Pick it up and let it fly."*

### Day 069: Undersea Pipes
**Riff on:** #69 *BioShock* · **Rare genre:** pipe-flow puzzle (Pipe-Mania-like) · **Target:** ~10 min

- **Pitch:** Hack the machines of a drowned art-deco city by routing the flow through pipe tiles before it reaches an
  open end.
- **Controls:** Tap a tile to rotate it. Drag to swap two tiles. Tap the valve to slow the flow (limited uses).
- **Run:** 15 hacks of growing size and flow speed, adding alarm tiles, one-way tiles and overflow tanks.
- **Win / Lose:** Hack the final vault. The 3rd failed hack (an alarm) is the fail state.
- **Secret ★:** Route the flow through the fish-tank tile and set the fish free.
- **Song: "The Pipes Sing to Me"**: 1950s crooner · ★celesta, radio-filtered string orchestra · voice: warm 1950s
  crooner · hook: *"Under the sea, the pipes sing to me."*

### Day 070: Four Screens
**Riff on:** #70 *GoldenEye 007* · **Rare genre:** split-screen surveillance deduction · **Target:** ~10 min

- **Pitch:** Four split-screen camera feeds follow four agents through a facility. One is a double agent. Watch their
  behaviour and flag the impostor.
- **Controls:** Tap a quadrant to zoom into it. Tap an agent to flag them. Drag the timeline to rewind 10 s (limited).
- **Run:** 6 rounds of about 90 s each, adding more behaviour rules and decoys.
- **Win / Lose:** Catch the double agent in round 6. The 3rd wrong flag is the fail state.
- **Secret ★:** In round 6, one monitor shows the security room you're sitting in. Flag yourself.
- **Song: "Four Screens, One Liar"**: surf spy · ★spring-reverb surf guitar, baritone sax · voice: cool male baritone
  with spoken asides · hook: *"Four screens, one liar."*

### Day 071: Journal of the Lost City
**Riff on:** #71 *Uncharted 2: Among Thieves* · **Rare genre:** journal-clue relic puzzles · **Target:** ~11 min

- **Pitch:** An explorer's journal holds sketches, rubbings and notes. Read them to set statues, dials and mirrors in ruined
  temples.
- **Controls:** Tap or drag mechanisms. Tap the journal and swipe through its pages.
- **Run:** 10 ruins across a mountain path, with clues that build on earlier clues.
- **Win / Lose:** Open the gate of the lost city. Running out of torch fuel (wrong attempts burn extra) is the fail state.
- **Secret ★:** Find the strange little glowing relic hidden in ruin 7.
- **Song: "The Page Knows the Way"**: Himalayan adventure orchestral · ★dungchen horn, singing bowls, strings · voice:
  heroic tenor over a low monk chant · hook: *"The page knows the way."*

### Day 072: Attaché
**Riff on:** #72 *Resident Evil 4 (2005)* · **Rare genre:** inventory-packing puzzle · **Target:** ~10 min

- **Pitch:** A shady merchant's packing service. Fit each client's oddly shaped kit into a case, against the clock.
- **Controls:** Drag items in and tap to rotate. Tap Close the case to submit.
- **Run:** 12 jobs. Cases get oddly shaped, and some items must stay upright or must not touch each other.
- **Win / Lose:** Complete all 12 jobs. The 3rd failed job (time out or a bad pack) is the fail state.
- **Secret ★:** Pack a case perfectly, with zero empty cells.
- **Song: "Make It Fit"**: Spanish gothic · ★flamenco guitar, castanets, cajón · voice: raspy hooded baritone · hook:
  *"Turn it sideways, make it fit."*

### Day 073: Natural Twenty
**Riff on:** #73 *Baldur's Gate 3* · **Rare genre:** dice-check narrative · **Target:** ~12 min

- **Pitch:** A branching adventure story told through skill checks. Choose an approach, stack up modifiers and inspiration,
  then flick a physical d20 to see what happens.
- **Controls:** Tap choices. Flick the die to roll it. Tap an inspiration token to reroll.
- **Run:** 10 scenes of about a minute each. Companions add bonuses, and earlier outcomes reshape later scenes.
- **Win / Lose:** Reach a good ending. Three critical failures lead to the bad ending, which is the fail state.
- **Secret ★:** At camp, tap the coffin to wake its bony caretaker.
- **Song: "Roll the Die"**: Celtic-baroque fantasy · ★hurdy-gurdy, frame drums, choir · voice: bardic tenor with
  choir · hook: *"Roll the die, kiss the sky."*

### Day 074: Payload Pals
**Riff on:** #74 *The Orange Box* · **Rare genre:** lane-push payload escort · **Target:** ~12 min

- **Pitch:** A cartoon team of nine specialists pushes a cart down a track against an AI team. Pick who to deploy, and
  where, to keep the cart rolling.
- **Controls:** Tap a class card, then tap a deploy spot. Energy refills over time.
- **Run:** 3 stages of about 4 min each, with checkpoints along the track.
- **Win / Lose:** Deliver the payload in all 3 stages. Time running out is the fail state.
- **Secret ★:** In stage 2, catch the crate that falls from the sky. Everyone gets a hat.
- **Song: "Push It All the Way"**: 60s spy-jazz · ★Hammond organ with Leslie, walking bass · voice: jazzy male scat
  singer · hook: *"Push it, push it, all the way."*

### Day 075: Fist Ball
**Riff on:** #75 *Tekken 3* · **Rare genre:** volley-ball fighter · **Target:** ~10 min

- **Pitch:** A fighting tournament played over a beach net. Charge the ball with your strikes, and if it hits your opponent
  they take damage.
- **Controls:** Tap the left or right side to step. Swipe up or down for high or low strikes. Hold to charge.
- **Run:** 6 opponents, each with a signature serve.
- **Win / Lose:** Win the final. Losing 2 matches is the fail state.
- **Secret ★:** Tap the bear sitting in the crowd. It joins as a final surprise opponent.
- **Song: "Bump It, Set It, Punch It"**: jungle · ★Reese bass, chopped breakbeats · voice: ragga MC toasting · hook:
  *"Bump it, set it, punch it."*

### Day 076: One Way Mission
**Riff on:** #76 *Mass Effect 2* · **Rare genre:** crew-assignment logic (suicide-mission planner) · **Target:** ~12 min

- **Pitch:** Recruit specialists, earn their loyalty and upgrade the ship. Then assign everyone to the right roles for a
  mission where every choice decides who comes home.
- **Controls:** Drag crew into role slots. Tap planets to send probes for resources. Tap dialogue choices.
- **Run:** 6 recruit and loyalty vignettes, scanning for upgrades, then a 6-stage final mission that plays out from your
  assignments.
- **Win / Lose:** The commander survives along with at least 6 of the 8 crew. The commander dying is the fail state.
- **Secret ★:** Feed the fish in your cabin before launching the mission.
- **Song: "Bring Them Home"**: Vangelis-style synth opera · ★CS-80-style brass synth, arpeggiators · voice: soaring
  female · hook: *"Bring them home, every one."*

### Day 077: The Mansion of Doors
**Riff on:** #77 *The House in Fata Morgana* · **Rare genre:** branching gothic visual novel · **Target:** ~13 min

- **Pitch:** A maid guides a ghost through four doors into four eras of one mansion's tragedies. Piece the truth together
  and choose who to forgive.
- **Controls:** Tap to advance and tap choices. Drag the memory timeline to revisit a scene.
- **Run:** 4 short tales of about 2.5 min each, then a finale where your earlier choices act as keys.
- **Win / Lose:** Reach the true ending and set the ghost free. A bad ending is the fail state, and the choice timeline
  makes retrying quick.
- **Secret ★:** At the very last choice, stay silent: tap nothing for 30 seconds. A hidden epilogue plays.
- **Song: "Remember Me More"**: gothic chamber · ★theorbo, chamber strings, low recorder · voice: haunting gothic
  mezzo · hook: *"Open the door, remember me more."*

### Day 078: Ground Messages
**Riff on:** #78 *Elden Ring* · **Rare genre:** message-trust deduction · **Target:** ~11 min

- **Pitch:** Phantom travellers have scrawled messages on the ground across a dark land, and some of them lie. Use ratings,
  handwriting and context to decide which ones to trust before you jump, attack or walk on.
- **Controls:** Tap a message to read it. Tap a path or action to commit. Tap a message's rating to see who appraised it.
- **Run:** 8 regions, each with branching paths and a guardian at the end.
- **Win / Lose:** Reach the great tree's summit. The 5th fall or death is the fail state.
- **Secret ★:** In the first region, one riddle message points to a spot. Stand there and use the "rest" gesture, and a
  spectral steed appears.
- **Song: "Trust No Sound"**: grand dark orchestral · ★concert harp, low choir, strings · voice: female choir · hook:
  *"Read the ground, trust no sound."*

### Day 079: Words of Power
**Riff on:** #79 *The Elder Scrolls V: Skyrim* · **Rare genre:** constructed-language deciphering · **Target:** ~12 min

- **Pitch:** Learn a dragon tongue from context: wall carvings, tavern songs and what the villagers say. Then speak whole
  phrases to calm dragons instead of fighting them.
- **Controls:** Tap glyph-words to build a phrase. Drag words into your translation journal to annotate them.
- **Run:** 6 dragon encounters or word walls. Each one adds grammar (plurals, verbs, negation).
- **Win / Lose:** Speak the calming word to the elder dragon. The 3rd wrong shout during an encounter is the fail state.
- **Secret ★:** Take the sweetroll from the inn table 3 times.
- **Song: "The Sky Will Hear"**: epic Nordic chant · ★lur horns, tagelharpa (bowed lyre), war drums · voice: huge male
  choir · hook: *"Speak the word and the sky will hear."*

### Day 080: Cascade Control
**Riff on:** #80 *Half-Life* · **Rare genre:** control-room instrument sim · **Target:** ~12 min

- **Pitch:** You run an underground lab's control room. Calibrate the test beam, then keep the facility standing when
  the experiment cascades, and get everyone out on the trams.
- **Controls:** Drag sliders and dials, tap switches, drag tram tokens along the rail map.
- **Run:** 3 phases: calibration (3 min), cascade containment (5 min), evacuation routing (4 min).
- **Win / Lose:** Evacuate at least 20 scientists. The core melting down is the fail state.
- **Secret ★:** Find the microwave in the break-room panel and heat the casserole until it pops.
- **Song: "All Systems Nominal"**: 90s industrial techno · ★TR-909-style kit, metallic FM stabs · voice: band-limited
  female PA announcer, singing · hook: *"All systems nominal… until they're not."*

### Day 081: Rewind Rock
**Riff on:** #81 *The Legend of Zelda: Tears of the Kingdom* · **Rare genre:** object time-reversal puzzle · **Target:** ~11 min

- **Pitch:** Select an object and send it backwards along its own history: falling rocks rise again as platforms, and
  thrown logs fly back as bridges.
- **Controls:** Tap an object to rewind it and tap again to freeze it. Tap a ceiling to rise up through it.
- **Run:** 14 chambers that combine rewind with ascending through ceilings and moving water.
- **Win / Lose:** Complete the final chamber. Running out of rewind energy (one shared pool) is the fail state.
- **Secret ★:** Rewind a fallen apple back up onto its tree.
- **Song: "Retrace the Track"**: lush orchestral · ★erhu, string orchestra, piano arpeggios · voice: wise
  old woman (alto) · hook: *"Turn it back, retrace the track."*

### Day 082: Baton Sails
**Riff on:** #82 *The Legend of Zelda: The Wind Waker* · **Rare genre:** wind-conducting sailing · **Target:** ~12 min

- **Pitch:** Sail an open sea by conducting the wind. Trace the conducting pattern in time with the metronome and the wind
  turns to the direction you chose.
- **Controls:** Draw the 3-beat baton pattern on the beat, then tap the compass direction. Drag the tiller.
- **Run:** A voyage through 7 islands (each with a short errand), with storms, whirlpools and rocks.
- **Win / Lose:** Find the hidden island. The hull reaching 0 is the fail state.
- **Secret ★:** Tap the little floating man with a balloon who drifts across the sky.
- **Song: "Wave the Wind"**: sea shanty · ★concertina, fiddle, tin whistle · voice: pirate-crew shanty
  (call-and-response) · hook: *"Wave the wind, the sea will spin."*

### Day 083: Slot Car Stadium
**Riff on:** #83 *Gran Turismo* · **Rare genre:** slot-car racing (one-button throttle) · **Target:** ~10 min

- **Pitch:** A tabletop slot-car cup. The only control is the throttle: push too hard into a corner and you fly off the
  slot.
- **Controls:** Hold anywhere to accelerate and release to coast or brake. Between races, tap to tune the motor, tyres
  and magnet.
- **Run:** A 5-race cup on tracks laid around a garage (hairpins, a figure-eight crossover, a banked loop).
- **Win / Lose:** Win the cup on points. Losing the cup is the fail state.
- **Secret ★:** Fly off the hairpin on purpose and land in the trophy cup on the shelf.
- **Song: "Figure Eight"**: 60s sunshine pop · ★electric sitar, surf drums, organ · voice: surf-pop harmony group ·
  hook: *"Round and round on the figure eight."*

### Day 084: Coolant
**Riff on:** #84 *Metal Gear Solid 2: Sons of Liberty* · **Rare genre:** bomb-disposal search · **Target:** ~12 min

- **Pitch:** Bombs are hidden across an offshore plant's struts. Sweep rooms with a sensor, avoid patrols, and freeze each
  charge with coolant spray before the timer runs out.
- **Controls:** Tap a room to move. Drag the sensor wand. Hold to spray, keeping the spray inside the freeze ring.
- **Run:** 2 struts with 12 bombs, under one global timer and guard patrols.
- **Win / Lose:** Freeze every bomb. The timer running out, or being spotted 3 times, is the fail state.
- **Secret ★:** Tap the seagull perched on the strut rail 5 times. It drops a dog tag.
- **Song: "Freeze It Fast"**: espionage electronica · ★bass clarinet, orchestral hits, breakbeat · voice: radio-filtered
  male/female "codec" duet · hook: *"Freeze it fast before it's gone."*

### Day 085: Twin City Drive
**Riff on:** #85 *Grand Theft Auto Double Pack* · **Rare genre:** dual-lane split-attention driving · **Target:** ~10 min

- **Pitch:** Two getaway cars in two cities at once. The left half of the screen drives one, the right half drives the
  other.
- **Controls:** Tap the left half to switch the left car's lane, and the right half for the right car. Taps are discrete,
  so a mouse can alternate quickly. There's no need for two touches at once.
- **Run:** 10 stages of about 60 s each. Traffic gets denser, police spikes appear, and the two cities swap sides.
- **Win / Lose:** Finish stage 10. The 3rd crash is the fail state.
- **Secret ★:** Collect the hidden packages in both cities within the same second.
- **Song: "Two Cities"**: tango noir · ★bandoneón, double bass, tango piano · voice: tango duet, male and female (one
  voice per city) · hook: *"Two cities, one night, no lights."*

### Day 086: Starbit Slingshot
**Riff on:** #86 *Super Mario Galaxy* · **Rare genre:** orbital gravity slingshot · **Target:** ~11 min

- **Pitch:** Launch a little star-child between planetoids. Gravity bends every path. Collect star bits and reach the
  goal in each tiny galaxy.
- **Controls:** Drag back and release to launch. Tap during flight for one small boost.
- **Run:** 20 tiny galaxies with black holes, moving moons and twin-planet figure-eights.
- **Win / Lose:** Reach the observatory. Losing 5 lives (drifting into the void) is the fail state.
- **Secret ★:** Orbit one planet 7 times without landing.
- **Song: "Fall Around"**: orchestral waltz · ★glass harmonica, waltz strings · voice: storybook-lullaby female · hook:
  *"Fall around, never down."*

### Day 087: Three-Way Heist
**Riff on:** #87 *Grand Theft Auto V* · **Rare genre:** simultaneous-plan heist (plan, then execute) · **Target:** ~12 min

- **Pitch:** Plan a heist for three crew members on a shared timeline, then press Go and watch your plan play out. It's
  non-violent: these are cartoon capers.
- **Controls:** Drag waypoints and action icons onto each crew member's timeline lane. Tap Go, tap Rewind.
- **Run:** 5 heists (a jewellery store, a museum diamond, an armoured van, a yacht party, a gold vault).
- **Win / Lose:** Pull off heist 5. Tripping the alarm 3 times is the fail state.
- **Secret ★:** Make all three crew members do the "stretch" action at the same moment.
- **Song: "Three Ways In"**: trap · ★808 glide sub-bass, trap hats, orchestral tension · voice: auto-tuned
  rapper-singer · hook: *"Three ways in, one way out."*

### Day 088: Updraft
**Riff on:** #88 *The Legend of Zelda: Breath of the Wild* · **Rare genre:** thermal-soaring glider · **Target:** ~11 min

- **Pitch:** Fly a paraglider across a vast land by riding thermals, cliff lift and campfire updrafts while your stamina
  holds.
- **Controls:** Drag to steer. Hold to dive. Tap to open or close the glider.
- **Run:** 8 regions of about 80 s each, with rain, wind shear and towers to reach.
- **Win / Lose:** Reach the summit tower. The 3rd crash landing is the fail state.
- **Secret ★:** Land on the lone rock on the plateau. A seed sprite pops out: "Hee-hoo!"
- **Song: "Where the Warm Winds Go"**: ambient pastoral · ★alto flute, soft pads, sparse piano · voice: breathy soft
  male · hook: *"Lift me where the warm winds go."*

### Day 089: Endless Manual
**Riff on:** #89 *Tony Hawk's Pro Skater 3* · **Rare genre:** balance-meter endurance (manual combos) · **Target:** ~10 min

- **Pitch:** Hold a manual across whole city lines. Balance the board, then ollie and kickflip between obstacles to keep
  one huge combo alive.
- **Controls:** Drag left and right to counter-balance. Tap to ollie, swipe to flip.
- **Run:** 6 city runs of about 90 s each, with target combo scores.
- **Win / Lose:** Hit all 6 targets. The 5th bail is the fail state.
- **Secret ★:** In the Tokyo run, ollie onto the roof of the moving bus.
- **Song: "Keep the Nose Up"**: ska punk · ★ska trombone skank, upstroke guitar · voice: ska-punk male · hook: *"Keep
  the nose up, keep it rolling."*

### Day 090: Sim Trainer
**Riff on:** #90 *Perfect Dark* · **Rare genre:** behaviour-programming auto-arena · **Target:** ~11 min

- **Pitch:** Program your training bots with if-then rule cards ("If ally hurt → heal", "If enemy near → shield"), then
  watch them fight arena simulations.
- **Controls:** Drag rule cards into a bot's slots and reorder them. Tap Run, tap Pause.
- **Run:** 10 arena challenges, adding new rules and enemy behaviours.
- **Win / Lose:** Beat the elite sims. Losing 3 challenges is the fail state.
- **Secret ★:** In arena 7, program a bot to guard the caged little alien.
- **Song: "If-Then Heart"**: electro-industrial spy · ★Stylophone, electro beat · voice: cool breathy female, slightly
  robotic · hook: *"If you see me, then defend."*

### Day 091: Camp Ledger
**Riff on:** #91 *Red Dead Redemption 2* · **Rare genre:** outlaw camp management · **Target:** ~11 min

- **Pitch:** Keep a frontier camp fed, rested and hopeful while the law closes in. Assign chores, settle disputes, and
  decide when to move.
- **Controls:** Drag campmates onto task posts. Tap events to resolve them. Short hunting and fishing mini-games use
  drag and tap.
- **Run:** 10 days of about 1 min each.
- **Win / Lose:** Move the camp on with morale above 50%. Morale hitting 0, or a raid, is the fail state.
- **Secret ★:** Pet the camp dog three days in a row.
- **Song: "One More Night"**: Americana gospel · ★harmonium (pump organ), campfire guitars, stomps and claps · voice:
  soul-gospel male lead with campfire group · hook: *"Keep the fire burning one more night."*

### Day 092: Logbook
**Riff on:** #92 *Metroid Prime* · **Rare genre:** taxonomy identification (dichotomous key) · **Target:** ~11 min

- **Pitch:** Scan alien creatures and classify them with a dichotomous field key ("has radial symmetry? → …"). Each correct
  entry unlocks the way forward.
- **Controls:** Hold to scan with the reticle. Tap traits in the key.
- **Run:** 5 biomes × 5 creatures, including mimics, larval forms and convergent look-alikes.
- **Win / Lose:** Fill in enough of the logbook to open the impact crater. The 5th misclassification is the fail state.
- **Secret ★:** Scan your own reflection in a puddle.
- **Song: "Name the Unknown"**: ambient space synth · ★Solina-style string machine, sonar pings · voice: distant
  whispering female · hook: *"Name the unknown, and it's never alone."*

### Day 093: Dispatch 5
**Riff on:** #93 *Grand Theft Auto III* · **Rare genre:** taxi fleet dispatch · **Target:** ~12 min

- **Pitch:** You're the night dispatcher for five cabs in a rough city. Match fares to cabs, reroute around incidents,
  and keep the meters running.
- **Controls:** Tap a fare, then a cab. Drag a route to override. Tap an incident to see detours.
- **Run:** One night shift, about 12 min, getting busier until bar closing time.
- **Win / Lose:** Hit the revenue target by dawn. The 5th customer walk-out is the fail state.
- **Secret ★:** Send a cab for the silent man in the leather jacket standing on a corner. He tips without a word.
- **Song: "Meter's Running"**: grunge · ★grunge-distorted guitar, sludgy drums · voice: raspy grunge male · hook:
  *"Meter's running, city's humming."*

### Day 094: Hat Trick
**Riff on:** #94 *Super Mario Odyssey* · **Rare genre:** possession puzzle · **Target:** ~11 min

- **Pitch:** Throw your living hat to possess creatures and objects, borrowing their abilities to solve each kingdom's
  puzzles.
- **Controls:** Drag and release to throw the hat. Tap to leave a creature. Each creature adds its own tap or drag ability.
- **Run:** 6 kingdoms × 2 puzzles, with moons hidden in each.
- **Win / Lose:** Collect 10 moons. Losing 5 lives is the fail state.
- **Secret ★:** In the final kingdom, throw your hat onto the moon in the sky.
- **Song: "Throw Your Hat into the Sky"**: big-band swing · ★bright trumpet section, sax soli, swing kit · voice: Broadway
  belter female · hook: *"Throw your hat into the sky."*

### Day 095: Ring Cartographer
**Riff on:** #95 *Halo: Combat Evolved* · **Rare genre:** exploration cartography (draw your own map) · **Target:** ~12 min

- **Pitch:** You're stranded on a ring-shaped world. Explore under fog of war and draw the map yourself, then use it to
  deduce where the control room must be.
- **Controls:** Tap to move (pathfinding). Switch to map mode and drag to draw walls and paths.
- **Run:** 4 sectors with sentinels to avoid and terminals that give you partial data.
- **Win / Lose:** Find and activate the control room. The 3rd death is the fail state.
- **Secret ★:** Hand in a map that is at least 95% accurate.
- **Song: "Chart the Sky"**: chant and percussion · ★congas, Gregorian-style chant, strings · voice: monk choir ·
  hook: *"Walk the ring, chart the sky."*

### Day 096: Booth Call
**Riff on:** #96 *NFL 2K1* · **Rare genre:** live sports-commentary sim · **Target:** ~12 min

- **Pitch:** You're in the broadcast booth. Call the plays as they happen, drop in stats and cue replays, all while
  keeping the broadcast rating up.
- **Controls:** Tap phrase cards at the right moment. Drag graphics onto the screen. Tap the replay angle.
- **Run:** A 4-quarter broadcast of about 12 min, adding a sponsor read, a weather delay and an overtime twist.
- **Win / Lose:** Hit the rating target. The 3rd on-air gaffe is the fail state.
- **Secret ★:** Tap the blimp when it floats into shot.
- **Song: "And the Crowd Goes Wild"**: sports-broadcast funk · ★timpani, brass fanfare, funk rhythm section · voice: two
  "announcers" singing a duet · hook: *"And the crowd goes wild."*

### Day 097: Soulforge
**Riff on:** #97 *SoulCalibur* · **Rare genre:** blacksmith forging (rhythm crafting) · **Target:** ~11 min

- **Pitch:** Forge legendary weapons for eight warriors. Heat the metal, hammer it to the rhythm, fold it, quench it, then
  watch a short duel that tests your work.
- **Controls:** Drag the bellows, tap the hammer in rhythm, swipe to quench, drag to fold.
- **Run:** 8 commissions, each with its own metal and shape.
- **Win / Lose:** Forge the legendary blade. The 3rd cracked weapon is the fail state.
- **Secret ★:** Forge a weapon from the spoon in the scrap pile.
- **Song: "Strike the Steel"**: epic forge orchestral · ★tuned anvils, orchestra, low choir · voice: heroic operatic
  tenor · hook: *"Strike the steel, the soul will heal."*

### Day 098: Tongue Swing
**Riff on:** #98 *Super Mario Galaxy 2* · **Rare genre:** grapple-swing platformer · **Target:** ~10 min

- **Pitch:** A friendly dinosaur swings through starry levels by latching its tongue onto flower posts. Momentum is
  everything.
- **Controls:** Tap a flower post to latch on, then release to fling yourself. Tap a fruit to eat it.
- **Run:** 15 levels around a planet-shaped starship hub.
- **Win / Lose:** Reach the final comet. Losing 5 lives is the fail state.
- **Secret ★:** In the hub, latch your tongue onto the ship's captain.
- **Song: "Swing, Fling"**: calypso · ★steel pan, bongos, marimba · voice: cheerful falsetto male · hook: *"Swing,
  fling, everything."*

### Day 099: Strike It Up
**Riff on:** #99 *Grand Theft Auto IV* · **Rare genre:** bowling (relationship comedy) · **Target:** ~9 min

- **Pitch:** Your over-eager cousin keeps phoning to invite you bowling. Tonight you finally go. Beat him over ten frames
  while he talks all the way through.
- **Controls:** Drag to position. Swipe to roll, with the curve of the swipe setting the hook. Tap the phone to answer
  his banter calls.
- **Run:** One 10-frame game against the cousin, with lane oil that changes per frame and comedic interruptions.
- **Win / Lose:** Beat your cousin's score. Losing is the fail state.
- **Secret ★:** Bowl into the *neighbouring* lane and get a strike there.
- **Song: "Strike It Up"**: Balkan party brass · ★flugelhorn-led Balkan brass band, tapan drum · voice: wobbly
  enthusiastic cousin tenor · hook: *"Strike it up, cousin, strike it up."*

### Day 100: The Hundredth Song
**Riff on:** #100 *The Legend of Zelda: Ocarina of Time* · **Rare genre:** ocarina song-casting adventure · **Target:** ~14 min

- **Pitch:** The finale. Learn songs by ear on a five-hole ocarina and play them to change time, weather and the world.
  The last temple is a medley of motifs from all 99 earlier songs.
- **Controls:** Five large note buttons. Tap a melody to play it. Drag the time-of-day dial.
- **Run:** 7 temples. Each one teaches a song by echo, then asks you to use it on the world. The final duet is the medley.
- **Win / Lose:** Play the grand song in the Temple of Days. Each temple gives 3 hearts, and losing all 3 in any temple
  is the fail state.
- **Secret ★:** Play the calendar's own theme ("One More Door") on the ocarina. All 100 doors light up in a secret credits
  roll.
- **Song: "One Hundred Doors"**: grand finale · ★ocarina, full orchestra, quoting a motif from each earlier day · voice:
  full SATB choir with cameo lines from earlier voice personas · hook: *"One hundred doors, one hundred songs."*
