class_name StarRow
extends Control
## Draws 3 stars, the first `filled` of them in color. Drawn as polygons so no font glyph is needed.

const STAR_COUNT := 3
const SPACING_RATIO := 2.7
const FILLED_COLOR := Color("ffca28")
const EMPTY_COLOR := Color("cfd8dc")

@export var star_radius := 26.0

var filled := 0:
	set(value):
		filled = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(_spacing() * STAR_COUNT, star_radius * 2.0 + 8.0)


func _draw() -> void:
	var start_x := size.x / 2.0 - _spacing() * (STAR_COUNT - 1) / 2.0
	for i in STAR_COUNT:
		var center := Vector2(start_x + _spacing() * i, size.y / 2.0)
		draw_colored_polygon(_star_points(center), FILLED_COLOR if i < filled else EMPTY_COLOR)


func _spacing() -> float:
	return star_radius * SPACING_RATIO


func _star_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius := star_radius if i % 2 == 0 else star_radius * 0.45
		points.append(center + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * radius)
	return points
