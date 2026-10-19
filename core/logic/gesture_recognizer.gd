class_name GestureRecognizer
extends RefCounted
## Turns touch (and mouse, emulated as touch index 0) into one-pointer gestures (PLAN.md §5).
## Feed it every input event with feed(), and call update() once per frame for long-press.
## Distances are in viewport units (1280x720 reference).

signal pressed(pos: Vector2)
signal released(pos: Vector2)
signal tapped(pos: Vector2)
signal double_tapped(pos: Vector2)
signal long_pressed(pos: Vector2)
signal drag_started(start: Vector2, pos: Vector2)
signal dragged(pos: Vector2, relative: Vector2)
signal drag_ended(pos: Vector2, velocity: Vector2)
signal swiped(direction: Vector2, velocity: Vector2, start: Vector2)
## factor > 1 zooms in. Emitted by two-finger pinch and by the mouse wheel.
signal pinched(factor: float, center: Vector2)

var slop := 12.0
var double_tap_ms := 300
var long_press_ms := 450
var swipe_min_speed := 900.0
var wheel_step := 1.1

var _touches := {}  # index -> TouchTrack
var _primary := -1
var _last_tap_ms := -100000
var _last_tap_pos := Vector2.INF
var _pinch_distance := 0.0


class TouchTrack:
	var start: Vector2
	var pos: Vector2
	var start_ms: int
	var dragging := false
	var long_fired := false
	var samples: Array[Vector3] = []  # x, y, time_ms

	func add_sample(p: Vector2, t: int) -> void:
		samples.append(Vector3(p.x, p.y, t))
		if samples.size() > 6:
			samples.pop_front()

	func velocity(now_ms: int) -> Vector2:
		# Velocity over roughly the last 80 ms of movement.
		if samples.size() < 2:
			return Vector2.ZERO
		var last := samples[-1]
		if now_ms - int(last.z) > 100:
			return Vector2.ZERO
		var first := samples[0]
		for s in samples:
			if last.z - s.z <= 80.0:
				first = s
				break
		var dt := (last.z - first.z) / 1000.0
		if dt <= 0.0:
			return Vector2.ZERO
		return Vector2(last.x - first.x, last.y - first.y) / dt


func is_active() -> bool:
	return _primary != -1


func is_dragging() -> bool:
	return _primary != -1 and _touches.has(_primary) and (_touches[_primary] as TouchTrack).dragging


func reset() -> void:
	_touches.clear()
	_primary = -1
	_pinch_distance = 0.0


## Returns true when the event was a pointer event this recognizer consumed.
func feed(event: InputEvent, now_ms: int = -1) -> bool:
	if now_ms < 0:
		now_ms = Time.get_ticks_msec()
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_down(touch.index, touch.position, now_ms)
		else:
			_on_up(touch.index, touch.position, now_ms, touch.canceled)
		return true
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_on_move(drag.index, drag.position, now_ms)
		return true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			pinched.emit(wheel_step, mb.position)
			return true
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pinched.emit(1.0 / wheel_step, mb.position)
			return true
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		pinched.emit(mg.factor, mg.position)
		return true
	return false


func update(now_ms: int = -1) -> void:
	if _primary == -1 or not _touches.has(_primary):
		return
	if now_ms < 0:
		now_ms = Time.get_ticks_msec()
	var t: TouchTrack = _touches[_primary]
	if not t.dragging and not t.long_fired and now_ms - t.start_ms >= long_press_ms:
		t.long_fired = true
		long_pressed.emit(t.pos)


func _on_down(index: int, pos: Vector2, now_ms: int) -> void:
	var t := TouchTrack.new()
	t.start = pos
	t.pos = pos
	t.start_ms = now_ms
	t.add_sample(pos, now_ms)
	_touches[index] = t
	if _primary == -1:
		_primary = index
		pressed.emit(pos)
	elif _touches.size() == 2:
		# A second finger turns the gesture into a pinch; the primary drag stops counting.
		_pinch_distance = _pinch_span()
		var primary: TouchTrack = _touches[_primary]
		if primary.dragging:
			drag_ended.emit(primary.pos, Vector2.ZERO)
		primary.dragging = false
		primary.long_fired = true


func _on_move(index: int, pos: Vector2, now_ms: int) -> void:
	if not _touches.has(index):
		return
	var t: TouchTrack = _touches[index]
	var relative := pos - t.pos
	t.pos = pos
	t.add_sample(pos, now_ms)
	if _touches.size() >= 2:
		var span := _pinch_span()
		if _pinch_distance > 0.0 and span > 0.0:
			pinched.emit(span / _pinch_distance, _pinch_center())
		_pinch_distance = span
		return
	if index != _primary:
		return
	if not t.dragging and pos.distance_to(t.start) > slop:
		t.dragging = true
		drag_started.emit(t.start, pos)
	if t.dragging:
		dragged.emit(pos, relative)


func _on_up(index: int, pos: Vector2, now_ms: int, canceled: bool) -> void:
	if not _touches.has(index):
		return
	var t: TouchTrack = _touches[index]
	t.pos = pos
	_touches.erase(index)
	if index != _primary:
		_pinch_distance = 0.0
		return
	_primary = -1
	released.emit(pos)
	if canceled:
		if t.dragging:
			drag_ended.emit(pos, Vector2.ZERO)
		return
	if t.dragging:
		var velocity := t.velocity(now_ms)
		drag_ended.emit(pos, velocity)
		if velocity.length() >= swipe_min_speed:
			swiped.emit(_cardinal(velocity), velocity, t.start)
		return
	if t.long_fired:
		return
	# Any short, still press that never became a long-press or drag counts as a tap.
	if pos.distance_to(t.start) <= slop:
		tapped.emit(pos)
		if now_ms - _last_tap_ms <= double_tap_ms and pos.distance_to(_last_tap_pos) <= slop * 3.0:
			double_tapped.emit(pos)
			_last_tap_ms = -100000
		else:
			_last_tap_ms = now_ms
			_last_tap_pos = pos


func _pinch_span() -> float:
	var points: Array[Vector2] = []
	for t: TouchTrack in _touches.values():
		points.append(t.pos)
		if points.size() == 2:
			break
	return points[0].distance_to(points[1]) if points.size() == 2 else 0.0


func _pinch_center() -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for t: TouchTrack in _touches.values():
		sum += t.pos
		count += 1
	return sum / maxf(1.0, count)


static func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0.0 else Vector2.UP
