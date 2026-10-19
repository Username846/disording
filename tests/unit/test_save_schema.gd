extends TestCase


func test_new_save_defaults() -> void:
	var s := SaveSchema.new_save("2026-11-01")
	check_eq(int(s["version"]), SaveSchema.VERSION)
	check_eq(s["first_launch"], "2026-11-01")
	check_eq(s["settings"]["quality"], "auto")


func test_migrate_garbage() -> void:
	check_eq(SaveSchema.migrate(null, "2026-11-01")["days"], {})
	check_eq(SaveSchema.migrate("nope", "2026-11-01")["first_launch"], "2026-11-01")
	var bad := {
		"version": 1,
		"days": {"1": {"completed_on": "not a date", "attempts": -4, "star": 1}, "999": {}, "x": 5},
		"settings": {"music": 0.5, "quality": 7, "captions": false},
	}
	var m := SaveSchema.migrate(bad, "2026-11-01")
	check_eq(m["days"]["1"]["completed_on"], "")
	check_eq(m["days"]["1"]["attempts"], 0)
	check_eq(m["days"]["1"]["star"], true)
	check(not m["days"].has("999"), "out-of-range day dropped")
	check_eq(m["settings"]["music"], 0.5)
	check_eq(m["settings"]["quality"], "auto")
	check_eq(m["settings"]["captions"], false)


func test_json_round_trip_keeps_types() -> void:
	var s := SaveSchema.new_save("2026-11-01")
	s["days"]["4"] = SaveSchema.new_day()
	s["days"]["4"]["best_seconds"] = 512
	var back := SaveSchema.migrate(JSON.parse_string(JSON.stringify(s)), "2026-11-02")
	check_eq(back["days"]["4"]["best_seconds"], 512)
	check_eq(back["first_launch"], "2026-11-01")


func test_save_code_round_trip() -> void:
	var s := SaveSchema.new_save("2026-11-01")
	s["days"]["1"] = SaveSchema.new_day()
	s["days"]["1"]["completed_on"] = "2026-11-01"
	var code := SaveCode.encode(s)
	check(code.begins_with("DSD1."), "prefix")
	var decoded: Variant = SaveCode.decode(code)
	check(decoded != null, "decodes")
	check_eq(SaveSchema.migrate(decoded, "2026-11-02")["days"]["1"]["completed_on"], "2026-11-01")
	check(SaveCode.decode(code.substr(0, code.length() - 2) + "zz") == null, "checksum catches damage")
	check(SaveCode.decode("hello") == null, "rejects junk")
