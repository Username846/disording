extends RefCounted
## Door art shown behind this day's door once it is completed (procedural, no textures).


func draw(ci: CanvasItem, rect: Rect2) -> void:
	# TEMPLATE: draw an emblem of the day inside `rect` (the calendar clips the arch corners).
	ci.draw_rect(rect, Pal.NIGHT_3)
	Glyphs.star(ci, rect.get_center(), rect.size.x * 0.3, Pal.GOLD)
