extends Node
## Music, stingers, SFX and the beat clock (PLAN.md §6.1). Autoload name: Audio.
## Music uses Stream playback (memory-friendly); SFX use Sample playback (low latency on web).
## The Music and SFX buses come from res://default_bus_layout.tres. Don't create buses at runtime:
## on web, AudioServer.add_bus() scrambles the order of the browser-side sample buses, which
## silences every Sample-playback sound.

signal beat(index: int)
signal bar(index: int)

const SFX_VOICES := 12
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const DUCK_DB := -12.0

var music_bundle: AudioBundle
var ui_bundle: AudioBundle
var day_bundle: AudioBundle

var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _stinger: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _beat_index := -1
var _bar_index := -1
var _last_time := 0.0
var _duck_tween: Tween
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			push_error("Audio bus '%s' missing from default_bus_layout.tres" % bus_name)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(p)
		_music.append(p)
	_stinger = AudioStreamPlayer.new()
	_stinger.bus = SFX_BUS
	add_child(_stinger)
	for i in SFX_VOICES:
		var s := AudioStreamPlayer.new()
		s.bus = SFX_BUS
		s.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		add_child(s)
		_sfx.append(s)
	Settings.changed.connect(_on_setting)
	_apply_volumes()


func _process(_delta: float) -> void:
	if music_bundle == null or not _music[_active].playing:
		return
	var beats: Array = music_bundle.beats.get("beats", [])
	if beats.is_empty():
		return
	var t := music_time()
	if t < _last_time:
		_beat_index = -1
		_bar_index = -1
	_last_time = t
	var index := _bisect(beats, t)
	if index != _beat_index and index >= 0:
		_beat_index = index
		beat.emit(index)
		var per_bar := int(music_bundle.beats.get("beats_per_bar", 4))
		var bar_index := int(index / float(per_bar))
		if bar_index != _bar_index:
			_bar_index = bar_index
			bar.emit(bar_index)


## Plays a bundle's music, crossfading from whatever is playing.
func play_music(bundle: AudioBundle, fade: float = 1.0) -> void:
	if bundle == null or bundle.music == null:
		return
	if bundle == music_bundle and _music[_active].playing:
		return
	var outgoing := _music[_active]
	_active = 1 - _active
	var incoming := _music[_active]
	music_bundle = bundle
	_beat_index = -1
	_bar_index = -1
	_last_time = 0.0
	incoming.stream = bundle.music
	incoming.volume_db = -40.0
	incoming.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	_music_tween.tween_property(incoming, "volume_db", 0.0, fade)
	if outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", -40.0, fade)
		_music_tween.chain().tween_callback(outgoing.stop)


func stop_music(fade: float = 0.8) -> void:
	var player := _music[_active]
	music_bundle = null
	if not player.playing:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(player, "volume_db", -40.0, fade)
	_music_tween.tween_callback(player.stop)


func is_music_playing() -> bool:
	return _music[_active].playing and music_bundle != null


## Seconds into music.ogg, compensated for output latency.
func music_time() -> float:
	var player := _music[_active]
	if not player.playing:
		return 0.0
	var t := player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(0.0, t)


func current_caption() -> String:
	if music_bundle == null or not Settings.get_bool("captions"):
		return ""
	return music_bundle.caption_at(music_time())


func beat_length() -> float:
	if music_bundle == null:
		return 0.5
	return 60.0 / maxf(1.0, float(music_bundle.beats.get("bpm", 120)))


## Plays a day SFX if the current day bundle has it, else a menu/UI SFX of that name.
## opts: volume_db, pitch, pitch_jitter.
func play_sfx(sfx_name: StringName, opts: Dictionary = {}) -> void:
	var stream: AudioStream = null
	if day_bundle != null:
		stream = day_bundle.sfx.get(sfx_name)
	if stream == null and ui_bundle != null:
		stream = ui_bundle.sfx.get(sfx_name)
	_play_stream(stream, opts)


## Plays a menu/UI SFX (from the calendar bundle) even while a day is running.
func play_ui(sfx_name: StringName, opts: Dictionary = {}) -> void:
	if ui_bundle != null:
		_play_stream(ui_bundle.sfx.get(sfx_name), opts)


func _play_stream(stream: AudioStream, opts: Dictionary) -> void:
	if stream == null:
		return
	var player := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	player.stream = stream
	player.volume_db = float(opts.get("volume_db", 0.0))
	var jitter := float(opts.get("pitch_jitter", 0.0))
	player.pitch_scale = float(opts.get("pitch", 1.0)) * (1.0 + randf_range(-jitter, jitter))
	player.play()


## Plays the day's "win"/"lose" stinger over ducked music.
func play_stinger(kind: StringName) -> void:
	if day_bundle == null or not day_bundle.stingers.has(kind):
		return
	_stinger.stream = day_bundle.stingers[kind]
	_stinger.play()
	duck(DUCK_DB, 0.2)
	_stinger.finished.connect(func() -> void: duck(0.0, 1.2), CONNECT_ONE_SHOT)


func duck(db: float, time: float = 0.3) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	var target := _volume_db("music") + db
	_duck_tween.tween_method(
		func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), AudioServer.get_bus_volume_db(bus), target, time
	)


func _on_setting(key: String) -> void:
	if key == "music" or key == "sfx":
		_apply_volumes()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), _volume_db("music"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), _volume_db("sfx"))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), Settings.get_float("music") <= 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), Settings.get_float("sfx") <= 0.0)


func _volume_db(key: String) -> float:
	return linear_to_db(maxf(0.0001, Settings.get_float(key)))


static func _bisect(values: Array, t: float) -> int:
	var lo := 0
	var hi := values.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if float(values[mid]) <= t:
			lo = mid + 1
		else:
			hi = mid
	return lo - 1
