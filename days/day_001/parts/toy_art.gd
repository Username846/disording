extends RefCounted
## Top-down "token" drawings of the wind-up toys. All shapes are drawn around (0, 0) with the
## toy facing +x; the caller rotates the canvas to the toy's facing.


static func draw(ci: CanvasItem, kind: StringName, r: float, t: float) -> void:
	match kind:
		&"knight":
			_knight(ci, r, t)
		&"dino":
			_dino(ci, r)
		&"ninja":
			_ninja(ci, r, t)
		&"bear":
			_bear(ci, r)
		&"robot":
			_robot(ci, r, t)
		&"champ":
			_champ(ci, r)
		&"ref":
			_referee(ci, r)
		_:
			ci.draw_circle(Vector2.ZERO, r, Color.MAGENTA)


static func color(kind: StringName) -> Color:
	match kind:
		&"knight":
			return Color("c9d2dc")
		&"dino":
			return Color("5fbf5a")
		&"ninja":
			return Color("3a3a48")
		&"bear":
			return Color("a86d3e")
		&"robot":
			return Color("9aa8b5")
		&"champ":
			return Color("8e4fc2")
		_:
			return Color.WHITE


static func _body(ci: CanvasItem, r: float, fill: Color) -> void:
	ci.draw_circle(Vector2.ZERO, r, fill.darkened(0.35))
	ci.draw_circle(Vector2.ZERO, r - 3.0, fill)
	ci.draw_circle(Vector2(-r * 0.25, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.18))


static func _eyes(ci: CanvasItem, r: float, eye: Color = Color.WHITE, pupil: Color = Pal.INK) -> void:
	for side in [-1.0, 1.0]:
		var p := Vector2(r * 0.45, side * r * 0.32)
		ci.draw_circle(p, r * 0.16, eye)
		ci.draw_circle(p + Vector2(r * 0.05, 0), r * 0.08, pupil)


static func _knight(ci: CanvasItem, r: float, t: float) -> void:
	# Wind-up key on the back.
	var spin := t * 6.0
	ci.draw_line(Vector2(-r, 0), Vector2(-r - 10, 0), Pal.GOLD_DEEP, 5.0)
	for k in [0.0, PI]:
		var a: float = spin + k
		ci.draw_circle(Vector2(-r - 14, 0) + Vector2(0, sin(a) * 9.0), 7.0, Pal.GOLD)
	_body(ci, r, color(&"knight"))
	# Plume and visor.
	ci.draw_colored_polygon(
		PackedVector2Array(
			[Vector2(-r * 0.2, -4), Vector2(-r * 1.05, -10), Vector2(-r * 1.05, 10), Vector2(-r * 0.2, 4)]
		),
		Pal.RED
	)
	ci.draw_rect(Rect2(r * 0.3, -r * 0.45, r * 0.22, r * 0.9), Color("30343c"))
	for i in 3:
		ci.draw_line(
			Vector2(r * 0.3, -r * 0.3 + i * r * 0.3), Vector2(r * 0.52, -r * 0.3 + i * r * 0.3), color(&"knight"), 2.0
		)


static func _dino(ci: CanvasItem, r: float) -> void:
	for i in 5:
		var a := PI * 0.6 + i * PI * 0.2
		var p := Vector2(cos(a), sin(a)) * r
		ci.draw_colored_polygon(
			PackedVector2Array([p * 0.85 + p.orthogonal() * 0.15, p * 1.35, p * 0.85 - p.orthogonal() * 0.15]),
			Color("f2a33a")
		)
	_body(ci, r, color(&"dino"))
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.42, Color("78d06f"))
	_eyes(ci, r)
	ci.draw_line(Vector2(r * 0.8, -r * 0.15), Vector2(r * 0.92, -r * 0.15), Pal.INK, 2.0)


