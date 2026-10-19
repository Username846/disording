class_name DayHost
extends Node
## Runs one day: loading, the DayGame instance, HUD, pause, results and bookkeeping
## (PLAN.md §3.2, §3.4). Days never see this class; they talk to DayContext.

enum Phase { LOADING, RUNNING, PAUSED, RESULTS }

const BUNDLE_TIMEOUT := 20.0

var day := 0
var info: DayInfo
var game: DayGame
var ctx: DayContext
var hud: Hud
var overlay_layer: CanvasLayer
var phase := Phase.LOADING
var elapsed := 0.0
var attempt := 0
var checkpoint_data: Dictionary = {}

var _scene: PackedScene
var _bundle: AudioBundle
var _overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	info = DayRegistry.info(day)
	hud = Hud.new()
	hud.pause_requested.connect(pause)
	add_child(hud)
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 20
	add_child(overlay_layer)
	App.focus_lost.connect(_on_focus_lost)
	if info == null or not DayRegistry.implemented(day):
		push_error("Day %d is not available." % day)
		Router.goto_calendar(day)
		return
	if await _load():
		_begin(false)


func _process(delta: float) -> void:
	if phase == Phase.RUNNING and not get_tree().paused:
		elapsed += delta
		ctx.input.update()
	hud.update_caption(Audio.current_caption() if phase != Phase.LOADING else "")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if phase == Phase.RUNNING:
			pause()
		elif phase == Phase.PAUSED:
			resume()
		get_viewport().set_input_as_handled()


func _load() -> bool:
	var panel := LoadingPanel.new(info)
	overlay_layer.add_child(panel)
	_publish("loading")
	var request: BundleRequest = Bundles.request(info.bundle_id) if info.bundle_id != "" else null
	ResourceLoader.load_threaded_request(info.scene_path)
	var waited := 0.0
	while true:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(info.scene_path, progress)
		var scene_progress := 1.0 if status == ResourceLoader.THREAD_LOAD_LOADED else float(progress[0])
		var bundle_progress := 1.0 if request == null or request.finished else request.progress
		panel.set_progress(scene_progress * 0.3 + bundle_progress * 0.7)
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Couldn't load %s" % info.scene_path)
			Router.goto_calendar(day)
			return false
		var bundle_done := request == null or request.finished or waited > BUNDLE_TIMEOUT
		if status == ResourceLoader.THREAD_LOAD_LOADED and bundle_done:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	_scene = ResourceLoader.load_threaded_get(info.scene_path)
	_bundle = request.bundle if request != null else null
	Audio.day_bundle = _bundle
	if _bundle != null:
		Audio.play_music(_bundle, 0.8)
	else:
		Audio.stop_music(0.5)
	panel.queue_free()
	return true


func _begin(from_checkpoint: bool) -> void:
	_clear_overlay()
	if game != null:
		game.queue_free()
		await get_tree().process_frame
	get_tree().paused = false
	attempt += 1
	var seed_value := hash("%d:%d:%d" % [day, attempt, Time.get_ticks_usec()])
	ctx = DayContext.new(day, info, seed_value, _on_star, func(data: Dictionary) -> void: checkpoint_data = data)
	ctx.hud = hud
	ctx.audio = Audio
	ctx.settings = Settings
	if from_checkpoint:
		ctx.checkpoint = checkpoint_data
	else:
		checkpoint_data = {}
	hud.reset()
	game = _scene.instantiate() as DayGame
	if game == null:
		push_error("%s root must extend DayGame." % info.scene_path)
		Router.goto_calendar(day)
		return
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.ctx = ctx
	game.finished.connect(_on_finished)
	add_child(game)
	move_child(game, 0)
	elapsed = 0.0
	phase = Phase.RUNNING
	SaveService.record_attempt(day, Clock.today())
	_publish("running")
	if from_checkpoint:
		game._day_restore(checkpoint_data)
	else:
		game._day_start()


func pause() -> void:
	if phase != Phase.RUNNING:
		return
	phase = Phase.PAUSED
	get_tree().paused = true
	game._day_pause(true)
	ctx.input.reset()
	Audio.duck(-8.0, 0.25)
	_show_overlay(_pause_menu())
	_publish("paused")


func resume() -> void:
	if phase != Phase.PAUSED:
		return
	_clear_overlay()
	phase = Phase.RUNNING
	get_tree().paused = false
	game._day_pause(false)
	Audio.duck(0.0, 0.25)
	_publish("running")


func leave() -> void:
	if phase == Phase.RUNNING or phase == Phase.PAUSED:
		Telemetry.record_run(day, "quit", elapsed)
	phase = Phase.RESULTS
	Audio.duck(0.0, 0.1)
	Audio.day_bundle = null
	if Audio.ui_bundle != null:
		Audio.play_music(Audio.ui_bundle, 1.0)
	Router.goto_calendar(day)


func qa_force(outcome: StringName) -> void:
	if game != null and phase == Phase.RUNNING:
		game._qa_force(outcome)


func _on_focus_lost() -> void:
	if phase == Phase.RUNNING and not App.test_mode:
		pause()


