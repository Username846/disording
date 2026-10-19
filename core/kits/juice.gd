class_name Juice
extends Node2D
## Game feel helpers (PLAN.md §3.7): screen shake, hit-stop, floating text and confetti.
## Add one as a child of the day; it respects the Reduce motion setting.

var camera: Camera2D
## While > 0, the game should freeze its simulation (hit-stop).
var hitstop_left := 0.0

var _shake := 0.0
var _shake_time := 0.0
var _rng := RandomNumberGenerator.new()
var _font: Font


func _init(cam: Camera2D = null) -> void:
	camera = cam
	z_index = 50


func _ready() -> void:
	_font = UiTheme.font(600)


func _process(delta: float) -> void:
	hitstop_left = maxf(0.0, hitstop_left - delta)
	if camera == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := _shake * clampf(_shake_time / 0.25, 0.0, 1.0)
		camera.offset = Vector2(_rng.randf_range(-k, k), _rng.randf_range(-k, k))
	else:
		camera.offset = Vector2.ZERO


func reduce_motion() -> bool:
	return Settings.reduce_motion()


func shake(strength: float = 8.0, duration: float = 0.25) -> void:
	if reduce_motion():
		return
	_shake = maxf(_shake if _shake_time > 0.0 else 0.0, strength)
	_shake_time = maxf(_shake_time, duration)


func hitstop(seconds: float = 0.06) -> void:
	hitstop_left = maxf(hitstop_left, seconds)


func is_frozen() -> bool:
	return hitstop_left > 0.0


## Text that rises and fades at a world position ("+12%", "KO!").
func popup(text: String, at: Vector2, color: Color = Pal.SNOW, size: int = 30) -> void:
	add_child(_Popup.new(text, at, color, size, _font))


## A one-shot confetti burst.
func burst(at: Vector2, colors: PackedColorArray = PackedColorArray(), amount: int = 40) -> void:
	if colors.is_empty():
		colors = PackedColorArray([Pal.GOLD, Pal.RED, Pal.SKY, Pal.GREEN, Pal.SNOW])
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount if not reduce_motion() else int(amount / 3.0)
	p.lifetime = 1.1
	p.spread = 180.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 420.0
	p.gravity = Vector2(0, 520)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(i / maxf(1.0, colors.size() - 1.0))
	var ramp := Gradient.new()
	ramp.offsets = offsets
	ramp.colors = colors
	p.color_initial_ramp = ramp
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


class _Popup:
	extends Node2D
	var _text: String
	var _color: Color
	var _size: int
	var _font: Font
	var _t := 0.0

	func _init(text: String, at: Vector2, color: Color, size: int, font: Font) -> void:
		_text = text
		_color = color
		_size = size
		_font = font
		position = at

	func _process(delta: float) -> void:
		_t += delta
		position.y -= 60.0 * delta
		if _t > 0.9:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.4 - _t * 1.5, 0.0, 1.0)
		var w := _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
		var at := Vector2(-w * 0.5, 0)
		draw_string_outline(_font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, 6, Color(Pal.INK, a))
		draw_string(_font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, Color(_color, a))
