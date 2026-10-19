class_name Hud
extends CanvasLayer
## Shared in-game HUD: pause button, lives/timer/score/label, captions, toasts, star twinkle.
## Days reach it through ctx.hud. Anchors mirror for the left-handed setting.

signal pause_requested

const MARGIN := 16.0

var root: Control
var pause_button: IconButton
var status: HBoxContainer
var hearts: HeartRow
var timer_label: Label
var score_label: Label
var info_label: Label
var caption_panel: PanelContainer
var caption_label: Label
var fx: Node2D


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	pause_button = IconButton.new(&"pause", 76.0)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	root.add_child(pause_button)

	status = HBoxContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_constant_override("separation", 22)
	root.add_child(status)
	hearts = HeartRow.new()
	hearts.visible = false
	status.add_child(hearts)
	timer_label = _status_label()
	score_label = _status_label()
	info_label = _status_label()

	caption_panel = PanelContainer.new()
	caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_panel.add_theme_stylebox_override("panel", UiTheme.box(Color(Pal.INK, 0.72), 16, Color.TRANSPARENT, 0, 18))
	caption_label = UiTheme.label("", 24, Pal.SNOW)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_panel.add_child(caption_label)
	caption_panel.visible = false
	root.add_child(caption_panel)

	fx = Node2D.new()
	add_child(fx)
	App.safe_area_changed.connect(_layout)
	Settings.changed.connect(func(_k: String) -> void: _layout())
	get_viewport().size_changed.connect(_layout)
	_layout()


func _status_label() -> Label:
	var l := UiTheme.label("", 30, Pal.SNOW, 600)
	l.add_theme_constant_override("outline_size", 8)
	l.visible = false
	status.add_child(l)
	return l


func reset() -> void:
	hearts.visible = false
	for l in [timer_label, score_label, info_label]:
		(l as Label).visible = false
	for child in fx.get_children():
		child.queue_free()


func set_lives(current: int, maximum: int) -> void:
	hearts.visible = true
	hearts.current = current
	hearts.maximum = maximum
	hearts.queue_redraw()


func set_timer(seconds: float, warning: bool = false) -> void:
	timer_label.visible = true
	var s := maxi(0, ceili(seconds))
	timer_label.text = "%d:%02d" % [int(s / 60.0), s % 60]
	timer_label.add_theme_color_override("font_color", Pal.RED if warning else Pal.SNOW)


func set_score(text: String) -> void:
	score_label.visible = text != ""
	score_label.text = text


func set_label(text: String) -> void:
	info_label.visible = text != ""
	info_label.text = text


func toast(text: String, seconds: float = 2.4) -> void:
	Toast.show_on(root, text, seconds)


func twinkle(at: Vector2) -> void:
	if at == Vector2.INF:
		at = App.visible_size() * 0.5
	fx.add_child(StarBurst.new(at))


func update_caption(text: String) -> void:
	caption_panel.visible = text != ""
	if caption_label.text != text:
		caption_label.text = text
		caption_panel.reset_size()
		_layout_caption()


func _layout() -> void:
	var view := App.visible_size()
	var m := App.safe_margins
	var left_handed := Settings.left_handed()
	var top := MARGIN + m.y
	pause_button.position = Vector2(
		MARGIN + m.x if left_handed else view.x - MARGIN - m.z - pause_button.custom_minimum_size.x, top
	)
	status.position = Vector2(view.x - m.z - MARGIN - status.size.x if left_handed else MARGIN + m.x + 4.0, top + 14.0)
	_layout_caption()


func _layout_caption() -> void:
	var view := App.visible_size()
	caption_panel.position = Vector2(
		(view.x - caption_panel.size.x) * 0.5, view.y - App.safe_margins.w - caption_panel.size.y - 14.0
	)


class HeartRow:
	extends Control
	var current := 3
	var maximum := 3

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(40, 40)

	func _draw() -> void:
		custom_minimum_size.x = maxi(1, maximum) * 40.0
		for i in maximum:
			var c := Vector2(20.0 + i * 40.0, 20.0)
			Glyphs.heart(self, c + Vector2(0, 2), 17.0, Pal.SHADOW)
			Glyphs.heart(self, c, 17.0, Pal.RED if i < current else Color(Pal.SNOW, 0.25))
