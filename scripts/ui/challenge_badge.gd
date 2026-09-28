class_name ChallengeBadge
extends Control

var earned := false:
	set(value):
		earned = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(36.0, 40.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(size.x / 2.0, 15.0)
	var medal_color := Color("ffca28") if earned else Color("90a4ae")
	var ribbon_color := Color("ef5350") if earned else Color("78909c")
	for side in [-1.0, 1.0]:
		var ribbon := PackedVector2Array([
			center + Vector2(side * 3.0, 7.0),
			center + Vector2(side * 10.0, 6.0),
			center + Vector2(side * 13.0, 23.0),
			center + Vector2(side * 6.0, 20.0),
			center + Vector2(side * 2.0, 23.0),
		])
		draw_colored_polygon(ribbon, ribbon_color)
	draw_circle(center, 13.0, medal_color)
	draw_arc(center, 10.0, 0.0, TAU, 32, medal_color.darkened(0.3), 1.5, true)
	if earned:
		draw_polyline(PackedVector2Array([center + Vector2(-6.0, 0.0), center + Vector2(-1.0, 5.0), center + Vector2(7.0, -5.0)]), Color("263238"), 3.0, true)