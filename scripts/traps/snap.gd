extends Trap

@export var close_delay := 0.5
@export var active_duration := 0.18

var elapsed := 0.0
var is_active := false


func _physics_process(delta: float) -> void:
	if consumed:
		return
	elapsed += delta
	is_active = elapsed >= close_delay and elapsed < close_delay + active_duration
	queue_redraw()
	if elapsed >= close_delay + active_duration:
		_consume()
		return
	if is_active:
		for body in get_overlapping_bodies():
			_on_body_entered(body)


func _on_runner_hit(runner: Runner) -> bool:
	return is_active and runner.take_hit()


func _consume() -> void:
	is_active = false
	super()
	set_physics_process(false)
	queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / close_delay, 0.0, 1.0) if close_delay > 0.0 else 1.0
	var closure := clampf((elapsed - close_delay) / 0.05, 0.0, 1.0)
	if consumed:
		closure = 1.0
	draw_rect(Rect2(-width / 2.0, -4.0, width, 8.0), Color("455a64"))
	for side in [-1.0, 1.0]:
		var hinge := Vector2(side * width * 0.45, -4.0)
		var tip := Vector2(side * lerpf(width * 0.48, 3.0, closure), -32.0)
		draw_line(hinge, tip, card_color, 6.0, true)
		draw_circle(hinge, 5.0, Color("cfd8dc"))
		for tooth in 3:
			var base := hinge.lerp(tip, 0.2 + tooth * 0.25)
			draw_colored_polygon(PackedVector2Array([base, base + Vector2(-side * 9.0, -3.0), base + Vector2(0.0, -6.0)]), Color("eceff1"))
	if not consumed:
		draw_rect(Rect2(-width / 2.0, 9.0, width, 5.0), Color("455a64"))
		draw_rect(Rect2(-width / 2.0, 9.0, width * progress, 5.0), card_color if is_active else Color("ffca28"))
		for light in 3:
			var lit := progress >= (light + 1) / 3.0
			draw_circle(Vector2((light - 1) * 13.0, -14.0), 4.0, Color("ffca28") if lit else Color("78909c"))