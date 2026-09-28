extends SceneTree
## Headless smoke test: godot --headless -s res://tests/smoke_test.gd

var _level: Node
var _runner: Runner
var _frame := 0
var _failures := 0
var _saw_confident := false
var _saw_focused := false
var _saw_surprised := false
var _saw_angry := false


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--capture"):
		root.focus_exited.connect(_resume_capture)
		AudioServer.set_bus_mute(0, true)
	# Autoloads aren't visible by name to -s scripts at compile time.
	var game_state := root.get_node("GameState")
	game_state.persist = false
	game_state.current_level_index = 0
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")


func _physics_process(_delta: float) -> bool:
	_frame += 1
	_saw_confident = _saw_confident or _runner._body.expression == RunnerVisual.Mood.CONFIDENT
	_saw_focused = _saw_focused or _runner._body.expression == RunnerVisual.Mood.FOCUSED
	_saw_surprised = _saw_surprised or _runner._body.expression == RunnerVisual.Mood.SURPRISED
	_saw_angry = _saw_angry or _runner._body.expression == RunnerVisual.Mood.ANGRY
	match _frame:
		1:
			_make_ai_deterministic()
			_test_expressions()
		60:
			_check(_runner.is_on_floor(), "runner lands on ground")
			_check(_runner.position.x > 150.0, "runner moves right (x=%.0f)" % _runner.position.x)
			_test_placement()
		220:
			_check(_runner.lives == 3, "AI jumps over far pit (lives=%d)" % _runner.lives)
			_check(_runner.is_on_floor(), "runner landed after dodging")
			_check(_saw_confident, "successful dodge triggers confidence")
			_check(not _saw_focused, "first encounter does not show learned expression")
		230:
			_check(_place_ahead(170.0), "place pit close to runner")
		300:
			_check(_runner.lives == 3, "AI escapes close pit (lives=%d)" % _runner.lives)
			_check(_saw_focused, "repeated trap triggers learned expression")
			_check(_runner.ai.seen_counts.get("pit", 0) == 2, "AI counted 2 pits")
			var learned := _runner.ai.get_reaction_time("pit")
			_check(learned < _runner.profile.reaction_time, "AI learned: reaction %.2f -> %.2f" % [_runner.profile.reaction_time, learned])
			_runner.ai.enabled = false
			_check(_place_ahead(170.0), "place pit for damage check with dodging disabled")
		390:
			_check(_runner.lives == 2, "unavoided pit still removes a life")
			_check(_saw_surprised, "trap hit triggers surprise")
			_runner.ai.enabled = true
		400:
			_runner.jump()
		410:
			_check(not _runner.is_on_floor(), "runner is airborne after jump")
		470:
			_capture_expression("angry")
		490:
			_check(_runner.is_on_floor(), "runner lands after jump")
			_runner.slide()
			_check(_runner.is_sliding(), "runner slides")
		540:
			_check(_saw_angry, "surviving a hit triggers anger after surprise")
			_check(_runner.take_hit(), "hit lands")
			_check(_runner.lives == 1, "hit removes a life")
			_check(_runner._body.anger_level == 2, "nearby second hit intensifies anger")
			_check(not _runner.take_hit(), "invulnerable right after hit")
			_runner.celebrate_dodge()
			_check(_runner._body.expression == RunnerVisual.Mood.SURPRISED, "passing traps while hurt does not trigger confidence")
		620:
			_check(is_equal_approx(_runner.velocity.x, _runner.profile.run_speed), "anger does not change running speed")
			_capture_expression("furious")
		640:
			_check(_runner._body.expression == RunnerVisual.Mood.ANGRY, "second hit leads to stronger anger")
			_check(_runner.take_hit(), "final hit lands")
			_check(_runner.is_down, "runner knocked out after 3 hits")
			_check(_runner._body.down, "knockout keeps defeated face")
			_check(_level._game_over, "game over after knockout")
			_check(not _runner.ai.enabled, "AI disabled after game over")
			_check(_level._end_panel.visible, "end panel shown")
			_check(_level._end_stars.filled >= 1, "stars awarded (%d)" % _level._end_stars.filled)
			_check(_level._next_button.visible, "next level button shown")
		650:
			print("DONE: %d failure(s)" % _failures)
			return true
	return false


