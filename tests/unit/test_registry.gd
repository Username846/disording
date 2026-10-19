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
		check(info.inspired_by != "", "day %d names the game it is inspired by" % n)
		check(info.est_minutes >= 5 and info.est_minutes <= 15, "day %d est 5-15 min" % n)
		check(info.palette.size() >= 3, "day %d palette" % n)
		check(not titles.has(info.title), "day %d unique title" % n)
		titles[info.title] = true
		if DayRegistry.implemented(n):
			check_eq(info.hints.size(), 3, "day %d needs three intro hints" % n)


func test_day_zero_is_debug_only_fixture() -> void:
	if OS.is_debug_build():
		check(DayRegistry.implemented(0), "Day 0 exists in debug builds")


func test_inspired_by_matches_game_list() -> void:
	var file := FileAccess.open("res://game_list.txt", FileAccess.READ)
	if file == null:
		return  # game_list.txt is not exported; this check runs in the editor/CI only.
	var lines := file.get_as_text().split("\n", false)
	check_eq(lines.size(), CalendarRules.DAY_COUNT, "game_list.txt has 100 lines")
	for line in lines:
		var dot := line.find(". ")
		var n := line.substr(0, dot).to_int()
		var title := line.substr(dot + 2).split(" — ")[0].strip_edges()
		var info := DayRegistry.info(n)
		if info != null:
			check_eq(info.inspired_by, title, "day %d inspired_by" % n)
