extends TestCase

var _log: Array = []


func _recognizer() -> GestureRecognizer:
	_log.clear()
	var g := GestureRecognizer.new()
	g.tapped.connect(func(p: Vector2) -> void: _log.append(["tap", p]))
	g.double_tapped.connect(func(_p: Vector2) -> void: _log.append(["double"]))
	g.long_pressed.connect(func(_p: Vector2) -> void: _log.append(["long"]))
	g.drag_started.connect(func(_s: Vector2, _p: Vector2) -> void: _log.append(["drag_start"]))
	g.drag_ended.connect(func(_p: Vector2, _v: Vector2) -> void: _log.append(["drag_end"]))
	g.swiped.connect(func(d: Vector2, _v: Vector2, _s: Vector2) -> void: _log.append(["swipe", d]))
	g.pinched.connect(func(f: float, _c: Vector2) -> void: _log.append(["pinch", f > 1.0]))
	return g


func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	return e


func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	return e


func _kinds() -> Array:
	return _log.map(func(entry: Array) -> String: return entry[0])


func test_tap_and_double_tap() -> void:
	var g := _recognizer()
	g.feed(_touch(0, Vector2(100, 100), true), 0)
	g.feed(_touch(0, Vector2(103, 101), false), 120)
	g.feed(_touch(0, Vector2(104, 100), true), 250)
	g.feed(_touch(0, Vector2(104, 100), false), 330)
	check_eq(_kinds(), ["tap", "tap", "double"])


func test_long_press_suppresses_tap() -> void:
	var g := _recognizer()
	g.feed(_touch(0, Vector2(50, 50), true), 0)
	g.update(300)
	check_eq(_kinds(), [])
	g.update(460)
	g.feed(_touch(0, Vector2(50, 50), false), 700)
	check_eq(_kinds(), ["long"])


func test_drag_and_swipe() -> void:
	var g := _recognizer()
	g.feed(_touch(0, Vector2(100, 300), true), 0)
	for i in range(1, 6):
		g.feed(_drag(0, Vector2(100 + i * 40, 300)), i * 16)
	g.feed(_touch(0, Vector2(300, 300), false), 90)
	check_eq(_kinds(), ["drag_start", "drag_end", "swipe"])
	check_eq(_log[2][1], Vector2.RIGHT)


func test_slow_drag_is_not_a_swipe() -> void:
	var g := _recognizer()
	g.feed(_touch(0, Vector2(100, 300), true), 0)
	for i in range(1, 11):
		g.feed(_drag(0, Vector2(100, 300 - i * 6)), i * 100)
	g.feed(_touch(0, Vector2(100, 240), false), 1100)
	check_eq(_kinds(), ["drag_start", "drag_end"])


func test_pinch_and_wheel() -> void:
	var g := _recognizer()
	g.feed(_touch(0, Vector2(100, 100), true), 0)
	g.feed(_touch(1, Vector2(200, 100), true), 10)
	g.feed(_drag(1, Vector2(260, 100)), 30)
	g.feed(_touch(1, Vector2(260, 100), false), 60)
	g.feed(_touch(0, Vector2(100, 100), false), 70)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	g.feed(wheel, 80)
	check_eq(_log, [["pinch", true], ["pinch", false]])
