class_name DayResult
extends RefCounted
## How a run ended (PLAN.md §3.4).

enum Outcome { SUCCESS, FAIL, QUIT }

var outcome := Outcome.SUCCESS
var reason: StringName = &""
## Optional player-facing line shown on the results panel ("The fox escaped 3 times").
var message := ""
var seconds := 0.0
var stats: Dictionary = {}


static func make(result_outcome: Outcome, result_reason: StringName = &"", text: String = "") -> DayResult:
	var r := DayResult.new()
	r.outcome = result_outcome
	r.reason = result_reason
	r.message = text
	return r


func is_success() -> bool:
	return outcome == Outcome.SUCCESS


func outcome_name() -> String:
	return ["success", "fail", "quit"][outcome]
