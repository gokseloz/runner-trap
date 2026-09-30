extends SceneTree

var _game_state: Node
var _level: Node
var _runner: Runner
var _failures := 0


func _initialize() -> void:
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_run()


func _run() -> void:
	await process_frame
	TranslationServer.set_locale("tr" if OS.get_cmdline_user_args().has("tr") else "en")
	_game_state.level_stars.clear()
	_game_state.challenge_badges.clear()
	await _start_level(0)
	_check(not _place(0, 50.0), "invalid drop rejected")
	_check(_level.traps_used == 0 and _level.trap_types_used.is_empty(), "invalid drop does not count")
	_check(_place(), "first trap placed")
	_check(not _place(0, 250.0), "overlapping drop rejected")
	_check(_level.traps_used == 1, "overlapping drop does not count")
	_level.energy = 0.0
	_check(not _level.place_card(_level._cards[1], _screen_position(500.0)), "unaffordable drop rejected")
	_check(_level.traps_used == 1 and _level.trap_types_used.size() == 1, "unaffordable drop does not count")
	_check(_place() and _place(), "three traps placed")
	_check(_level._challenge_progress.text == tr("Traps: %d/%d") % [3, 6], "live trap counter")
	await _capture("progress")
	_check(_place() and _place() and _place(), "six traps remain within challenge limit")
	_knock_out()
	await _settle()
	_check(_game_state.has_challenge_badge("level_01"), "winning within trap limit earns badge")
	_check(_level._end_challenge_badge.earned, "win panel shows earned badge")
	_check(not _level._challenge_label.visible, "end panel replaces HUD objective")
	await _capture("win")

	await _start_level(0)
	_check(_level.traps_used == 0 and _level.combo_count == 0 and _level.trap_types_used.is_empty(), "new attempt resets all counters")
	_level._end_game(false)
	await _settle()
	_check(_game_state.has_challenge_badge("level_01"), "later loss preserves earned badge")
	await _capture("loss")

	_game_state.challenge_badges.clear()
	await _start_level(0)
	for trap_index in 7:
		_check(_place(), "place trap %d for over-limit run" % (trap_index + 1))
	_check(_level._challenge_progress.text.contains(tr("Challenge not completed")), "over-limit HUD shows missed challenge")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_01"), "over-limit win earns no badge")
	_check(_game_state.get_level_stars("level_01") > 0 and _game_state.is_level_unlocked(1), "missed challenge still awards stars and unlocks next level")

	await _start_level(1)
	_check(_place() and _place() and _place(), "place traps for combo run")
	_hit(_level._placed_traps[0])
	_level._last_dodge_time = _level._time
	_hit(_level._placed_traps[1])
	_check(_level.combo_count == 1, "first combo counted")
	_hit(_level._placed_traps[2])
	_check(_level._game_over and _level.combo_count == 2, "knockout trap is second combo")
	await _settle()
	_check(_game_state.has_challenge_badge("level_02"), "final-hit combo earns badge")
	await _capture("combo_win")

	await _start_level(2)
	_check(_place() and _place() and _place(), "place one type for single-type run")
	_knock_out()
	await _settle()
	_check(_game_state.has_challenge_badge("level_03"), "single-type win earns badge")
	_game_state.challenge_badges.erase("level_03")
	await _start_level(2)
	_check(_place() and _place(1) and _place(), "place mixed trap types")
	_check(_level.trap_types_used.size() == 2, "unique trap types counted")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_03"), "mixed-type win earns no badge")

	await _start_level(0, true)
	_check(_level._challenge_progress.text == tr("Challenge: fresh run required"), "ad replay shows ineligible challenge")
	_check(_place() and _place(), "place traps in ad replay")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_01"), "ad replay cannot earn badge")
	await _capture("continued")

	await _test_spring_challenge()
	await _test_magnet_challenge()
	await _test_arsenal_challenge()
	await _test_seesaw_challenge()
	await _test_quick_hunter_challenge()
	await _start_level(8)
	_check(not _level._challenge_label.visible and not _level._challenge_progress.visible, "later levels hide challenge HUD")
	_level._end_game(false)
	await _settle()
	_check(not _level._end_challenge.visible, "later levels hide challenge result")
	_level.queue_free()
	await _settle()
	_level = null
	_game_state.award_challenge_badge("level_01")
	var select: Control = load("res://scenes/level_select.tscn").instantiate()
	root.add_child(select)
	await _settle()
	_check(select.buttons[0].get_node("ChallengeBadge").earned, "level select shows persisted badge")
	_check(not select.buttons[2].get_node("ChallengeBadge").earned, "unfinished challenge has unearned badge")
	_check(select.buttons[3].get_node("ChallengeBadge").earned, "level 4 shows earned spring badge")
	_check(select.buttons[4].get_node("ChallengeBadge").earned, "level 5 shows earned magnet badge")
	_check(select.buttons[5].get_node("ChallengeBadge").earned, "level 6 shows earned arsenal badge")
	_check(select.buttons[6].get_node("ChallengeBadge").earned, "level 7 shows earned seesaw badge")
	_check(select.buttons[7].get_node("ChallengeBadge").earned, "level 8 shows earned quick hunter badge")
	_check(not select.buttons[8].has_node("ChallengeBadge"), "no badge on level without challenge")
	for button: Button in select.buttons:
		_check(root.get_visible_rect().encloses(button.get_global_rect()), "level button stays inside viewport")
		for content: Control in button.get_node("Content").get_children():
			_check(button.get_global_rect().encloses(content.get_global_rect()), "level text and stars stay inside button: " + str(content.name))
	await _capture("select")
	select.queue_free()
	await _settle()
	print("DONE: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_spring_challenge() -> void:
	await _start_level(3)
	_check(_level._challenge_label.visible, "spring challenge HUD visible")
	_check(_place() and _place() and _place(), "place traps for non-spring run")
	_hit(_level._placed_traps[0])
	_level._last_dodge_time = _level._time
	_hit(_level._placed_traps[1])
	_runner.speed_multiplier = 1.5
	_hit(_level._placed_traps[2])
	await _settle()
	_check(_level.combo_count == 2 and _level.spring_combo_count == 0, "chain and slippery combos do not count as spring combos")
	_check(not _game_state.has_challenge_badge("level_04"), "non-spring win earns no spring badge")

	await _start_level(3, true)
	_check(_place() and _place(), "place traps for spring ad replay")
	_hit(_level._placed_traps[0])
	_runner._spring_landing_time = 0.25
	_hit(_level._placed_traps[1])
	await _settle()
	_check(_level.spring_combo_count == 1 and not _game_state.has_challenge_badge("level_04"), "spring combo in ad replay earns no badge")

	await _start_level(3)
	_check(_level.spring_combo_count == 0, "new attempt resets spring counter")
	_check(_level._challenge_progress.text == tr("Spring combos: %d/%d") % [0, 1], "spring progress starts at zero")
	_check(_place() and _place() and _place(), "place traps for spring knockout run")
	_hit(_level._placed_traps[0])
	_hit(_level._placed_traps[1])
	_runner._spring_landing_time = 0.25
	_hit(_level._placed_traps[2])
	_check(_level._game_over and _level.spring_combo_count == 1, "knockout counts spring combo")
	_check(_level._challenge_progress.text == tr("Spring combos: %d/%d") % [1, 1], "spring progress updates after hit")
	await _settle()
	_check(_game_state.has_challenge_badge("level_04") and _level._end_challenge_badge.earned, "final spring combo awards medal")
	await _capture("spring_win")


func _test_magnet_challenge() -> void:
	await _start_level(4)
	_check(_level._challenge_label.visible, "magnet challenge HUD visible")
	_check(_place() and _place() and _place(), "place traps for ordinary combo run")
	_level._last_dodge_time = _level._time
	_knock_out()
	await _settle()
	_check(_level.combo_count > 0 and _level.magnet_hit_count == 0, "ordinary combos do not count as magnet hits")
	_check(not _game_state.has_challenge_badge("level_05"), "ordinary win earns no magnet medal")

	await _start_level(4)
	_check(_place(), "place trap for magnet loss")
	_hit_with_magnet(_level._placed_traps[0])
	_check(_level.magnet_hit_count == 1, "magnet hit updates live counter")
	_level._end_game(false)
	await _settle()
	_check(not _game_state.has_challenge_badge("level_05"), "qualifying hit still requires a win")

	await _start_level(4, true)
	_check(_place() and _place(), "place traps for magnet ad replay")
	_hit(_level._placed_traps[0])
	_hit_with_magnet(_level._placed_traps[1])
	await _settle()
	_check(_level._game_over and _level.magnet_hit_count == 1, "magnet knockout counted in ad replay")
	_check(not _game_state.has_challenge_badge("level_05"), "ad replay earns no magnet medal")

	await _start_level(4)
	_check(_level.magnet_hit_count == 0, "new attempt resets magnet counter")
	_check(_level._challenge_progress.text == tr("Magnet hits: %d/%d") % [0, 1], "magnet progress starts at zero")
	_check(_place() and _place() and _place(), "place traps for magnet knockout run")
	_hit(_level._placed_traps[0])
	_hit(_level._placed_traps[1])
	_hit_with_magnet(_level._placed_traps[2])
	_check(_level._game_over and _level.magnet_hit_count == 1, "knockout counts magnet hit")
	_check(_level._challenge_progress.text == tr("Magnet hits: %d/%d") % [1, 1], "magnet progress updates on final hit")
	await _settle()
	_check(_game_state.has_challenge_badge("level_05") and _level._end_challenge_badge.earned, "final magnet hit awards medal")
	await _capture("magnet_win")


func _hit_with_magnet(trap: Trap) -> void:
	_runner._invulnerable_time_left = 0.0
	_runner._stun_time_left = 0.0
	_check(_runner.pull_from_magnet(240.0, 0.65), "magnet pull starts before hit")
	_hit(trap)


func _test_arsenal_challenge() -> void:
	await _start_level(5)
	_check(_level._challenge_label.visible, "arsenal challenge HUD visible")
	_check(_level._challenge_progress.text == tr("Trap types: %d/%d") % [0, 3], "arsenal progress starts at zero")
	_check(_place(0) and _place(0), "place same trap type twice")
	_check(_level._challenge_progress.text == tr("Trap types: %d/%d") % [1, 3], "repeated type only counts once")
	_check(not _place(2, 250.0), "overlapping new trap type rejected")
	_level.energy = 0.0
	_check(not _level.place_card(_level._cards[2], _screen_position(650.0)), "unaffordable new trap type rejected")
	_check(_level.trap_types_used.size() == 1, "failed new types do not advance arsenal counter")
	_check(_place(1), "place second trap type")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_06"), "two-type win earns no arsenal medal")
	_check(_game_state.get_level_stars("level_06") > 0 and _game_state.is_level_unlocked(6), "missing arsenal challenge still awards stars and next level")

	await _start_level(5, true)
	_check(_place(0) and _place(1) and _place(2), "place all types in arsenal ad replay")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_06"), "arsenal ad replay earns no medal")

	await _start_level(5)
	_check(_level.trap_types_used.is_empty(), "arsenal types reset for fresh attempt")
	_check(_place(0) and _place(1) and _place(2), "place all types before loss")
	_level._end_game(false)
	await _settle()
	_check(not _game_state.has_challenge_badge("level_06"), "all types placed without win earn no medal")

	await _start_level(5)
	_check(_place(0) and _place(0) and _place(0) and _place(1) and _place(2), "place all three types for winning run")
	_check(_level._challenge_progress.text == tr("Trap types: %d/%d") % [3, 3], "arsenal progress reaches three types")
	_check(not _game_state.has_challenge_badge("level_06"), "all types placed do not award medal before win")
	_knock_out()
	await _settle()
	_check(not _level._placed_traps[3].consumed and not _level._placed_traps[4].consumed, "arsenal does not require each trap type to hit")
	_check(_game_state.has_challenge_badge("level_06") and _level._end_challenge_badge.earned, "three-type win awards arsenal medal")
	await _capture("arsenal_win")

	await _start_level(5)
	_level._end_game(false)
	await _settle()
	_check(_game_state.has_challenge_badge("level_06"), "later loss preserves arsenal medal")


func _test_seesaw_challenge() -> void:
	await _start_level(6)
	_check(_level._challenge_label.visible, "seesaw challenge HUD visible")
	_check(_level._challenge_progress.text == tr("Seesaw launches: %d/%d") % [0, 1], "seesaw progress starts at zero")
	_check(_place(3, 250.0), "place spring for non-seesaw run")
	for trap_index in 3:
		_check(_place(0, 1200.0 + trap_index * 140.0), "place damage traps beyond seesaw")
	_runner._spring_landing_time = 0.25
	_knock_out()
	await _settle()
	_check(_level.spring_combo_count > 0 and _level.seesaw_launch_count == 0, "spring combo alone is not a seesaw launch")
	_check(not _game_state.has_challenge_badge("level_07"), "win without seesaw launch earns no medal")
	_check(_game_state.get_level_stars("level_07") > 0 and _game_state.is_level_unlocked(7), "missing seesaw challenge still awards stars and next level")

	await _start_level(6)
	_check(_place(3, 250.0), "place spring for seesaw loss")
	_level.get_node("Track/Seesaw").launched.emit()
	_check(_level.seesaw_launch_count == 1, "seesaw event advances live counter")
	_check(_level._challenge_progress.text == tr("Seesaw launches: %d/%d") % [1, 1], "seesaw HUD shows completed launch count")
	_check(not _game_state.has_challenge_badge("level_07"), "launch does not award medal before win")
	await _capture("seesaw_progress")
	_level._end_game(false)
	await _settle()
	_check(not _game_state.has_challenge_badge("level_07"), "seesaw launch followed by loss earns no medal")
	_level.get_node("Track/Seesaw").launched.emit()
	_check(_level.seesaw_launch_count == 1, "late launch event after game over is ignored")

	await _start_level(6, true)
	_check(_place(0, 1200.0) and _place(0, 1340.0), "place traps for seesaw ad replay")
	_level.get_node("Track/Seesaw").launched.emit()
	_check(_level._challenge_progress.text == tr("Challenge: fresh run required"), "seesaw ad replay stays ineligible after launch")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_07"), "seesaw ad replay earns no medal")

	await _start_level(6)
	_check(_level.seesaw_launch_count == 0, "fresh run resets seesaw count")
	_check(_place(3, 250.0), "place spring for winning seesaw run")
	for trap_index in 3:
		_check(_place(0, 1200.0 + trap_index * 140.0), "place traps for seesaw win")
	_level.get_node("Track/Seesaw").launched.emit()
	_knock_out()
	await _settle()
	_check(_game_state.has_challenge_badge("level_07") and _level._end_challenge_badge.earned, "seesaw launch and win award medal")
	await _capture("seesaw_win")

	await _start_level(6)
	_level._end_game(false)
	await _settle()
	_check(_game_state.has_challenge_badge("level_07"), "later loss preserves seesaw medal")


func _test_quick_hunter_challenge() -> void:
	await _start_level(7)
	_check(_level._challenge_label.visible, "quick hunter HUD visible")
	_check(_place() and _place() and _place(), "place traps for late quick hunter win")
	_runner.position.x = _level.level_data.track_length * 0.25
	_level._physics_process(0.0)
	_check(_level._challenge_progress.text == tr("Track: %d%% / %d%%") % [25, 50], "track progress updates without trap placement")
	await _capture("quick_hunter_progress")
	_runner.position.x = _level.level_data.track_length * 0.500001
	_level._physics_process(0.0)
	_check(_level._challenge_progress.text == (tr("Track: %d%% / %d%%") % [51, 50]) + " - " + tr("Challenge not completed"), "crossing halfway immediately shows missed challenge without rounding down")
	_check(not _level._game_over, "crossing challenge deadline does not end the level")
	await _capture("quick_hunter_missed")
	_knock_out()
	_runner.position.x = _level.level_data.track_length * 0.25
	await _settle()
	_check(not _game_state.has_challenge_badge("level_08"), "late win does not earn medal even if position later changes")
	_check(_game_state.get_level_stars("level_08") == 2 and _game_state.is_level_unlocked(8), "late win retains normal stars and unlocks next level")

	await _start_level(7)
	_check(not _level._challenge_progress.text.contains(tr("Challenge not completed")), "new run resets deadline progress")
	_check(_place(), "place trap before early loss")
	_runner.position.x = _level.level_data.track_length * 0.25
	_level._end_game(false)
	await _settle()
	_check(not _game_state.has_challenge_badge("level_08"), "loss before halfway earns no medal")

	await _start_level(7, true)
	_check(_place() and _place(), "place traps for early ad replay win")
	_runner.position.x = _level.level_data.track_length * 0.25
	_level._physics_process(0.0)
	_check(_level._challenge_progress.text == tr("Challenge: fresh run required"), "track updates preserve ad replay ineligibility")
	_knock_out()
	await _settle()
	_check(not _game_state.has_challenge_badge("level_08"), "early ad replay win earns no medal")

	await _start_level(7)
	_check(_place() and _place() and _place(), "place traps for halfway win")
	_runner.position.x = _level.level_data.track_length * 0.5
	_level._physics_process(0.0)
	_check(_level._challenge_progress.text == tr("Track: %d%% / %d%%") % [50, 50], "exactly halfway remains eligible")
	_knock_out()
	_runner.position.x += 1.0
	await _settle()
	_check(_game_state.has_challenge_badge("level_08") and _level._end_challenge_badge.earned, "halfway knockout awards medal using knockout position")
	_check(_game_state.get_level_stars("level_08") == 3, "halfway knockout retains three stars")
	await _capture("quick_hunter_win")

	await _start_level(7)
	_level._end_game(false)
	await _settle()
	_check(_game_state.has_challenge_badge("level_08"), "later loss preserves quick hunter medal")


func _start_level(index: int, continued := false) -> void:
	if _level != null:
		_level.queue_free()
		await _settle()
	_game_state.current_level_index = index
	_game_state.continue_run = continued
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")
	_runner.ai.enabled = false
	_runner.set_physics_process(false)
	_level.set_physics_process(false)
	await _settle()


func _place(card_index := 0, distance := -1.0) -> bool:
	_level.energy = _level.level_data.max_energy
	var ahead: float = distance if distance >= 0.0 else 250.0 + _level.traps_used * 140.0
	return _level.place_card(_level._cards[card_index], _screen_position(ahead))


func _screen_position(distance: float) -> Vector2:
	return root.get_canvas_transform() * Vector2(_runner.position.x + distance, 600.0)


func _hit(trap: Trap) -> void:
	_runner._invulnerable_time_left = 0.0
	trap._on_body_entered(_runner)


func _knock_out() -> void:
	for trap: Trap in _level._placed_traps:
		if _runner.is_down:
			break
		_hit(trap)


func _settle() -> void:
	for frame in 3:
		await process_frame


func _capture(label: String) -> void:
	if _level != null and _level._end_panel.visible:
		_check(root.get_visible_rect().encloses(_level._end_panel.get_global_rect()), "end panel fits viewport: " + label)
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await RenderingServer.frame_post_draw
	var directory := "res://build/challenges/"
	DirAccess.make_dir_recursive_absolute(directory)
	var image := root.get_texture().get_image()
	_check(not image.is_empty(), "rendered image is nonempty: " + label)
	var name := "%s_%dx%d_%s.png" % [TranslationServer.get_locale(), image.get_width(), image.get_height(), label]
	_check(image.save_png(directory + name) == OK, "saved " + name)


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1