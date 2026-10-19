extends Node
## Owns the save file: load, debounced atomic writes, save codes (PLAN.md §3.3, §3.5).
## Every other system reads and writes progress through this node.

signal changed

const DIR := "user://disording"

var data: Dictionary = {}
## False when the browser refuses storage (e.g. some private windows); play continues in memory.
var persistent := true
var path := ""

var _dirty := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var slot := App.save_slot()
	path = "%s/save%s.json" % [DIR, "" if slot == "main" else "_" + slot]
	if slot == "test":
		_delete(path)
	load_from_disk()
	if App.is_web() and not App.test_mode:
		JavaScriptBridge.eval(
			"if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); }", true
		)


func load_from_disk() -> void:
	var today := Time.get_date_string_from_system(false)
	var raw: Variant = null
	if FileAccess.file_exists(path):
		raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	data = SaveSchema.migrate(raw, today)
	changed.emit()


func day(n: int) -> Dictionary:
	return data["days"].get(str(n), SaveSchema.new_day())


func _day_mut(n: int) -> Dictionary:
	var key := str(n)
	if not data["days"].has(key):
		data["days"][key] = SaveSchema.new_day()
	return data["days"][key]


func record_attempt(n: int, today: String) -> void:
	var d := _day_mut(n)
	d["attempts"] = int(d["attempts"]) + 1
	d["last_played"] = today
	request_save()


## Returns true when this was the day's first ever completion.
func record_success(n: int, seconds: int, today: String) -> bool:
	var d := _day_mut(n)
	var first := String(d["completed_on"]) == ""
	if first:
		d["completed_on"] = today
	var best := int(d["best_seconds"])
	if best == 0 or seconds < best:
		d["best_seconds"] = seconds
	save_now()
	return first


func record_fail(n: int) -> void:
	var d := _day_mut(n)
	d["fails"] = int(d["fails"]) + 1
	request_save()


## Returns true when the star is new.
func set_star(n: int) -> bool:
	var d := _day_mut(n)
	if bool(d["star"]):
		return false
	d["star"] = true
	save_now()
	return true


func flag(name: String) -> bool:
	return bool(data["flags"].get(name, false))


func set_flag(name: String, value: bool = true) -> void:
	data["flags"][name] = value
	request_save()


func touch_seen_date(today: String) -> void:
	if today > String(data["last_seen_date"]):
		data["last_seen_date"] = today
		request_save()


func setting(key: String) -> Variant:
	return data["settings"].get(key, SaveSchema.DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	request_save()


func export_code() -> String:
	return SaveCode.encode(data)


func import_code(code: String) -> bool:
	var decoded: Variant = SaveCode.decode(code)
	if decoded == null:
		return false
	data = SaveSchema.migrate(decoded, Time.get_date_string_from_system(false))
	save_now()
	changed.emit()
	return true


func reset(today: String) -> void:
	var settings: Dictionary = data.get("settings", {}).duplicate()
	data = SaveSchema.new_save(today)
	data["settings"] = settings
	save_now()
	changed.emit()


## Coalesces many small changes into one write at the end of the frame.
func request_save() -> void:
	changed.emit()
	if _dirty:
		return
	_dirty = true
	save_now.call_deferred()


func save_now() -> void:
	_dirty = false
	changed.emit()
	if not persistent:
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		_storage_failed(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var dir := DirAccess.open(DIR)
	if dir == null:
		_storage_failed(DirAccess.get_open_error())
		return
	if dir.rename(tmp.get_file(), path.get_file()) != OK:
		dir.remove(path.get_file())
		if dir.rename(tmp.get_file(), path.get_file()) != OK:
			_storage_failed(ERR_CANT_CREATE)


func _storage_failed(err: Error) -> void:
	push_warning("Save storage unavailable (%s); progress is kept in memory only." % error_string(err))
	persistent = false


func _delete(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
