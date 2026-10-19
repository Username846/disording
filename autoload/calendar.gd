extends Node
## Door states for the menu, built on CalendarRules + SaveService + Clock (PLAN.md §4).

signal refreshed

## Dev panel: treat every built day as open (session only, never saved).
var dev_unlock_all := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Clock.date_changed.connect(func(_today: String) -> void: refreshed.emit())
	SaveService.changed.connect(func() -> void: refreshed.emit())


func days() -> Dictionary:
	return SaveService.data["days"]


func state(n: int) -> CalendarRules.DoorState:
	var implemented := DayRegistry.implemented(n)
	if dev_unlock_all and n >= 1:
		if not implemented:
			return CalendarRules.DoorState.BEING_PAINTED
		if CalendarRules.is_completed(days(), n):
			return CalendarRules.DoorState.COMPLETED
		return CalendarRules.DoorState.OPEN
	return CalendarRules.state(n, days(), Clock.today(), implemented)


func is_playable(n: int) -> bool:
	var s := state(n)
	return (
		s == CalendarRules.DoorState.OPEN
		or s == CalendarRules.DoorState.PLAYED
		or s == CalendarRules.DoorState.COMPLETED
	)


func has_star(n: int) -> bool:
	return CalendarRules.has_star(days(), n)


func star_count() -> int:
	return CalendarRules.star_count(days())


func newest_open() -> int:
	return CalendarRules.newest_unlocked(days(), Clock.today())
