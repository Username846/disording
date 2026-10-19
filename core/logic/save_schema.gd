class_name SaveSchema
extends RefCounted
## Save-file schema, defaults and migrations (PLAN.md §3.5).

const VERSION := 1

const DEFAULT_SETTINGS := {
	"music": 0.8,
	"sfx": 0.9,
	"captions": true,
	"haptics": true,
	"reduce_motion": false,
	"left_handed": false,
	"quality": "auto",
}

const DEFAULT_DAY := {
	"completed_on": "",
	"best_seconds": 0,
	"attempts": 0,
	"fails": 0,
	"star": false,
	"last_played": "",
}


static func new_save(today: String) -> Dictionary:
	return {
		"version": VERSION,
		"first_launch": today,
		"last_seen_date": today,
		"days": {},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"flags": {},
	}


static func new_day() -> Dictionary:
	return DEFAULT_DAY.duplicate()


## Upgrades any older or damaged dictionary to the current schema. Never throws: unknown
## or malformed fields fall back to defaults so a bad save can't brick the calendar.
static func migrate(raw: Variant, today: String) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return new_save(today)
	var data: Dictionary = raw
	var version := int(data.get("version", 0))
	# Future migrations chain here: if version < 2: data = _v1_to_v2(data)
	if version > VERSION:
		push_warning("Save is from a newer build (v%d); reading what we understand." % version)
	return _sanitize(data, today)


static func _sanitize(data: Dictionary, today: String) -> Dictionary:
	var out := new_save(today)
	if IsoDate.is_valid(str(data.get("first_launch", ""))):
		out["first_launch"] = data["first_launch"]
	if IsoDate.is_valid(str(data.get("last_seen_date", ""))):
		out["last_seen_date"] = data["last_seen_date"]
	var settings: Variant = data.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		for key: String in DEFAULT_SETTINGS:
			if settings.has(key) and typeof(settings[key]) == typeof(DEFAULT_SETTINGS[key]):
				out["settings"][key] = settings[key]
			elif settings.has(key) and typeof(DEFAULT_SETTINGS[key]) == TYPE_FLOAT:
				out["settings"][key] = float(settings[key])
	var flags: Variant = data.get("flags", {})
	if typeof(flags) == TYPE_DICTIONARY:
		out["flags"] = (flags as Dictionary).duplicate()
	var days: Variant = data.get("days", {})
	if typeof(days) == TYPE_DICTIONARY:
		for key: Variant in days:
			var n := str(key).to_int()
			if n < 0 or n > CalendarRules.DAY_COUNT or typeof(days[key]) != TYPE_DICTIONARY:
				continue
			out["days"][str(n)] = _sanitize_day(days[key])
	return out


static func _sanitize_day(raw: Dictionary) -> Dictionary:
	var day := new_day()
	var completed := str(raw.get("completed_on", ""))
	day["completed_on"] = completed if IsoDate.is_valid(completed) else ""
	var last := str(raw.get("last_played", ""))
	day["last_played"] = last if IsoDate.is_valid(last) else ""
	day["best_seconds"] = maxi(0, int(raw.get("best_seconds", 0)))
	day["attempts"] = maxi(0, int(raw.get("attempts", 0)))
	day["fails"] = maxi(0, int(raw.get("fails", 0)))
	day["star"] = bool(raw.get("star", false))
	return day
