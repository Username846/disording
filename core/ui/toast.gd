class_name Toast
extends PanelContainer
## A short message that fades in at the top of the screen and away again.


static func show_on(parent: Node, text: String, seconds: float = 2.4) -> Toast:
	for child in parent.get_children():
		if child is Toast:
			child.queue_free()
	var toast := Toast.new()
	toast.process_mode = Node.PROCESS_MODE_ALWAYS
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", UiTheme.box(Color(Pal.INK, 0.92), 22, Pal.GOLD_DEEP, 2, 26))
	var label := UiTheme.label(text, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_child(label)
	parent.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position.y = 96.0 + App.safe_margins.y
	toast.modulate.a = 0.0
	toast.resized.connect(func() -> void: toast.position.x = (App.visible_size().x - toast.size.x) * 0.5)
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	tween.tween_interval(seconds)
	tween.tween_property(toast, "modulate:a", 0.0, 0.35)
	tween.tween_callback(toast.queue_free)
	return toast
