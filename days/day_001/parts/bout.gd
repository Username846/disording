extends Node2D
## One bout of Toybox Ring-Out: the arena, the toys and the ring-out rules.
## The game script drives it with step(dt) and listens to its signals.

signal ended(player_won: bool)
signal toy_fell(toy: Node2D)
signal referee_fell(at: Vector2)
signal sound(sfx_name: StringName, opts: Dictionary)
signal impact(strength: float, at: Vector2, player_involved: bool)

const Arena := preload("res://days/day_001/parts/arena.gd")
const Toy := preload("res://days/day_001/parts/toy.gd")
const Brain := preload("res://days/day_001/parts/brain.gd")
const OVERTIME_AFTER := 110.0
const DAMAGE_PER_SPEED := 0.02
## The player's tin knight is sturdier than the rivals.
const PLAYER_DAMAGE_TAKEN := 0.8
const PICKUP_EVERY := Vector2(14.0, 20.0)
const PICKUP_LIFETIME := 12.0
const PICKUP_KINDS: Array[StringName] = [&"marble", &"balloon", &"magnet"]
const LEAP_TIME := 0.95
const MIN_DRAG := 18.0
## A toy drifting over the edge slower than this teeters instead of falling...
const TEETER_SPEED := 260.0
## ...and gets this long, while being pulled back, before it drops anyway.
const TEETER_TIME := 0.7
const FULL_DRAG := 170.0

var index := 0
var arena: RefCounted
var world := CircleWorld.new()
var toys: Array[Node2D] = []
var player: Node2D
var referee: Node2D
var rng: RandomNumberGenerator
var time := 0.0
var running := false
var finished := false
var overtime := false
var pickups: Array[Dictionary] = []
var pickup_timer := 16.0
## When set, the player's toy is driven by this brain (tests and tuning).
var autopilot: RefCounted
var leap_target := Vector2.ZERO
## Every ring-out this bout: {kind, by (kind or ""), t}. Used for tuning and tests.
var fall_log: Array[Dictionary] = []

var _pending_flick := Vector2.ZERO
var _pending_left := 0.0
var _was_cooling := false
var _prop_reset: Dictionary = {}  # prop index -> seconds left


func setup(bout_index: int, random: RandomNumberGenerator) -> void:
	index = bout_index
	rng = random
	arena = Arena.new(index)
	arena.build(world)
	world.collided.connect(_on_collided)
	world.bumped.connect(_on_bumped)
	player = _add_toy(&"knight", arena.spawns[0], true)
	for i in arena.rivals.size():
		var rival := _add_toy(arena.rivals[i], arena.spawns[i + 1])
		rival.brain = Brain.new().for_kind(rival.kind, index)
		rival.think_wait = 0.6 + i * 0.5
	if index == 4:
		referee = _add_toy(&"ref", arena.referee_path[0])
	pickup_timer = rng.randf_range(PICKUP_EVERY.x, PICKUP_EVERY.y)


func _add_toy(kind: StringName, at: Vector2, is_player: bool = false) -> Node2D:
	var toy := Toy.new()
	toy.setup(kind, at, is_player)
	add_child(toy)
	world.add(toy.body)
	toys.append(toy)
	return toy


func rivals() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for toy in toys:
		if not toy.is_player and not toy.is_referee:
			out.append(toy)
	return out


func rival_names() -> String:
	var names := PackedStringArray()
	for toy in rivals():
		names.append(toy.display_name)
	return " & ".join(names)


## Visual-only update (intro countdown, results banner).
func animate(dt: float) -> void:
	arena.t += dt
	for toy in toys:
		toy.tick(dt)
	queue_redraw()


func on_beat() -> void:
	for toy in toys:
		toy.bob = 1.0


# --- Player input ---------------------------------------------------------------------------


## `drag` is the slingshot vector: press point minus current pointer position.
func aim_player(drag: Vector2) -> void:
	if not player.is_active():
		player.aim = Vector2.ZERO
		return
	player.aiming = true
	player.aim = (
		drag.normalized() * clampf(drag.length() / FULL_DRAG, 0.0, 1.0) if drag.length() > MIN_DRAG else Vector2.ZERO
	)


