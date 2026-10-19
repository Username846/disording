extends Node
## Boot info, platform detection, quality tier, safe areas and web integration (PLAN.md §3.3).

signal focus_lost
signal focus_gained
signal safe_area_changed

const BUILD_INFO_PATH := "res://build_info.json"

var version := "0.1.0"
var commit := "dev"
var build_date := ""
## Margins (left, top, right, bottom) in viewport units that the HUD must stay inside.
var safe_margins := Vector4.ZERO
var test_mode := false

var _js_callbacks: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_mode = "--test" in OS.get_cmdline_user_args()
	version = str(ProjectSettings.get_setting("application/config/version", version))
	_load_build_info()
	# Merge into the engine default theme too: UI under CanvasLayers (HUD, overlays) doesn't
	# inherit the root window's theme.
	var theme := UiTheme.build()
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.fallback_font = theme.default_font
	ThemeDB.fallback_font_size = theme.default_font_size
	get_tree().root.theme = theme
	get_tree().root.size_changed.connect(_refresh_safe_area)
	if is_web():
		_setup_web()
	_refresh_safe_area.call_deferred()


func is_web() -> bool:
	return OS.has_feature("web")


func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")


## Dev tools (dev panel, separate save, test hooks) exist only in debug/preview builds.
func is_dev() -> bool:
	return OS.is_debug_build()


func save_slot() -> String:
	if test_mode:
		return "test"
	return "preview" if is_dev() else "main"


func apply_quality(quality: String) -> void:
	# "fast" renders the 2D canvas at the reference resolution and scales it up (cheap on
	# high-DPI phones); "sharp" renders at the device's native resolution.
	var fast := quality == "fast" or (quality == "auto" and is_mobile())
	var root := get_tree().root
	root.content_scale_mode = (Window.CONTENT_SCALE_MODE_VIEWPORT if fast else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)


func visible_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focus_lost.emit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_gained.emit()


func _load_build_info() -> void:
	if not FileAccess.file_exists(BUILD_INFO_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILD_INFO_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		commit = str(parsed.get("commit", commit))
		build_date = str(parsed.get("date", ""))


func _refresh_safe_area() -> void:
	var margins := Vector4.ZERO
	if is_web():
		var raw: Variant = JavaScriptBridge.eval(
			"JSON.stringify(Object.assign({innerWidth: window.innerWidth}, window.__safeArea || {}))", true
		)
		var parsed: Variant = JSON.parse_string(str(raw)) if raw != null else null
		if typeof(parsed) == TYPE_DICTIONARY and float(parsed.get("innerWidth", 0)) > 0.0:
			var to_viewport := visible_size().x / float(parsed["innerWidth"])
			margins = (
				Vector4(
					float(parsed.get("left", 0)),
					float(parsed.get("top", 0)),
					float(parsed.get("right", 0)),
					float(parsed.get("bottom", 0))
				)
				* to_viewport
			)
	if margins != safe_margins:
		safe_margins = margins
		safe_area_changed.emit()


func _setup_web() -> void:
	var document := JavaScriptBridge.get_interface("document")
	var on_visibility := JavaScriptBridge.create_callback(_on_visibility_change)
	_js_callbacks.append(on_visibility)
	document.addEventListener("visibilitychange", on_visibility)
	if is_dev():
		_setup_test_api()


func _on_visibility_change(_args: Array) -> void:
	var hidden: Variant = JavaScriptBridge.eval("document.hidden", true)
	if hidden:
		focus_lost.emit()
	else:
		focus_gained.emit()


## Browser test hooks for Playwright (preview builds only): window.__disording.cmd(name, arg)
## runs a command; window.__disordingState holds the latest JSON state.
func _setup_test_api() -> void:
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	var api: JavaScriptObject = JavaScriptBridge.create_object("Object")
	var cmd := JavaScriptBridge.create_callback(_on_test_command)
	_js_callbacks.append(cmd)
	api.cmd = cmd
	window.__disording = api
	publish_test_state({"screen": "boot"})


func publish_test_state(state: Dictionary) -> void:
	if not (is_web() and is_dev()):
		return
	state["fps"] = Engine.get_frames_per_second()
	state["today"] = Clock.today()
	JavaScriptBridge.eval("window.__disordingState = %s;" % JSON.stringify(JSON.stringify(state)), true)


func _on_test_command(args: Array) -> void:
	var name := str(args[0]) if args.size() > 0 else ""
	var arg: Variant = args[1] if args.size() > 1 else null
	DevTools.run_command(name, arg)
