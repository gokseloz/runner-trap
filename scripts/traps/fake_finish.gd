extends Trap


func _on_runner_hit(runner: Runner) -> bool:
	if runner.celebrate_fake_finish():
		_consume()
		queue_redraw()
	return false


func _draw() -> void:
	for side in [-1.0, 1.0]:
		var pole_x: float = side * width / 2.0
		draw_line(Vector2(pole_x, 0.0), Vector2(pole_x, -132.0), Color("455a64"), 5.0, true)
		draw_circle(Vector2(pole_x, -132.0), 5.0, card_color)
	for row in 2:
		for column in 8:
			var cell_color := Color.WHITE if (row + column) % 2 == 0 else Color("263238")
			var drop := absf(column - 3.5) * -3.0 + 24.0 if consumed else 0.0
			draw_rect(Rect2(-width / 2.0 + column * width / 8.0, -126.0 + row * 12.0 + drop, width / 8.0, 12.0), cell_color)
	draw_line(Vector2(-width / 2.0, -3.0), Vector2(width / 2.0, -3.0), card_color, 5.0)
	if consumed:
		draw_line(Vector2(-12.0, -94.0), Vector2(12.0, -70.0), card_color, 5.0, true)
		draw_line(Vector2(12.0, -94.0), Vector2(-12.0, -70.0), card_color, 5.0, true)