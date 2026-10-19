class_name DevPanel
extends Overlay
## Preview/debug-only tools (PLAN.md §7.6): fake date, unlock all, jump to a day, perf HUD.

var _date_label: Label


func _init() -> void:
	super(860.0, 0.6)


func _ready() -> void:
	add_title("Dev panel", 40)
	_date_label = add_text("", 24, Pal.SNOW_DIM)
	_refresh()

	var date_row := HBoxContainer.new()
	date_row.alignment = BoxContainer.ALIGNMENT_CENTER
	date_row.add_theme_constant_override("separation", 10)
	for spec: Array in [["−1 day", -1], ["+1 day", 1], ["+7 days", 7]]:
		var b := UiTheme.button(spec[0], 150.0)
		var days: int = spec[1]
		b.pressed.connect(
			func() -> void:
				DevTools.run_command("shift_date", days)
				_refresh()
		)
		date_row.add_child(b)
	var real := UiTheme.button("Real date", 170.0)
	real.pressed.connect(
		func() -> void:
			DevTools.run_command("set_date", "")
			_refresh()
	)
	date_row.add_child(real)
	body.add_child(date_row)

	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", 10)
	var unlock := UiTheme.button("Unlock all: %s" % ("on" if Calendar.dev_unlock_all else "off"), 250.0)
	unlock.pressed.connect(
		func() -> void:
			DevTools.run_command("unlock_all", not Calendar.dev_unlock_all)
			unlock.text = "Unlock all: %s" % ("on" if Calendar.dev_unlock_all else "off")
	)
	toggles.add_child(unlock)
	var perf := UiTheme.button("Perf HUD", 180.0)
	perf.pressed.connect(func() -> void: DevTools.run_command("perf_hud", not PerfHud.is_on()))
	toggles.add_child(perf)
	var reset := UiTheme.button("Reset save", 200.0)
	reset.pressed.connect(
		func() -> void:
			DevTools.run_command("reset_save")
			_refresh()
	)
	toggles.add_child(reset)
	body.add_child(toggles)

	add_text("Play a built day (ignores locks):", 22, Pal.SNOW_DIM)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for n in DayRegistry.implemented_days():
		var b := UiTheme.button(str(n), 84.0)
		b.pressed.connect(func() -> void: DevTools.run_command("start_day", n))
		grid.add_child(b)
	var center := CenterContainer.new()
	center.add_child(grid)
	body.add_child(center)

	var stats := ""
	for n in DayRegistry.implemented_days():
		var s := Telemetry.summary(n)
		if int(s["runs"]) > 0:
			stats += (
				"Day %d: %d runs, %d clears, median clear %s\n"
				% [n, s["runs"], s["clears"], DayHost._clock(s["median_clear"])]
			)
	if stats != "":
		add_text(stats.strip_edges(), 20, Pal.SNOW_DIM)

	var close_btn := UiTheme.button("Close", 200.0, true)
	close_btn.pressed.connect(close)
	add_buttons([close_btn])


func _refresh() -> void:
	var fake := " (fake)" if Clock.fake_date != "" else ""
	_date_label.text = "Calendar date: %s%s   ·   save: %s" % [Clock.today(), fake, SaveService.path.get_file()]
