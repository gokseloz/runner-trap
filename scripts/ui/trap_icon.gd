class_name TrapIcon
extends Control
## Small drawing of a trap type for its card.

const GROUND := Color("6d4c41")
const GRASS := Color("7cb342")
const SKY := Color("e6f4fb")

var trap_type := ""
var color := Color.WHITE


func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground_y := h * 0.7
	draw_rect(Rect2(0, 0, w, h), SKY)
	draw_rect(Rect2(0, ground_y, w, h - ground_y), GROUND)
	draw_rect(Rect2(0, ground_y, w, 3), GRASS)
	var center_x := w / 2.0
	match trap_type:
		"pit":
			draw_rect(Rect2(center_x - w * 0.22, ground_y, w * 0.44, h - ground_y), color.darkened(0.4))
		"wall":
			var wall := Rect2(center_x - 8, ground_y - h * 0.5, 16, h * 0.5)
			draw_rect(wall, color)
			for i in range(1, 4):
				var y := wall.position.y + wall.size.y * i / 4.0
				draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), color.darkened(0.25), 2)
		"saw":
			var hub := Vector2(center_x, h * 0.32)
			draw_line(Vector2(center_x, 0), hub, Color("546e7a"), 2)
			var points := PackedVector2Array()
			for i in 16:
				var radius := h * 0.2 if i % 2 == 0 else h * 0.14
				points.append(hub + Vector2.from_angle(TAU * i / 16) * radius)
			draw_colored_polygon(points, color)
			draw_circle(hub, h * 0.05, Color("cfd8dc"))
		"slippery":
			draw_rect(Rect2(w * 0.1, ground_y - 2, w * 0.8, 6), color)
			draw_line(Vector2(w * 0.25, ground_y), Vector2(w * 0.4, ground_y), Color.WHITE, 2)
			draw_line(Vector2(w * 0.55, ground_y), Vector2(w * 0.7, ground_y), Color.WHITE, 2)
		_:
			draw_rect(Rect2(w * 0.2, h * 0.2, w * 0.6, h * 0.6), color)
