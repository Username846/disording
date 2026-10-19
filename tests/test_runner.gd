extends Node
## Runs unit tests (tests/unit/test_*.gd) then the platform smoke test (tests/smoke/).
## Run: godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn -- --test
## Exit code 0 = all green.


func _ready() -> void:
	var failures := PackedStringArray()
	var total := 0
	for path in _test_files("res://tests/unit"):
		var script := load(path) as GDScript
		var case: TestCase = script.new()
		for method in script.get_script_method_list():
			var name := String(method["name"])
			if not name.begins_with("test_"):
				continue
			total += 1
			case.run(name)
		for f in case.failures:
			failures.append("%s › %s" % [path.get_file(), f])
	print("[tests] unit: %d tests, %d failures" % [total, failures.size()])
	var smoke := preload("res://tests/smoke/platform_smoke.gd").new()
	add_child(smoke)
	var smoke_failures: PackedStringArray = await smoke.run()
	failures.append_array(smoke_failures)
	for f in failures:
		printerr("[tests] FAIL ", f)
	print(
		(
			"[tests] %s (%d failure%s)"
			% ["PASSED" if failures.is_empty() else "FAILED", failures.size(), "" if failures.size() == 1 else "s"]
		)
	)
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir != null:
		for file in dir.get_files():
			if file.begins_with("test_") and file.ends_with(".gd"):
				out.append(dir_path.path_join(file))
	out.sort()
	return out
