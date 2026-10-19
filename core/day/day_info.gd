class_name DayInfo
extends Resource
## Static description of one door (PLAN.md §3.4). One per day at res://days/day_NNN/info.tres.

@export var day := 0
@export var title := ""
@export var genre := ""
## The game from game_list.txt this day riffs on, shown to the player as "Inspired by …".
@export var inspired_by := ""
@export_multiline var pitch := ""
## Three "icon|text" hints for the intro card, e.g. "drag|Drag back to aim".
## Icons: tap, double_tap, hold, drag, swipe, draw, pinch, flick, timer.
@export var hints := PackedStringArray()
@export var est_minutes := 10
@export_file("*.tscn") var scene_path := ""
@export var bundle_id := ""
## [main, accent, dark] colours used for the door art and intro card.
@export var palette := PackedColorArray()
## Optional procedural door art (a script with `func draw(ci: CanvasItem, rect: Rect2)`), drawn
## behind a completed door. Takes precedence over `thumbnail`.
@export var door_art: Script
@export var thumbnail: Texture2D


func color(index: int, fallback: Color = Color.WHITE) -> Color:
	return palette[index] if index < palette.size() else fallback
