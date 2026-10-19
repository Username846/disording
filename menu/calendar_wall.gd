class_name CalendarWall
extends Control
## The 100-door façade: one custom-drawn, scrollable control (PLAN.md §4.1).
## Drawing everything in one node keeps the menu to a handful of draw batches.

signal door_tapped(n: int, at: Vector2)

const COLS := 10
const ROWS := 10
const SIDE_MARGIN := 36.0
const ROOF_HEIGHT := 150.0
const LOCKED := CalendarRules.DoorState.LOCKED
const UNLOCKS_TOMORROW := CalendarRules.DoorState.UNLOCKS_TOMORROW
const OPEN := CalendarRules.DoorState.OPEN
const PLAYED := CalendarRules.DoorState.PLAYED
const COMPLETED := CalendarRules.DoorState.COMPLETED
const BEING_PAINTED := CalendarRules.DoorState.BEING_PAINTED
## Wall colours per floor, from the ground floor (doors 1–10) up: winter → spring → summer →
## autumn → winter. Door 1 is bottom-left; the numbers climb floor by floor to 100 under the roof.
const FLOOR_COLORS: Array[Color] = [
	Color("3b4a6b"),
	Color("3f5470"),
	Color("4b6a5a"),
	Color("557353"),
	Color("7a6a45"),
	Color("826344"),
	Color("8a5235"),
	Color("7a4636"),
	Color("4a4a6a"),
	Color("3e3d5c"),
]

## Space above the wall covered by the top bar.
var top_inset := 96.0
var bottom_inset := 40.0
var scroll := 0.0

var _velocity := 0.0
var _states: Array[int] = []
var _stars: Array[bool] = []
var _shake: Dictionary = {}  # n -> seconds left
var _gestures := GestureRecognizer.new()
var _t := 0.0
var _redraw_accum := 0.0
var _scroll_tween: Tween
var _font: Font
var _bold: Font
var _door_art: Dictionary = {}  # day -> door art instance


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_font = UiTheme.font(500)
	_bold = UiTheme.font(600)
	_gestures.dragged.connect(_on_dragged)
	_gestures.drag_ended.connect(func(_p: Vector2, v: Vector2) -> void: _velocity = -v.y)
	_gestures.pressed.connect(func(_p: Vector2) -> void: _velocity = 0.0)
	_gestures.tapped.connect(_on_tapped)
	Calendar.refreshed.connect(refresh)
	resized.connect(func() -> void: set_scroll(scroll))
	refresh()


func refresh() -> void:
	_states.resize(ROWS * COLS + 1)
	_stars.resize(ROWS * COLS + 1)
	for n in range(1, ROWS * COLS + 1):
		_states[n] = Calendar.state(n)
		_stars[n] = Calendar.has_star(n)
	queue_redraw()


func state_of(n: int) -> int:
	return _states[n]


func row_height() -> float:
	return door_size().y + 66.0


func door_size() -> Vector2:
	var col_w := (size.x - SIDE_MARGIN * 2.0) / COLS
	var w := clampf(col_w * 0.72, 72.0, 150.0)
	return Vector2(w, w * 1.3)


func content_height() -> float:
	return top_inset + ROOF_HEIGHT + ROWS * row_height() + bottom_inset + 40.0


func max_scroll() -> float:
	return maxf(0.0, content_height() - size.y)


func set_scroll(value: float) -> void:
	scroll = clampf(value, 0.0, max_scroll())
	queue_redraw()


## Rect of door n in content coordinates (before scrolling).
func door_rect(n: int) -> Rect2:
	var i := n - 1
	var floor_index := int(i / float(COLS))
	var col := i % COLS
	var col_w := (size.x - SIDE_MARGIN * 2.0) / COLS
	var d := door_size()
	var x := SIDE_MARGIN + col_w * col + (col_w - d.x) * 0.5
	var y := top_inset + ROOF_HEIGHT + _screen_row(floor_index) * row_height() + 18.0
	return Rect2(x, y, d.x, d.y)


## Floors are counted from the ground; screen rows from the roof.
func _screen_row(floor_index: int) -> int:
	return ROWS - 1 - floor_index


