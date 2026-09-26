extends Node2D
## Runs a single level: builds the track, starts the runner, follows it with the camera.

const GROUND_Y := 600.0
const GROUND_DEPTH := 200.0
const RUNNER_START_X := 100.0
## Extra ground before the start and after the finish line.
const TRACK_MARGIN := 1500.0
const MARKER_SPACING := 250.0
## Runner is kept at this fraction of the screen width so the track ahead is visible.
const CAMERA_LEAD := 0.2

const GROUND_COLOR := Color("37474f")
const MARKER_COLOR := Color("546e7a")
const FINISH_COLOR := Color("ffca28")

@export var level_data: LevelData

var _finished := false

@onready var _track: Node2D = $Track
@onready var _runner: Runner = $Runner
@onready var _camera: Camera2D = $Camera2D
@onready var _lives_label: Label = $HUD/LivesLabel


func _ready() -> void:
	_build_track()
	_runner.position = Vector2(RUNNER_START_X, GROUND_Y)
	# Move the runner before the camera follows it each physics frame.
	_runner.process_physics_priority = -1
	_runner.hit.connect(_on_runner_hit)
	_runner.knocked_out.connect(_on_runner_knocked_out)
	_runner.setup(level_data.runner)
	_update_lives_label()
	_update_camera()


func _physics_process(_delta: float) -> void:
	_update_camera()
	if not _finished and not _runner.is_down and _runner.position.x >= level_data.track_length:
		_finished = true
		_runner.set_physics_process(false)
		print("Runner reached the finish — player loses")


func _unhandled_input(event: InputEvent) -> void:
	# Debug controls until the runner AI exists.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_SPACE, KEY_UP:
			_runner.jump()
		KEY_DOWN:
			_runner.slide()
		KEY_S:
			_runner.stop()
		KEY_H:
			_runner.take_hit()
		KEY_R:
			get_tree().reload_current_scene()


func _update_camera() -> void:
	var view_width := get_viewport_rect().size.x
	_camera.position = Vector2(_runner.position.x + view_width * (0.5 - CAMERA_LEAD), 360.0)


func _update_lives_label() -> void:
	_lives_label.text = "Lives: %d" % _runner.lives


func _build_track() -> void:
	var start_x := -TRACK_MARGIN
	var width := level_data.track_length + TRACK_MARGIN * 2.0

	var ground := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, GROUND_DEPTH)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(start_x + width / 2.0, GROUND_Y + GROUND_DEPTH / 2.0)
	ground.add_child(collision)
	_track.add_child(ground)

	_add_rect(Rect2(start_x, GROUND_Y, width, GROUND_DEPTH), GROUND_COLOR)

	# Distance markers so movement is visible on the flat ground.
	var x := 0.0
	while x < level_data.track_length:
		_add_rect(Rect2(x, GROUND_Y + 10.0, 30.0, 6.0), MARKER_COLOR)
		x += MARKER_SPACING

	_add_rect(Rect2(level_data.track_length, GROUND_Y - 200.0, 12.0, 200.0), FINISH_COLOR)


func _add_rect(rect: Rect2, color: Color) -> void:
	var color_rect := ColorRect.new()
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(color_rect)


func _on_runner_hit(_lives_left: int) -> void:
	_update_lives_label()


func _on_runner_knocked_out() -> void:
	print("Runner knocked out — player wins")
