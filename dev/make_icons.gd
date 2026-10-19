extends SceneTree
## Renders web/icons/icon.svg to the PNG sizes the PWA manifest needs.
## Run: godot --headless --path . -s res://dev/make_icons.gd


func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://web/icons/icon.svg")
	for size in [144, 180, 512]:
		var img := Image.new()
		img.load_svg_from_string(svg, size / 512.0)
		img.save_png("res://web/icons/icon_%d.png" % size)
		print("wrote icon_%d.png" % size)
	quit()