func release_player(drag: Vector2) -> void:
	player.aiming = false
	player.aim = Vector2.ZERO
	if drag.length() < MIN_DRAG or not player.is_active():
		return
	var power := clampf(drag.length() / FULL_DRAG, 0.0, 1.0)
	var velocity := drag.normalized() * lerpf(250.0, Toy.MAX_FLICK, power)
	if player.can_flick():
		_flick(player, velocity)
	elif player.cooldown < 0.5:
		# Released a moment early: fire as soon as the key is wound.
		_pending_flick = velocity
		_pending_left = 0.6


func _flick(toy: Node2D, velocity: Vector2) -> void:
	toy.flick(velocity)
	var pitch := 1.0
	match toy.kind:
		&"dino", &"champ":
			pitch = 0.8
		&"ninja":
			pitch = 1.25
	sound.emit(&"flick", {"pitch": pitch, "pitch_jitter": 0.05, "volume_db": 0.0 if toy.is_player else -4.0})


# --- Simulation -----------------------------------------------------------------------------


func step(dt: float) -> void:
	if not running or finished:
		return
	time += dt
	overtime = time > OVERTIME_AFTER
	var bonus := maxf(0.0, time - OVERTIME_AFTER) * 0.006
	for toy in toys:
		toy.tick(dt)
		if overtime and not toy.is_referee:
			toy.body.knockback += bonus
	_update_player(dt)
	_update_rivals(dt)
	_update_leaps(dt)
	_update_referee(dt)
	_update_pickups(dt)
	_update_magnets()
	var bodies: Array[CircleBody] = []
	for toy in toys:
		if not toy.is_referee:
			bodies.append(toy.body)
	for prop in arena.props:
		bodies.append(prop)
	arena.update(dt, bodies)
	world.step(dt)
	for toy in toys:
		toy.position = toy.body.pos
	_check_falls()
	_update_props(dt)
	queue_redraw()


func _update_player(dt: float) -> void:
	if autopilot != null:
		if player.can_flick() and player.think_wait <= 0.0:
			var v: Vector2 = autopilot.think(player, toys, arena, arena.damping, rng)
			if v != Vector2.ZERO:
				_flick(player, v)
				player.think_wait = rng.randf_range(autopilot.reaction.x, autopilot.reaction.y)
			else:
				player.think_wait = 0.2
		return
	if _pending_left > 0.0:
		_pending_left -= dt
		if player.can_flick():
			_flick(player, _pending_flick)
			_pending_left = 0.0
	var cooling: bool = player.cooldown > 0.0
	if _was_cooling and not cooling and player.is_active():
		sound.emit(&"ready", {"volume_db": -6.0})
	_was_cooling = cooling


func _update_rivals(dt: float) -> void:
	for toy in rivals():
		if not toy.is_active() or toy.leap_time > 0.0:
			continue
		if toy.telegraph > 0.0:
			toy.telegraph -= dt
			if toy.telegraph <= 0.0:
				_flick(toy, toy.queued)
				toy.think_wait = rng.randf_range(toy.brain.reaction.x, toy.brain.reaction.y)
			continue
		if not toy.can_flick() or toy.think_wait > 0.0 or time < 0.8:
			continue
		var v: Vector2 = toy.brain.think(toy, toys, arena, arena.damping, rng)
		if v == Vector2.ZERO:
			toy.think_wait = 0.25
		elif toy.brain.telegraph > 0.0:
			toy.queue_flick(v, toy.brain.telegraph)
		else:
			_flick(toy, v)


## The jack-in-the-box champion springs across the lid and lands with a shockwave.
func _update_leaps(dt: float) -> void:
	for toy in toys:
		if toy.kind != &"champ" or not toy.is_active():
			continue
		if toy.leap_time > 0.0:
			toy.leap_time -= dt
			var k := clampf(1.0 - toy.leap_time / LEAP_TIME, 0.0, 1.0)
			toy.body.pos = toy.leap_from.lerp(toy.leap_to, k)
			if toy.leap_time <= 0.0:
				_land(toy)
			continue
		toy.leap_cooldown -= dt
		if toy.leap_cooldown <= 0.0 and toy.telegraph <= 0.0 and time > 4.0:
			var prey: Node2D = player if rng.randf() < 0.7 and player.is_active() else toy
			var spot: Vector2 = prey.body.pos + prey.body.vel * 0.4
			if prey == toy or not arena.contains(spot) or arena.edge_distance(spot) < 70.0:
				spot = arena.random_point(rng, 90.0)
			toy.leap_from = toy.body.pos
			toy.leap_to = spot
			toy.leap_time = LEAP_TIME
			toy.body.kinematic = true
			toy.body.vel = Vector2.ZERO
			leap_target = spot
			sound.emit(&"spring", {})


