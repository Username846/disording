class_name StateMachine
extends RefCounted
## Tiny finite-state machine for AI and game flow (PLAN.md §3.7).
## add(&"idle", update_fn, enter_fn, exit_fn) then go(&"idle") and call update(dt) every frame.

var state: StringName = &""
## Seconds spent in the current state.
var time := 0.0

var _states: Dictionary = {}  # name -> [update, enter, exit]


func add(
	state_name: StringName, update_fn: Callable, enter_fn: Callable = Callable(), exit_fn: Callable = Callable()
) -> StateMachine:
	_states[state_name] = [update_fn, enter_fn, exit_fn]
	return self


func go(state_name: StringName) -> void:
	if state != &"" and _states.has(state) and (_states[state][2] as Callable).is_valid():
		(_states[state][2] as Callable).call()
	state = state_name
	time = 0.0
	if (_states[state][1] as Callable).is_valid():
		(_states[state][1] as Callable).call()


func is_in(state_name: StringName) -> bool:
	return state == state_name


func update(dt: float) -> void:
	if state == &"":
		return
	time += dt
	var update_fn: Callable = _states[state][0]
	if update_fn.is_valid():
		update_fn.call(dt)
