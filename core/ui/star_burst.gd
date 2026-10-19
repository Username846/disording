class_name StarBurst
extends Node2D
## The wordless golden twinkle shown when a secret is found (PLAN.md §8.4).

const LIFE := 0.6

var _t := 0.0
var _sparks: Array[Vector2] = []


func _init(at: Vector2) -> void:
	position = at
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		_sparks.append(Vector2.from_angle(i * TAU / 8.0 + randf() * 0.3) * randf_range(50.0, 90.0))


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var fade := 1.0 - k
	var grow := ease(k, 0.3)
	Glyphs.star(self, Vector2.ZERO, 34.0 * (0.6 + grow * 0.6), Color(Pal.GOLD, fade))
	for s in _sparks:
		Glyphs.star(self, s * grow, 9.0 * fade + 2.0, Color(Pal.SNOW, fade), 0.35)