func scroll_to_door(n: int, animate: bool = true) -> void:
	var r := door_rect(clampi(n, 1, ROWS * COLS))
	var target := clampf(r.get_center().y - size.y * 0.5, 0.0, max_scroll())
	if _scroll_tween:
		_scroll_tween.kill()
	_velocity = 0.0
	if not animate or Settings.reduce_motion():
		set_scroll(target)
		return
	_scroll_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_method(set_scroll, scroll, target, 0.6)


func shake(n: int) -> void:
	_shake[n] = 0.4


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_scroll(scroll - 90.0)
			accept_event()
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_scroll(scroll + 90.0)
			accept_event()
			return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_gestures.feed(event)
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_gestures.update()
	var dirty := false
	if absf(_velocity) > 5.0 and not _gestures.is_dragging():
		set_scroll(scroll + _velocity * delta)
		_velocity = lerpf(_velocity, 0.0, 1.0 - exp(-4.0 * delta))
		if scroll <= 0.0 or scroll >= max_scroll():
			_velocity = 0.0
		dirty = true
	for n: int in _shake.keys():
		_shake[n] = float(_shake[n]) - delta
		if _shake[n] <= 0.0:
			_shake.erase(n)
		dirty = true
	_redraw_accum += delta
	if dirty or _redraw_accum >= 1.0 / 20.0:
		_redraw_accum = 0.0
		queue_redraw()


func _on_dragged(_pos: Vector2, relative: Vector2) -> void:
	if _scroll_tween:
		_scroll_tween.kill()
	set_scroll(scroll - relative.y)


func _on_tapped(pos: Vector2) -> void:
	var content := pos + Vector2(0, scroll)
	for n in range(1, ROWS * COLS + 1):
		if door_rect(n).grow(8.0).has_point(content):
			door_tapped.emit(n, pos)
			return


func _draw() -> void:
	var view := size
	draw_rect(Rect2(Vector2.ZERO, view), Pal.NIGHT)
	var off := Vector2(0, -scroll)
	_draw_roof(off)
	var rh := row_height()
	for floor_index in ROWS:
		var y := top_inset + ROOF_HEIGHT + _screen_row(floor_index) * rh - scroll
		if y > view.y or y + rh < 0.0:
			continue
		_draw_floor(floor_index, y, rh)
		for c in COLS:
			var n := floor_index * COLS + c + 1
			_draw_door(n, door_rect(n).position + off)
	var base_y := top_inset + ROOF_HEIGHT + ROWS * rh - scroll
	draw_rect(Rect2(0, base_y, view.x, view.y), Pal.SNOW)


func _draw_roof(off: Vector2) -> void:
	var w := size.x
	var top := top_inset + off.y
	var eave := top + ROOF_HEIGHT
	draw_colored_polygon(
		PackedVector2Array([Vector2(8, eave), Vector2(w * 0.5, top + 6), Vector2(w - 8, eave)]), Pal.INK
	)
	draw_rect(Rect2(w * 0.7, top + 30, 46, 80), Pal.INK)
	draw_polyline(
		PackedVector2Array([Vector2(0, eave + 4), Vector2(w * 0.5, top + 2), Vector2(w, eave + 4)]),
		Pal.SNOW,
		10.0,
		true
	)
	var title := "Advent Doors"
	var fs := 34
	var tw := _bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_bold, Vector2((w - tw) * 0.5, eave - 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.GOLD)


func _draw_floor(floor_index: int, y: float, rh: float) -> void:
	var color := FLOOR_COLORS[floor_index]
	draw_rect(Rect2(0, y, size.x, rh), color)
	# Brick courses give the wall some texture without textures.
	var line := color.darkened(0.12)
	for k in range(1, 4):
		draw_line(Vector2(0, y + k * rh / 4.0), Vector2(size.x, y + k * rh / 4.0), line, 2.0)
	# Ledge with snow under the doors.
	var ledge_y := y + rh - 30.0
	draw_rect(Rect2(0, ledge_y, size.x, 14), color.darkened(0.35))
	if floor_index <= 1 or floor_index >= 8:
		draw_rect(Rect2(0, ledge_y - 5, size.x, 7), Color(Pal.SNOW, 0.9))


