class_name CalendarRules
extends RefCounted
## Pure unlock rules for the 100 doors (PLAN.md §4). No engine state: everything is passed in.

enum DoorState { LOCKED, UNLOCKS_TOMORROW, OPEN, PLAYED, COMPLETED, BEING_PAINTED }

const DAY_COUNT := 100


static func day_record(days: Dictionary, n: int) -> Dictionary:
	return days.get(str(n), {})


static func completed_on(days: Dictionary, n: int) -> String:
	return String(day_record(days, n).get("completed_on", ""))


static func is_completed(days: Dictionary, n: int) -> bool:
	return completed_on(days, n) != ""


static func has_star(days: Dictionary, n: int) -> bool:
	return bool(day_record(days, n).get("star", false))


## Door N is unlocked once door N-1 was first completed on an earlier local date.
static func is_unlocked(n: int, days: Dictionary, today: String) -> bool:
	if n <= 1:
		return true
	var prev := completed_on(days, n - 1)
	return prev != "" and today > prev


static func state(n: int, days: Dictionary, today: String, implemented: bool) -> DoorState:
	if not is_unlocked(n, days, today):
		var prev := completed_on(days, n - 1)
		return DoorState.UNLOCKS_TOMORROW if prev != "" else DoorState.LOCKED
	if not implemented:
		return DoorState.BEING_PAINTED
	if is_completed(days, n):
		return DoorState.COMPLETED
	if int(day_record(days, n).get("attempts", 0)) > 0:
		return DoorState.PLAYED
	return DoorState.OPEN


## The highest-numbered unlocked door (what the "Today" button jumps to).
static func newest_unlocked(days: Dictionary, today: String, count: int = DAY_COUNT) -> int:
	var newest := 1
	for n in range(2, count + 1):
		if is_unlocked(n, days, today):
			newest = n
		else:
			break
	return newest


static func star_count(days: Dictionary) -> int:
	var total := 0
	for key: String in days:
		if key != "0" and has_star(days, key.to_int()):
			total += 1
	return total