func _land(toy: Node2D) -> void:
	toy.leap_time = 0.0
	toy.body.kinematic = false
	toy.body.pos = toy.leap_to
	toy.leap_cooldown = rng.randf_range(6.0, 8.5)
	for other in toys:
		if other == toy or not other.is_active() or other.invuln > 0.0:
			continue
		var d: Vector2 = other.body.pos - toy.body.pos
		var dist := d.length()
		if dist < 160.0 and dist > 0.0:
			var falloff := 1.0 - dist / 160.0
			other.body.vel += d / dist * 640.0 * falloff * other.body.knockback
			other.damage += 11.0 * falloff * _damage_scale(other)
			other.last_hitter = toy
			other.last_hit_time = time
	sound.emit(&"hit_heavy", {"pitch": 0.8})
	impact.emit(900.0, toy.body.pos, true)


## The referee shuffles along the lid's edge. He is heavy: only a full-power flick (or a
## rival bounced into him) moves him much, which is exactly the secret.
func _update_referee(_dt: float) -> void:
	if referee == null or not referee.is_active():
		return
	var path: PackedVector2Array = arena.referee_path
	var target: Vector2 = path[int(referee.get_meta("waypoint", 1)) % path.size()]
	if referee.body.pos.distance_to(target) < 24.0:
		referee.set_meta("waypoint", int(referee.get_meta("waypoint", 1)) + 1)
	var desired: Vector2 = (target - referee.body.pos).normalized() * 95.0
	referee.body.accel += (desired - referee.body.vel) * 2.2


func _update_pickups(dt: float) -> void:
	pickup_timer -= dt
	if pickup_timer <= 0.0:
		pickup_timer = rng.randf_range(PICKUP_EVERY.x, PICKUP_EVERY.y)
		if pickups.is_empty():
			var kind := PICKUP_KINDS[rng.randi() % PICKUP_KINDS.size()]
			pickups.append({"kind": kind, "pos": arena.random_point(rng, 90.0), "t": 0.0})
	for i in range(pickups.size() - 1, -1, -1):
		var p: Dictionary = pickups[i]
		p["t"] = float(p["t"]) + dt
		if float(p["t"]) > PICKUP_LIFETIME:
			pickups.remove_at(i)
			continue
		for toy in toys:
			if toy.is_referee or not toy.is_active() or toy.leap_time > 0.0:
				continue
			if toy.body.pos.distance_to(p["pos"]) < toy.radius() + 20.0:
				match p["kind"]:
					&"marble":
						toy.marble_ready = true
					&"balloon":
						toy.float_time = 3.5
					&"magnet":
						toy.magnet_time = 3.0
				sound.emit(&"pickup", {"volume_db": 0.0 if toy.is_player else -6.0})
				pickups.remove_at(i)
				break


func _update_magnets() -> void:
	for holder in toys:
		if holder.magnet_time <= 0.0 or not holder.is_active():
			continue
		for other in toys:
			if other == holder or not other.is_active():
				continue
			var d: Vector2 = holder.body.pos - other.body.pos
			if d.length() < 300.0:
				other.body.accel += d.normalized() * 700.0


func _update_props(dt: float) -> void:
	for i in arena.props.size():
		var prop: CircleBody = arena.props[i]
		if prop.enabled and not arena.contains(prop.pos):
			prop.enabled = false
			_prop_reset[i] = 7.0
			sound.emit(&"ringout", {"pitch": 0.7, "volume_db": -8.0})
		elif not prop.enabled:
			_prop_reset[i] = float(_prop_reset.get(i, 7.0)) - dt
			if _prop_reset[i] <= 0.0:
				prop.pos = arena.prop_homes[i]
				prop.vel = Vector2.ZERO
				prop.enabled = true


