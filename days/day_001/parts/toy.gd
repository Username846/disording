extends Node2D
## One wind-up toy: physics body, stocks, damage %, flick cooldown, pickups and drawing.

enum State { ALIVE, FALLING, WAITING, OUT }

const ToyArt := preload("res://days/day_001/parts/toy_art.gd")
const MAX_FLICK := 900.0
const FALL_TIME := 0.7
const RESPAWN_WAIT := 1.0
const INVULN_TIME := 1.6
const KNOCKBACK_BASE := 0.45
const KNOCKBACK_PER := 160.0
const KINDS := {
	&"knight": {"name": "Tin Knight", "radius": 30.0, "mass": 1.25, "restitution": 0.75},
	&"dino": {"name": "Rubber Dino", "radius": 36.0, "mass": 1.35, "restitution": 0.6},
	&"ninja": {"name": "Yo-yo Ninja", "radius": 26.0, "mass": 0.8, "restitution": 0.8},
	&"bear": {"name": "Plush Bear", "radius": 33.0, "mass": 1.0, "restitution": 1.05},
	&"robot": {"name": "Dash Robot", "radius": 31.0, "mass": 1.1, "restitution": 0.7},
	&"champ": {"name": "Jack-in-the-Box", "radius": 36.0, "mass": 1.3, "restitution": 0.75},
	&"ref": {"name": "Referee", "radius": 30.0, "mass": 3.2, "restitution": 0.4},
}

var kind: StringName = &"knight"
var display_name := ""
var is_player := false
var is_referee := false
var body: CircleBody
var base_mass := 1.0
var stocks := 3
var damage := 0.0
var state := State.ALIVE
var state_time := 0.0
var cooldown := 0.0
var cooldown_max := 1.2
var invuln := 0.0
var facing := 0.0
## Aim preview (player drag or AI telegraph): unit direction scaled by power 0..1.
var aim := Vector2.ZERO
var aiming := false
## AI: seconds until the queued flick fires (shown as a telegraph line).
var telegraph := 0.0
var queued := Vector2.ZERO
var brain: RefCounted
var think_wait := 0.0
var marble_ready := false
var heavy_time := 0.0
var float_time := 0.0
var magnet_time := 0.0
var last_hitter: Node2D
var last_hit_time := -100.0
var leap_time := 0.0
var leap_from := Vector2.ZERO
var leap_to := Vector2.ZERO
var leap_cooldown := 7.0
var bob := 0.0
var t := 0.0
## Seconds spent teetering over the edge (slow toys get a moment to wobble back).
var teeter := 0.0

var _font: Font


func setup(toy_kind: StringName, at: Vector2, player: bool = false) -> void:
	kind = toy_kind
	is_player = player
	is_referee = toy_kind == &"ref"
	var spec: Dictionary = KINDS[kind]
	display_name = spec["name"]
	body = CircleBody.new(at, spec["radius"], spec["mass"])
	body.restitution = spec["restitution"]
	body.owner = self
	base_mass = body.mass
	if is_referee:
		body.damping_scale = 1.8
		stocks = 99
	position = at
	_font = UiTheme.font(600)


func radius() -> float:
	return body.radius


func is_active() -> bool:
	return state == State.ALIVE


func can_flick() -> bool:
	return state == State.ALIVE and cooldown <= 0.0 and leap_time <= 0.0 and telegraph <= 0.0 and not is_referee


## Launches the toy. `velocity` is already capped by the caller.
func flick(velocity: Vector2) -> void:
	if marble_ready:
		marble_ready = false
		velocity *= 1.4
		heavy_time = 1.2
		body.mass = base_mass * 1.6
	body.vel = velocity
	facing = velocity.angle()
	cooldown = cooldown_max
	aim = Vector2.ZERO
	aiming = false
	scale = Vector2(1.18, 0.86)


func queue_flick(velocity: Vector2, delay: float) -> void:
	queued = velocity
	telegraph = delay
	aim = velocity / MAX_FLICK
	facing = velocity.angle()


