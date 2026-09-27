extends SceneTree
## Continue after a rewarded ad: godot --headless -s res://tests/continue_test.gd

var _game_state: Node
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_game_state.current_level_index = 0
	_run()


func _run() -> void:
	await process_frame
	var level: Node = load("res://scenes/level.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await physics_frame
	var runner: Runner = level.get_node("Runner")
	var full_lives := runner.profile.lives
	_check(runner.lives == full_lives, "first run starts with full lives (%d)" % runner.lives)

	await _let_runner_escape(level)
	_check(level._end_panel.visible and not level._next_button.visible, "lose panel shown")
	_check(level._continue_button.visible, "continue button offered after losing")

	level._continue_button.pressed.emit()
	await process_frame
	await physics_frame
	level = current_scene
	runner = level.get_node("Runner")
	_check(not level._game_over, "level restarted after the ad")
	_check(runner.lives == full_lives - 1, "continued run starts one life down (%d)" % runner.lives)
	_check(not _game_state.continue_run, "continue flag cleared")

	await _let_runner_escape(level)
	_check(not level._continue_button.visible, "no second continue on a continued run")

	level._retry_button.pressed.emit()
	await process_frame
	await physics_frame
	runner = current_scene.get_node("Runner")
	_check(runner.lives == full_lives, "plain retry restores full lives")

	print("DONE: %d failure(s)" % _failures)
	quit()


func _let_runner_escape(level: Node) -> void:
	var runner: Runner = level.get_node("Runner")
	runner.position.x = level.level_data.track_length + 10.0
	await physics_frame
	await physics_frame


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
