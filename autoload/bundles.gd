extends Node
## Downloads and caches Songsmith audio bundles (PLAN.md §3.6).
## Web: fetched over HTTP next to the page (generated/manifest.json lists hashed file names).
## Desktop/editor: read straight from res://generated/ (git-ignored, rendered by Songsmith).

signal manifest_loaded

const CACHE_DIR := "user://disording/cache"
const LOCAL_DIR := "res://generated/"
const KEEP_LOADED := 2

var manifest: Dictionary = {}
var manifest_ready := false

var _assets_base := LOCAL_DIR
var _loaded: Dictionary = {}  # id -> AudioBundle
var _lru: Array[String] = []
var _requests: Dictionary = {}  # id -> BundleRequest
var _http: Dictionary = {}  # id -> HTTPRequest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_manifest()


func _process(_delta: float) -> void:
	for id: String in _http:
		var http: HTTPRequest = _http[id]
		var total := http.get_body_size()
		if total > 0 and _requests.has(id):
			(_requests[id] as BundleRequest).progress = clampf(float(http.get_downloaded_bytes()) / total, 0.0, 0.99)


func has_bundle(id: String) -> bool:
	return manifest.get("bundles", {}).has(id)


func get_loaded(id: String) -> AudioBundle:
	return _loaded.get(id)


## Starts (or joins) loading a bundle. Always returns a request; check request.error.
func request(id: String) -> BundleRequest:
	if _requests.has(id):
		return _requests[id]
	var req := BundleRequest.new()
	req.id = id
	_requests[id] = req
	if _loaded.has(id):
		_touch(id)
		req.finish(_loaded[id])
		return req
	_start(req)
	return req


func _start(req: BundleRequest) -> void:
	if not manifest_ready:
		await manifest_loaded
	var entry: Dictionary = manifest.get("bundles", {}).get(req.id, {})
	if entry.is_empty():
		_fail(req, "no bundle '%s' in manifest" % req.id)
		return
	var file := str(entry["file"])
	if not App.is_web():
		_finish_from_path(req, LOCAL_DIR + file)
		return
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var cached := "%s/%s" % [CACHE_DIR, file]
	if FileAccess.file_exists(cached):
		_finish_from_path(req, cached)
		return
	var http := _new_request()
	_http[req.id] = http
	http.request_completed.connect(
		func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			_http.erase(req.id)
			http.queue_free()
			if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.is_empty():
				_fail(req, "download failed (%d/%d)" % [result, code])
				return
			var out := FileAccess.open(cached, FileAccess.WRITE)
			if out == null:
				_fail(req, "can't write cache (%s)" % error_string(FileAccess.get_open_error()))
				return
			out.store_buffer(body)
			out.close()
			_finish_from_path(req, cached)
	)
	if http.request(_assets_base + file) != OK:
		_http.erase(req.id)
		http.queue_free()
		_fail(req, "request could not start")


func _finish_from_path(req: BundleRequest, path: String) -> void:
	var bundle := AudioBundle.from_zip(req.id, path)
	if bundle == null:
		_fail(req, "bundle unreadable")
		return
	_loaded[req.id] = bundle
	_touch(req.id)
	_prune_cache(path.get_file())
	req.finish(bundle)


func _fail(req: BundleRequest, err: String) -> void:
	push_warning("Audio bundle '%s': %s. Continuing without it." % [req.id, err])
	_requests.erase(req.id)
	req.finish(null, err)


func _touch(id: String) -> void:
	_lru.erase(id)
	_lru.append(id)
	# The menu bundle stays resident; day bundles rotate.
	while _lru.size() > KEEP_LOADED + 1:
		var victim := ""
		for candidate in _lru:
			if candidate != "menu":
				victim = candidate
				break
		if victim == "" or victim == id:
			break
		_lru.erase(victim)
		_loaded.erase(victim)
		_requests.erase(victim)


func _prune_cache(keep_file: String) -> void:
	if not App.is_web():
		return
	var dir := DirAccess.open(CACHE_DIR)
	if dir == null:
		return
	var wanted := {keep_file: true}
	for id in _lru:
		var entry: Dictionary = manifest.get("bundles", {}).get(id, {})
		if not entry.is_empty():
			wanted[str(entry["file"])] = true
	for file in dir.get_files():
		if not wanted.has(file):
			dir.remove(file)


func _load_manifest() -> void:
	if not App.is_web():
		var path := LOCAL_DIR + "manifest.json"
		if FileAccess.file_exists(path):
			_set_manifest(JSON.parse_string(FileAccess.get_file_as_string(path)))
		else:
			_set_manifest({})
		return
	var page_base := str(JavaScriptBridge.eval("new URL('.', window.location.href).href", true))
	var stamp := "?t=%d" % Time.get_unix_time_from_system()
	var build: Variant = await _fetch_json(page_base + "build.json" + stamp)
	var assets := "generated/"
	if typeof(build) == TYPE_DICTIONARY:
		assets = str(build.get("assets_base", assets))
	_assets_base = page_base + assets
	_set_manifest(await _fetch_json(_assets_base + "manifest.json" + stamp))


func _set_manifest(parsed: Variant) -> void:
	manifest = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	manifest_ready = true
	manifest_loaded.emit()


func _fetch_json(url: String) -> Variant:
	var http := _new_request()
	if http.request(url) != OK:
		http.queue_free()
		return null
	var response: Array = await http.request_completed
	http.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS or int(response[1]) != 200:
		push_warning("Couldn't fetch %s (result %d, HTTP %d)" % [url, int(response[0]), int(response[1])])
		return null
	return JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())


func _new_request() -> HTTPRequest:
	var http := HTTPRequest.new()
	# The browser already decompresses gzip responses (GitHub Pages gzips JSON) but still reports
	# "Content-Encoding: gzip", so Godot would try to inflate plain bytes and fail the request.
	http.accept_gzip = false
	add_child(http)
	return http