func _draw_door(n: int, pos: Vector2) -> void:
	var d := door_size()
	var state: int = _states[n]
	if _shake.has(n):
		pos.x += sin(_t * 60.0) * 6.0 * float(_shake[n]) / 0.4
	var rect := Rect2(pos, d)
	var frame := rect.grow(7.0)
	_draw_arch(Rect2(frame.position + Vector2(4, 6), frame.size), Pal.SHADOW)
	_draw_arch(frame, Pal.WOOD_DARK.darkened(0.25))
	var info := DayRegistry.info(n)
	match state:
		COMPLETED:
			_draw_interior(rect, info, true)
			_draw_open_leaf(rect, 0.18)
		PLAYED:
			_draw_interior(rect, info, false)
			_draw_open_leaf(rect, 0.72)
		_:
			var wood := Pal.WOOD
			if state == LOCKED:
				wood = Pal.WOOD_DARK
			elif state == OPEN:
				wood = Pal.WOOD_LIGHT
			elif state == BEING_PAINTED:
				wood = Color("d9d2c3")
			_draw_arch(rect, wood)
			_draw_panels(rect, wood)
	match state:
		LOCKED:
			Glyphs.lock(self, rect.get_center() + Vector2(0, d.y * 0.08), d.x * 0.2, Color(Pal.SNOW_DIM, 0.75))
		UNLOCKS_TOMORROW:
			var glow := 0.45 + 0.35 * sin(_t * 3.0)
			_draw_arch_outline(rect.grow(3.0), Color(Pal.GOLD, glow), 4.0)
			Glyphs.clock(self, rect.get_center(), d.x * 0.16, Pal.GOLD)
		OPEN:
			_draw_wreath(rect)
			_draw_shimmer(rect)
		BEING_PAINTED:
			_draw_wet_paint(rect)
	if _stars[n]:
		Glyphs.star(self, frame.position + Vector2(frame.size.x - 6, 6), d.x * 0.2 + 2.0, Pal.GOLD_DEEP)
		Glyphs.star(self, frame.position + Vector2(frame.size.x - 6, 4), d.x * 0.2, Pal.GOLD)
	_draw_plaque(n, rect, state)


func _draw_plaque(n: int, rect: Rect2, state: int) -> void:
	var plaque := Rect2(rect.get_center().x - 34, rect.end.y + 12, 68, 34)
	var bright := state == OPEN or state == PLAYED or state == COMPLETED
	draw_rect(plaque, Pal.GOLD if bright else Color(Pal.INK, 0.8))
	var text := str(n)
	var fs := 24
	var tw := _bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var color := Pal.INK if bright else Pal.SNOW_DIM
	draw_string(
		_bold,
		Vector2(plaque.get_center().x - tw * 0.5, plaque.end.y - 8),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		color
	)


## Door outline: a rectangle with a round arch on top.
func _arch_points(rect: Rect2) -> PackedVector2Array:
	var r := rect.size.x * 0.5
	var pts := PackedVector2Array([rect.end, Vector2(rect.position.x, rect.end.y)])
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(rect.position.x + r, rect.position.y + r) + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw_arch(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(_arch_points(rect), color)


func _draw_arch_outline(rect: Rect2, color: Color, width: float) -> void:
	var pts := _arch_points(rect)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)


func _draw_panels(rect: Rect2, wood: Color) -> void:
	var inset := rect.grow(-rect.size.x * 0.16)
	var line := wood.darkened(0.25)
	var upper := Rect2(inset.position + Vector2(0, rect.size.x * 0.32), Vector2(inset.size.x, inset.size.y * 0.32))
	var lower := Rect2(inset.position + Vector2(0, inset.size.y * 0.58), Vector2(inset.size.x, inset.size.y * 0.36))
	draw_rect(upper, line, false, 3.0)
	draw_rect(lower, line, false, 3.0)
	draw_circle(Vector2(rect.end.x - rect.size.x * 0.14, rect.get_center().y + 6), 4.0, Pal.GOLD_DEEP)


