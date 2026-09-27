class_name RunnerVisual
extends Node2D
## Flat drawn runner: rounded body, headband, eye and swinging legs. Origin is at the feet.

const WIDTH := 40.0
const LEG_LENGTH := 14.0
const LEG_WIDTH := 6.0
const CORNER_RADIUS := 10
## Leg swing cycles per second while running.
const STRIDE_SPEED := 10.0
const EYE_COLOR := Color.WHITE
const PUPIL_COLOR := Color("263238")

var color := Color.WHITE:
	set(value):
		color = value
		_style.bg_color = value
		queue_redraw()
## Full height including legs; smaller while sliding.
var height := 64.0:
	set(value):
		height = value
		queue_redraw()
var running := false
var airborne := false
var down := false:
	set(value):
		down = value
		queue_redraw()

var _phase := 0.0
var _style := StyleBoxFlat.new()


func _init() -> void:
	_style.set_corner_radius_all(CORNER_RADIUS)


func _process(delta: float) -> void:
	if running and not airborne and not down:
		_phase = fmod(_phase + delta * STRIDE_SPEED, TAU)
		queue_redraw()
	elif airborne:
		queue_redraw()


func _draw() -> void:
	var sliding := height < 64.0
	var leg_length := 0.0 if sliding else LEG_LENGTH
	var body_top := -height
	var body := Rect2(-WIDTH / 2.0, body_top, WIDTH, height - leg_length)

	if not sliding:
		_draw_legs()
	draw_style_box(_style, body)

	# Headband near the top.
	var band_y := body_top + minf(10.0, body.size.y * 0.25)
	draw_rect(Rect2(-WIDTH / 2.0, band_y, WIDTH, 6.0), color.darkened(0.35))
	draw_rect(Rect2(-WIDTH / 2.0 - 8.0, band_y + 1.0, 8.0, 4.0), color.darkened(0.35))

	# Eye looking ahead.
	var eye := Vector2(8.0, band_y + 14.0) if not sliding else Vector2(8.0, body_top + body.size.y / 2.0)
	if down:
		var s := 4.0
		draw_line(eye + Vector2(-s, -s), eye + Vector2(s, s), PUPIL_COLOR, 3.0)
		draw_line(eye + Vector2(-s, s), eye + Vector2(s, -s), PUPIL_COLOR, 3.0)
	else:
		draw_circle(eye, 6.0, EYE_COLOR)
		draw_circle(eye + Vector2(2.0, 0.0), 3.0, PUPIL_COLOR)


func _draw_legs() -> void:
	var hip_y := -LEG_LENGTH - 2.0
	var swing := 0.0
	if airborne:
		swing = 0.6
	elif running and not down:
		swing = sin(_phase) * 0.7
	var leg_color := color.darkened(0.45)
	for side in [-1.0, 1.0]:
		var hip := Vector2(side * 8.0, hip_y)
		var foot := hip + Vector2(0.0, LEG_LENGTH + 2.0).rotated(swing * side)
		draw_line(hip, foot, leg_color, LEG_WIDTH)
		draw_circle(foot, LEG_WIDTH / 2.0, leg_color)
