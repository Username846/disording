class_name AudioBundle
extends RefCounted
## One day's (or the menu's) rendered audio: music, stingers, SFX, lyrics and beat map.
## Built from a Songsmith bundle zip (PLAN.md §3.6, §6).

var id := ""
var meta: Dictionary = {}
var music: AudioStreamOggVorbis
var stingers: Dictionary = {}  # StringName -> AudioStream ("win", "lose")
var sfx: Dictionary = {}  # StringName -> AudioStream
var lyrics: Array = []  # [{t, end, text, section}]
var beats: Dictionary = {}  # {bpm, beats_per_bar, beats: [], bars: [], sections: []}


## Parses a bundle zip on disk. Returns null (and pushes an error) when unreadable.
static func from_zip(bundle_id: String, zip_path: String) -> AudioBundle:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		push_error("Can't open audio bundle %s" % zip_path)
		return null
	var bundle := AudioBundle.new()
	bundle.id = bundle_id
	var files := reader.get_files()
	bundle.meta = _json(reader, "meta.json", files)
	bundle.lyrics = _json(reader, "lyrics.json", files).get("lines", [])
	bundle.beats = _json(reader, "beats.json", files)
	for file in files:
		if not file.ends_with(".ogg"):
			continue
		var stream := AudioStreamOggVorbis.load_from_buffer(reader.read_file(file))
		if stream == null:
			push_error("Bad OGG %s in %s" % [file, zip_path])
			continue
		if file == "music.ogg":
			stream.loop = true
			stream.loop_offset = float(bundle.meta.get("loop_start", 0.0))
			bundle.music = stream
		elif file.begins_with("sfx/"):
			bundle.sfx[StringName(file.get_file().get_basename())] = stream
		else:
			bundle.stingers[StringName(file.get_basename())] = stream
	reader.close()
	return bundle


static func _json(reader: ZIPReader, name: String, files: PackedStringArray) -> Dictionary:
	if not name in files:
		return {}
	var parsed: Variant = JSON.parse_string(reader.read_file(name).get_string_from_utf8())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func loop_start() -> float:
	return float(meta.get("loop_start", 0.0))


func duration() -> float:
	return float(meta.get("duration", music.get_length() if music != null else 0.0))


## The lyric line being sung at time t (seconds into music.ogg), or "".
func caption_at(t: float) -> String:
	for line: Dictionary in lyrics:
		if t >= float(line["t"]) and t < float(line["end"]):
			return str(line["text"])
	return ""
