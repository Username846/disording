class_name CircleBody
extends RefCounted
## One circle in a CircleWorld (PLAN.md §3.7).

var pos := Vector2.ZERO
var vel := Vector2.ZERO
## Extra acceleration for this step (cleared after each step): tilt, magnets, wind…
var accel := Vector2.ZERO
var radius := 24.0
var mass := 1.0
var restitution := 0.8
## Kinematic bodies are moved by their owner (pos/vel), never by collisions.
var kinematic := false
## Ghost bodies move but never collide (respawn invulnerability, mid-air leaps).
var ghost := false
var enabled := true
## Scales the world's damping for this body (2.0 = stops twice as fast).
var damping_scale := 1.0
## Multiplies every impulse this body receives (damage-based knockback).
var knockback := 1.0
## Free slot for the owner (usually the node that draws this body).
var owner: Variant = null


func _init(p: Vector2 = Vector2.ZERO, r: float = 24.0, m: float = 1.0) -> void:
	pos = p
	radius = r
	mass = m


func inv_mass() -> float:
	return 0.0 if kinematic or mass <= 0.0 else 1.0 / mass


func speed() -> float:
	return vel.length()
