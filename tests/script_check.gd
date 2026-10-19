extends Node
## Loads every GDScript in the project (with autoloads active) so parse/compile errors fail CI.
## Run: godot --headless --path . res://tests/script_check.tscn

const ROOTS := ["res://autoload", "res://core", "res://menu", "res://days", "res://tests", "res://dev"]


func _ready() -> void:
	var failures := 0
	var count := 0
	for root in ROOTS:
		for path in _scripts(root):
			if path == get_script().resource_path:
				continue
			count += 1
			var script := load(path) as Script
			if script == null or not script.can_instantiate() and not _is_abstract_ok(script):
				failures += 1
				printerr("[script_check] FAILED: %s" % path)
	print("[script_check] %d scripts, %d failed" % [count, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _is_abstract_ok(script: Script) -> bool:
	return script != null and script.get_instance_base_type() != &""


func _scripts(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	for sub in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(sub)))
	return out
