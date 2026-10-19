extends Node
## Loads the 100 DayInfo resources (plus the debug-only Day 0) (PLAN.md §3.3).

const INFO_PATH := "res://days/day_%03d/info.tres"

var _infos: Dictionary = {}  # int -> DayInfo
var _implemented: Dictionary = {}  # int -> bool


func _ready() -> void:
	for n in range(0, CalendarRules.DAY_COUNT + 1):
		var path := INFO_PATH % n
		if ResourceLoader.exists(path):
			var info := load(path) as DayInfo
			if info != null:
				_infos[n] = info
				_implemented[n] = info.scene_path != "" and ResourceLoader.exists(info.scene_path)


func info(n: int) -> DayInfo:
	return _infos.get(n)


func has_day(n: int) -> bool:
	return _infos.has(n)


func implemented(n: int) -> bool:
	return bool(_implemented.get(n, false))


func implemented_days() -> Array[int]:
	var out: Array[int] = []
	for n: int in _implemented:
		if _implemented[n]:
			out.append(n)
	out.sort()
	return out


func title(n: int) -> String:
	var i := info(n)
	return i.title if i != null else "Door %d" % n