func _test_expressions() -> void:
	var visual := RunnerVisual.new()
	visual.react(RunnerVisual.Mood.CONFIDENT, 0.8)
	_check(visual.expression == RunnerVisual.Mood.CONFIDENT, "dodge expression starts")
	visual.react(RunnerVisual.Mood.FOCUSED, 1.0)
	_check(visual.expression == RunnerVisual.Mood.FOCUSED, "learning takes priority over confidence")
	visual.react(RunnerVisual.Mood.SURPRISED, 1.0)
	visual.react(RunnerVisual.Mood.CONFIDENT, 0.8)
	_check(visual.expression == RunnerVisual.Mood.SURPRISED, "hit takes priority over confidence")
	visual._process(0.6)
	visual.react(RunnerVisual.Mood.SURPRISED, 1.0)
	visual._process(0.5)
	_check(visual.expression == RunnerVisual.Mood.NEUTRAL, "expression expires without repeated events extending it")
	visual.react_to_hit(1.0)
	_check(visual.expression == RunnerVisual.Mood.SURPRISED and visual.anger_level == 1, "first hit starts with surprise and mild anger")
	visual._process(1.0)
	_check(visual.expression == RunnerVisual.Mood.ANGRY, "surprise transitions to anger")
	visual.react(RunnerVisual.Mood.CONFIDENT, 0.8)
	visual.react(RunnerVisual.Mood.FOCUSED, 1.0)
	_check(visual.expression == RunnerVisual.Mood.ANGRY, "anger takes priority over dodge and learning")
	visual._process(2.0)
	_check(visual.expression == RunnerVisual.Mood.NEUTRAL, "mild anger expires")
	visual.react_to_hit(1.0)
	_check(visual.anger_level == 2, "second recent hit strengthens anger")
	visual._process(1.0)
	visual._process(2.5)
	_check(visual.expression == RunnerVisual.Mood.ANGRY, "strong anger lasts longer")
	visual._process(0.5)
	_check(visual.expression == RunnerVisual.Mood.NEUTRAL, "strong anger expires")
	visual._process(3.0)
	visual.react_to_hit(1.0)
	_check(visual.anger_level == 1, "distant hit starts mild anger again")
	visual.down = true
	visual._process(1.0)
	_check(visual.expression == RunnerVisual.Mood.NEUTRAL, "knockout cancels pending anger")
	visual.react_to_hit(1.0)
	visual.react(RunnerVisual.Mood.CONFIDENT, 0.8)
	_check(visual.expression == RunnerVisual.Mood.NEUTRAL, "knocked out runner ignores expressions")
	visual.free()


func _resume_capture() -> void:
	if is_instance_valid(_level):
		_level.resume.call_deferred()


func _capture_expression(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png("/tmp/runner-trap-%s.png" % label) == OK, "capture " + label)


func _test_placement() -> void:
	var card: TrapCard = _level._cards[0]
	var cost := card.trap_info.energy_cost
	var energy_before: float = _level.energy

	_check(not _place_ahead(-100.0), "can't place behind runner")
	_check(not _place_ahead(50.0), "can't place under runner")
	_check(_place_ahead(500.0), "place pit far ahead")
	_check(is_equal_approx(_level.energy, energy_before - cost), "energy spent (%.1f -> %.1f)" % [energy_before, _level.energy])
	_check(not _place_ahead(530.0), "can't overlap existing trap")

	var energy_after: float = _level.energy
	_level.energy = 0.0
	_check(not _place_ahead(900.0), "can't place without energy")
	_level.energy = energy_after


func _place_ahead(distance: float) -> bool:
	var screen_pos := root.get_canvas_transform() * Vector2(_runner.position.x + distance, 600.0)
	return _level.place_card(_level._cards[0], screen_pos)


## Call once the level is ready. The profile must be edited on the runner itself:
## a reference taken before the scene is ready can be freed and reloaded from disk.
func _make_ai_deterministic() -> void:
	_runner.profile.reaction_jitter = 0.0
	_runner.profile.timing_error = 0.0
	_runner.profile.mistake_chance = 0.0


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
