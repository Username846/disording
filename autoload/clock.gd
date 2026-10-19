extends Node
## Local calendar time with dev/test overrides (PLAN.md §3.3, §4.2).
## today() never goes backwards: winding the device clock back can't re-lock a door.

signal date_changed(today: String)

## When set ("YYYY-MM-DD"), replaces the system date. Dev panel and tests only.
var fake_date := ""

var _last_today := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_today = today()
	SaveService.touch_seen_date(_last_today)
	var timer := Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(check_rollover)
	add_child(timer)
	App.focus_gained.connect(check_rollover)


func system_today() -> String:
	return fake_date if fake_date != "" else Time.get_date_string_from_system(false)


func today() -> String:
	return IsoDate.later(system_today(), String(SaveService.data.get("last_seen_date", "")))


func seconds_until_midnight() -> int:
	var t := Time.get_time_dict_from_system(false)
	return maxi(1, 86400 - (int(t.hour) * 3600 + int(t.minute) * 60 + int(t.second)))


## Dev/test: jump the calendar. Moving backwards also rewinds the monotonic guard.
func set_fake_date(date: String) -> void:
	fake_date = date
	if date != "" and date < String(SaveService.data["last_seen_date"]):
		SaveService.data["last_seen_date"] = date
	check_rollover()


func check_rollover() -> void:
	var now := today()
	SaveService.touch_seen_date(now)
	if now != _last_today:
		_last_today = now
		date_changed.emit(now)


static func format_countdown(seconds: int) -> String:
	var h := int(seconds / 3600.0)
	var m := int((seconds % 3600) / 60.0)
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm %02ds" % [m, seconds % 60]
