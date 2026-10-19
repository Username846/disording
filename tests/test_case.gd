class_name TestCase
extends RefCounted
## Minimal assertion base for unit tests: every method named test_* runs once.

var failures: PackedStringArray = []
var _current := ""


func run(name: String) -> void:
	_current = name
	call(name)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s: %s" % [_current, message])


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s, got %s %s" % [_current, var_to_str(expected), var_to_str(actual), message])
