class_name SaveCode
extends RefCounted
## Turns a save into a short copy-pasteable string and back ("DSD1.<base64>.<check>").

const PREFIX := "DSD1"


static func encode(data: Dictionary) -> String:
	var json := JSON.stringify(data)
	var packed := json.to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	return "%s.%s.%s" % [PREFIX, Marshalls.raw_to_base64(packed), json.sha256_text().substr(0, 8)]


## Returns the decoded dictionary, or null when the code is damaged.
static func decode(code: String) -> Variant:
	var parts := code.strip_edges().split(".")
	if parts.size() != 3 or parts[0] != PREFIX:
		return null
	var packed := Marshalls.base64_to_raw(parts[1])
	if packed.is_empty():
		return null
	var raw := packed.decompress_dynamic(1 << 20, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		return null
	var json := raw.get_string_from_utf8()
	if json.sha256_text().substr(0, 8) != parts[2]:
		return null
	var parsed: Variant = JSON.parse_string(json)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else null
