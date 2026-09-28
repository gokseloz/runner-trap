class_name Seesaw
extends Node2D

const WIDTH := 240.0
const HEIGHT := 44.0
const RAMP_WIDTH := 100.0
const FOOTPRINT := WIDTH + RAMP_WIDTH * 2.0
const MIN_IMPACT_SPEED := 400.0
const LAUNCH_SPEED := 740.0
const MAX_TILT := 0.1

var runner: Runner
var activated := false
var _beam: AnimatableBody2D
var _left_ramp: CollisionPolygon2D
var _right_ramp: CollisionPolygon2D
var _recoil := 0.0


func _ready() -> void:
	z_index = 2
	_beam = AnimatableBody2D.new()
	_beam.position.y = -HEIGHT
	_beam.rotation = -MAX_TILT
	_beam.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, 8.0)
	collision.shape = shape
	collision.position.y = 4.0
	collision.one_way_collision = true
	_beam.add_child(collision)
	add_child(_beam)
	var ramps := StaticBody2D.new()
	ramps.collision_mask = 0
	_left_ramp = CollisionPolygon2D.new()
	_right_ramp = CollisionPolygon2D.new()
	ramps.add_child(_left_ramp)
	ramps.add_child(_right_ramp)
	add_child(ramps)
	_update_ramps()
	runner.landed.connect(_on_runner_landed)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(runner) or not runner.is_physics_processing():
		return
	var offset := runner.global_position.x - global_position.x
	var target := -MAX_TILT
	if runner.is_on_floor() and absf(offset) < WIDTH / 2.0:
		target = offset / (WIDTH / 2.0) * MAX_TILT
	_recoil = move_toward(_recoil, 0.0, delta * 0.35)
	_beam.rotation = move_toward(_beam.rotation, target + _recoil, delta * 1.4)
	_update_ramps()
	queue_redraw()


func _on_runner_landed(impact_speed: float, from_spring: bool) -> void:
	if activated or not from_spring or impact_speed < MIN_IMPACT_SPEED or not runner.is_physics_processing():
		return
	var offset := runner.global_position - global_position
	if absf(offset.x) > WIDTH / 2.0 or absf(offset.y + HEIGHT) > 32.0:
		return
	if not runner.launch_from_spring(LAUNCH_SPEED):
		return
	activated = true
	_recoil = -signf(offset.x) * 0.22
	queue_redraw()


func _update_ramps() -> void:
	var left := _beam.transform * Vector2(-WIDTH / 2.0, 0.0)
	var right := _beam.transform * Vector2(WIDTH / 2.0, 0.0)
	_left_ramp.polygon = PackedVector2Array([Vector2(-FOOTPRINT / 2.0, 0), left, Vector2(left.x, 4)])
	_right_ramp.polygon = PackedVector2Array([right, Vector2(FOOTPRINT / 2.0, 0), Vector2(right.x, 4)])


func _draw() -> void:
	if is_instance_valid(_left_ramp):
		for ramp in [_left_ramp, _right_ramp]:
			draw_colored_polygon(ramp.polygon, Color("546e7a"))
			draw_line(ramp.polygon[0], ramp.polygon[1], Color("cfd8dc"), 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(0, -HEIGHT), Vector2(34, 0)]), Color("26a69a"))
	draw_line(Vector2(-38, 1), Vector2(38, 1), Color("263238"), 5.0, true)
	var tilt := _beam.rotation if is_instance_valid(_beam) else 0.0
	draw_set_transform(Vector2(0, -HEIGHT), tilt)
	draw_rect(Rect2(-WIDTH / 2.0, 0.0, WIDTH, 9.0), Color("efb45b"))
	draw_line(Vector2(-WIDTH / 2.0, 0), Vector2(WIDTH / 2.0, 0), Color("ffe0a3"), 3.0, true)
	for side in [-1.0, 1.0]:
		var center_x: float = side * (WIDTH / 2.0 - 24.0)
		draw_rect(Rect2(center_x - 20.0, -3.0, 40.0, 6.0), Color("26a69a") if not activated else Color("78909c"))
		for stripe in [-1.0, 1.0]:
			draw_line(Vector2(center_x + stripe * 9.0, 6.0), Vector2(center_x + stripe * 4.0, 2.0), Color("263238"), 2.0, true)
	draw_circle(Vector2(0, 5), 6.0, Color("eceff1"))
	draw_circle(Vector2(0, 5), 2.5, Color("546e7a"))
	draw_set_transform(Vector2.ZERO)