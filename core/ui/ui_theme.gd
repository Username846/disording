class_name UiTheme
extends RefCounted
## Builds the shared Theme in code (PLAN.md §8.1: big targets, readable text).

const FONT_PATH := "res://core/ui/fonts/Fredoka.woff2"
const BUTTON_MIN_HEIGHT := 72.0

static var _font_cache: Dictionary = {}


static func font(weight: int = 500) -> Font:
	if _font_cache.has(weight):
		return _font_cache[weight]
	var base := load(FONT_PATH) as FontFile
	var variation := FontVariation.new()
	if base != null:
		variation.base_font = base
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		variation.fallbacks = [ThemeDB.fallback_font]
	else:
		variation.base_font = ThemeDB.fallback_font
	_font_cache[weight] = variation
	return variation


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font(500)
	t.default_font_size = 28

	t.set_color("font_color", "Label", Pal.SNOW)
	t.set_color("font_outline_color", "Label", Pal.INK)
	t.set_color("font_color", "RichTextLabel", Pal.SNOW)
	t.set_color("default_color", "RichTextLabel", Pal.SNOW)

	t.set_stylebox("normal", "Button", box(Pal.NIGHT_3, 18, Pal.SNOW_DIM.darkened(0.5)))
	t.set_stylebox("hover", "Button", box(Pal.NIGHT_3.lightened(0.12), 18, Pal.SNOW_DIM))
	t.set_stylebox("pressed", "Button", box(Pal.GOLD_DEEP, 18, Pal.GOLD))
	t.set_stylebox("hover_pressed", "Button", box(Pal.GOLD_DEEP, 18, Pal.GOLD))
	t.set_stylebox("disabled", "Button", box(Pal.NIGHT_2, 18, Pal.NIGHT_3))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(state, "Button", Pal.SNOW)
	t.set_color("font_pressed_color", "Button", Pal.INK)
	t.set_color("font_hover_pressed_color", "Button", Pal.INK)
	t.set_color("font_disabled_color", "Button", Pal.SNOW_DIM.darkened(0.4))
	t.set_constant("h_separation", "Button", 12)

	t.set_stylebox("panel", "Panel", box(Color(Pal.NIGHT_2, 0.96), 28, Pal.NIGHT_3, 3))
	t.set_stylebox("panel", "PanelContainer", box(Color(Pal.NIGHT_2, 0.96), 28, Pal.NIGHT_3, 3, 28))

	var track := box(Pal.NIGHT, 12)
	track.content_margin_top = 10
	track.content_margin_bottom = 10
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", box(Pal.GOLD_DEEP, 12))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(Pal.GOLD, 12))
	var knob := circle_texture(44, Pal.GOLD)
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", circle_texture(44, Pal.SNOW))

	var scroll := box(Color(Pal.SNOW, 0.08), 8)
	t.set_stylebox("scroll", "VScrollBar", scroll)
	t.set_stylebox("grabber", "VScrollBar", box(Color(Pal.SNOW, 0.35), 8))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(Pal.SNOW, 0.55), 8))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Pal.GOLD, 8))
	return t


static func box(
	color: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 2, pad: int = 20
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(border_width)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.5
	s.content_margin_bottom = pad * 0.5
	s.anti_aliasing = true
	return s


static func circle_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(color, clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## A large, touch-friendly button.
static func button(text: String, min_width: float = 220.0, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, BUTTON_MIN_HEIGHT)
	b.focus_mode = Control.FOCUS_NONE
	if primary:
		b.add_theme_stylebox_override("normal", box(Pal.GOLD, 18, Pal.GOLD_DEEP, 3))
		b.add_theme_stylebox_override("hover", box(Pal.GOLD.lightened(0.15), 18, Pal.GOLD_DEEP, 3))
		b.add_theme_color_override("font_color", Pal.INK)
		b.add_theme_color_override("font_hover_color", Pal.INK)
		b.add_theme_color_override("font_focus_color", Pal.INK)
	b.pressed.connect(func() -> void: Audio.play_ui(&"tap"))
	return b


static func label(text: String, size: int = 28, color: Color = Pal.SNOW, weight: int = 500) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if weight != 500:
		l.add_theme_font_override("font", font(weight))
	return l
