class_name DayGame
extends Node2D
## Base class for every day's root node (PLAN.md §3.4).
## Override the _day_* hooks; call succeed()/fail() exactly once to end the run.

signal finished(result: DayResult)

## Injected by DayHost before _day_start()/_day_restore().
var ctx: DayContext

var _ended := false


## Build the level and start phase 1.
func _day_start() -> void:
	pass


## Called when the pause menu opens/closes. The scene tree pause already stops _process.
func _day_pause(_paused: bool) -> void:
	pass


## Resume from data passed to checkpoint(). Default: start from scratch.
func _day_restore(_checkpoint: Dictionary) -> void:
	_day_start()


## Raw input hook after gesture recognition (gestures arrive via ctx.input signals).
func _day_input(_event: InputEvent) -> void:
	pass


## Tests force outcomes through here: &"success", &"fail" or &"star".
func _qa_force(outcome: StringName) -> void:
	match outcome:
		&"success":
			succeed({"qa": true})
		&"fail":
			fail(&"qa", "Forced fail (QA).")
		&"star":
			ctx.award_star()


## Dev/QA: jump straight to phase `index` (e.g. a bout or level). Return true if supported.
func _qa_jump(_index: int) -> bool:
	return false


## Tests: let an AI play the day (scripted win bot). Return true if supported.
func _qa_autoplay(_enabled: bool) -> bool:
	return false


func succeed(stats: Dictionary = {}) -> void:
	if _ended:
		return
	_ended = true
	var r := DayResult.make(DayResult.Outcome.SUCCESS)
	r.stats = stats
	finished.emit(r)


func fail(reason: StringName = &"", message: String = "") -> void:
	if _ended:
		return
	_ended = true
	finished.emit(DayResult.make(DayResult.Outcome.FAIL, reason, message))


func checkpoint(data: Dictionary) -> void:
	ctx.save_checkpoint(data)


func is_ended() -> bool:
	return _ended


## Converts a viewport/screen position into this node's canvas (world) coordinates.
func to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos


func _unhandled_input(event: InputEvent) -> void:
	if _ended or ctx == null:
		return
	ctx.input.feed(event)
	_day_input(event)