func _on_star(at: Vector2) -> void:
	SaveService.set_star(day)
	hud.twinkle(at)
	Audio.play_ui(&"star")
	ctx.haptic(30)
	_publish("running")


func _on_finished(result: DayResult) -> void:
	if phase != Phase.RUNNING:
		return
	phase = Phase.RESULTS
	result.seconds = elapsed
	var first_clear := false
	if result.is_success():
		first_clear = SaveService.record_success(day, roundi(elapsed), Clock.today())
		Audio.play_stinger(&"win")
	else:
		SaveService.record_fail(day)
		Audio.play_stinger(&"lose")
	Telemetry.record_run(day, result.outcome_name(), elapsed, String(result.reason))
	_publish("success" if result.is_success() else "fail")
	if not App.test_mode:
		await get_tree().create_timer(0.7).timeout
	get_tree().paused = true
	_show_overlay(_results_panel(result, first_clear))


func _results_panel(result: DayResult, first_clear: bool) -> Overlay:
	var o := Overlay.new(700.0, 0.55)
	if result.is_success():
		o.add_title("Door %d complete!" % day)
		var best := int(SaveService.day(day)["best_seconds"])
		o.add_text("Time %s   ·   Best %s" % [_clock(result.seconds), _clock(best)], 28, Pal.SNOW)
		o.add_text(_next_door_text(first_clear), 26, Pal.SNOW_DIM)
		var cal := UiTheme.button("Calendar", 240.0, true)
		cal.pressed.connect(leave)
		var again := UiTheme.button("Play again", 240.0)
		again.pressed.connect(func() -> void: _begin(false))
		o.add_buttons([again, cal])
	else:
		o.add_title("Not this time", 44, Pal.SNOW)
		o.add_text(result.message if result.message != "" else "The door stays open. Try again!", 28)
		var buttons: Array = []
		var retry := UiTheme.button("Try again", 240.0, true)
		retry.pressed.connect(func() -> void: _begin(false))
		buttons.append(retry)
		if not checkpoint_data.is_empty():
			var from_cp := UiTheme.button("From checkpoint", 280.0)
			from_cp.pressed.connect(func() -> void: _begin(true))
			buttons.append(from_cp)
		var cal := UiTheme.button("Calendar", 220.0)
		cal.pressed.connect(leave)
		buttons.append(cal)
		o.add_buttons(buttons)
	return o


func _next_door_text(_first_clear: bool) -> String:
	if day >= CalendarRules.DAY_COUNT:
		return "That was the last door. Thank you for playing!"
	if day == 0:
		return "Test room cleared."
	match Calendar.state(day + 1):
		CalendarRules.DoorState.UNLOCKS_TOMORROW:
			return "Door %d opens tomorrow." % (day + 1)
		CalendarRules.DoorState.BEING_PAINTED:
			return "Door %d is still being painted." % (day + 1)
		_:
			return "Door %d is waiting for you." % (day + 1)


func _pause_menu() -> Overlay:
	var o := Overlay.new(560.0, 0.55)
	o.add_title("Paused")
	o.add_text(info.title, 28, Pal.SNOW_DIM)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	var resume_btn := UiTheme.button("Resume", 360.0, true)
	resume_btn.pressed.connect(resume)
	var restart := UiTheme.button("Restart", 360.0)
	restart.pressed.connect(
		func() -> void:
			Telemetry.record_run(day, "quit", elapsed, "restart")
			_begin(false)
	)
	var settings := UiTheme.button("Settings", 360.0)
	settings.pressed.connect(func() -> void: overlay_layer.add_child(SettingsPanel.new()))
	var leave_btn := UiTheme.button("Leave to calendar", 360.0)
	leave_btn.pressed.connect(leave)
	for b: Button in [resume_btn, restart, settings, leave_btn]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(b)
	o.body.add_child(col)
	return o


func _show_overlay(control: Control) -> void:
	_clear_overlay()
	_overlay = control
	overlay_layer.add_child(control)


func _clear_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _publish(state: String) -> void:
	App.publish_test_state(
		{"screen": "day", "day": day, "state": state, "star": Calendar.has_star(day), "elapsed": elapsed}
	)


static func _clock(seconds: float) -> String:
	var s := roundi(seconds)
	return "%d:%02d" % [int(s / 60.0), s % 60]


class LoadingPanel:
	extends Control
	var _info: DayInfo
	var _progress := 0.0

	func _init(day_info: DayInfo) -> void:
		_info = day_info
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_progress(value: float) -> void:
		_progress = maxf(_progress, value)
		queue_redraw()

	func _draw() -> void:
		var view := size
		draw_rect(Rect2(Vector2.ZERO, view), Pal.NIGHT)
		var f := UiTheme.font(600)
		var title := "Door %d · %s" % [_info.day, _info.title]
		var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
		draw_string(f, Vector2((view.x - w) * 0.5, view.y * 0.45), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Pal.GOLD)
		var bar := Rect2(view.x * 0.3, view.y * 0.55, view.x * 0.4, 16)
		draw_rect(bar, Pal.NIGHT_3)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _progress, bar.size.y)), Pal.GOLD)