func _check_falls() -> void:
	for toy in toys:
		match toy.state:
			Toy.State.ALIVE:
				if toy.leap_time > 0.0 or toy.float_time > 0.0:
					continue
				if arena.contains(toy.body.pos):
					toy.teeter = 0.0
					continue
				if toy.body.speed() < TEETER_SPEED and toy.teeter < TEETER_TIME:
					if toy.teeter == 0.0:
						sound.emit(&"tilt", {"volume_db": -6.0, "pitch_jitter": 0.1})
					toy.teeter += 1.0 / 120.0
					var inward: Vector2 = arena.closest_edge_point(toy.body.pos) - toy.body.pos
					toy.body.accel += inward.normalized() * 1400.0
					continue
				if not arena.contains(toy.body.pos):
					toy.start_fall()
					var hitter: Node2D = toy.last_hitter if time - toy.last_hit_time < 3.0 else null
					fall_log.append(
						{
							"kind": toy.kind,
							"by": hitter.kind if hitter != null else &"",
							"t": time,
							"damage": toy.damage
						}
					)
					sound.emit(&"ringout", {"volume_db": 0.0 if toy.is_player else -3.0})
					toy_fell.emit(toy)
					if toy.is_referee:
						referee_fell.emit(toy.body.pos)
			Toy.State.FALLING:
				if toy.state_time >= Toy.FALL_TIME:
					if not toy.is_referee:
						toy.stocks -= 1
					toy.state_time = 0.0
					toy.state = Toy.State.WAITING if toy.stocks > 0 else Toy.State.OUT
					if _check_end():
						return
			Toy.State.WAITING:
				var wait := 6.0 if toy.is_referee else Toy.RESPAWN_WAIT
				if toy.state_time >= wait:
					toy.respawn(_spawn_point(toy))
					if toy.is_referee:
						toy.set_meta("waypoint", 1)
					sound.emit(&"respawn", {"volume_db": 0.0 if toy.is_player else -6.0})


func _check_end() -> bool:
	if player.state == Toy.State.OUT:
		_finish(false)
		return true
	for toy in rivals():
		if toy.state != Toy.State.OUT:
			return false
	_finish(true)
	return true


func _finish(player_won: bool) -> void:
	finished = true
	running = false
	ended.emit(player_won)


func _spawn_point(toy: Node2D) -> Vector2:
	if toy.is_referee:
		return arena.referee_path[0]
	var best: Vector2 = arena.spawns[0]
	var best_gap := -INF
	for spot: Vector2 in arena.spawns:
		var gap := INF
		for other in toys:
			if other != toy and other.is_active():
				gap = minf(gap, spot.distance_to(other.body.pos))
		if gap > best_gap:
			best_gap = gap
			best = spot
	return best


func _on_collided(a: CircleBody, b: CircleBody, impulse: float, n: Vector2) -> void:
	# Recover the pre-collision approach speeds to split the damage fairly:
	# the toy that was hit takes damage from the other's speed into it.
	var va := a.vel + n * impulse * a.inv_mass() * a.knockback
	var vb := b.vel - n * impulse * b.inv_mass() * b.knockback
	var speed_a := maxf(0.0, va.dot(n))
	var speed_b := maxf(0.0, -vb.dot(n))
	var ta: Node2D = a.owner as Node2D
	var tb: Node2D = b.owner as Node2D
	var mass_a := a.mass if not a.kinematic else 1.2
	var mass_b := b.mass if not b.kinematic else 1.2
	if tb != null and speed_a > 120.0:
		tb.damage += DAMAGE_PER_SPEED * speed_a * mass_a * _damage_scale(tb)
		if ta != null:
			tb.last_hitter = ta
			tb.last_hit_time = time
	if ta != null and speed_b > 120.0:
		ta.damage += DAMAGE_PER_SPEED * speed_b * mass_b * _damage_scale(ta)
		if tb != null:
			ta.last_hitter = tb
			ta.last_hit_time = time
	var strength := maxf(speed_a, speed_b)
	if strength < 90.0:
		return
	if a.kinematic or b.kinematic:
		sound.emit(&"squeak" if index == 2 else &"train", {"volume_db": -2.0})
	elif strength > 650.0:
		sound.emit(&"hit_heavy", {"pitch_jitter": 0.06})
	else:
		sound.emit(&"hit_light", {"pitch_jitter": 0.1, "volume_db": -3.0})
	var involved: bool = (ta != null and ta.is_player) or (tb != null and tb.is_player)
	impact.emit(strength, (a.pos + b.pos) * 0.5, involved)