func tick(dt: float) -> void:
	t += dt
	state_time += dt
	cooldown = maxf(0.0, cooldown - dt)
	think_wait = maxf(0.0, think_wait - dt)
	invuln = maxf(0.0, invuln - dt)
	float_time = maxf(0.0, float_time - dt)
	magnet_time = maxf(0.0, magnet_time - dt)
	bob = maxf(0.0, bob - dt * 4.0)
	if heavy_time > 0.0:
		heavy_time -= dt
		if heavy_time <= 0.0:
			body.mass = base_mass
	body.ghost = invuln > 0.0 or leap_time > 0.0 or state != State.ALIVE
	# Light hits at low damage barely move a toy; knockback grows with damage %.
	body.knockback = KNOCKBACK_BASE + damage / KNOCKBACK_PER
	scale = scale.lerp(Vector2.ONE, 1.0 - exp(-10.0 * dt))
	if state == State.FALLING:
		var k := clampf(state_time / FALL_TIME, 0.0, 1.0)
		scale = Vector2.ONE * (1.0 - k * 0.8)
		rotation += dt * 9.0
		modulate.a = 1.0 - k
	else:
		rotation = 0.0
		modulate.a = 0.45 + 0.4 * sin(t * 30.0) if invuln > 0.0 else 1.0
	if teeter > 0.0 and state == State.ALIVE:
		rotation = sin(t * 40.0) * 0.18
	if body.vel.length() > 60.0 and state == State.ALIVE:
		facing = lerp_angle(facing, body.vel.angle(), 1.0 - exp(-6.0 * dt))
	position = body.pos
	queue_redraw()


func start_fall() -> void:
	state = State.FALLING
	state_time = 0.0
	body.enabled = false
	telegraph = 0.0
	aim = Vector2.ZERO
	aiming = false
	leap_time = 0.0
	teeter = 0.0


func respawn(at: Vector2) -> void:
	state = State.ALIVE
	state_time = 0.0
	damage = 0.0
	body.pos = at
	body.vel = Vector2.ZERO
	body.enabled = true
	body.kinematic = false
	body.mass = base_mass
	heavy_time = 0.0
	invuln = INVULN_TIME
	cooldown = 0.4
	scale = Vector2.ONE
	rotation = 0.0
	modulate.a = 1.0
	position = at


func _draw() -> void:
	if state == State.OUT or state == State.WAITING:
		return
	var r := radius()
	var lift := 0.0
	if leap_time > 0.0:
		var k := clampf(1.0 - leap_time / 0.95, 0.0, 1.0)
		lift = sin(k * PI)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(0, 8), r * (1.0 - lift * 0.3), Color(0, 0, 0, 0.25))
	else:
		draw_circle(Vector2(4, 8), r, Color(0, 0, 0, 0.25))
	if is_player and state == State.ALIVE:
		draw_arc(Vector2.ZERO, r + 9.0, 0.0, TAU, 40, Color(Pal.GOLD, 0.7), 3.0, true)
	_draw_aim(r)
	var size := 1.0 + bob * 0.06 + lift * 0.6
	draw_set_transform(Vector2(0, -lift * 30.0), facing, Vector2.ONE * size)
	ToyArt.draw(self, kind, r, t if cooldown > 0.0 or kind != &"knight" else 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if float_time > 0.0:
		draw_line(Vector2(0, -r), Vector2(10, -r - 40), Pal.SNOW, 2.0)
		draw_circle(Vector2(12, -r - 56), 18.0, Pal.RED)
	if magnet_time > 0.0:
		draw_arc(Vector2.ZERO, r + 22.0 + fmod(t * 60.0, 30.0), 0.0, TAU, 40, Color(Pal.SKY, 0.6), 3.0)
	if marble_ready:
		draw_circle(Vector2(-r * 0.7, -r * 0.7), 9.0, Color("6fb7e0"))
	if is_player and state == State.ALIVE and cooldown > 0.0:
		draw_arc(
			Vector2.ZERO, r + 9.0, -PI / 2, -PI / 2 + TAU * (1.0 - cooldown / cooldown_max), 40, Pal.SNOW, 5.0, true
		)
	if not is_referee and state == State.ALIVE:
		_draw_status(r)


func _draw_aim(r: float) -> void:
	if aim == Vector2.ZERO:
		return
	var dir := aim.normalized()
	var power := aim.length()
	var dots := 3 + int(power * 8.0)
	var col := Pal.GOLD if is_player else Color(ToyArt.color(kind).lightened(0.3), 0.8)
	if is_player and cooldown > 0.0:
		col = Color(Pal.SNOW, 0.5)
	for i in dots:
		var p := dir * (r + 16.0 + i * 20.0)
		draw_circle(p, 5.0 - i * 0.25, col)
	if not is_player:
		draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 32, col, 3.0)


func _draw_status(r: float) -> void:
	var text := "%d%%" % roundi(damage)
	var col := Pal.SNOW.lerp(Pal.GOLD, clampf(damage / 60.0, 0, 1)).lerp(Pal.RED, clampf((damage - 60.0) / 60.0, 0, 1))
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var at := Vector2(-w * 0.5, -r - 14.0)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Pal.INK)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
	for i in stocks:
		draw_circle(Vector2((i - (stocks - 1) * 0.5) * 12.0, r + 12.0), 4.0, Pal.SNOW if not is_player else Pal.GOLD)
