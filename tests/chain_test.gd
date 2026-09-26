extends SceneTree
## Jump planning against trap chains on level 1 (basic runner):
## godot --headless --fixed-fps 60 -s res://tests/chain_test.gd

var _level: Node
var _runner: Runner
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	var game_state := root.get_node("GameState")
	game_state.persist = false
	game_state.current_level_index = 0
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")
	_run()


func _run() -> void:
	await _wait(1)
	_make_ai_deterministic()
	await _wait(30)
	await _test_chain_seen_early()
	await _test_landing_trap_mid_air()
	await _test_wall_then_pit()
	print("DONE: %d failure(s)" % _failures)
	quit()


## Second pit sits exactly where the ideal jump over the first one lands.
## Both are known before takeoff, so the runner shifts its takeoff and clears both.
func _test_chain_seen_early() -> void:
	var landing := _ideal_landing_offset()
	var lives_before := _runner.lives
	_check(_place("Pit", 450.0), "place first pit")
	_check(_place("Pit", 450.0 + landing), "place pit on landing spot")
	await _wait_until_traps_behind()
	_check(_runner.lives == lives_before, "known chain dodged (lives %d -> %d)" % [lives_before, _runner.lives])
	await _recover()


## Landing trap dropped after takeoff: a single-jump runner can't react in the air.
func _test_landing_trap_mid_air() -> void:
	var lives_before := _runner.lives
	_check(_place("Pit", 450.0), "place pit")
	for i in 240:
		if not _runner.is_on_floor():
			break
		await physics_frame
	_check(not _runner.is_on_floor(), "runner took off")
	_check(_place("Pit", _air_distance() - 20.0), "place pit under landing mid-air")
	await _wait_until_traps_behind()
	_check(_runner.lives == lives_before - 1, "mid-air landing trap hits (lives %d -> %d)" % [lives_before, _runner.lives])
	await _recover()


func _test_wall_then_pit() -> void:
	var landing := _ideal_landing_offset()
	var lives_before := _runner.lives
	_check(_place("Wall", 450.0), "place wall")
	_check(_place("Pit", 450.0 + landing), "place pit behind wall")
	await _wait_until_traps_behind()
	_check(_runner.lives == lives_before, "known wall + pit dodged (lives %d -> %d)" % [lives_before, _runner.lives])
	await _recover()


## Distance from a trap center to where the ideal jump over it lands.
func _ideal_landing_offset() -> float:
	return _air_distance() / 2.0


func _air_distance() -> float:
	return _runner.profile.run_speed * 2.0 * absf(_runner.profile.jump_velocity) / _runner.gravity


func _wait_until_traps_behind() -> void:
	for i in 400:
		var all_behind := true
		for trap: Trap in _level._placed_traps:
			if not trap.consumed and trap.global_position.x + trap.width / 2.0 >= _runner.global_position.x - Runner.SIZE.x / 2.0:
				all_behind = false
		if all_behind:
			return
		await physics_frame


## Let stun and invulnerability wear off, keep the runner alive.
func _recover() -> void:
	await _wait(100)
	_runner.lives = 3


func _place(trap_name: String, distance: float) -> bool:
	_level.energy = _level.level_data.max_energy
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
