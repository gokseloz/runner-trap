class_name Runner
extends CharacterBody2D
## Auto-running character. Its RunnerAI child decides when to call jump(), slide() or stop().

signal hit(lives_left: int)
signal magnet_hit
signal knocked_out
signal landed(impact_speed: float, from_spring: bool)
## For sound and effects.
signal jumped
signal slid

const SIZE := Vector2(40, 64)
const SLIDE_HEIGHT := 32.0
const SLIDE_DURATION := 0.6
const STOP_DURATION := 0.8
const STUN_DURATION := 1.0
const INVULNERABLE_DURATION := 1.5
const HIT_FLASH_COLOR := Color("ff5252")

var profile: RunnerProfile
var lives := 0
var is_down := false

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
## Set by surface traps (e.g. slippery floor) while the runner is on them.
var speed_multiplier := 1.0

var _air_jumps_left := 0
var _slide_time_left := 0.0
var _stop_time_left := 0.0
var _stun_time_left := 0.0
var _invulnerable_time_left := 0.0
var _was_on_floor := true
var _spring_airborne := false
var _spring_landing_time := 0.0
var _magnet_time_left := 0.0
var _magnet_speed := 0.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Node2D = $Visual
@onready var _body: RunnerVisual = $Visual/Body
@onready var _alert: Label = $Alert
@onready var ai: RunnerAI = $AI


func _ready() -> void:
	# Each runner resizes its own shape when sliding.
	_collision.shape = _collision.shape.duplicate()
	ai.trap_spotted.connect(_on_trap_spotted)
	set_physics_process(false)


## lives_lost starts the runner already hurt (used when continuing after an ad).
func setup(runner_profile: RunnerProfile, lives_lost := 0) -> void:
	profile = runner_profile
	lives = maxi(profile.lives - lives_lost, 1)
	_body.color = profile.color
	_set_height(SIZE.y)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_spring_landing_time = maxf(_spring_landing_time - delta, 0.0)
	if is_on_floor():
		_air_jumps_left = profile.max_jumps - 1
	else:
		velocity.y += gravity * delta

	if _slide_time_left > 0.0:
		_slide_time_left -= delta
		if _slide_time_left <= 0.0:
			_end_slide()
	_stop_time_left = maxf(_stop_time_left - delta, 0.0)
	_stun_time_left = maxf(_stun_time_left - delta, 0.0)
	_update_invulnerability(delta)

	var halted := is_down or _stop_time_left > 0.0 or _stun_time_left > 0.0
	velocity.x = 0.0 if halted else profile.run_speed * speed_multiplier
	if is_magnet_pulled() and not halted:
		velocity.x = -_magnet_speed
	var impact_speed := velocity.y
	var from_spring := _spring_airborne
	move_and_slide()
	_magnet_time_left = maxf(_magnet_time_left - delta, 0.0)
	if _spring_airborne and is_on_floor() and velocity.y >= 0.0:
		_spring_airborne = false
		_spring_landing_time = 0.25
	var just_landed := is_on_floor() and not _was_on_floor and not is_down
	if just_landed:
		Fx.squash(_visual, Vector2(1.25, 0.8))
	_was_on_floor = is_on_floor()
	_body.airborne = not is_on_floor()
	_body.running = not is_zero_approx(velocity.x)
	if just_landed:
		landed.emit(impact_speed, from_spring)


func can_act() -> bool:
	return not is_down and _stun_time_left <= 0.0 and not is_magnet_pulled()


func is_magnet_pulled() -> bool:
	return _magnet_time_left > 0.0


func pull_from_magnet(pull_speed: float, duration: float) -> bool:
	if not can_act() or _invulnerable_time_left > 0.0 or pull_speed <= 0.0 or duration <= 0.0:
		return false
	_end_slide()
	_stop_time_left = 0.0
	_magnet_speed = pull_speed
	_magnet_time_left = duration
	set_alert(false)
	_body.react(RunnerVisual.Mood.SURPRISED, duration)
	return true


func is_sliding() -> bool:
	return _slide_time_left > 0.0


