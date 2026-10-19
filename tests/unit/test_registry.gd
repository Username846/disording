extends TestCase


func test_all_hundred_days_registered() -> void:
	var titles := {}
	for n in range(1, CalendarRules.DAY_COUNT + 1):
		var info := DayRegistry.info(n)
		check(info != null, "day %d has info.tres" % n)
		if info == null:
			continue
		check_eq(info.day, n)
		check(info.title != "" and info.genre != "", "day %d title/genre" % n)
		check(info.est_minutes >= 5 and info.est_minutes <= 15, "day %d est 5-15 min" % n)
		check(info.palette.size() >= 3, "day %d palette" % n)
		check(not titles.has(info.title), "day %d unique title" % n)
		titles[info.title] = true
		if DayRegistry.implemented(n):
			check_eq(info.hints.size(), 3, "day %d needs three intro hints" % n)


func test_day_zero_is_debug_only_fixture() -> void:
	if OS.is_debug_build():
		check(DayRegistry.implemented(0), "Day 0 exists in debug builds")
