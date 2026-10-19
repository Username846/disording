class_name TitleScreen
extends Control
## "Tap to open": the first user gesture, which also unlocks web audio (PLAN.md §3.2, §7.2).

var _t := 0.0
var _stars: Array[Vector3] = []
var _hint: Label
var _leaving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.6, rng.randf() * TAU))

	var snow := CPUParticles2D.new()
	snow.amount = 60 if not Settings.reduce_motion() else 20
	snow.lifetime = 9.0
	snow.preprocess = 9.0
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(900, 10)
	snow.position = Vector2(640, -20)
	snow.direction = Vector2(0.15, 1)
	snow.spread = 12.0
	snow.gravity = Vector2.ZERO
	snow.initial_velocity_min = 40.0
	snow.initial_velocity_max = 80.0
	snow.scale_amount_min = 2.0
	snow.scale_amount_max = 5.0
	snow.color = Color(Pal.SNOW, 0.8)
	add_child(snow)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var title := UiTheme.label("Disording", 112, Pal.GOLD, 600)
	title.add_theme_color_override("font_outline_color", Pal.INK)
	title.add_theme_constant_override("outline_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiTheme.label("A hundred doors. One a day.", 32, Pal.SNOW)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = 60
	col.add_child(gap)
	_hint = UiTheme.label("Tap to open", 40, Pal.SNOW, 600)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_hint)
	col.resized.connect(func() -> void: col.position = (App.visible_size() - col.size) * 0.5 - Vector2(0, 40))

	var version := UiTheme.label("v%s" % App.version, 18, Color(Pal.SNOW_DIM, 0.6))
	version.position = Vector2(16, 8)
	add_child(version)
	App.publish_test_state({"screen": "title"})
	print("[disording] title ready")


func _process(delta: float) -> void:
	_t += delta
	_hint.modulate.a = 0.55 + 0.45 * sin(_t * 3.0) if not Settings.reduce_motion() else 1.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed := (
		(event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if pressed and not _leaving:
		_leaving = true
		accept_event()
		_open()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not _leaving:
		_leaving = true
		_open()


func _open() -> void:
	Audio.play_ui(&"open")
	var request := Bundles.request("menu")
	if request.finished:
		Audio.ui_bundle = request.bundle
		Audio.play_music(request.bundle, 1.5)
	else:
		request.done.connect(
			func(bundle: AudioBundle) -> void:
				Audio.ui_bundle = bundle
				if Router.current is CalendarScreen:
					Audio.play_music(bundle, 1.5)
		)
	Router.goto_calendar()


func _draw() -> void:
	var view := App.visible_size()
	var top := Pal.NIGHT
	var bottom := Pal.NIGHT_3
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(view.x, 0), view, Vector2(0, view.y)]),
		PackedColorArray([top, top, bottom, bottom])
	)
	for s in _stars:
		var a := 0.35 + 0.35 * sin(_t * 1.5 + s.z)
		draw_circle(Vector2(s.x * view.x, s.y * view.y), 1.6, Color(Pal.SNOW, a))
	draw_circle(Vector2(view.x * 0.82, view.y * 0.18), 46.0, Color("fdf3d0"))
	draw_circle(Vector2(view.x * 0.82 + 16, view.y * 0.18 - 10), 40.0, top.lerp(bottom, 0.15))
	# Townhouse silhouette with a grid of glowing windows: a hint of the calendar inside
	# (bottom-left window lit, where door 1 is).
	var house := Rect2(view.x * 0.5 - 330, view.y - 190, 660, 190)
	draw_colored_polygon(
		PackedVector2Array(
			[
				house.position + Vector2(-20, 0),
				Vector2(view.x * 0.5, house.position.y - 90),
				house.position + Vector2(house.size.x + 20, 0),
			]
		),
		Pal.INK
	)
	draw_rect(house, Pal.INK)
	for row in 3:
		for c in 10:
			var lit := (row == 2 and c == 0) or sin(c * 1.7 + row * 2.3) > 0.4
			var w := Rect2(house.position + Vector2(24 + c * 63, 22 + row * 56), Vector2(36, 40))
			draw_rect(w, Color(Pal.GOLD, 0.85) if lit else Color(Pal.NIGHT_3, 0.9))
	draw_rect(Rect2(0, view.y - 14, view.x, 14), Pal.SNOW)
