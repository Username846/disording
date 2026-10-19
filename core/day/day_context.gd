class_name DayContext
extends RefCounted
## Everything a day may use from the platform (PLAN.md §3.4). Days never touch autoloads directly.

var day := 0
var info: DayInfo
## Seeded per attempt; the seed is shown in the dev panel so runs can be reproduced.
var rng := RandomNumberGenerator.new()
var input: GestureRecognizer
var hud: Hud
## The Audio autoload: play_sfx(), beat/bar signals, music_time(), beat_length().
var audio: Node
## The Settings autoload: reduce_motion(), left_handed(), get_bool("haptics")...
var settings: Node
## Checkpoint data when the run was restarted from a checkpoint, else empty.
var checkpoint: Dictionary = {}

var _star_callback: Callable
var _checkpoint_callback: Callable


func _init(day_number: int, day_info: DayInfo, seed_value: int, on_star: Callable, on_checkpoint: Callable) -> void:
	day = day_number
	info = day_info
	rng.seed = seed_value
	input = GestureRecognizer.new()
	_star_callback = on_star
	_checkpoint_callback = on_checkpoint


## Awards this door's gold star. `at` is a screen position for the twinkle (default: centre).
func award_star(at: Vector2 = Vector2.INF) -> void:
	_star_callback.call(at)


func save_checkpoint(data: Dictionary) -> void:
	_checkpoint_callback.call(data)


func haptic(ms: int = 15) -> void:
	Haptics.pulse(ms)
