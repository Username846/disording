extends RefCounted
## Door art for the calendar once Day 1 is complete: the tin knight on a quilt, crowned.

const ToyArt := preload("res://days/day_001/parts/toy_art.gd")


func draw(ci: CanvasItem, rect: Rect2) -> void:
	var cell := rect.size.x / 4.0
	for x in 4:
		for y in int(ceil(rect.size.y / cell)):
			var r := Rect2(rect.position + Vector2(x * cell, y * cell), Vector2(cell, cell)).intersection(rect)
			ci.draw_rect(r, Color("e8b4c8") if (x + y) % 2 == 0 else Color("f4d9e4"))
	var c := rect.get_center() + Vector2(0, rect.size.y * 0.12)
	var radius := rect.size.x * 0.26
	ci.draw_set_transform(c, -PI / 2, Vector2.ONE)
	ToyArt.draw(ci, &"knight", radius, 0.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var crown := c + Vector2(0, -radius - rect.size.x * 0.12)
	var w := rect.size.x * 0.22
	(
		ci
		. draw_colored_polygon(
			PackedVector2Array(
				[
					crown + Vector2(-w, w * 0.4),
					crown + Vector2(-w, -w * 0.2),
					crown + Vector2(-w * 0.5, w * 0.1),
					crown + Vector2(0, -w * 0.45),
					crown + Vector2(w * 0.5, w * 0.1),
					crown + Vector2(w, -w * 0.2),
					crown + Vector2(w, w * 0.4),
				]
			),
			Pal.GOLD
		)
	)
