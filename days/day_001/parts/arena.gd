extends RefCounted
## Toybox Ring-Out arenas: platform shape, gimmicks and drawing. World coordinates are
## centred on the arena (0, 0); anything whose centre leaves `polygon` falls off.

const COUNT := 5
const TITLES := ["Pillow Fort", "Bookshelf", "Bathtub", "Train Set", "Toy Box Lid"]
const RIVALS := [
	[&"dino"], [&"ninja", &"bear"], [&"robot", &"dino"], [&"ninja", &"robot", &"bear"], [&"champ", &"bear"]
]

var index := 0
var title := ""
var polygon := PackedVector2Array()
var half_extents := Vector2(400, 230)
var damping := 1.6
var spawns: Array[Vector2] = []
var rivals: Array = []
var void_color := Color("2b2033")
var floor_color := Color("e8b4c8")
var floor_alt := Color("f4d9e4")
## Pillows: bouncy segments on the platform edge.
var bumpers: Array = []  # [[a, b]]
## Moving obstacles the arena drives itself (rubber duck, train cars).
var movers: Array[CircleBody] = []
## Pushable props (books) and where they reset to after falling.
var props: Array[CircleBody] = []
var prop_homes: Array[Vector2] = []
var turntable_radius := 0.0
var turntable_angle := 0.0
var tilt := Vector2.ZERO
var referee_path := PackedVector2Array()
var t := 0.0


func _init(arena_index: int) -> void:
	index = arena_index
	title = TITLES[index]
	rivals = RIVALS[index]
	match index:
		0:
			half_extents = Vector2(410, 230)
			polygon = rounded_rect(half_extents, 60.0)
			damping = 2.4
			spawns = [Vector2(-200, 0), Vector2(200, 0), Vector2(0, -120), Vector2(0, 120)]
			bumpers = [
				[Vector2(-410, -140), Vector2(-410, 140)],
				[Vector2(410, -140), Vector2(410, 140)],
			]
		1:
			half_extents = Vector2(520, 125)
			polygon = rounded_rect(half_extents, 8.0)
			damping = 2.6
			void_color = Color("23303f")
			floor_color = Color("a8743f")
			floor_alt = Color("94632f")
			spawns = [Vector2(-430, 0), Vector2(430, -40), Vector2(430, 45), Vector2(-120, 0)]
			prop_homes = [Vector2(-240, 10), Vector2(40, -35), Vector2(290, 25)]
		2:
			half_extents = Vector2(360, 215)
			polygon = ellipse(half_extents, 40)
			damping = 1.45
			void_color = Color("3c86c0")
			floor_color = Color("f2d36b")
			floor_alt = Color("e3c055")
			spawns = [Vector2(-210, 0), Vector2(210, 0), Vector2(0, -110), Vector2(0, 110)]
		3:
			half_extents = Vector2(450, 250)
			polygon = rounded_rect(half_extents, 40.0)
			damping = 2.3
			void_color = Color("4a2f58")
			floor_color = Color("4f8a5a")
			floor_alt = Color("467d50")
			turntable_radius = 112.0
			spawns = [Vector2(-300, -150), Vector2(300, 150), Vector2(-300, 150), Vector2(300, -150)]
		4:
			half_extents = Vector2(380, 250)
			polygon = rounded_rect(half_extents, 22.0)
			damping = 2.2
			void_color = Color("4d1e2a")
			floor_color = Color("c58a4a")
			floor_alt = Color("b67b3d")
			spawns = [Vector2(-220, 0), Vector2(220, 0), Vector2(0, -150), Vector2(0, 150)]
			referee_path = PackedVector2Array(
				[Vector2(-300, -180), Vector2(300, -180), Vector2(300, 180), Vector2(-300, 180)]
			)


func build(world: CircleWorld) -> void:
	world.damping = damping
	for pair: Array in bumpers:
		world.add_segment(pair[0], pair[1], 0.95, 140.0)
	if index == 1:
		for home in prop_homes:
			var book := CircleBody.new(home, 30.0, 2.6)
			book.restitution = 0.25
			book.damping_scale = 2.2
			props.append(world.add(book))
	elif index == 2:
		var duck := CircleBody.new(Vector2(250, 0), 34.0, 0.0)
		duck.kinematic = true
		duck.restitution = 1.25
		movers.append(world.add(duck))
	elif index == 3:
		for i in 3:
			var car := CircleBody.new(Vector2(340, 0), 24.0, 0.0)
			car.kinematic = true
			car.restitution = 1.0
			movers.append(world.add(car))


