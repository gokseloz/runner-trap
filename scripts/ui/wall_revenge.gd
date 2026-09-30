extends Control

signal returned
signal missed

const CATCH_DURATION := 1.5
const TARGET_SIZE := Vector2(112.0, 112.0)
const BRICK_COLOR := Color("b76b50")
const RING_COLOR := Color("ffca28")

var active := false
var elapsed := 0.0
var _start := Vector2.ZERO
var _target := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = TARGET_SIZE
	hide()


func launch(from_position: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	_start = from_position - TARGET_SIZE / 2.0
	_target = Vector2(viewport_size.x * 0.55, viewport_size.y * 0.32) - TARGET_SIZE / 2.0
	_start = _start.clamp(Vector2.ZERO, viewport_size - TARGET_SIZE)
	_target = _target.clamp(Vector2.ZERO, viewport_size - TARGET_SIZE)
	position = _start
	elapsed = 0.0
	active = true
	show()
	queue_redraw()


func cancel() -> void:
	active = false
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif what == NOTIFICATION_DRAG_END:
		mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var travel := clampf(elapsed / 0.35, 0.0, 1.0)
	position = _start.lerp(_target, travel)
	position.y -= sin(travel * PI) * 50.0
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size - TARGET_SIZE)
	if elapsed >= CATCH_DURATION:
		cancel()
		missed.emit()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var is_press: bool = event is InputEventScreenTouch and event.pressed
	is_press = is_press or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	if not active or not is_press or get_tree().paused or get_viewport().gui_is_dragging():
		return
	accept_event()
	cancel()
	returned.emit()


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, 49.0, Color("263238"))
	var remaining := clampf(1.0 - elapsed / CATCH_DURATION, 0.0, 1.0)
	if remaining > 0.0:
		draw_arc(center, 49.0, -PI / 2.0, -PI / 2.0 + TAU * remaining, 48, RING_COLOR, 5.0, true)
	draw_set_transform(center, sin(elapsed * 10.0) * 0.12)
	draw_rect(Rect2(-24.0, -33.0, 48.0, 66.0), BRICK_COLOR)
	for row in range(1, 4):
		var mortar_y := -33.0 + row * 16.5
		draw_line(Vector2(-24.0, mortar_y), Vector2(24.0, mortar_y), Color("efc6a4"), 3.0)
	for row in 4:
		var joint_x := -7.0 if row % 2 == 0 else 7.0
		draw_line(Vector2(joint_x, -33.0 + row * 16.5), Vector2(joint_x, -16.5 + row * 16.5), Color("efc6a4"), 3.0)
	draw_set_transform(Vector2.ZERO)