func get_air_jumps_left() -> int:
	return _air_jumps_left


## Action methods return false when the action isn't possible right now.
func jump() -> bool:
	if not can_act() or (_spring_airborne and is_on_floor()):
		return false
	if is_on_floor():
		velocity.y = profile.jump_velocity
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		velocity.y = profile.jump_velocity
	else:
		return false
	_end_slide()
	Fx.squash(_visual, Vector2(0.8, 1.2))
	jumped.emit()
	return true


func slide() -> bool:
	if not can_act() or not is_on_floor() or _spring_airborne:
		return false
	_slide_time_left = SLIDE_DURATION
	_set_height(SLIDE_HEIGHT)
	slid.emit()
	return true


func launch_from_spring(launch_speed: float) -> bool:
	if not can_act() or not is_on_floor() or _spring_airborne or _invulnerable_time_left > 0.0 or launch_speed <= 0.0:
		return false
	_end_slide()
	_stop_time_left = 0.0
	velocity.y = -launch_speed
	_spring_airborne = true
	_spring_landing_time = 0.0
	_body.react(RunnerVisual.Mood.SURPRISED, 0.6)
	Fx.squash(_visual, Vector2(0.8, 1.2))
	jumped.emit()
	return true


func is_spring_combo_active() -> bool:
	return _spring_airborne or _spring_landing_time > 0.0


func clear_spring_combo() -> void:
	_spring_airborne = false
	_spring_landing_time = 0.0


func stop() -> bool:
	if not can_act():
		return false
	_stop_time_left = STOP_DURATION
	return true


## Shows the "!" while the AI has spotted a trap but can't react yet.
func set_alert(active: bool) -> void:
	_alert.visible = active


func celebrate_dodge() -> void:
	if not can_act() or _invulnerable_time_left > 0.0:
		return
	_body.react(RunnerVisual.Mood.CONFIDENT, 0.85)


func _on_trap_spotted(trap: Trap, _reaction_time: float) -> void:
	if not can_act() or _invulnerable_time_left > 0.0:
		return
	if ai.seen_counts.get(trap.trap_type, 0) > 1 and ai.get_reaction_time(trap.trap_type) < profile.reaction_time:
		_body.react(RunnerVisual.Mood.FOCUSED, 1.0)


## Returns false if the hit was ignored (already down or invulnerable).
func take_hit() -> bool:
	if is_down or _invulnerable_time_left > 0.0:
		return false
	var was_magnet_pulled := is_magnet_pulled()
	lives -= 1
	_magnet_time_left = 0.0
	if was_magnet_pulled:
		magnet_hit.emit()
	_body.react_to_hit(STUN_DURATION)
	hit.emit(lives)
	_end_slide()
	if lives <= 0:
		is_down = true
		set_alert(false)
		_body.down = true
		_fall_over()
		knocked_out.emit()
		return true
	_flash()
	_stun_time_left = STUN_DURATION
	_invulnerable_time_left = INVULNERABLE_DURATION
	return true


func _flash() -> void:
	_body.color = HIT_FLASH_COLOR
	create_tween().tween_property(_body, "color", profile.color, 0.25)


## Tips forward onto the ground; the pivot is at the feet, so lift by half the body width.
func _fall_over() -> void:
	_visual.scale = Vector2.ONE
	modulate.a = 1.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "rotation", PI / 2.0, 0.6)
	tween.tween_property(_visual, "position:y", -SIZE.x / 2.0, 0.6)
	tween.tween_property(_body, "color", profile.color.darkened(0.5), 0.6)


func _end_slide() -> void:
	_slide_time_left = 0.0
	_set_height(SIZE.y)


func _set_height(height: float) -> void:
	var rect := _collision.shape as RectangleShape2D
	rect.size = Vector2(SIZE.x, height)
	_collision.position.y = -height / 2.0
	_body.height = height


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_time_left <= 0.0:
		return
	_invulnerable_time_left -= delta
	var blink_on := fmod(_invulnerable_time_left, 0.2) < 0.1
	modulate.a = 0.4 if blink_on and _invulnerable_time_left > 0.0 else 1.0