func _draw_interior(rect: Rect2, info: DayInfo, full: bool) -> void:
	var main := info.color(0, Pal.SKY) if info != null else Pal.SKY
	var dark := info.color(2, main.darkened(0.5)) if info != null else main.darkened(0.5)
	_draw_arch(rect, dark)
	if not full:
		# Warm light spilling through the gap on the opening (right) side.
		var gap := Rect2(rect.position + Vector2(rect.size.x * 0.62, 0), Vector2(rect.size.x * 0.38, rect.size.y))
		draw_rect(gap.grow_individual(0, -rect.size.x * 0.3, 0, -3), Color(Pal.GOLD, 0.45))
		return
	_draw_arch(rect.grow(-4.0), main)
	if info != null and info.door_art != null:
		_draw_door_art(info, rect.grow(-4.0))
		return
	if info != null and info.thumbnail != null:
		draw_texture_rect(info.thumbnail, rect.grow(-6.0), false)
		return
	var title := info.title if info != null else ""
	var letter := title.substr(0, 1).to_upper()
	var fs := int(rect.size.x * 0.55)
	var tw := _bold.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(rect.get_center().x - tw * 0.5, rect.get_center().y + fs * 0.35)
	draw_string(_bold, at + Vector2(2, 3), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(dark, 0.8))
	draw_string(_bold, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.SNOW)


## Day-provided art, clipped to the arch by painting the two top corners back over it.
func _draw_door_art(info: DayInfo, rect: Rect2) -> void:
	if not _door_art.has(info.day):
		_door_art[info.day] = info.door_art.new()
	_door_art[info.day].draw(self, rect)
	var r := rect.size.x * 0.5
	var c := Vector2(rect.position.x + r, rect.position.y + r)
	var mask := info.color(2, Pal.NIGHT)
	for corner: Array in [[rect.position, PI], [Vector2(rect.end.x, rect.position.y), PI * 1.5]]:
		var pts := PackedVector2Array([corner[0]])
		for i in 7:
			var a: float = corner[1] + (PI * 0.5) * i / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, mask)


## The door leaf swung open on its left hinge: the arch squashed toward the hinge.
## `amount` is the leaf's visible width as a fraction of the doorway.
func _draw_open_leaf(rect: Rect2, amount: float) -> void:
	var pts := _arch_points(rect)
	var x0 := rect.position.x
	var lift := rect.size.y * 0.04 * (1.0 - amount)
	for i in pts.size():
		var k := (pts[i].x - x0) / rect.size.x
		pts[i] = Vector2(
			x0 + (pts[i].x - x0) * amount, pts[i].y + (lift * k if pts[i].y < rect.get_center().y else -lift * k)
		)
	var wood := Pal.WOOD.darkened(0.15 * (1.0 - amount))
	draw_colored_polygon(pts, wood)
	pts.append(pts[0])
	draw_polyline(pts, Pal.WOOD_DARK, 2.0, true)
	draw_circle(Vector2(x0 + rect.size.x * amount * 0.82, rect.get_center().y + 6), 3.5, Pal.GOLD_DEEP)


func _draw_wreath(rect: Rect2) -> void:
	var c := Vector2(rect.get_center().x, rect.position.y + rect.size.x * 0.5)
	var r := rect.size.x * 0.2
	draw_arc(c, r, 0.0, TAU, 24, Pal.GREEN, r * 0.45, true)
	draw_circle(c + Vector2(0, r), r * 0.22, Pal.RED)


func _draw_shimmer(rect: Rect2) -> void:
	if Settings.reduce_motion():
		return
	var k := fmod(_t * 0.5, 1.6) - 0.3
	if k < 0.0 or k > 1.0:
		return
	var x := rect.position.x + rect.size.x * k
	var band := PackedVector2Array(
		[
			Vector2(x, rect.position.y + rect.size.x * 0.3),
			Vector2(x + 14, rect.position.y + rect.size.x * 0.3),
			Vector2(x - 10, rect.end.y - 4),
			Vector2(x - 24, rect.end.y - 4),
		]
	)
	draw_colored_polygon(band, Color(1, 1, 1, 0.25))


func _draw_wet_paint(rect: Rect2) -> void:
	var sign_rect := Rect2(
		rect.position + Vector2(rect.size.x * 0.1, rect.size.y * 0.45), Vector2(rect.size.x * 0.8, rect.size.y * 0.22)
	)
	draw_rect(sign_rect, Color("f6f1d8"))
	draw_rect(sign_rect, Pal.RED, false, 2.0)
	var fs := int(rect.size.x * 0.15)
	var text := "WET PAINT"
	var tw := _bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(
		_bold,
		Vector2(sign_rect.get_center().x - tw * 0.5, sign_rect.get_center().y + fs * 0.35),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		Pal.RED
	)
