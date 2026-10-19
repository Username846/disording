extends Node
## Local-only play statistics used to tune each day to 5–15 minutes (PLAN.md §3.3).
## Nothing here ever leaves the device.

const PATH := "user://disording/telemetry.json"
const KEEP_RUNS := 30

var runs: Dictionary = {}  # "day" -> Array of {t, outcome, seconds, reason}


func _ready() -> void:
	if App.test_mode:
		return
	if FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			runs = parsed


func record_run(day: int, outcome: String, seconds: float, reason: String = "") -> void:
	var key := str(day)
	var list: Array = runs.get(key, [])
	(
		list
		. append(
			{
				"t": int(Time.get_unix_time_from_system()),
				"outcome": outcome,
				"seconds": snappedf(seconds, 0.1),
				"reason": reason,
			}
		)
	)
	while list.size() > KEEP_RUNS:
		list.pop_front()
	runs[key] = list
	if App.test_mode or not SaveService.persistent:
		return
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(runs))


func summary(day: int) -> Dictionary:
	var list: Array = runs.get(str(day), [])
	var clears: Array[float] = []
	for run: Dictionary in list:
		if run.get("outcome") == "success":
			clears.append(float(run["seconds"]))
	clears.sort()
	var median := clears[int(clears.size() / 2.0)] if not clears.is_empty() else 0.0
	return {"runs": list.size(), "clears": clears.size(), "median_clear": median}
