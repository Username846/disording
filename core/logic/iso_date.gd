class_name IsoDate
extends RefCounted
## Helpers for "YYYY-MM-DD" date strings. ISO dates compare correctly as plain strings.


static func is_valid(date: String) -> bool:
	if date.length() != 10 or date[4] != "-" or date[7] != "-":
		return false
	var parts := date.split("-")
	if not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()):
		return false
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	return month >= 1 and month <= 12 and day >= 1 and day <= 31


static func add_days(date: String, days: int) -> String:
	# Noon avoids any edge effects; the arithmetic itself is in UTC so DST never applies.
	var unix := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	return Time.get_date_string_from_unix_time(unix + days * 86400)


static func days_between(from_date: String, to_date: String) -> int:
	var a := Time.get_unix_time_from_datetime_string(from_date + "T12:00:00")
	var b := Time.get_unix_time_from_datetime_string(to_date + "T12:00:00")
	return roundi((b - a) / 86400.0)


static func later(a: String, b: String) -> String:
	return a if a > b else b
