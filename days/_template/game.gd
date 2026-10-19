extends DayGame
## Day NNN, <Title>: <one-line pitch> (docs/GAMES.md, Day NNN).
## Copy this folder to days/day_NNN/, rename the scene's root node and replace every
## TEMPLATE comment. Day scripts never declare `class_name`: preload siblings instead,
## e.g. `const Level := preload("res://days/day_NNN/parts/level.gd")`.

const PHASES := 3
## TEMPLATE: the fail resource (lives, time, ink, keys...).
const START_LIVES := 3

var phase := 0
var lives := START_LIVES
var camera: Camera2D
var juice: Juice
var flow := StateMachine.new()
## >= 0 when an AI plays the player's side (tests and tuning).
var autoplay_skill := -1.0


func _day_start() -> void:
	_setup()
	_start_phase(0)


func _day_restore(data: Dictionary) -> void:
	_setup()
	lives = int(data.get("lives", START_LIVES))
	_start_phase(int(data.get("phase", 0)))


func _setup() -> void:
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	juice = Juice.new(camera)
	add_child(juice)
	flow.add(&"intro", _intro_update)
	flow.add(&"play", _play_update)
	flow.add(&"done", func(_dt: float) -> void: pass)
	ctx.input.tapped.connect(_on_tapped)
	ctx.audio.beat.connect(_on_beat)


func _process(delta: float) -> void:
	flow.update(delta)


func _start_phase(index: int) -> void:
	phase = index
	checkpoint({"phase": phase, "lives": lives})
	ctx.hud.set_lives(lives, START_LIVES)
	ctx.hud.set_score("%d/%d" % [phase + 1, PHASES])
	flow.go(&"intro")


func _intro_update(_dt: float) -> void:
	if flow.time > 2.0 or App.test_mode:
		flow.go(&"play")


func _play_update(_dt: float) -> void:
	# TEMPLATE: simulate the phase; call _phase_cleared() / _lose_life() from the rules.
	pass


func _phase_cleared() -> void:
	if phase >= PHASES - 1:
		flow.go(&"done")
		succeed({"lives": lives})
	else:
		_start_phase(phase + 1)


func _lose_life() -> void:
	lives -= 1
	ctx.hud.set_lives(lives, START_LIVES)
	if lives <= 0:
		flow.go(&"done")
		fail(&"lives", "TEMPLATE: say why the run ended, kindly.")


func _on_tapped(_pos: Vector2) -> void:
	pass


func _on_beat(_index: int) -> void:
	pass


func _qa_force(outcome: StringName) -> void:
	if outcome == &"star":
		# TEMPLATE: perform the REAL secret trigger here (see days/day_001/game.gd).
		ctx.award_star()
		return
	super(outcome)


func _qa_jump(index: int) -> bool:
	_start_phase(clampi(index, 0, PHASES - 1))
	return true


func _qa_autoplay(_enabled: bool) -> bool:
	# TEMPLATE: let an AI play the player's side and return true (the scripted win bot).
	return false
