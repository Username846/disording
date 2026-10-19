class_name IntroCard
extends Overlay
## Door intro: title, genre, pitch, three icon hints, time estimate, Play (PLAN.md §8.1).

var day := 0


func _init(day_number: int) -> void:
	super(820.0, 0.6)
	day = day_number


func _ready() -> void:
	var info := DayRegistry.info(day)
	var record := SaveService.day(day)
	var door := UiTheme.label("Door %d" % day, 26, Pal.SNOW_DIM, 600)
	door.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(door)
	add_title(info.title, 52)
	add_text(info.genre.substr(0, 1).to_upper() + info.genre.substr(1), 24, Pal.SKY)
	if info.pitch != "":
		add_text(info.pitch, 26)
	if not info.hints.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 26)
		for hint in info.hints:
			row.add_child(HintChip.new(hint))
		body.add_child(row)
	var facts := "About %d minutes" % info.est_minutes
	if int(record["best_seconds"]) > 0:
		facts += "   ·   Best %s" % DayHost._clock(float(record["best_seconds"]))
	add_text(facts, 24, Pal.SNOW_DIM)
	if Calendar.has_star(day):
		var star := CalendarScreen.StarIcon.new()
		star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		body.add_child(star)
	var close_btn := UiTheme.button("Close", 200.0)
	close_btn.pressed.connect(close)
	var play := UiTheme.button("Play", 260.0, true)
	play.pressed.connect(_play)
	add_buttons([close_btn, play])
	App.publish_test_state({"screen": "intro", "day": day})


func _play() -> void:
	Audio.play_ui(&"open")
	Router.start_day(day)


class HintChip:
	extends VBoxContainer
	var _glyph: StringName

	func _init(hint: String) -> void:
		var parts := hint.split("|", true, 1)
		_glyph = StringName(parts[0])
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(84, 84)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.draw.connect(
			func() -> void:
				icon.draw_circle(Vector2(42, 42), 40.0, Pal.NIGHT_3)
				Glyphs.hint(icon, _glyph, Vector2(42, 42), 70.0, Pal.GOLD)
		)
		add_child(icon)
		var l := UiTheme.label(parts[1] if parts.size() > 1 else "", 22, Pal.SNOW)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.x = 200
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(l)
