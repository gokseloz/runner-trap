class_name StarRow
extends Control
## Draws 3 stars, the first `filled` of them in color. Drawn as polygons so no font glyph is needed.

const STAR_COUNT := 3
const STAR_RADIUS := 26.0
const SPACING := 70.0
const FILLED_COLOR := Color("ffca28")
const EMPTY_COLOR := Color("cfd8dc")

var filled := 0:
	set(value):
		filled = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(SPACING * STAR_COUNT, STAR_RADIUS * 2.0 + 8.0)


func _draw() -> void:
	var start_x := size.x / 2.0 - SPACING * (STAR_COUNT - 1) / 2.0
	for i in STAR_COUNT:
		var center := Vector2(start_x + SPACING * i, size.y / 2.0)
		draw_colored_polygon(_star_points(center), FILLED_COLOR if i < filled else EMPTY_COLOR)


func _star_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius := STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * 0.45
		points.append(center + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * radius)
	return points
