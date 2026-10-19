extends DayGame
## Day 1, Toybox Ring-Out: a five-bout flick-physics sumo tournament (docs/GAMES.md, Day 001).
## Drag back from anywhere and release to flick the tin knight; ring everyone else out.
## Losing a bout costs a spare key and restarts it; losing the last key fails the run.

const Bout := preload("res://days/day_001/parts/bout.gd")
const Arena := preload("res://days/day_001/parts/arena.gd")
const Brain := preload("res://days/day_001/parts/brain.gd")
const START_KEYS := 3
const INTRO_TIME := 3.4
const OVER_TIME := 2.8
const SUBSTEPS := 2

var bout_index := 0
var keys := START_KEYS
var bout: Node2D
var camera: Camera2D
var juice: Juice
var flow := StateMachine.new()
## >= 0: the player's toy is driven by the AI at this skill (tests and tuning).
var autoplay_skill := -1.0

var _banner: Label
var _sub_banner: Label
var _dragging := false
var _drag_start := Vector2.ZERO
var _countdown := -1
var _star_given := false
var _won := false


func _day_start() -> void:
	_setup()
	_start_bout(0)


func _day_restore(data: Dictionary) -> void:
	_setup()
	keys = int(data.get("keys", START_KEYS))
	_start_bout(int(data.get("bout", 0)))


func _setup() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(0, -24)
	add_child(camera)
	camera.make_current()
	juice = Juice.new(camera)
	add_child(juice)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_banner = _make_banner(64, Pal.GOLD)
	_sub_banner = _make_banner(30, Pal.SNOW)
	layer.add_child(_banner)
	layer.add_child(_sub_banner)
	flow.add(&"intro", _intro_update, _intro_enter)
	flow.add(&"fight", _fight_update, _fight_enter)
	flow.add(&"over", _over_update, _over_enter)
	flow.add(&"done", func(_dt: float) -> void: pass)
	ctx.input.pressed.connect(_on_pressed)
	ctx.input.dragged.connect(_on_dragged)
	ctx.input.released.connect(_on_released)
	ctx.audio.beat.connect(_on_beat)


