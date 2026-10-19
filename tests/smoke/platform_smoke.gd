extends Node
## End-to-end platform smoke test (PLAN.md §7.3): title → calendar → every implemented day,
## fuzzed input, forced success/fail/star, unlock rules, back to the calendar.

const FUZZ_SECONDS := 40.0
const TODAY := "2026-11-01"

var failures := PackedStringArray()


func run() -> PackedStringArray:
	Clock.fake_date = TODAY
	SaveService.reset(TODAY)
	await Router.goto_title()
	_check(Router.current is TitleScreen, "title screen shows")
	await Router.goto_calendar()
	await _frames(3)
	_check(Router.current is CalendarScreen, "calendar shows")
	_check_eq(Calendar.state(2), CalendarRules.DoorState.LOCKED, "door 2 locked on a fresh save")
	var days := DayRegistry.implemented_days()
	_check(not days.is_empty(), "at least one implemented day")
	for n in days:
		await _exercise_day(n)
	_check_rollback()
	print("[tests] smoke: %d day(s) exercised, %d failures" % [days.size(), failures.size()])
	return failures


func _exercise_day(n: int) -> void:
	var label := "day %d" % n
	Clock.fake_date = TODAY
	await Router.start_day(n)
	var host := Router.current as DayHost
	_check(host != null, "%s: host created" % label)
	if host == null:
		return
	if not await _until(func() -> bool: return host.phase == DayHost.Phase.RUNNING, 1200):
		_fail("%s: never reached RUNNING" % label)
		return
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	await _fuzz(host, FUZZ_SECONDS)
	if host.phase == DayHost.Phase.RESULTS or host.phase == DayHost.Phase.PAUSED:
		host._begin(false)
		await _frames(2)

	host.qa_force(&"star")
	await _frames(2)
	_check(Calendar.has_star(n), "%s: star saved" % label)

	var fails_before := int(SaveService.day(n)["fails"])
	host.qa_force(&"fail")
	await _until(func() -> bool: return host.phase == DayHost.Phase.RESULTS, 120)
	_check_eq(host.phase, DayHost.Phase.RESULTS, "%s: fail shows results" % label)
	_check_eq(int(SaveService.day(n)["fails"]), fails_before + 1, "%s: fail recorded" % label)
	_check_eq(SaveService.day(n)["completed_on"], "", "%s: fail does not complete" % label)

	host._begin(false)
	await _until(func() -> bool: return host.phase == DayHost.Phase.RUNNING, 120)
	host.qa_force(&"success")
	await _until(func() -> bool: return host.phase == DayHost.Phase.RESULTS, 120)
	_check_eq(SaveService.day(n)["completed_on"], TODAY, "%s: success completes the door" % label)
	if n >= 1 and n < CalendarRules.DAY_COUNT:
		_check_eq(Calendar.state(n + 1), CalendarRules.DoorState.UNLOCKS_TOMORROW, "%s: next door waits a day" % label)
		Clock.fake_date = IsoDate.add_days(TODAY, 1)
		_check(Calendar.state(n + 1) != CalendarRules.DoorState.LOCKED, "%s: next door opens tomorrow" % label)
		_check(Calendar.state(n + 1) != CalendarRules.DoorState.UNLOCKS_TOMORROW, "%s: countdown ends" % label)
		Clock.fake_date = TODAY

	host.leave()
	await _until(func() -> bool: return Router.current is CalendarScreen, 300)
	_check(Router.current is CalendarScreen, "%s: leave returns to calendar" % label)
	await _frames(5)
	var leaked := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) - orphans_before
	_check(leaked <= 0, "%s: %d orphan node(s) leaked" % [label, leaked])


func _check_rollback() -> void:
	SaveService.data["last_seen_date"] = "2026-11-05"
	Clock.fake_date = "2026-11-02"
	_check_eq(Clock.today(), "2026-11-05", "winding the clock back never re-locks doors")
	Clock.fake_date = TODAY
	SaveService.data["last_seen_date"] = TODAY


## Random taps, drags, swipes and holds across the play area (avoiding the pause button).
func _fuzz(host: DayHost, seconds: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var view := App.visible_size()
	var frames := int(seconds * 60.0)
	var frame := 0
	while frame < frames:
		if host.phase != DayHost.Phase.RUNNING:
			host._begin(false)
			await _frames(2)
		var start := Vector2(rng.randf_range(20, view.x - 20), rng.randf_range(120, view.y - 20))
		_touch(start, true)
		var steps := rng.randi_range(0, 12)
		var dir := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(5, 40)
		var pos := start
		for i in steps:
			pos = (pos + dir).clamp(Vector2(1, 120), view - Vector2.ONE)
			var drag := InputEventScreenDrag.new()
			drag.position = pos
			drag.relative = dir
			Input.parse_input_event(drag)
			await _frames(1)
			frame += 1
		if rng.randf() < 0.15:
			await _frames(35)
			frame += 35
		_touch(pos, false)
		await _frames(rng.randi_range(1, 8))
		frame += 8


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().process_frame
	return condition.call()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("%s (expected %s, got %s)" % [message, var_to_str(expected), var_to_str(actual)])


func _fail(message: String) -> void:
	failures.append("smoke: " + message)
