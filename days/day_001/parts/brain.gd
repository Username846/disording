extends RefCounted
## Rival AI for Toybox Ring-Out. Each think() picks a target, aims to knock it toward its
## nearest edge and refuses most flicks that would carry itself off the platform.
## The same brain (with high skill and no telegraph) drives the autoplay test bot.

## 0 = clumsy, 1 = sharp. Scales aim error, caution and target choice.
var skill := 0.5
var aim_error_deg := 14.0
## Fraction of the maximum flick speed this toy will use.
var power := 0.85
## Seconds the aim line is shown before the flick fires (gives the player time to react).
var telegraph := 0.5
## Extra random wait after each flick before thinking again.
var reaction := Vector2(0.3, 0.8)
var player_bias := 0.25


## Tunes this brain for a rival kind in bout `bout_index` (0..4). Returns self.
func for_kind(kind: StringName, bout_index: int) -> RefCounted:
	var brain := self
	# Rivals sharpen up over the five bouts.
	var sharpen := clampf(bout_index / 4.0, 0.0, 1.0)
	match kind:
		&"dino":
			# Bout 1's teacher: slow, readable, a little clumsy.
			brain.power = 0.82
			brain.aim_error_deg = 18.0
			brain.telegraph = 0.65
			brain.reaction = Vector2(1.0, 1.6)
		&"ninja":
			brain.power = 0.72
			brain.aim_error_deg = 11.0
			brain.telegraph = 0.42
			brain.reaction = Vector2(0.1, 0.4)
		&"bear":
			brain.power = 0.8
			brain.aim_error_deg = 18.0
			brain.telegraph = 0.5
			brain.reaction = Vector2(0.4, 0.9)
		&"robot":
			brain.power = 1.0
			brain.aim_error_deg = 21.0
			brain.telegraph = 0.45
			brain.reaction = Vector2(0.3, 0.7)
		&"champ":
			brain.power = 0.95
			brain.aim_error_deg = 9.0
			brain.telegraph = 0.42
			brain.reaction = Vector2(0.2, 0.5)
			brain.player_bias = 0.6
	brain.skill = lerpf(0.35, 0.75, sharpen)
	brain.aim_error_deg *= lerpf(1.15, 0.75, sharpen)
	brain.telegraph *= lerpf(1.1, 0.85, sharpen)
	return brain


## Tunes this brain to drive the player's toy (tests and tuning). Returns self.
func autopilot(skill_level: float) -> RefCounted:
	var brain := self
	brain.skill = skill_level
	brain.aim_error_deg = lerpf(18.0, 4.0, skill_level)
	brain.power = lerpf(0.75, 1.0, skill_level)
	brain.telegraph = 0.0
	brain.reaction = Vector2(lerpf(0.6, 0.0, skill_level), lerpf(1.2, 0.2, skill_level))
	brain.player_bias = 0.0
	return brain


## Returns a launch velocity, or Vector2.ZERO to wait.
func think(me: Node2D, toys: Array, arena: RefCounted, damping: float, rng: RandomNumberGenerator) -> Vector2:
	var my_body: CircleBody = me.body
	var target: Node2D = _pick_target(me, toys, arena, rng)
	var edge: float = arena.edge_distance(my_body.pos)
	if target == null:
		return _retreat(my_body, arena, damping) if edge < 90.0 else Vector2.ZERO
	var tb: CircleBody = target.body
	var to_edge: Vector2 = (arena.closest_edge_point(tb.pos) - tb.pos).normalized()
	var aim_point: Vector2 = tb.pos + tb.vel * 0.25 - to_edge * tb.radius * 0.65
	var offset := aim_point - my_body.pos
	var dist := offset.length()
	if dist < 1.0:
		return Vector2.ZERO
	var dir := offset / dist
	dir = dir.rotated(deg_to_rad(rng.randf_range(-aim_error_deg, aim_error_deg)))
	var impact := 520.0 * power
	var speed := clampf(dist * damping + impact, 260.0, 1050.0 * power)
	# Don't sail off the edge: cap the stopping distance unless the target is in the way.
	var exit: float = arena.ray_exit(my_body.pos, dir)
	var stop := speed / damping
	if stop > exit - my_body.radius and rng.randf() < 0.55 + skill * 0.45:
		var safe := maxf(dist + 40.0, exit - my_body.radius - 30.0)
		if safe > exit - my_body.radius:
			# Even reaching the target would carry us over: look for something safer.
			return _retreat(my_body, arena, damping) if edge < 120.0 else Vector2.ZERO
		speed = minf(speed, safe * damping)
	if edge < 70.0 and dist > 260.0:
		return _retreat(my_body, arena, damping)
	return dir * speed


func _pick_target(me: Node2D, toys: Array, arena: RefCounted, rng: RandomNumberGenerator) -> Node2D:
	var best: Node2D = null
	var best_score := -INF
	for other: Node2D in toys:
		if other == me or not other.is_active() or other.is_referee or other.invuln > 0.0 or other.leap_time > 0.0:
			continue
		var ob: CircleBody = other.body
		var dist: float = me.body.pos.distance_to(ob.pos)
		var near_edge := 1.0 - clampf(arena.edge_distance(ob.pos) / 200.0, 0.0, 1.0)
		var score: float = 260.0 / (dist + 120.0) + other.damage / 110.0 + near_edge * 1.1
		if other.is_player:
			score += player_bias
		score += rng.randf_range(0.0, 0.6) * (1.0 - skill)
		if score > best_score:
			best_score = score
			best = other
	return best


func _retreat(body: CircleBody, arena: RefCounted, damping: float) -> Vector2:
	var inward: Vector2 = (body.pos - arena.closest_edge_point(body.pos)).normalized()
	if not arena.contains(body.pos) or inward == Vector2.ZERO:
		inward = -body.pos.normalized()
	var toward_center := (-body.pos).normalized()
	var dir := (inward + toward_center).normalized()
	return dir * clampf(140.0 * damping + 120.0, 200.0, 520.0)
