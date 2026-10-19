class_name SettingsPanel
extends Overlay
## Settings overlay, reachable from the calendar and the pause menu (PLAN.md §3.3).


func _init() -> void:
	super(760.0, 0.65)


func _ready() -> void:
	add_title("Settings")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, minf(470.0, App.visible_size().y - 250.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 14)
	scroll.add_child(rows)

	rows.add_child(_slider_row("Music", "music"))
	rows.add_child(_slider_row("Sound effects", "sfx"))
	rows.add_child(_toggle_row("Lyrics captions", "captions"))
	if App.is_mobile():
		rows.add_child(_toggle_row("Vibration", "haptics"))
	rows.add_child(_toggle_row("Reduce motion", "reduce_motion"))
	rows.add_child(_toggle_row("Left-handed controls", "left_handed"))
	rows.add_child(_quality_row())
	if App.is_web() and not OS.has_feature("web_ios"):
		var full := UiTheme.button("Toggle fullscreen", 360.0)
		full.pressed.connect(_toggle_fullscreen)
		rows.add_child(_row("Screen", full))

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	var export_btn := UiTheme.button("Copy save code", 250.0)
	export_btn.pressed.connect(_export_code)
	var import_btn := UiTheme.button("Load save code", 250.0)
	import_btn.pressed.connect(_import_code)
	save_row.add_child(export_btn)
	save_row.add_child(import_btn)
	rows.add_child(_row("Progress", save_row))

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	var credits := UiTheme.button("Credits", 200.0)
	credits.pressed.connect(func() -> void: add_child(CreditsPanel.new()))
	var reset := UiTheme.button("Reset progress", 250.0)
	reset.add_theme_color_override("font_color", Pal.RED)
	reset.pressed.connect(_confirm_reset)
	bottom.add_child(credits)
	bottom.add_child(reset)
	rows.add_child(_row("", bottom))

	var done := UiTheme.button("Done", 240.0, true)
	done.pressed.connect(close)
	add_buttons([done])


func _row(title: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UiTheme.label(title, 26, Pal.SNOW_DIM)
	l.custom_minimum_size.x = 280
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _slider_row(title: String, key: String) -> HBoxContainer:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.get_float(key)
	slider.custom_minimum_size.y = 64
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(v: float) -> void: Settings.set_value(key, v))
	slider.drag_ended.connect(func(_c: bool) -> void: Audio.play_ui(&"toggle"))
	return _row(title, slider)


func _toggle_row(title: String, key: String) -> HBoxContainer:
	var b := UiTheme.button("", 160.0)
	b.toggle_mode = true
	b.button_pressed = Settings.get_bool(key)
	b.text = "On" if b.button_pressed else "Off"
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.toggled.connect(
		func(on: bool) -> void:
			b.text = "On" if on else "Off"
			Settings.set_value(key, on)
	)
	var row := _row(title, b)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return row


func _quality_row() -> HBoxContainer:
	var group := ButtonGroup.new()
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	for option: String in ["auto", "fast", "sharp"]:
		var b := UiTheme.button(option.capitalize(), 140.0)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = Settings.get_value("quality") == option
		b.pressed.connect(func() -> void: Settings.set_value("quality", option))
		box.add_child(b)
	return _row("Graphics", box)


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_WINDOWED
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	)


func _export_code() -> void:
	var code := SaveService.export_code()
	DisplayServer.clipboard_set(code)
	var o := Overlay.new(720.0, 0.5)
	o.add_title("Your save code", 36)
	o.add_text("Copied to the clipboard. Keep it somewhere safe to move your calendar to another device.", 24)
	var field := LineEdit.new()
	field.text = code
	field.editable = false
	field.custom_minimum_size.y = 64
	o.body.add_child(field)
	var ok := UiTheme.button("OK", 200.0, true)
	ok.pressed.connect(o.close)
	o.add_buttons([ok])
	add_child(o)


func _import_code() -> void:
	var code := ""
	if App.is_web():
		var raw: Variant = JavaScriptBridge.eval("window.prompt('Paste your save code') || ''", true)
		code = str(raw) if raw != null else ""
		_finish_import(code)
		return
	var o := Overlay.new(720.0, 0.5)
	o.add_title("Load save code", 36)
	var field := LineEdit.new()
	field.placeholder_text = "DSD1..."
	field.custom_minimum_size.y = 64
	o.body.add_child(field)
	var load_btn := UiTheme.button("Load", 200.0, true)
	load_btn.pressed.connect(
		func() -> void:
			o.close()
			_finish_import(field.text)
	)
	var cancel := UiTheme.button("Cancel", 200.0)
	cancel.pressed.connect(o.close)
	o.add_buttons([cancel, load_btn])
	add_child(o)


func _finish_import(code: String) -> void:
	if code.strip_edges() == "":
		return
	if SaveService.import_code(code):
		Toast.show_on(self, "Save loaded.")
	else:
		Toast.show_on(self, "That code didn't work. Check it was copied in full.")


func _confirm_reset() -> void:
	var o := Overlay.new(640.0, 0.5)
	o.add_title("Reset progress?", 36, Pal.RED)
	o.add_text("Every door closes again and stars are cleared. Settings are kept.", 24)
	var cancel := UiTheme.button("Keep my doors", 260.0, true)
	cancel.pressed.connect(o.close)
	var confirm := UiTheme.button("Reset", 200.0)
	confirm.pressed.connect(
		func() -> void:
			SaveService.reset(Clock.system_today())
			o.close()
			Toast.show_on(self, "Progress reset.")
	)
	o.add_buttons([cancel, confirm])
	add_child(o)


class CreditsPanel:
	extends Overlay

	func _init() -> void:
		super(780.0, 0.5)

	func _ready() -> void:
		add_title("Credits", 40)
		var lines := [
			"Made with Godot Engine %s (MIT licence)." % Engine.get_version_info().string,
			"Music, voices and sound rendered by Songsmith, our own offline synthesizer.",
			"Lyrics pronunciations: CMU Pronouncing Dictionary (BSD licence).",
			"Font: Fredoka by The Fredoka Project Authors (SIL Open Font Licence 1.1).",
			"Thanks to the games that shaped us.",
			"Version %s · %s" % [App.version, App.commit],
		]
		for line: String in lines:
			add_text(line, 22, Pal.SNOW_DIM)
		var ok := UiTheme.button("Close", 200.0, true)
		ok.pressed.connect(close)
		add_buttons([ok])
