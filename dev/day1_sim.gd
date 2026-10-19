extends Node
## Tuning harness for Day 1: plays whole runs headlessly with the autopilot at several skill
## levels and prints bout results, ring-out causes and run lengths.
## Run: godot --headless --path . res://dev/day1_sim.tscn -- [runs] [skill,skill,...]

const SCENE := "res://days/day_001/game.tscn"
const DT := 1.0 / 60.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 6
	var skills: Array[float] = [0.45, 0.7, 0.9]
	if args.size() > 1:
		skills.clear()
		for s in args[1].split(","):
			skills.append(float(s))
	for skill in skills:
		var wins := 0
		var minutes: Array[float] = []
		for r in runs:
			var result := _run(skill, 1000 + r)
			wins += 1 if result["won"] else 0
			minutes.append(result["minutes"])
			print(
				(
					"skill %.2f seed %d: %s in %.1f min | %s"
					% [skill, 1000 + r, "WIN " if result["won"] else "LOSS", result["minutes"], result["log"]]
				)
			)
		minutes.sort()
		print(
			(
				"== skill %.2f: %d/%d wins, median %.1f min, range %.1f–%.1f\n"
				% [skill, wins, runs, minutes[runs / 2], minutes[0], minutes[-1]]
			)
		)
	get_tree().quit()


func _run(skill: float, seed_value: int) -> Dictionary:
	var info := DayRegistry.info(1)
	var outcome := {"done": false, "won": false}
	var ctx := DayContext.new(1, info, seed_value, func(_at: Vector2) -> void: pass, func(_d: Dictionary) -> void: pass)
	var hud := Hud.new()
	add_child(hud)
	ctx.hud = hud
	ctx.audio = Audio
	ctx.settings = Settings
	var game := (load(SCENE) as PackedScene).instantiate() as DayGame
	game.ctx = ctx
	game.finished.connect(
		func(r: DayResult) -> void:
			outcome["done"] = true
			outcome["won"] = r.is_success()
	)
	add_child(game)
	game.autoplay_skill = skill
	game._day_start()
	var t := 0.0
	var log := PackedStringArray()
	var last_bout: Node2D = null
	while not outcome["done"] and t < 30.0 * 60.0:
		if game.bout != last_bout:
			if last_bout != null:
				log.append(_summary(last_bout))
			last_bout = game.bout
		game.juice._process(DT)
		game._process(DT)
		t += DT
	if last_bout != null and is_instance_valid(last_bout):
		log.append(_summary(last_bout))
	game.queue_free()
	hud.queue_free()
	return {"won": outcome["won"], "minutes": t / 60.0, "log": " ".join(log)}


func _summary(bout: Node2D) -> String:
	var mine := 0
	var self_out := 0
	for f: Dictionary in bout.fall_log:
		if f["kind"] == &"knight":
			mine += 1
		if f["by"] == &"":
			self_out += 1
	var won: bool = bout.player.state != 3
	var dmg := PackedStringArray()
	for f: Dictionary in bout.fall_log:
		dmg.append("%s%d%s" % [String(f["kind"]).substr(0, 2), roundi(f["damage"]), "" if f["by"] != &"" else "!"])
	return (
		"[B%d %s %.0fs P-out:%d self:%d/%d %s]"
		% [bout.index + 1, "W" if won else "L", bout.time, mine, self_out, bout.fall_log.size(), ",".join(dmg)]
	)
