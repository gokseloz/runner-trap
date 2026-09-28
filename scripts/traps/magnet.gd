extends Trap

@export var pull_speed := 240.0
@export var pull_duration := 0.65

var _runner: Runner
var _phase := 0.0
var _faded := false


func _ready() -> void:
	super()
	body_exited.connect(_on_body_exited)


func _on_runner_hit(_body: Runner) -> bool:
	return false


func _on_body_exited(body: Node2D) -> void:
	if consumed or not body is Runner or not body.is_physics_processing():
		return
	if body.global_position.x <= global_position.x or body.velocity.x <= 0.0:
		return
	if not body.pull_from_magnet(pull_speed, pull_duration):
		return
	_runner = body
	consumed = true
	set_deferred("monitoring", false)


func _process(delta: float) -> void:
	_phase += delta
	if consumed and not _faded and (not is_instance_valid(_runner) or not _runner.is_magnet_pulled()):
		_faded = true
		_consume()
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(0.0, -30.0)
	if is_instance_valid(_runner) and _runner.is_magnet_pulled():
		var target := to_local(_runner.global_position) + Vector2(0.0, -30.0)
		for strand in 3:
			var offset := Vector2(0.0, (strand - 1) * 9.0)
			draw_line(center + offset, target + offset, Color(0.2, 0.8, 0.85, 0.5), 2.0, true)
			var travel := fmod(_phase * 3.0 + strand / 3.0, 1.0)
			draw_circle(target.lerp(center, travel) + offset, 3.0, Color("b2ebf2"))
	draw_rect(Rect2(-width / 2.0, -3.0, width, 6.0), Color("455a64"))
	draw_arc(center, 20.0, 0.0, PI, 24, card_color, 10.0, true)
	for side in [-1.0, 1.0]:
		var pole := center + Vector2(side * 20.0, 0.0)
		draw_line(pole, pole + Vector2(0.0, -22.0), card_color if side < 0 else Color("ef5350"), 10.0, true)
		draw_line(pole + Vector2(0.0, -17.0), pole + Vector2(0.0, -24.0), Color("eceff1"), 10.0, true)