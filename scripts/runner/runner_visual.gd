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

enum Mood { NEUTRAL, CONFIDENT, FOCUSED, ANGRY, SURPRISED }

var expression := Mood.NEUTRAL
var anger_level := 0
var _expression_time_left := 0.0
var _pending_anger_duration := 0.0
var _recent_hit_time_left := 0.0
var throw_time_left := 0.0

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
var umbrella_open := false:
	set(value):
		umbrella_open = value
		queue_redraw()
var celebrating := false:
	set(value):
		celebrating = value
		queue_redraw()
var down := false:
	set(value):
		down = value
		queue_redraw()

var _phase := 0.0
var _style := StyleBoxFlat.new()


func _init() -> void:
	_style.set_corner_radius_all(CORNER_RADIUS)


func _process(delta: float) -> void:
	if throw_time_left > 0.0:
		throw_time_left = maxf(throw_time_left - delta, 0.0)
		queue_redraw()
	_recent_hit_time_left = maxf(_recent_hit_time_left - delta, 0.0)
	if _expression_time_left > 0.0:
		_expression_time_left = maxf(_expression_time_left - delta, 0.0)
		if _expression_time_left == 0.0:
			if _pending_anger_duration > 0.0 and not down:
				expression = Mood.ANGRY
				_expression_time_left = _pending_anger_duration
			else:
				expression = Mood.NEUTRAL
				anger_level = 0
			_pending_anger_duration = 0.0
		queue_redraw()
	if running and not airborne and not down:
		_phase = fmod(_phase + delta * STRIDE_SPEED, TAU)
		queue_redraw()
	elif airborne:
		queue_redraw()


func react_to_hit(surprise_duration: float) -> void:
	if down:
		return
	anger_level = 2 if _recent_hit_time_left > 0.0 else 1
	_recent_hit_time_left = 6.0
	_pending_anger_duration = 3.0 if anger_level == 2 else 2.0
	expression = Mood.SURPRISED
	_expression_time_left = surprise_duration
	queue_redraw()


func react(next_expression: Mood, duration: float) -> void:
	if down or (_expression_time_left > 0.0 and next_expression <= expression):
		return
	expression = next_expression
	_expression_time_left = duration
	queue_redraw()


func _draw() -> void:
	var sliding := height < 64.0
	var leg_length := 0.0 if sliding else LEG_LENGTH
	var body_top := -height
	var body := Rect2(-WIDTH / 2.0, body_top, WIDTH, height - leg_length)

	if not sliding:
		_draw_legs()
		_draw_gesture()
	if umbrella_open and not down:
		_draw_umbrella()
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
		_draw_face(eye, sliding)


func _draw_umbrella() -> void:
	var center := Vector2(4.0, -height - 22.0)
	draw_line(center + Vector2(0.0, -42.0), Vector2(4.0, -height + 28.0), Color("455a64"), 4.0, true)
	for panel in 2:
		var points := PackedVector2Array([center])
		for step in 17:
			var angle := PI + panel * PI / 2.0 + step * PI / 32.0
			points.append(center + Vector2(cos(angle) * 48.0, sin(angle) * 36.0))
		draw_colored_polygon(points, Color("26a69a") if panel == 0 else Color("ffca28"))
		draw_polyline(points, Color("455a64"), 2.0, true)
	draw_line(Vector2(-16.0, -height + 26.0), Vector2(4.0, -height + 16.0), color.darkened(0.25), 5.0, true)
	draw_circle(Vector2(4.0, -height + 16.0), 5.0, color)