## Moves the gimmicks and applies arena forces to the given bodies.
func update(dt: float, bodies: Array[CircleBody]) -> void:
	t += dt
	match index:
		2:
			var duck := movers[0]
			var target := Vector2(cos(t * 0.45) * 250.0, sin(t * 0.45) * 118.0)
			duck.vel = (target - duck.pos) / maxf(dt, 0.001)
		3:
			turntable_angle += dt * 1.0
			for i in movers.size():
				var a := t * 0.7 - i * 0.34
				var target := Vector2(cos(a) * 340.0, sin(a) * 180.0)
				movers[i].vel = (target - movers[i].pos) / maxf(dt, 0.001)
			for body in bodies:
				if body.enabled and not body.kinematic and body.pos.length() < turntable_radius:
					var carry := Vector2(-body.pos.y, body.pos.x) * 1.0
					body.accel += (carry - body.vel) * 2.5
		4:
			var weight := 0.0
			var centroid := Vector2.ZERO
			for body in bodies:
				if body.enabled and not body.ghost:
					centroid += body.pos * body.mass
					weight += body.mass
			var target_tilt := Vector2.ZERO
			if weight > 0.0:
				target_tilt = (centroid / weight / half_extents).limit_length(1.0)
			tilt = tilt.lerp(target_tilt, 1.0 - exp(-1.2 * dt))
			for body in bodies:
				if body.enabled and not body.kinematic:
					body.accel += tilt * 230.0


func contains(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, polygon)


func closest_edge_point(p: Vector2) -> Vector2:
	var best := p
	var best_d := INF
	for i in polygon.size():
		var q := Geometry2D.get_closest_point_to_segment(p, polygon[i], polygon[(i + 1) % polygon.size()])
		var d := p.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best = q
	return best


func edge_distance(p: Vector2) -> float:
	var d := p.distance_to(closest_edge_point(p))
	return d if contains(p) else -d


## Distance along `dir` from `p` until the ray leaves the platform.
func ray_exit(p: Vector2, dir: Vector2) -> float:
	var far := p + dir * 4000.0
	var best := INF
	for i in polygon.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(p, far, polygon[i], polygon[(i + 1) % polygon.size()])
		if hit != null:
			best = minf(best, p.distance_to(hit))
	return best if best < INF else 0.0


func random_point(rng: RandomNumberGenerator, margin: float) -> Vector2:
	for _i in 40:
		var p := Vector2(
			rng.randf_range(-half_extents.x, half_extents.x), rng.randf_range(-half_extents.y, half_extents.y)
		)
		if contains(p) and edge_distance(p) >= margin:
			return p
	return Vector2.ZERO


static func rounded_rect(half: Vector2, radius: float, steps: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(half.x - radius, half.y - radius), 0.0],
		[Vector2(-half.x + radius, half.y - radius), PI * 0.5],
		[Vector2(-half.x + radius, -half.y + radius), PI],
		[Vector2(half.x - radius, -half.y + radius), PI * 1.5],
	]
	for corner: Array in corners:
		for s in steps + 1:
			var a: float = corner[1] + s * (PI * 0.5) / steps
			pts.append((corner[0] as Vector2) + Vector2(cos(a), sin(a)) * radius)
	return pts


static func ellipse(half: Vector2, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := i * TAU / steps
		pts.append(Vector2(cos(a) * half.x, sin(a) * half.y))
	return pts


# --- Drawing -------------------------------------------------------------------------------


func draw(ci: CanvasItem) -> void:
	_draw_void(ci)
	if index == 4:
		# The lid's shadow slides toward the low side, so the tilt is visible.
		var shadow := PackedVector2Array()
		for p in polygon:
			shadow.append(p + tilt * 26.0 + Vector2(0, 14))
		ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.45))
	else:
		var shadow := PackedVector2Array()
		for p in polygon:
			shadow.append(p + Vector2(10, 18))
		ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	ci.draw_colored_polygon(polygon, floor_color)
	match index:
		0:
			_draw_quilt(ci)
		1:
			_draw_planks(ci, true)
		2:
			_draw_sponge(ci)
		3:
			_draw_train_table(ci)
		4:
			_draw_planks(ci, false)
			_draw_level(ci)
	var outline := polygon.duplicate()
	outline.append(polygon[0])
	ci.draw_polyline(outline, floor_color.darkened(0.35), 4.0, true)
	for pair: Array in bumpers:
		_draw_pillow(ci, pair[0], pair[1])


