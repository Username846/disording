class_name IconButton
extends Button
## Round, touch-sized button that draws a Glyphs icon instead of text.

var glyph: StringName
var glyph_color := Pal.SNOW


func _init(icon_glyph: StringName = &"close", size: float = 72.0) -> void:
	glyph = icon_glyph
	custom_minimum_size = Vector2(size, size)
	focus_mode = Control.FOCUS_NONE
	var round_box := UiTheme.box(Color(Pal.NIGHT_2, 0.85), int(size / 2), Color(Pal.SNOW, 0.25), 2, 0)
	add_theme_stylebox_override("normal", round_box)
	add_theme_stylebox_override("hover", UiTheme.box(Pal.NIGHT_3, int(size / 2), Pal.SNOW_DIM, 2, 0))
	add_theme_stylebox_override("pressed", UiTheme.box(Pal.GOLD_DEEP, int(size / 2), Pal.GOLD, 2, 0))
	add_theme_stylebox_override("hover_pressed", UiTheme.box(Pal.GOLD_DEEP, int(size / 2), Pal.GOLD, 2, 0))
	pressed.connect(func() -> void: Audio.play_ui(&"tap"))


func _draw() -> void:
	Glyphs.draw(self, glyph, size * 0.5, minf(size.x, size.y) * 0.62, glyph_color)
