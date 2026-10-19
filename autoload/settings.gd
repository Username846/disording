extends Node
## Player settings stored inside the save (PLAN.md §3.3). Emits changed(key) on every edit.

signal changed(key: String)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveService.changed.connect(_apply_quality)
	_apply_quality()


func get_value(key: String) -> Variant:
	return SaveService.setting(key)


func get_bool(key: String) -> bool:
	return bool(SaveService.setting(key))


func get_float(key: String) -> float:
	return float(SaveService.setting(key))


func set_value(key: String, value: Variant) -> void:
	if SaveService.setting(key) == value:
		return
	SaveService.set_setting(key, value)
	changed.emit(key)
	if key == "quality":
		_apply_quality()


func reduce_motion() -> bool:
	return get_bool("reduce_motion")


func left_handed() -> bool:
	return get_bool("left_handed")


func _apply_quality() -> void:
	App.apply_quality(str(get_value("quality")))
