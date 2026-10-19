class_name CircleWorld
extends RefCounted
## Lightweight, deterministic top-down circle physics (PLAN.md §3.7): bodies, impulses with
## restitution, exponential damping and static bumper segments. Far cheaper than physics
## servers for a few dozen bodies, and fully under the game's control.

## Two bodies touched. `impulse` is the normal impulse (0 when they were only separating).
signal collided(a: CircleBody, b: CircleBody, impulse: float, normal: Vector2)
## A body bounced off a bumper segment at `speed` (normal component before the bounce).
signal bumped(body: CircleBody, segment_index: int, speed: float)

var bodies: Array[CircleBody] = []
var segments: Array[Dictionary] = []  # {a, b, restitution, boost}
## Per-second exponential velocity damping.
var damping := 1.5
var max_speed := 2600.0
var iterations := 2


func add(body: CircleBody) -> CircleBody:
	bodies.append(body)
	return body


func remove(body: CircleBody) -> void:
	bodies.erase(body)


## A static bouncy wall from a to b. `boost` adds a fixed outward kick (pillows, bumpers).
func add_segment(a: Vector2, b: Vector2, restitution: float = 0.9, boost: float = 0.0) -> int:
	segments.append({"a": a, "b": b, "restitution": restitution, "boost": boost})
	return segments.size() - 1


func step(dt: float) -> void:
	for body in bodies:
		if not body.enabled:
			continue
		if body.kinematic:
			body.pos += body.vel * dt
			continue
		body.vel += body.accel * dt
		body.vel *= exp(-damping * body.damping_scale * dt)
		body.vel = body.vel.limit_length(max_speed)
		body.pos += body.vel * dt
		body.accel = Vector2.ZERO
	for _i in iterations:
		_collide_bodies()
		_collide_segments()


func _collide_bodies() -> void:
	var count := bodies.size()
	for i in count:
		var a := bodies[i]
		if not a.enabled or a.ghost:
			continue
		for j in range(i + 1, count):
			var b := bodies[j]
			if not b.enabled or b.ghost:
				continue
			var d := b.pos - a.pos
			var min_dist := a.radius + b.radius
			var dist_sq := d.length_squared()
			if dist_sq >= min_dist * min_dist or dist_sq == 0.0:
				continue
			var ia := a.inv_mass()
			var ib := b.inv_mass()
			var total := ia + ib
			if total == 0.0:
				continue
			var dist := sqrt(dist_sq)
			var n := d / dist
			var overlap := min_dist - dist
			a.pos -= n * overlap * ia / total
			b.pos += n * overlap * ib / total
			var vn := (a.vel - b.vel).dot(n)
			if vn <= 0.0:
				continue
			var e := maxf(a.restitution, b.restitution)
			var impulse := (1.0 + e) * vn / total
			a.vel -= n * impulse * ia * a.knockback
			b.vel += n * impulse * ib * b.knockback
			collided.emit(a, b, impulse, n)


func _collide_segments() -> void:
	for body in bodies:
		if not body.enabled or body.ghost or body.kinematic:
			continue
		for k in segments.size():
			var seg: Dictionary = segments[k]
			var closest := Geometry2D.get_closest_point_to_segment(body.pos, seg["a"], seg["b"])
			var d := body.pos - closest
			var dist := d.length()
			if dist >= body.radius or dist == 0.0:
				continue
			var n := d / dist
			body.pos = closest + n * body.radius
			var vn := body.vel.dot(n)
			if vn < 0.0:
				body.vel -= n * vn * (1.0 + float(seg["restitution"]))
				body.vel += n * float(seg["boost"])
				bumped.emit(body, k, -vn)