func _make_banner(size: int, color: Color) -> Label:
	var l := UiTheme.label("", size, color, 600)
	l.add_theme_color_override("font_outline_color", Pal.INK)
	l.add_theme_constant_override("outline_size", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	flow.update(delta)
	_layout_banners()


func _start_bout(index: int) -> void:
	bout_index = index
	if bout != null:
		bout.queue_free()
	bout = Bout.new()
	bout.setup(index, ctx.rng)
	add_child(bout)
	move_child(bout, 0)
	bout.ended.connect(_on_bout_ended)
	bout.sound.connect(func(sfx: StringName, opts: Dictionary) -> void: ctx.audio.play_sfx(sfx, opts))
	bout.impact.connect(_on_impact)
	bout.toy_fell.connect(_on_toy_fell)
	bout.referee_fell.connect(_on_referee_fell)
	if autoplay_skill >= 0.0:
		bout.autopilot = Brain.new().autopilot(autoplay_skill)
	_dragging = false
	checkpoint({"bout": index, "keys": keys})
	_update_hud()
	flow.go(&"intro")


func _update_hud() -> void:
	ctx.hud.set_lives(keys, START_KEYS)
	ctx.hud.set_score("Bout %d/%d" % [bout_index + 1, Arena.COUNT])
	ctx.hud.set_label("Overtime!" if bout != null and bout.overtime else Arena.TITLES[bout_index])


# --- Flow ---------------------------------------------------------------------------------


func _intro_enter() -> void:
	_countdown = -1
	_banner.text = "Bout %d · %s" % [bout_index + 1, Arena.TITLES[bout_index]]
	_sub_banner.text = "Tin Knight vs %s" % bout.rival_names()
	_banner.visible = true
	_sub_banner.visible = true


func _intro_update(dt: float) -> void:
	bout.animate(dt)
	var step := int((flow.time - 1.0) / 0.6)
	if flow.time >= 1.0 and step != _countdown and step < 3:
		_countdown = step
		_banner.text = str(3 - step)
		ctx.audio.play_sfx(&"countdown")
	if flow.time >= INTRO_TIME or App.test_mode and flow.time >= 0.2:
		flow.go(&"fight")


func _fight_enter() -> void:
	_banner.text = "GO!"
	_sub_banner.text = ""
	ctx.audio.play_sfx(&"go")
	ctx.audio.play_sfx(&"whistle", {"volume_db": -4.0})
	bout.running = true
	get_tree().create_timer(0.7, false).timeout.connect(
		func() -> void:
			if flow.is_in(&"fight"):
				_banner.visible = false
	)


func _fight_update(dt: float) -> void:
	if juice.is_frozen():
		bout.animate(0.0)
		return
	for i in SUBSTEPS:
		bout.step(dt / SUBSTEPS)
	if bout.overtime and Engine.get_process_frames() % 30 == 0:
		_update_hud()


func _over_enter() -> void:
	_dragging = false
	_banner.visible = true
	_sub_banner.visible = true
	if _won:
		_banner.text = "Bout won!" if bout_index < Arena.COUNT - 1 else "Champion!"
		_sub_banner.text = "" if bout_index < Arena.COUNT - 1 else "The crown is yours."
		ctx.audio.play_sfx(&"bout_win")
		juice.burst(bout.player.position + Vector2(0, -20))
	else:
		_banner.text = "Rung out!"
		var left := keys - 1
		_sub_banner.text = "Out of spare keys." if left <= 0 else "−1 spare key · %d left" % left
		ctx.audio.play_sfx(&"bout_lose")


func _over_update(dt: float) -> void:
	bout.animate(dt)
	if flow.time < OVER_TIME and not App.test_mode:
		return
	if flow.time < 0.2:
		return
	if _won:
		if bout_index >= Arena.COUNT - 1:
			flow.go(&"done")
			succeed({"keys": keys})
		else:
			_start_bout(bout_index + 1)
	else:
		keys -= 1
		_update_hud()
		if keys <= 0:
			flow.go(&"done")
			fail(&"keys", "You ran out of spare keys. The champion keeps the crown.")
		else:
			_start_bout(bout_index)


func _on_beat(_index: int) -> void:
	if bout != null:
		bout.on_beat()


func _on_bout_ended(player_won: bool) -> void:
	_won = player_won
	flow.go(&"over")


# --- Input --------------------------------------------------------------------------------


func _on_pressed(pos: Vector2) -> void:
	if autoplay_skill >= 0.0 or not flow.is_in(&"fight") or not bout.player.is_active():
		return
	_dragging = true
	_drag_start = pos


func _on_dragged(pos: Vector2, _relative: Vector2) -> void:
	if _dragging:
		bout.aim_player(_drag_start - pos)


func _on_released(pos: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	if flow.is_in(&"fight"):
		bout.release_player(_drag_start - pos)


# --- Feedback -----------------------------------------------------------------------------


func _on_impact(strength: float, _at: Vector2, player_involved: bool) -> void:
	if strength > 700.0:
		juice.hitstop(0.05)
		juice.shake(minf(12.0, strength / 90.0), 0.2)
	if player_involved and strength > 300.0:
		ctx.haptic(15)


func _on_toy_fell(toy: Node2D) -> void:
	juice.shake(10.0, 0.3)
	if toy.is_referee:
		return
	juice.popup("Ring out!", toy.position + Vector2(0, -50), Pal.GOLD, 34)
	if toy.is_player:
		ctx.haptic(60)


## The secret: ringing the referee out in the final bout.
func _on_referee_fell(at: Vector2) -> void:
	if _star_given:
		return
	_star_given = true
	ctx.award_star(bout.get_global_transform_with_canvas() * at)


func _layout_banners() -> void:
	var view := App.visible_size()
	for l: Label in [_banner, _sub_banner]:
		l.reset_size()
	_banner.position = Vector2((view.x - _banner.size.x) * 0.5, view.y * 0.36 - _banner.size.y * 0.5)
	_sub_banner.position = Vector2((view.x - _sub_banner.size.x) * 0.5, _banner.position.y + _banner.size.y + 6)


# --- QA hooks -----------------------------------------------------------------------------


func _qa_force(outcome: StringName) -> void:
	if outcome == &"star":
		# Real trigger: a full-power knock sends the referee over the edge in the final bout,
		# and the ring-out rules notice.
		if bout_index != Arena.COUNT - 1:
			_start_bout(Arena.COUNT - 1)
		flow.go(&"fight")
		var edge_x: float = bout.arena.half_extents.x - 10.0
		bout.referee.body.pos = Vector2(edge_x, 0.0)
		bout.referee.body.vel = Vector2(900.0, 0.0)
		return
	super(outcome)


func _qa_jump(index: int) -> bool:
	_start_bout(clampi(index, 0, Arena.COUNT - 1))
	return true


func _qa_autoplay(enabled: bool) -> bool:
	autoplay_skill = 0.85 if enabled else -1.0
	if bout != null:
		bout.autopilot = Brain.new().autopilot(autoplay_skill) if enabled else null
	return true
