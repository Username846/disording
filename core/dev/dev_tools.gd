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
		"force":
			var host := Router.current as DayHost
			if host != null:
				host.qa_force(StringName(str(arg)))
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
