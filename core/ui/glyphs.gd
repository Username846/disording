class_name Glyphs
extends RefCounted
## Procedural vector icons (no texture files). Every function draws centred on `c`, sized by `s`.


static func draw(ci: CanvasItem, glyph: StringName, c: Vector2, s: float, color: Color) -> void:
	match glyph:
		&"pause":
			ci.draw_rect(Rect2(c + Vector2(-0.32, -0.36) * s, Vector2(0.22, 0.72) * s), color)
			ci.draw_rect(Rect2(c + Vector2(0.10, -0.36) * s, Vector2(0.22, 0.72) * s), color)
		&"play":
			ci.draw_colored_polygon(_pts(c, s, [Vector2(-0.3, -0.4), Vector2(0.42, 0), Vector2(-0.3, 0.4)]), color)
		&"close":
			ci.draw_line(c + Vector2(-0.3, -0.3) * s, c + Vector2(0.3, 0.3) * s, color, s * 0.12, true)
			ci.draw_line(c + Vector2(0.3, -0.3) * s, c + Vector2(-0.3, 0.3) * s, color, s * 0.12, true)
		&"back":
			ci.draw_polyline(
				_pts(c, s, [Vector2(0.15, -0.35), Vector2(-0.2, 0), Vector2(0.15, 0.35)]), color, s * 0.12, true
			)
		&"gear":
			gear(ci, c, s * 0.42, color)
		&"star":
			star(ci, c, s * 0.5, color)
		&"heart":
			heart(ci, c, s * 0.5, color)
		&"lock":
			lock(ci, c, s * 0.5, color)
		&"clock":
			clock(ci, c, s * 0.42, color)
		&"today":
			ci.draw_rect(Rect2(c + Vector2(-0.36, -0.3) * s, Vector2(0.72, 0.66) * s), color, false, s * 0.08)
			ci.draw_rect(Rect2(c + Vector2(-0.36, -0.3) * s, Vector2(0.72, 0.16) * s), color)
			ci.draw_circle(c + Vector2(0.0, 0.12) * s, s * 0.1, color)
		&"wrench":
			ci.draw_line(c + Vector2(-0.3, 0.3) * s, c + Vector2(0.15, -0.15) * s, color, s * 0.14, true)
			ci.draw_arc(c + Vector2(0.2, -0.2) * s, s * 0.16, 0.0, TAU * 0.8, 16, color, s * 0.1, true)
		_:
			hint(ci, glyph, c, s, color)


## Intro-card hint icons: a hand/finger plus a motion cue.
static func hint(ci: CanvasItem, glyph: StringName, c: Vector2, s: float, color: Color) -> void:
	var tip := c + Vector2(0.0, -0.05) * s
	match glyph:
		&"tap", &"double_tap":
			ci.draw_arc(tip, s * 0.18, 0.0, TAU, 20, color, s * 0.05, true)
			if glyph == &"double_tap":
				ci.draw_arc(tip, s * 0.3, 0.0, TAU, 24, Color(color, 0.6), s * 0.04, true)
		&"hold":
			ci.draw_circle(tip, s * 0.14, color)
			ci.draw_arc(tip, s * 0.3, -PI / 2, PI * 1.1, 24, color, s * 0.05, true)
		&"drag", &"flick":
			ci.draw_circle(c + Vector2(0.25, 0.1) * s, s * 0.12, color)
			var dash := Color(color, 0.7)
			for i in 3:
				var a := c + Vector2(0.05 - i * 0.18, 0.1 - i * 0.05) * s
				ci.draw_circle(a, s * 0.04, dash)
			if glyph == &"flick":
				ci.draw_line(c + Vector2(0.25, 0.1) * s, c + Vector2(0.45, -0.25) * s, color, s * 0.05, true)
		&"swipe":
			ci.draw_line(c + Vector2(-0.35, 0.1) * s, c + Vector2(0.3, 0.1) * s, color, s * 0.06, true)
			ci.draw_colored_polygon(_pts(c, s, [Vector2(0.4, 0.1), Vector2(0.22, -0.04), Vector2(0.22, 0.24)]), color)
		&"draw":
			var pts := PackedVector2Array()
			for i in 13:
				var a := i / 12.0 * TAU * 0.85
				pts.append(c + Vector2(cos(a), sin(a)) * s * 0.3)
			ci.draw_polyline(pts, color, s * 0.06, true)
		&"pinch":
			ci.draw_circle(c + Vector2(-0.22, 0.18) * s, s * 0.1, color)
			ci.draw_circle(c + Vector2(0.22, -0.18) * s, s * 0.1, color)
			ci.draw_line(c + Vector2(-0.1, 0.06) * s, c + Vector2(0.1, -0.06) * s, Color(color, 0.6), s * 0.04, true)
		&"timer":
			clock(ci, c, s * 0.38, color)
		_:
			ci.draw_circle(c, s * 0.15, color)


static func star(ci: CanvasItem, c: Vector2, r: float, color: Color, inner: float = 0.45) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * inner))
	ci.draw_colored_polygon(pts, color)


static func heart(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := i / 32.0 * TAU
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * r / 17.0)
	ci.draw_colored_polygon(pts, color)


static func lock(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ci.draw_arc(c + Vector2(0, -0.15) * r, r * 0.42, PI, TAU, 16, color, r * 0.16, true)
	ci.draw_rect(Rect2(c + Vector2(-0.62, -0.18) * r, Vector2(1.24, 0.95) * r), color)
	ci.draw_circle(c + Vector2(0, 0.22) * r, r * 0.13, Color(0, 0, 0, 0.45))


static func clock(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ci.draw_arc(c, r, 0.0, TAU, 28, color, r * 0.16, true)
	ci.draw_line(c, c + Vector2(0, -0.6) * r, color, r * 0.14, true)
	ci.draw_line(c, c + Vector2(0.45, 0.2) * r, color, r * 0.14, true)


static func gear(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := i / 48.0 * TAU
		var tooth := 1.0 if int(i / 3.0) % 2 == 0 else 0.78
		pts.append(c + Vector2(cos(a), sin(a)) * r * tooth)
	ci.draw_colored_polygon(pts, color)
	ci.draw_circle(c, r * 0.32, Color(0, 0, 0, 0.55))


static func _pts(c: Vector2, s: float, unit: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in unit:
		out.append(c + p * s)
	return out
