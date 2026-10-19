class_name DevTools
extends RefCounted
## Commands shared by the dev panel and the browser test API (preview/debug builds only).


static func run_command(command: String, arg: Variant = null) -> void:
	if not App.is_dev():
		return
	match command:
		"goto_title":
			Router.goto_title()
		"goto_calendar":
			Router.goto_calendar(int(arg) if arg != null else -1)
		"start_day":
			Router.start_day(int(arg))
		"unlock_all":
			Calendar.dev_unlock_all = bool(arg)
			Calendar.refreshed.emit()
		"set_date":
			Clock.set_fake_date(str(arg) if arg != null else "")
		"shift_date":
			Clock.set_fake_date(IsoDate.add_days(Clock.today(), int(arg)))
		"jump":
			var day_host := Router.current as DayHost
			if day_host != null and day_host.game != null:
				day_host.game._qa_jump(int(arg))
		"autoplay":
			var auto_host := Router.current as DayHost
			if auto_host != null and auto_host.game != null:
				auto_host.game._qa_autoplay(bool(arg))
		"force":
			var host := Router.current as DayHost
			if host != null:
				host.qa_force(StringName(str(arg)))
		"play_sfx":
			Audio.play_ui(StringName(str(arg)))
		"stop_music":
			Audio.stop_music(0.05)
		"audio_info":
			print(_audio_info())
		"reset_save":
			SaveService.reset(Clock.system_today())
		"perf_hud":
			PerfHud.toggle(bool(arg))
		"show_intro", "show_settings", "show_dev":
			var screen := Router.current as CalendarScreen
			if screen == null:
				return
			match command:
				"show_intro":
					screen.open_intro(int(arg))
				"show_settings":
					screen.add_child(SettingsPanel.new())
				"show_dev":
					screen.add_child(DevPanel.new())
		_:
			push_warning("Unknown dev command '%s'" % command)


## Bus levels and player states, for checking sound on a real device from the browser console:
## window.__disording.cmd('audio_info')
static func _audio_info() -> String:
	var lines := PackedStringArray()
	var driver := AudioServer.get_driver_name()
	lines.append(
		"driver=%s mix_rate=%d latency=%.3f" % [driver, AudioServer.get_mix_rate(), AudioServer.get_output_latency()]
	)
	for i in AudioServer.bus_count:
		var bus := "bus %d %s send=%s" % [i, AudioServer.get_bus_name(i), AudioServer.get_bus_send(i)]
		var level := "vol=%.1f mute=%s" % [AudioServer.get_bus_volume_db(i), AudioServer.is_bus_mute(i)]
		lines.append("%s %s peak=%.1f" % [bus, level, AudioServer.get_bus_peak_volume_left_db(i, 0)])
	for child in Audio.get_children():
		var player := child as AudioStreamPlayer
		if player != null and player.playing:
			var where := "bus=%s pos=%.2f" % [player.bus, player.get_playback_position()]
			lines.append("playing %s %s vol=%.1f" % [player.name, where, player.volume_db])
	lines.append("ui_bundle=%s music_bundle=%s" % [Audio.ui_bundle != null, Audio.music_bundle != null])
	return "[audio] " + "\n[audio] ".join(lines)
