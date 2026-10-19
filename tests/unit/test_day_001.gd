extends TestCase
## Day 1 (Toybox Ring-Out) rules: arenas, knockback, teetering, ring-outs and the AI.

const Arena := preload("res://days/day_001/parts/arena.gd")
const Bout := preload("res://days/day_001/parts/bout.gd")
const Toy := preload("res://days/day_001/parts/toy.gd")
const Brain := preload("res://days/day_001/parts/brain.gd")


func _bout(index: int) -> Node2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bout: Node2D = Bout.new()
	bout.setup(index, rng)
	bout.running = true
	return bout


func _step(bout: Node2D, seconds: float) -> void:
	for i in int(seconds * 120.0):
		bout.step(1.0 / 120.0)


func test_arenas_are_sane() -> void:
	for i in Arena.COUNT:
		var arena: RefCounted = Arena.new(i)
		check(arena.contains(Vector2.ZERO), "arena %d contains its centre" % i)
		check(arena.edge_distance(Vector2.ZERO) > 100.0, "arena %d centre is far from the edge" % i)
		check(not arena.contains(arena.half_extents * 1.2), "arena %d excludes points outside" % i)
		var exit: float = arena.ray_exit(Vector2.ZERO, Vector2.RIGHT)
		check(absf(exit - arena.half_extents.x) < 25.0, "arena %d ray exit %.0f" % [i, exit])
		for spawn: Vector2 in arena.spawns:
			check(arena.edge_distance(spawn) > 60.0, "arena %d spawn %s is safe" % [i, spawn])
		check(arena.rivals.size() >= 1, "arena %d has rivals" % i)


func test_knockback_grows_with_damage() -> void:
	var bout := _bout(0)
	var knight: Node2D = bout.player
	knight.damage = 0.0
	knight.tick(0.0)
	check(absf(knight.body.knockback - Toy.KNOCKBACK_BASE) < 0.001, "base knockback at 0%")
	knight.damage = 160.0
	knight.tick(0.0)
	check(absf(knight.body.knockback - (Toy.KNOCKBACK_BASE + 1.0)) < 0.001, "knockback at 160%")
	bout.free()


func test_slow_drift_teeters_but_a_hard_knock_rings_out() -> void:
	var bout := _bout(0)
	var knight: Node2D = bout.player
	# Drifting slowly over the bottom edge: teeters and is pulled back.
	knight.body.pos = Vector2(0, bout.arena.half_extents.y - 5.0)
	knight.body.vel = Vector2(0, 120.0)
	_step(bout, 1.0)
	check(knight.is_active(), "slow drift does not ring out")
	check(bout.arena.contains(knight.body.pos), "teetering toy is pulled back on")
	# A hard knock carries it straight off.
	knight.body.pos = Vector2(0, bout.arena.half_extents.y - 40.0)
	knight.body.vel = Vector2(0, 900.0)
	_step(bout, 0.3)
	check(not knight.is_active(), "a hard knock rings the toy out")
	check(bout.fall_log.size() >= 1 and bout.fall_log[-1]["kind"] == &"knight", "ring-out is logged")
	bout.free()


func test_losing_three_stocks_ends_the_bout() -> void:
	var bout := _bout(0)
	var result := {"ended": false, "won": true}
	bout.ended.connect(
		func(won: bool) -> void:
			result["ended"] = true
			result["won"] = won
	)
	for stock in 3:
		var knight: Node2D = bout.player
		_step(bout, 2.0)  # respawn + invulnerability
		knight.invuln = 0.0
		knight.body.pos = Vector2(bout.arena.half_extents.x - 20.0, 150.0)
		knight.body.vel = Vector2(1000.0, 0.0)
		_step(bout, 1.0)
	check(result["ended"] and not result["won"], "player out of stocks loses the bout")
	bout.free()


func test_referee_only_falls_to_a_real_knock() -> void:
	var bout := _bout(4)
	var ref: Node2D = bout.referee
	var fell := {"count": 0}
	bout.referee_fell.connect(func(_at: Vector2) -> void: fell["count"] += 1)
	_step(bout, 20.0)
	check(fell["count"] == 0, "the referee never walks off by himself")
	ref.body.pos = Vector2(bout.arena.half_extents.x - 10.0, 0.0)
	ref.body.vel = Vector2(900.0, 0.0)
	_step(bout, 0.5)
	check(fell["count"] == 1, "a full-power knock rings the referee out")
	bout.free()


func test_brain_retreats_from_the_edge() -> void:
	var bout := _bout(0)
	var dino: Node2D = bout.rivals()[0]
	dino.body.pos = Vector2(bout.arena.half_extents.x - 30.0, 0.0)
	for toy: Node2D in bout.toys:
		if toy != dino:
			toy.state = Toy.State.OUT
	var rng := RandomNumberGenerator.new()
	var v: Vector2 = dino.brain.think(dino, bout.toys, bout.arena, bout.arena.damping, rng)
	check(v.x < 0.0, "with nobody to hit, a toy near the right edge moves left (got %s)" % v)
	bout.free()
