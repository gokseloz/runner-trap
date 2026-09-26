class_name RunnerAI
extends Node
## Watches traps ahead of the runner. After the (learned) reaction time it waits for the
## ideal moment and performs the trap's counter action. Reacting too late = getting hit.

signal trap_spotted(trap: Trap, reaction_time: float)

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
		if trap.global_position.x - _runner.global_position.x > plan.action_distance:
			continue
		plan.done = _perform(trap.counter_action)
	_runner.set_alert(thinking)


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
