class_name Overlay
extends Control
## Full-screen modal: dims what's behind and centres a panel. Works while the tree is paused.

signal closed

var panel: PanelContainer
var body: VBoxContainer


func _init(panel_width: float = 640.0, dim: float = 0.6) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = panel_width
	center.add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	panel.add_child(body)


func add_title(text: String, size: int = 44, color: Color = Pal.GOLD) -> Label:
	var l := UiTheme.label(text, size, color, 600)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)
	return l


func add_text(text: String, size: int = 26, color: Color = Pal.SNOW) -> Label:
	var l := UiTheme.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)
	return l


func add_buttons(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for b: Control in buttons:
		row.add_child(b)
	body.add_child(row)
	return row


func close() -> void:
	closed.emit()
	queue_free()