func _draw_void(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(-1400, -900, 2800, 1800), void_color)
	match index:
		0:
			for i in range(-14, 15):
				ci.draw_line(Vector2(-1400, i * 64), Vector2(1400, i * 64), void_color.darkened(0.2), 3.0)
		1:
			ci.draw_rect(Rect2(-700, half_extents.y + 30, 1400, 30), void_color.darkened(0.3))
			ci.draw_rect(Rect2(-700, -half_extents.y - 200, 1400, 30), void_color.darkened(0.3))
		2:
			for i in 9:
				var r := fmod(t * 30.0 + i * 70.0, 640.0) + 380.0
				ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1, 1, 1, 0.12 * (1.0 - r / 1020.0)), 3.0)
		3:
			for x in range(-12, 13):
				for y in range(-8, 9):
					if (x + y) % 2 == 0:
						ci.draw_rect(Rect2(x * 64, y * 64, 64, 64), void_color.lightened(0.05))
		4:
			for i in 6:
				var c := Vector2(-560 + i * 230, 300 + (i % 2) * 60)
				ci.draw_circle(c, 70.0, void_color.lightened(0.08))


func _draw_quilt(ci: CanvasItem) -> void:
	var cell := 68.0
	for x in range(-6, 6):
		for y in range(-4, 4):
			if (x + y) % 2 == 0:
				var r := Rect2(x * cell, y * cell, cell, cell)
				if contains(r.get_center()):
					ci.draw_rect(r.grow(-3), floor_alt)
	for x in range(-6, 7):
		ci.draw_line(
			Vector2(x * cell, -half_extents.y + 20), Vector2(x * cell, half_extents.y - 20), Color(1, 1, 1, 0.25), 2.0
		)


func _draw_pillow(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	var rect_pts := PackedVector2Array(
		[a - n * 26 - dir * 10, b - n * 26 + dir * 10, b + n * 26 + dir * 10, a + n * 26 - dir * 10]
	)
	ci.draw_colored_polygon(rect_pts, Color("fbf3e4"))
	ci.draw_polyline(rect_pts + PackedVector2Array([rect_pts[0]]), Color("d8c7aa"), 3.0, true)
	ci.draw_line((a + b) * 0.5 - dir * 50, (a + b) * 0.5 + dir * 50, Color("d8c7aa"), 2.0)


func _draw_planks(ci: CanvasItem, horizontal_grain: bool) -> void:
	var step := 40.0
	if horizontal_grain:
		for y in range(-3, 4):
			ci.draw_line(Vector2(-half_extents.x + 6, y * step), Vector2(half_extents.x - 6, y * step), floor_alt, 2.0)
	else:
		for x in range(-9, 10):
			ci.draw_line(Vector2(x * step, -half_extents.y + 6), Vector2(x * step, half_extents.y - 6), floor_alt, 3.0)
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			ci.draw_circle((half_extents - Vector2(30, 30)) * corner, 14.0, Pal.GOLD_DEEP)


func _draw_sponge(ci: CanvasItem) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 46:
		var p := Vector2(rng.randf_range(-320, 320), rng.randf_range(-190, 190))
		if contains(p) and edge_distance(p) > 20.0:
			ci.draw_circle(p, rng.randf_range(4, 11), floor_alt)


func _draw_train_table(ci: CanvasItem) -> void:
	var rail := PackedVector2Array()
	for i in 49:
		var a := i * TAU / 48.0
		rail.append(Vector2(cos(a) * 340.0, sin(a) * 180.0))
	ci.draw_polyline(rail, Color("6b4a2b"), 26.0, true)
	ci.draw_polyline(rail, Color("9a7a55"), 4.0, true)
	ci.draw_circle(Vector2.ZERO, turntable_radius, Color("3a6b45"))
	ci.draw_arc(Vector2.ZERO, turntable_radius, 0.0, TAU, 48, Color("2c5536"), 6.0, true)
	for i in 4:
		var a := turntable_angle + i * PI * 0.5
		ci.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * (turntable_radius - 8), Color(1, 1, 1, 0.25), 4.0)


func _draw_level(ci: CanvasItem) -> void:
	var c := Vector2(half_extents.x - 80, -half_extents.y + 40)
	ci.draw_rect(Rect2(c - Vector2(50, 12), Vector2(100, 24)), Color("2b3a2e"))
	ci.draw_circle(c + Vector2(clampf(-tilt.x, -1, 1) * 38, 0), 9.0, Color("b8f0a0"))
