extends Node
## Screen flow and transitions (PLAN.md §3.2). Screens are plain nodes swapped under the root.

signal screen_changed(screen: Node)

var current: Node
var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Pal.NIGHT
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_layer.add_child(_fade)


func goto_title() -> void:
	await goto(TitleScreen.new())


func goto_calendar(focus_day: int = -1) -> void:
	var screen := CalendarScreen.new()
	screen.focus_day = focus_day
	await goto(screen)


func start_day(n: int) -> void:
	var host := DayHost.new()
	host.day = n
	await goto(host)


## Replaces the current screen, with a short fade (instant in test mode).
func goto(screen: Node, fade_time: float = 0.25) -> void:
	if _busy:
		await get_tree().process_frame
	_busy = true
	if App.test_mode:
		fade_time = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if fade_time > 0.0 and current != null:
		await create_tween().tween_property(_fade, "modulate:a", 1.0, fade_time).finished
	get_tree().paused = false
	if current != null and is_instance_valid(current):
		current.queue_free()
	# Always yield once: the old screen finishes freeing and the root is never busy.
	await get_tree().process_frame
	var tree_root := get_tree().root
	tree_root.add_child(screen)
	get_tree().current_scene = screen
	current = screen
	screen_changed.emit(screen)
	if fade_time > 0.0:
		await create_tween().tween_property(_fade, "modulate:a", 0.0, fade_time).finished
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
