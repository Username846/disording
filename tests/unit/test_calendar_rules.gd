extends TestCase

const S := CalendarRules.DoorState


func _days(entries: Dictionary) -> Dictionary:
	var out := {}
	for n: int in entries:
		var d := SaveSchema.new_day()
		d.merge(entries[n], true)
		out[str(n)] = d
	return out


func test_fresh_calendar() -> void:
	var days := {}
	check_eq(CalendarRules.state(1, days, "2026-11-01", true), S.OPEN)
	check_eq(CalendarRules.state(1, days, "2026-11-01", false), S.BEING_PAINTED)
	check_eq(CalendarRules.state(2, days, "2026-11-01", true), S.LOCKED)
	check_eq(CalendarRules.state(100, days, "2026-11-01", true), S.LOCKED)
	check_eq(CalendarRules.newest_unlocked(days, "2026-11-01"), 1)


func test_next_door_opens_the_following_day() -> void:
	var days := _days({1: {"completed_on": "2026-11-01", "attempts": 2}})
	check_eq(CalendarRules.state(1, days, "2026-11-01", true), S.COMPLETED)
	check_eq(CalendarRules.state(2, days, "2026-11-01", true), S.UNLOCKS_TOMORROW)
	check_eq(CalendarRules.state(3, days, "2026-11-01", true), S.LOCKED)
	check_eq(CalendarRules.state(2, days, "2026-11-02", true), S.OPEN)
	check_eq(CalendarRules.state(2, days, "2026-12-25", true), S.OPEN)
	check_eq(CalendarRules.state(3, days, "2026-12-25", true), S.LOCKED)


func test_only_one_new_door_per_day() -> void:
	var days := _days({1: {"completed_on": "2026-11-01"}, 2: {"completed_on": "2026-11-02"}})
	check_eq(CalendarRules.state(3, days, "2026-11-02", true), S.UNLOCKS_TOMORROW)
	check_eq(CalendarRules.state(3, days, "2026-11-03", true), S.OPEN)
	check_eq(CalendarRules.newest_unlocked(days, "2026-11-03"), 3)


func test_played_and_unbuilt_states() -> void:
	var days := _days({1: {"completed_on": "2026-11-01"}, 2: {"attempts": 1}})
	check_eq(CalendarRules.state(2, days, "2026-11-05", true), S.PLAYED)
	check_eq(CalendarRules.state(2, days, "2026-11-05", false), S.BEING_PAINTED)


func test_year_boundary() -> void:
	var days := _days({1: {"completed_on": "2026-12-31"}})
	check_eq(CalendarRules.state(2, days, "2026-12-31", true), S.UNLOCKS_TOMORROW)
	check_eq(CalendarRules.state(2, days, "2027-01-01", true), S.OPEN)


func test_star_count_ignores_day_zero() -> void:
	var days := _days({0: {"star": true}, 3: {"star": true}, 9: {"star": true}})
	check_eq(CalendarRules.star_count(days), 2)
	check(CalendarRules.has_star(days, 3), "day 3 star")
