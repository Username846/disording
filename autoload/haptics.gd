extends Node
## Short vibrations on phones that support them; honours the Haptics setting.


func pulse(ms: int = 15) -> void:
	if App.is_mobile() and Settings.get_bool("haptics"):
		Input.vibrate_handheld(ms)