func _damage_scale(toy: Node2D) -> float:
	if toy.is_referee:
		return 0.5
	return PLAYER_DAMAGE_TAKEN if toy.is_player else 1.0


func _on_bumped(_body: CircleBody, _segment: int, speed: float) -> void:
	if speed > 200.0:
		sound.emit(&"hit_light", {"pitch": 0.6, "volume_db": -8.0})


# --- Drawing --------------------------------------------------------------------------------


func _draw() -> void:
	arena.draw(self)
	for prop: CircleBody in arena.props:
		if prop.enabled:
			_draw_book(prop)
	if index == 2 and not arena.movers.is_empty():
		_draw_duck(arena.movers[0])
	elif index == 3:
		for i in arena.movers.size():
			_draw_car(arena.movers[i], i == 0)
	for p in pickups:
		_draw_pickup(p)
	for toy in toys:
		if toy.kind == &"champ" and toy.leap_time > 0.0:
			draw_arc(toy.leap_to, 70.0, 0.0, TAU, 40, Color(Pal.RED, 0.8), 4.0, true)
			draw_circle(toy.leap_to, 70.0 * (1.0 - toy.leap_time / LEAP_TIME), Color(Pal.RED, 0.18))


func _draw_book(prop: CircleBody) -> void:
	var colors := [Color("c0392b"), Color("2e86c1"), Color("27ae60")]
	var c: Color = colors[arena.props.find(prop) % colors.size()]
	var r := Rect2(prop.pos - Vector2(26, 34), Vector2(52, 68))
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, c)
	draw_rect(Rect2(r.position + Vector2(0, 10), Vector2(52, 8)), c.lightened(0.3))
	draw_rect(Rect2(r.position + Vector2(0, 50), Vector2(52, 8)), c.lightened(0.3))


func _draw_duck(duck: CircleBody) -> void:
	var p := duck.pos
	draw_circle(p + Vector2(5, 8), duck.radius, Color(0, 0, 0, 0.25))
	draw_circle(p, duck.radius, Color("f7d02c"))
	draw_circle(p + Vector2(18, -14), 16.0, Color("f7d02c"))
	draw_colored_polygon(
		PackedVector2Array([p + Vector2(30, -18), p + Vector2(46, -12), p + Vector2(30, -8)]), Color("f08a24")
	)
	draw_circle(p + Vector2(22, -18), 3.5, Pal.INK)


func _draw_car(car: CircleBody, engine: bool) -> void:
	var angle := car.vel.angle()
	draw_set_transform(car.pos, angle, Vector2.ONE)
	draw_rect(Rect2(-30, -20, 60, 40), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-28, -18, 56, 36), Pal.RED if engine else Color("2e86c1"))
	draw_rect(Rect2(-14, -12, 28, 24), Color(1, 1, 1, 0.3))
	if engine:
		draw_circle(Vector2(20, 0), 8.0, Pal.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pickup(p: Dictionary) -> void:
	var pos: Vector2 = p["pos"] + Vector2(0, sin(float(p["t"]) * 4.0) * 4.0)
	var fade := clampf((PICKUP_LIFETIME - float(p["t"])) / 2.0, 0.2, 1.0)
	draw_circle(pos, 22.0, Color(1, 1, 1, 0.25 * fade))
	match p["kind"]:
		&"marble":
			draw_circle(pos, 13.0, Color(Pal.SKY, fade))
			draw_circle(pos + Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.8 * fade))
		&"balloon":
			draw_line(pos + Vector2(0, 12), pos + Vector2(3, 24), Color(Pal.SNOW, fade), 2.0)
			draw_circle(pos, 13.0, Color(Pal.RED, fade))
		&"magnet":
			draw_arc(pos, 11.0, PI, TAU, 12, Color(Pal.RED, fade), 7.0)
			draw_rect(Rect2(pos + Vector2(-14, 0), Vector2(7, 9)), Color(Pal.SNOW, fade))
			draw_rect(Rect2(pos + Vector2(7, 0), Vector2(7, 9)), Color(Pal.SNOW, fade))