func _draw_face(eye: Vector2, sliding: bool) -> void:
	var mouth := eye + Vector2(-1.0, 12.0)
	match Mood.CONFIDENT if celebrating else expression:
		Mood.CONFIDENT:
			draw_arc(eye + Vector2(0.0, 2.0), 5.0, PI, TAU, 12, PUPIL_COLOR, 3.0, true)
			if not sliding:
				draw_arc(mouth + Vector2(-2.0, -3.0), 6.0, 0.1, PI - 0.1, 12, PUPIL_COLOR, 2.5, true)
		Mood.FOCUSED:
			draw_circle(eye, 6.0, EYE_COLOR)
			draw_circle(eye + Vector2(3.0, 1.0), 2.5, PUPIL_COLOR)
			draw_line(eye + Vector2(-6.0, -7.0), eye + Vector2(6.0, -3.0), PUPIL_COLOR, 3.0, true)
			if not sliding:
				draw_line(mouth + Vector2(-5.0, 0.0), mouth + Vector2(4.0, -1.0), PUPIL_COLOR, 2.5, true)
		Mood.SURPRISED:
			draw_circle(eye, 8.0, EYE_COLOR)
			draw_circle(eye + Vector2(1.0, 0.0), 2.0, PUPIL_COLOR)
			if not sliding:
				draw_circle(mouth, 4.0, PUPIL_COLOR)
		Mood.ANGRY:
			draw_circle(eye, 6.0, EYE_COLOR)
			draw_circle(eye + Vector2(3.0, 1.0), 2.5, PUPIL_COLOR)
			draw_line(eye + Vector2(-7.0, -8.0), eye + Vector2(7.0, -2.0), PUPIL_COLOR, 4.0, true)
			if not sliding:
				if anger_level == 2:
					draw_rect(Rect2(mouth + Vector2(-7.0, -2.0), Vector2(12.0, 7.0)), PUPIL_COLOR)
					draw_rect(Rect2(mouth + Vector2(-5.0, 0.0), Vector2(8.0, 3.0)), EYE_COLOR)
					draw_line(mouth + Vector2(-6.0, 1.0), mouth + Vector2(4.0, 1.0), PUPIL_COLOR, 1.5, true)
				else:
					draw_arc(mouth + Vector2(-2.0, 4.0), 5.0, PI + 0.2, TAU - 0.2, 12, PUPIL_COLOR, 2.5, true)
			if anger_level == 2:
				var mark := Vector2(-8.0, -height - 9.0)
				draw_line(mark + Vector2(-6.0, -5.0), mark, Color("ff5252"), 3.0, true)
				draw_line(mark, mark + Vector2(-6.0, 5.0), Color("ff5252"), 3.0, true)
				draw_line(mark + Vector2(7.0, -5.0), mark + Vector2(2.0, 0.0), Color("ff5252"), 3.0, true)
		_:
			draw_circle(eye, 6.0, EYE_COLOR)
			draw_circle(eye + Vector2(2.0, 0.0), 3.0, PUPIL_COLOR)


func _draw_gesture() -> void:
	if throw_time_left > 0.0 and not down:
		var shoulder := Vector2(WIDTH / 2.0 - 2.0, -height + 30.0)
		var hand := shoulder + Vector2(28.0, -24.0)
		draw_line(shoulder, hand, color.darkened(0.25), 6.0, true)
		draw_circle(hand, 5.0, color)
		return
	if celebrating and not down:
		for side in [-1.0, 1.0]:
			var shoulder := Vector2(side * (WIDTH / 2.0 - 2.0), -height + 30.0)
			var hand := Vector2(side * (WIDTH / 2.0 + 14.0), -height - 8.0)
			draw_line(shoulder, hand, color.darkened(0.25), 5.0, true)
			draw_circle(hand, 4.0, color)
		return
	if down or expression not in [Mood.CONFIDENT, Mood.ANGRY]:
		return
	var shoulder := Vector2(-WIDTH / 2.0 + 2.0, -height + 30.0)
	var elbow := shoulder + Vector2(-10.0, -3.0)
	var hand := elbow + Vector2(-3.0 + sin(_expression_time_left * 18.0) * 3.0, -14.0)
	if expression == Mood.ANGRY:
		elbow = shoulder + Vector2(-9.0, 9.0)
		hand = elbow + Vector2(-2.0, -8.0 - sin(_expression_time_left * 22.0) * anger_level * 2.0)
	var arm_color := color.darkened(0.25)
	draw_line(shoulder, elbow, arm_color, 5.0, true)
	draw_line(elbow, hand, arm_color, 5.0, true)
	draw_circle(hand, 5.0 if expression == Mood.ANGRY else 4.0, color)


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
