extends TestCase
## The Music and SFX buses must come from default_bus_layout.tres: buses added at runtime with
## AudioServer.add_bus() end up in the wrong order on web, which silences Sample-playback SFX.


func test_bus_layout_loaded_at_startup() -> void:
	check_eq(AudioServer.bus_count, 3, "Master, Music, SFX")
	check_eq(AudioServer.get_bus_index(&"Music"), 1)
	check_eq(AudioServer.get_bus_index(&"SFX"), 2)
	check_eq(AudioServer.get_bus_send(1), &"Master")
	check_eq(AudioServer.get_bus_send(2), &"Master")


func test_web_latency_covers_slow_frames() -> void:
	# Single-threaded web builds mix Stream audio between frames; the buffer must outlast a slow frame.
	check(int(ProjectSettings.get_setting("audio/driver/output_latency.web", 0)) >= 100, "web output latency >= 100 ms")