static func _ninja(ci: CanvasItem, r: float, t: float) -> void:
	var yoyo := Vector2(cos(t * 9.0), sin(t * 9.0)) * (r + 14.0)
	ci.draw_line(Vector2.ZERO, yoyo, Color(1, 1, 1, 0.5), 1.5)
	ci.draw_circle(yoyo, 6.0, Pal.RED)
	_body(ci, r, color(&"ninja"))
	ci.draw_colored_polygon(
		PackedVector2Array([Vector2(-r * 0.7, -6), Vector2(-r * 1.4, -14), Vector2(-r * 1.3, 2), Vector2(-r * 0.7, 6)]),
		Pal.RED
	)
	ci.draw_arc(Vector2.ZERO, r * 0.78, -0.9, 0.9, 12, Pal.RED, 6.0)
	ci.draw_rect(Rect2(r * 0.35, -r * 0.4, r * 0.25, r * 0.8), Color("f4e2c8"))
	ci.draw_circle(Vector2(r * 0.5, -r * 0.18), 2.5, Pal.INK)
	ci.draw_circle(Vector2(r * 0.5, r * 0.18), 2.5, Pal.INK)


static func _bear(ci: CanvasItem, r: float) -> void:
	for side in [-1.0, 1.0]:
		ci.draw_circle(Vector2(r * 0.1, side * r * 0.8), r * 0.32, color(&"bear").darkened(0.2))
		ci.draw_circle(Vector2(r * 0.1, side * r * 0.8), r * 0.18, Color("e6b98d"))
	_body(ci, r, color(&"bear"))
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.38, Color("e6b98d"))
	ci.draw_circle(Vector2(r * 0.8, 0), r * 0.12, Pal.INK)
	_eyes(ci, r * 0.9, Pal.INK, Pal.INK)


static func _robot(ci: CanvasItem, r: float, t: float) -> void:
	var s := r * 0.95
	var box := PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
	ci.draw_colored_polygon(box, color(&"robot").darkened(0.35))
	var inner := PackedVector2Array(
		[Vector2(-s + 3, -s + 3), Vector2(s - 3, -s + 3), Vector2(s - 3, s - 3), Vector2(-s + 3, s - 3)]
	)
	ci.draw_colored_polygon(inner, color(&"robot"))
	ci.draw_rect(Rect2(s * 0.3, -s * 0.55, s * 0.45, s * 1.1), Color("223040"))
	var glow := Color("62e0ff") if fmod(t, 1.2) > 0.15 else Color("1b5a6a")
	ci.draw_circle(Vector2(s * 0.52, -s * 0.28), s * 0.12, glow)
	ci.draw_circle(Vector2(s * 0.52, s * 0.28), s * 0.12, glow)
	ci.draw_line(Vector2(-s * 0.4, 0), Vector2(-s * 0.95, 0), Pal.SNOW_DIM, 3.0)
	ci.draw_circle(Vector2(-s * 1.0, 0), 5.0, Pal.RED if fmod(t, 0.8) < 0.4 else Pal.GOLD)


static func _champ(ci: CanvasItem, r: float) -> void:
	var s := r * 0.95
	var box := PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
	ci.draw_colored_polygon(box, color(&"champ").darkened(0.3))
	ci.draw_rect(Rect2(-s + 4, -s + 4, s * 2 - 8, s * 2 - 8), color(&"champ"))
	for i in 4:
		ci.draw_line(Vector2(-s + 4, -s + 4 + i * s * 0.6), Vector2(s - 4, -s + 4 + i * s * 0.6), Pal.GOLD, 2.0)
	ci.draw_circle(Vector2(r * 0.1, 0), r * 0.62, Color("fde2c4"))
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.16, Pal.RED)
	_eyes(ci, r * 0.8)
	Glyphs.star(ci, Vector2(-r * 0.35, 0), r * 0.3, Pal.GOLD)


static func _referee(ci: CanvasItem, r: float) -> void:
	ci.draw_circle(Vector2.ZERO, r, Pal.INK)
	ci.draw_circle(Vector2.ZERO, r - 3.0, Color.WHITE)
	for i in range(-2, 3):
		var x := i * r * 0.36
		var h := sqrt(maxf(0.0, (r - 3.0) * (r - 3.0) - x * x))
		ci.draw_line(Vector2(x, -h), Vector2(x, h), Pal.INK, r * 0.16)
	ci.draw_circle(Vector2(r * 0.25, 0), r * 0.42, Pal.INK)
	ci.draw_circle(Vector2(r * 0.7, r * 0.15), 5.0, Pal.GOLD)
