extends SceneTree
## Headless smoke test: godot --headless -s res://tests/smoke_test.gd

var _level: Node
var _runner: Runner
var _frame := 0
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	var game_state := root.get_node("GameState")
	game_state.persist = false
	game_state.current_level_index = 0
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")


func _physics_process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		1:
			_make_ai_deterministic()
		60:
			_check(_runner.is_on_floor(), "runner lands on ground")
			_check(_runner.position.x > 150.0, "runner moves right (x=%.0f)" % _runner.position.x)
			_test_placement()
		220:
			_check(_runner.lives == 3, "AI jumps over far pit (lives=%d)" % _runner.lives)
			_check(_runner.is_on_floor(), "runner landed after dodging")
		230:
			_check(_place_ahead(170.0), "place pit close to runner")
		300:
			_check(_runner.lives == 2, "AI too slow for close pit (lives=%d)" % _runner.lives)
			_check(_runner.ai.seen_counts.get("pit", 0) == 2, "AI counted 2 pits")
			var learned := _runner.ai.get_reaction_time("pit")
			_check(learned < _runner.profile.reaction_time, "AI learned: reaction %.2f -> %.2f" % [_runner.profile.reaction_time, learned])
		400:
			_runner.jump()
		410:
			_check(not _runner.is_on_floor(), "runner is airborne after jump")
		490:
			_check(_runner.is_on_floor(), "runner lands after jump")
			_runner.slide()
			_check(_runner.is_sliding(), "runner slides")
		540:
			_check(_runner.take_hit(), "hit lands")
			_check(_runner.lives == 1, "hit removes a life")
			_check(not _runner.take_hit(), "invulnerable right after hit")
		640:
			_check(_runner.take_hit(), "final hit lands")
			_check(_runner.is_down, "runner knocked out after 3 hits")
			_check(_level._game_over, "game over after knockout")
			_check(not _runner.ai.enabled, "AI disabled after game over")
			_check(_level._end_panel.visible, "end panel shown")
			_check(_level._end_stars.filled >= 1, "stars awarded (%d)" % _level._end_stars.filled)
			_check(_level._next_button.visible, "next level button shown")
		650:
			print("DONE: %d failure(s)" % _failures)
			return true
	return false


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
