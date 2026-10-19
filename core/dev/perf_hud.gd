class_name PerfHud
extends CanvasLayer
## Dev overlay: fps, frame time, draw calls, nodes, memory (PLAN.md §2 budgets).

static var _instance: PerfHud

var _label: Label
var _accum := 0.0


static func is_on() -> bool:
	return _instance != null and is_instance_valid(_instance)


static func toggle(on: bool) -> void:
	if on and not is_on():
		_instance = PerfHud.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(_instance)
	elif not on and is_on():
		_instance.queue_free()
		_instance = null


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = UiTheme.label("", 20, Pal.GOLD)
	_label.position = Vector2(12, 100)
	_label.add_theme_color_override("font_outline_color", Pal.INK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	_label.text = (
		"%d fps  %.1f ms\n%d draw calls  %d nodes  %.0f MB"
		% [
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		]
	)
