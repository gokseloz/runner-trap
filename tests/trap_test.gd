extends SceneTree
## Per-trap AI test on level 3 (all traps, fast runner):
## godot --headless --fixed-fps 60 -s res://tests/trap_test.gd

var _level: Node
var _runner: Runner
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	var game_state := root.get_node("GameState")
	game_state.persist = false
	game_state.current_level_index = 2
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")
	_run()


func _run() -> void:
	await _wait(1)
	_make_ai_deterministic()
	await _wait(30)
	await _expect("Wall", 400.0, false, "AI jumps a far wall")
	await _expect("Wall", 200.0, true, "AI too slow for a close wall")
	await _expect("Saw", 400.0, false, "AI slides under a far saw")
	await _expect("Saw", 180.0, true, "AI too slow for a close saw")
	await _expect("Pit", 300.0, false, "AI jumps a pit at 300")
	await _test_slippery_combo()
	print("DONE: %d failure(s)" % _failures)
	quit()


## Same pit distance that was dodged above now hits because the runner is on a slippery floor.
func _test_slippery_combo() -> void:
	_level.energy = _level.level_data.max_energy
	_check(_place("Slippery", 300.0), "place slippery floor")
	for i in 120:
		if _runner.speed_multiplier > 1.0:
			break
		await physics_frame
	_check(_runner.speed_multiplier > 1.0, "slippery speeds runner up")
	await _expect("Pit", 300.0, true, "slippery + pit combo hits at 300")


func _expect(trap_name: String, distance: float, should_hit: bool, label: String) -> void:
	_level.energy = _level.level_data.max_energy
	var lives_before := _runner.lives
	if not _place(trap_name, distance):
		_check(false, label + " (placement failed)")
		return
	var trap: Trap = _level._placed_traps.back()
	for i in 300:
		if trap.consumed or trap.global_position.x + trap.width / 2.0 < _runner.global_position.x - Runner.SIZE.x / 2.0:
			break
		await physics_frame
	_check((_runner.lives < lives_before) == should_hit, "%s (lives %d -> %d)" % [label, lives_before, _runner.lives])
	# Let stun and invulnerability wear off, keep the runner alive.
	await _wait(100)
	_runner.lives = 3


func _place(trap_name: String, distance: float) -> bool:
	for card: TrapCard in _level._cards:
		if card.trap_info.display_name == trap_name:
			var screen_pos := root.get_canvas_transform() * Vector2(_runner.position.x + distance, 600.0)
			return _level.place_card(card, screen_pos)
	return false


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


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
