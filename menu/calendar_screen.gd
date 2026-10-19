class_name CalendarScreen
extends Control
## The advent calendar menu: wall of doors, top bar, captions, intro card (PLAN.md §4.1).

## Door to centre on open; -1 = the newest open door.
var focus_day := -1
var wall: CalendarWall

var _top: Control
var _stars_label: Label
var _star_badge: Control
var _caption: Label
var _overlay_layer: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wall = CalendarWall.new()
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wall.door_tapped.connect(_on_door_tapped)
	add_child(wall)
	_build_top_bar()
	_caption = UiTheme.label("", 22, Pal.SNOW)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_color_override("font_outline_color", Pal.INK)
	_caption.add_theme_constant_override("outline_size", 8)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_layer)
	Calendar.refreshed.connect(_refresh_top_bar)
	App.safe_area_changed.connect(_layout)
	resized.connect(_layout)
	_layout()
	_refresh_top_bar()
	if Audio.ui_bundle != null and Audio.music_bundle != Audio.ui_bundle:
		Audio.play_music(Audio.ui_bundle, 1.2)
	await get_tree().process_frame
	wall.scroll_to_door(focus_day if focus_day > 0 else Calendar.newest_open(), false)
	_publish()
	print("[disording] calendar ready")


func _process(_delta: float) -> void:
	var text := Audio.current_caption()
	if _caption.text != text:
		_caption.text = text
		_caption.reset_size()
		_layout_caption()


func _build_top_bar() -> void:
	_top = Control.new()
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(Pal.NIGHT, 0.9)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.name = "Bg"
	_top.add_child(bar_bg)
	var title := UiTheme.label("Disording", 40, Pal.GOLD, 600)
	title.name = "Title"
	_top.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 12)
	_top.add_child(buttons)
	_star_badge = HBoxContainer.new()
	_star_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var star_icon := StarIcon.new()
	_star_badge.add_child(star_icon)
	_stars_label = UiTheme.label("0", 32, Pal.GOLD, 600)
	_star_badge.add_child(_stars_label)
	buttons.add_child(_star_badge)
	var today := IconButton.new(&"today", 72.0)
	today.tooltip_text = "Today"
	today.pressed.connect(func() -> void: wall.scroll_to_door(Calendar.newest_open()))
	buttons.add_child(today)
	var settings := IconButton.new(&"gear", 72.0)
	settings.pressed.connect(func() -> void: _overlay_layer.add_child(SettingsPanel.new()))
	buttons.add_child(settings)
	if App.is_dev():
		var dev := IconButton.new(&"wrench", 72.0)
		dev.glyph_color = Pal.GOLD
		dev.pressed.connect(func() -> void: _overlay_layer.add_child(DevPanel.new()))
		buttons.add_child(dev)


func _layout() -> void:
	var view := App.visible_size()
	var m := App.safe_margins
	var bar_h := 96.0 + m.y
	wall.top_inset = bar_h
	wall.bottom_inset = 40.0 + m.w
	var bg := _top.get_node("Bg") as ColorRect
	bg.position = Vector2.ZERO
	bg.size = Vector2(view.x, bar_h)
	var title := _top.get_node("Title") as Label
	title.position = Vector2(24.0 + m.x, m.y + 20.0)
	var buttons := _top.get_node("Buttons") as HBoxContainer
	buttons.reset_size()
	buttons.position = Vector2(view.x - buttons.size.x - 20.0 - m.z, m.y + 12.0)
	_layout_caption()


func _layout_caption() -> void:
	var view := App.visible_size()
	_caption.position = Vector2((view.x - _caption.size.x) * 0.5, view.y - _caption.size.y - 12.0 - App.safe_margins.w)


func _refresh_top_bar() -> void:
	var stars := Calendar.star_count()
	# Stars stay invisible until the player has found one on their own (PLAN.md §8.4).
	_star_badge.visible = stars > 0
	_stars_label.text = str(stars)
	if is_inside_tree():
		_layout()
		_publish()


func _on_door_tapped(n: int, _at: Vector2) -> void:
	match wall.state_of(n):
		CalendarRules.DoorState.LOCKED:
			wall.shake(n)
			Audio.play_ui(&"rattle")
			Haptics.pulse(25)
			Toast.show_on(_overlay_layer, "Finish door %d first." % (n - 1))
		CalendarRules.DoorState.UNLOCKS_TOMORROW:
			Audio.play_ui(&"countdown")
			Toast.show_on(
				_overlay_layer, "Door %d opens in %s." % [n, Clock.format_countdown(Clock.seconds_until_midnight())]
			)
		CalendarRules.DoorState.BEING_PAINTED:
			Audio.play_ui(&"knock")
			Toast.show_on(_overlay_layer, "This door is still being painted.")
		_:
			open_intro(n)


func open_intro(n: int) -> void:
	Audio.play_ui(&"creak")
	var info := DayRegistry.info(n)
	if info != null and info.bundle_id != "":
		Bundles.request(info.bundle_id)
	_overlay_layer.add_child(IntroCard.new(n))


func _publish() -> void:
	var playable: Array[int] = []
	for n in range(0, CalendarRules.DAY_COUNT + 1):
		if Calendar.is_playable(n):
			playable.append(n)
	App.publish_test_state({"screen": "calendar", "playable": playable, "stars": Calendar.star_count()})


class StarIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(44, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Glyphs.star(self, Vector2(22, 32), 20.0, Pal.GOLD)
