extends SceneTree
## Pause menu: godot --headless -s res://tests/pause_test.gd

var _game_state: Node
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_game_state.current_level_index = 0
	_run()


func _run() -> void:
	var level := await _load_level()
	var runner: Runner = level.get_node("Runner")
	_check(not level._pause_menu.visible and level._pause_button.visible, "menu hidden, pause button shown")
	_check(not quit_on_go_back, "back button handled by the level")

	level._pause_button.pressed.emit()
	var x := runner.position.x
	for i in 10:
		await physics_frame
	_check(paused and level._pause_menu.visible, "pause button pauses and shows menu")
	_check(runner.position.x == x, "runner frozen while paused")

	level._resume_button.pressed.emit()
	for i in 10:
		await physics_frame
	_check(not paused and not level._pause_menu.visible, "resume hides menu")
	_check(runner.position.x > x, "runner moves again after resume")

	level.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(paused, "back button pauses")
	level.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not paused, "back button again resumes")
	level.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(paused, "leaving the app pauses")

	level._restart_button.pressed.emit()
	await process_frame
	await physics_frame
	level = current_scene
	_check(not paused and level != null and not level._game_over, "restart reloads unpaused")

	runner = level.get_node("Runner")
	runner.position.x = level.level_data.track_length + 10.0
	await physics_frame
	await physics_frame
	level.pause()
	_check(not paused and not level._pause_button.visible, "no pause after the level ended")

	level._pause_levels_button.pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/level_select.tscn" and not paused, "levels button opens level select unpaused")
	_check(quit_on_go_back, "back button quits again outside a level")

	print("DONE: %d failure(s)" % _failures)
	quit()


func _load_level() -> Node:
	await process_frame
	var level: Node = load("res://scenes/level.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await physics_frame
	return level


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
