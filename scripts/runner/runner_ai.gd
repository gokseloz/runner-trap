class_name RunnerAI
extends Node
## Watches traps ahead of the runner. After the (learned) reaction time it waits for the
## ideal moment and performs the trap's counter action. Reacting too late = getting hit.

signal trap_spotted(trap: Trap, reaction_time: float)

## Jump planning: candidate takeoff spacing, arc sample step, safety margin around traps,
## and how long after landing the path must stay clear (time to react again).
const TAKEOFF_STEP := 5.0
const SIM_STEP := 1.0 / 60.0
const HAZARD_MARGIN := 2.0
const POST_LANDING_TIME := 0.15

var enabled := true
var rng := RandomNumberGenerator.new()
## trap_type -> number of times spotted, drives learning.
var seen_counts: Dictionary = {}

## trap -> {ready_at: float, action_distance: float, ignored: bool, done: bool}
var _plans: Dictionary = {}
var _time := 0.0

@onready var _runner: Runner = get_parent()


func _physics_process(delta: float) -> void:
	if not enabled or _runner.profile == null or _runner.is_down:
		return
	_time += delta
	_spot_new_traps()
	_follow_plans()


## Reaction time for the next trap of this type, before jitter.
func get_reaction_time(trap_type: String) -> float:
	var profile := _runner.profile
	var learned := profile.reaction_time * pow(1.0 - profile.learning_rate, seen_counts.get(trap_type, 0))
	return maxf(learned, profile.min_reaction_time)


func _spot_new_traps() -> void:
	var profile := _runner.profile
	for node in get_tree().get_nodes_in_group(Trap.GROUP):
		var trap := node as Trap
		if trap.consumed or trap.counter_action == "none" or _plans.has(trap) or _is_behind(trap):
			continue
		if trap.global_position.x - _runner.global_position.x > profile.vision_range:
			continue
		var reaction := maxf(get_reaction_time(trap.trap_type) + rng.randf_range(-profile.reaction_jitter, profile.reaction_jitter), 0.0)
		seen_counts[trap.trap_type] = seen_counts.get(trap.trap_type, 0) + 1
		_plans[trap] = {
			"ready_at": _time + reaction,
			"action_distance": trap.get_action_distance(_runner) + rng.randf_range(-profile.timing_error, profile.timing_error),
			"ignored": rng.randf() < profile.mistake_chance,
			"done": false,
		}
		trap_spotted.emit(trap, reaction)


func _follow_plans() -> void:
	var thinking := false
	var next_jump: Trap = null
	for key in _plans.keys():
		if not is_instance_valid(key):
			_plans.erase(key)
			continue
		var trap := key as Trap
		if trap.consumed or _is_behind(trap):
			_plans.erase(trap)
			continue
		var plan: Dictionary = _plans[trap]
		# Plans stay until the trap is behind the runner so it isn't spotted twice.
		if plan.done or plan.ignored:
			continue
		if _time < plan.ready_at:
			thinking = true
			continue
		if trap.counter_action == "jump" and _runner.is_on_floor():
			if next_jump == null or trap.global_position.x < next_jump.global_position.x:
				next_jump = trap
			continue
		if trap.global_position.x - _runner.global_position.x > plan.action_distance:
			continue
		plan.done = _perform(trap.counter_action)
	if next_jump != null and _should_jump_now(next_jump):
		_plans[next_jump].done = _runner.jump()
	_runner.set_alert(thinking)


## Picks the takeoff point closest to the ideal one whose arc avoids every trap the runner
## knows about, so a trap on the landing spot is only a threat if it shows up too late.
## Returns true when that point is the runner's current position.
func _should_jump_now(target: Trap) -> bool:
	var runner_x := _runner.global_position.x
	var ideal_x: float = target.global_position.x - _plans[target].action_distance
	if runner_x >= ideal_x and _is_clean_jump(0.0):
		return true
	var best_offset := INF
	var offset := 0.0
	var max_offset := target.global_position.x - runner_x
	while offset <= max_offset:
		if _is_clean_jump(offset) and absf(runner_x + offset - ideal_x) < absf(runner_x + best_offset - ideal_x):
			best_offset = offset
		offset += TAKEOFF_STEP
	if best_offset == INF:
		# No safe takeoff: go for the ideal one and hope.
		return runner_x >= ideal_x
	return best_offset < TAKEOFF_STEP


## Simulates a jump taken `offset` px ahead of the runner, plus a short run after landing.
func _is_clean_jump(offset: float) -> bool:
	var hazards: Array[Rect2] = []
	for trap: Trap in _plans:
		var plan: Dictionary = _plans[trap]
		if is_instance_valid(trap) and not trap.consumed and not plan.ignored and _time >= plan.ready_at:
			hazards.append(trap.get_hit_rect().grow(HAZARD_MARGIN))
	var speed := _runner.profile.run_speed * _runner.speed_multiplier
	var start := _runner.global_position + Vector2(offset, 0.0)
	var air_time := 2.0 * absf(_runner.profile.jump_velocity) / _runner.gravity
	var t := 0.0
	while t <= air_time + POST_LANDING_TIME:
		var air_t := minf(t, air_time)
		var feet := start + Vector2(speed * t, _runner.profile.jump_velocity * air_t + 0.5 * _runner.gravity * air_t * air_t)
		var body := Rect2(feet.x - Runner.SIZE.x / 2.0, feet.y - Runner.SIZE.y, Runner.SIZE.x, Runner.SIZE.y)
		for hazard in hazards:
			if body.intersects(hazard):
				return false
		t += SIM_STEP
	return true


func _perform(action: String) -> bool:
	match action:
		"jump":
			return _runner.jump()
		"slide":
			return _runner.slide()
		"stop":
			return _runner.stop()
	return false


func _is_behind(trap: Trap) -> bool:
	return trap.global_position.x + trap.width / 2.0 < _runner.global_position.x - Runner.SIZE.x / 2.0
