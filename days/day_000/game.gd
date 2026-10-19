extends DayGame
## Day 0 "Test Room": a debug-only fixture that exercises the whole day contract
## (gestures, HUD, checkpoint, success, fail, star). Excluded from release builds.

const TIME_LIMIT := 120.0
const TASKS := [
	"Tap the bubble 3 times",
	"Drag the box into the slot",
	"Swipe the way the arrow points",
	"Hold the button until it fills",
	"Zoom in, then tap the tiny word",
]

const HOLD_CENTER := Vector2(1020, 300)
const NOTE_POS := Vector2(760, 200)
const MOON := Vector2(1190, 110)
const TRAP := Vector2(180, 620)

var done: Array[bool] = [false, false, false, false, false]
var lives := 3
var time_left := TIME_LIMIT
var bubble := Vector2(600, 260)
var bubble_taps := 0
var box := Vector2(560, 560)
var slot := Vector2(980, 560)
var dragging_box := false
var arrow_dir := Vector2.RIGHT
var hold_fill := 0.0
var holding := false
var zoom := 1.0
var moon_taps := 0
var _font: Font


func _day_start() -> void:
	_setup()


func _day_restore(data: Dictionary) -> void:
	_setup()
	var saved: Array = data.get("done", [])
	for i in mini(saved.size(), done.size()):
		done[i] = bool(saved[i])
	time_left = float(data.get("time_left", TIME_LIMIT))
	_update_hud()


func _setup() -> void:
	_font = UiTheme.font(600)
	arrow_dir = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][ctx.rng.randi() % 4]
	ctx.input.tapped.connect(_on_tap)
	ctx.input.pressed.connect(_on_press)
	ctx.input.released.connect(_on_release)
	ctx.input.dragged.connect(_on_drag)
	ctx.input.swiped.connect(_on_swipe)
	ctx.input.pinched.connect(func(f: float, _c: Vector2) -> void: _zoom_by(f))
	var layer := CanvasLayer.new()
	add_child(layer)
	var row := HBoxContainer.new()
	row.position = Vector2(560, 380)
	row.add_theme_constant_override("separation", 12)
	for spec: Array in [["-", 1.0 / 1.25], ["+", 1.25]]:
		var b := UiTheme.button(spec[0], 72.0)
		var f: float = spec[1]
		b.pressed.connect(func() -> void: _zoom_by(f))
		row.add_child(b)
	layer.add_child(row)
	_update_hud()


func _process(delta: float) -> void:
	time_left -= delta
	if holding and not done[3]:
		hold_fill = minf(1.0, hold_fill + delta / 1.2)
		if hold_fill >= 1.0:
			_complete(3, &"hold")
	elif not done[3]:
		hold_fill = maxf(0.0, hold_fill - delta)
	if time_left <= 0.0:
		fail(&"time", "The test room clock ran out.")
	_update_hud()
	queue_redraw()


func _on_tap(pos: Vector2) -> void:
	if pos.distance_to(MOON) < 40.0:
		moon_taps += 1
		if moon_taps == 3:
			ctx.award_star(MOON)
		return
	if pos.distance_to(TRAP) < 50.0:
		lives -= 1
		ctx.audio.play_sfx(&"bad")
		ctx.haptic(40)
		if lives <= 0:
			fail(&"lives", "You tapped the red button three times.")
		return
	if not done[0] and pos.distance_to(bubble) < 60.0:
		bubble_taps += 1
		ctx.audio.play_sfx(&"pop", {"pitch_jitter": 0.1})
		bubble = Vector2(ctx.rng.randf_range(540, 680), ctx.rng.randf_range(180, 300))
		if bubble_taps >= 3:
			_complete(0, &"ok")
		return
	if not done[4] and zoom >= 2.4 and pos.distance_to(NOTE_POS) < 26.0 * zoom:
		_complete(4, &"ok")


func _on_press(pos: Vector2) -> void:
	dragging_box = not done[1] and pos.distance_to(box) < 70.0
	holding = not done[3] and pos.distance_to(HOLD_CENTER) < 70.0


func _on_release(_pos: Vector2) -> void:
	holding = false
	if dragging_box:
		dragging_box = false
		if box.distance_to(slot) < 50.0:
			box = slot
			_complete(1, &"drop")


func _on_drag(pos: Vector2, _relative: Vector2) -> void:
	if dragging_box:
		box = pos
	if holding and pos.distance_to(HOLD_CENTER) > 90.0:
		holding = false


func _on_swipe(direction: Vector2, _velocity: Vector2, start: Vector2) -> void:
	if dragging_box or start.distance_to(box) < 70.0:
		return
	if not done[2] and direction == arrow_dir:
		_complete(2, &"swipe")


func _zoom_by(factor: float) -> void:
	zoom = clampf(zoom * factor, 1.0, 4.0)
	ctx.audio.play_sfx(&"zoom", {"pitch": zoom * 0.5 + 0.5})


func _complete(index: int, sfx: StringName) -> void:
	if done[index]:
		return
	done[index] = true
	ctx.audio.play_sfx(sfx)
	if done[0] and done[1] and done[2]:
		checkpoint({"done": done.duplicate(), "time_left": time_left})
	if not done.has(false):
		succeed({"time_left": time_left})


func _update_hud() -> void:
	ctx.hud.set_lives(lives, 3)
	ctx.hud.set_timer(time_left, time_left < 20.0)
	ctx.hud.set_score("%d / 5" % done.count(true))


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1400, 800), ctx.info.color(2, Pal.NIGHT))
	for i in TASKS.size():
		var color := Pal.GREEN if done[i] else Pal.SNOW
		draw_string(_font, Vector2(40, 150 + i * 44), "• " + TASKS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	if not done[0]:
		draw_circle(bubble, 54, Color(Pal.SKY, 0.7))
		draw_arc(bubble, 54, 0, TAU, 32, Pal.SNOW, 3, true)
	draw_rect(Rect2(slot - Vector2(52, 52), Vector2(104, 104)), Pal.SNOW_DIM, false, 4)
	draw_rect(Rect2(box - Vector2(46, 46), Vector2(92, 92)), Pal.GREEN if done[1] else Pal.WOOD_LIGHT)
	if not done[2]:
		var c := Vector2(780, 560)
		draw_line(c - arrow_dir * 60, c + arrow_dir * 50, Pal.GOLD, 14, true)
		var side := arrow_dir.orthogonal() * 30
		draw_colored_polygon(
			PackedVector2Array([c + arrow_dir * 80, c + arrow_dir * 40 + side, c + arrow_dir * 40 - side]), Pal.GOLD
		)
	draw_circle(HOLD_CENTER, 64, Pal.NIGHT_3)
	draw_arc(HOLD_CENTER, 64, -PI / 2, -PI / 2 + TAU * hold_fill, 40, Pal.GREEN if done[3] else Pal.GOLD, 12, true)
	var note_size := int(8 * zoom)
	draw_string(
		_font,
		NOTE_POS - Vector2(note_size, -note_size * 0.3),
		"door",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		note_size,
		Pal.GREEN if done[4] else Pal.SNOW
	)
	draw_circle(MOON, 22, Color("fdf3d0"))
	draw_circle(TRAP, 44, Pal.RED)
	draw_string(_font, TRAP - Vector2(16, -10), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Pal.SNOW)


func _qa_force(outcome: StringName) -> void:
	if outcome == &"star":
		for i in 3:
			_on_tap(MOON)
		return
	super(outcome)
