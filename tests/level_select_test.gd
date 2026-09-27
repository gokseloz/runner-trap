extends SceneTree
## Level list and unlock flow: godot --headless -s res://tests/level_select_test.gd

var _game_state: Node
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_run()


func _run() -> void:
	# GameState loads the real save in _ready, which runs after _initialize.
	await process_frame
	_game_state.level_stars = {}
	_check(_game_state.LEVELS.size() == 10, "10 levels listed")
	var ids := {}
	for i in _game_state.LEVELS.size():
		var level: LevelData = _game_state.get_level(i)
		_check(level != null and level.runner != null and not level.available_traps.is_empty(), "level %d loads with runner and traps" % (i + 1))
		ids[level.level_id] = true
	_check(ids.size() == 10, "level ids are unique")

	var select := await _open_select()
	_check(select.buttons.size() == 10, "10 level buttons")
	_check(not select.buttons[0].disabled, "level 1 open on a fresh save")
	_check(select.buttons[1].disabled, "level 2 locked on a fresh save")
	select.queue_free()

	_game_state.set_level_stars("level_01", 2)
	select = await _open_select()
	_check(not select.buttons[1].disabled, "level 2 opens after level 1 has stars")
	_check(select.buttons[2].disabled, "level 3 still locked")
	select.queue_free()

	print("DONE: %d failure(s)" % _failures)
	quit()


func _open_select() -> Control:
	var select: Control = load("res://scenes/level_select.tscn").instantiate()
	root.add_child(select)
	await process_frame
	return select


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
