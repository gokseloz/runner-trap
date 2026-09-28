extends Trap

@export var launch_speed := 650.0

var extension := 0.0:
	set(value):
		extension = value
		queue_redraw()


func _on_runner_hit(runner: Runner) -> bool:
	if not runner.launch_from_spring(launch_speed):
		return false
	_consume()
	var tween := create_tween()
	tween.tween_property(self, "extension", 18.0, 0.08)
	tween.tween_property(self, "extension", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return false


func _draw() -> void:
	var top := -18.0 - extension
	draw_rect(Rect2(-width / 2.0, -4.0, width, 8.0), Color("455a64"))
	for side in [-1.0, 1.0]:
		var center_x: float = side * width * 0.25
		var coil := PackedVector2Array()
		for step in 7:
			var offset := -7.0 if step % 2 == 0 else 7.0
			coil.append(Vector2(center_x + offset, lerpf(-4.0, top, step / 6.0)))
		draw_polyline(coil, Color("cfd8dc"), 3.0, true)
	draw_rect(Rect2(-width / 2.0, top - 6.0, width, 7.0), card_color)
	for stripe in [-1.0, 1.0]:
		draw_line(Vector2(stripe * 10.0, top - 4.0), Vector2(0.0, top - 10.0), Color.WHITE, 2.5, true)