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
	_game_state.challenge_badges = {}
	_test_challenge_rules()
	_test_challenge_save()
	_check(_game_state.LEVELS.size() == 10, "10 levels listed")
	var ids := {}
	for i in _game_state.LEVELS.size():
		var level: LevelData = _game_state.get_level(i)
		_check(level != null and level.runner != null and not level.available_traps.is_empty(), "level %d loads with runner and traps" % (i + 1))
		ids[level.level_id] = true
		_check(level.seesaw_positions.is_empty() == (i != 6), "only level 7 has a fixed seesaw (%d)" % (i + 1))
		_check((level.challenge != LevelData.Challenge.NONE) == (i < 6), "only first six levels have challenges (%d)" % (i + 1))
		if i == 3:
			_check(level.challenge == LevelData.Challenge.MIN_SPRING_COMBOS and level.challenge_target == 1, "level 4 requires one spring combo")
		if i == 4:
			_check(level.challenge == LevelData.Challenge.MIN_MAGNET_HITS and level.challenge_target == 1, "level 5 requires one magnet hit")
		if i == 5:
			_check(level.challenge == LevelData.Challenge.MIN_TRAP_TYPES and level.challenge_target == 3, "level 6 requires three trap types")
			_check(level.available_traps.size() == 3, "level 6 offers all three required cards")
		if i in [2, 4]:
			_check(is_equal_approx(level.runner.reaction_time, 0.45), "earlier fast runners retain reaction time (%d)" % (i + 1))
		if i == 7:
			_check(level.runner.resource_path != _game_state.get_level(2).runner.resource_path, "level 8 owns a separate fast runner profile")
		var has_spring := false
		var has_snap := false
		var has_magnet := false
		for trap_scene: PackedScene in level.available_traps:
			has_spring = has_spring or trap_scene.resource_path == "res://scenes/traps/spring.tscn"
			has_snap = has_snap or trap_scene.resource_path == "res://scenes/traps/snap.tscn"
			has_magnet = has_magnet or trap_scene.resource_path == "res://scenes/traps/magnet.tscn"
		_check(has_spring == (i in [3, 6]), "spring is exclusive to levels 4 and 7 (%d)" % (i + 1))
		_check(not has_snap, "snap is not offered in levels (%d)" % (i + 1))
		_check(has_magnet == (i == 4), "magnet is exclusive to level 5 (%d)" % (i + 1))
	_check(ids.size() == 10, "level ids are unique")

	var select := await _open_select()
	_check(select.buttons.size() == 10, "10 level buttons")
	_check(not select.buttons[0].disabled, "level 1 open on a fresh save")
	_check(select.buttons[1].disabled, "level 2 locked on a fresh save")
	select.sound_button.pressed.emit()
	_check(not _game_state.sound_enabled and AudioServer.is_bus_mute(0), "sound button mutes")
	select.sound_button.pressed.emit()
	_check(_game_state.sound_enabled and not AudioServer.is_bus_mute(0), "sound button unmutes")
	select.queue_free()

	_game_state.set_level_stars("level_01", 2)
	select = await _open_select()
	_check(not select.buttons[1].disabled, "level 2 opens after level 1 has stars")
	_check(select.buttons[2].disabled, "level 3 still locked")
	select.queue_free()

	print("DONE: %d failure(s)" % _failures)
	quit()


func _test_challenge_rules() -> void:
	var level := LevelData.new()
	_check(not level.is_challenge_completed(true, 3, 2, 1), "no challenge means no badge")
	level.challenge = LevelData.Challenge.MAX_TRAPS
	level.challenge_target = 6
	_check(level.is_challenge_completed(true, 6, 0, 2), "six traps meets limit")
	_check(not level.is_challenge_completed(true, 7, 0, 2), "seven traps exceeds limit")
	_check(not level.is_challenge_completed(false, 3, 0, 1), "loss cannot earn badge")
	_check(not level.is_challenge_completed(true, 0, 0, 0), "empty run cannot earn badge")
	_check(not level.is_challenge_completed(true, 3, 0, 1, true), "ad retry cannot earn badge")
	level.challenge = LevelData.Challenge.MIN_COMBOS
	level.challenge_target = 2
	_check(not level.is_challenge_completed(true, 4, 1, 2), "one combo is insufficient")
	_check(level.is_challenge_completed(true, 4, 2, 2), "two combos meets target")
	level.challenge = LevelData.Challenge.SINGLE_TYPE
	_check(level.is_challenge_completed(true, 4, 0, 1), "one trap type earns badge")
	_check(not level.is_challenge_completed(true, 4, 0, 2), "mixed trap types cannot earn single type badge")
	level.challenge = LevelData.Challenge.MIN_SPRING_COMBOS
	level.challenge_target = 1
	_check(not level.is_challenge_completed(true, 4, 2, 2), "ordinary combos cannot earn spring badge")
	_check(level.is_challenge_completed(true, 4, 1, 2, false, 1), "one spring combo meets target")
	_check(not level.is_challenge_completed(false, 4, 1, 2, false, 1), "spring combo without win earns no badge")
	_check(not level.is_challenge_completed(true, 4, 1, 2, true, 1), "spring combo in ad retry earns no badge")
	level.challenge = LevelData.Challenge.MIN_MAGNET_HITS
	_check(not level.is_challenge_completed(true, 4, 2, 2, false, 1), "other combos do not earn magnet badge")
	_check(level.is_challenge_completed(true, 4, 0, 2, false, 0, 1), "one magnet hit meets target without extra combo requirement")
	_check(not level.is_challenge_completed(false, 4, 1, 2, false, 0, 1), "magnet hit without win earns no badge")
	_check(not level.is_challenge_completed(true, 4, 1, 2, true, 0, 1), "magnet hit in ad retry earns no badge")
	level.challenge = LevelData.Challenge.MIN_TRAP_TYPES
	level.challenge_target = 3
	_check(not level.is_challenge_completed(true, 6, 0, 2), "repeated placements of two types do not meet arsenal target")
	_check(level.is_challenge_completed(true, 3, 0, 3), "three distinct trap types meet arsenal target")
	_check(not level.is_challenge_completed(false, 3, 0, 3), "all trap types without win earn no badge")
	_check(not level.is_challenge_completed(true, 3, 0, 3, true), "arsenal ad retry earns no badge")


func _test_challenge_save() -> void:
	var save_path := "user://challenge_test_%d.cfg" % Time.get_ticks_usec()
	var old_save := ConfigFile.new()
	old_save.set_value("stars", "level_01", 2)
	old_save.save(save_path)
	_game_state.load_game(save_path)
	_check(_game_state.get_level_stars("level_01") == 2, "old save preserves stars")
	_check(not _game_state.has_challenge_badge("level_01"), "old save starts without badges")
	_game_state.award_challenge_badge("level_01")
	_game_state.award_challenge_badge("level_01")
	_game_state.persist = true
	_game_state.save_game(save_path)
	_game_state.persist = false
	_game_state.challenge_badges.clear()
	_game_state.level_stars.clear()
	_game_state.load_game(save_path)
	_check(_game_state.has_challenge_badge("level_01"), "badge survives save and reload")
	_check(_game_state.challenge_badges.size() == 1, "repeated completion does not duplicate badge")
	_check(_game_state.get_level_stars("level_01") == 2, "badge save preserves stars")
	DirAccess.remove_absolute(save_path)
	_game_state.level_stars.clear()
	_game_state.challenge_badges.clear()


func _open_select() -> Control:
	var select: Control = load("res://scenes/level_select.tscn").instantiate()
	root.add_child(select)
	await process_frame
	return select


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
