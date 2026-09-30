extends SceneTree
## Per-trap AI test on level 3 (all traps, fast runner):
## godot --headless --fixed-fps 60 -s res://tests/trap_test.gd

var _level: Node
var _runner: Runner
var _failures := 0
var _combos: Array[String] = []


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--capture"):
		root.focus_exited.connect(_resume_capture)
	# Autoloads aren't visible by name to -s scripts at compile time.
	var game_state := root.get_node("GameState")
	game_state.persist = false
	game_state.current_level_index = 2
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")
	_level.combo_landed.connect(_combos.append)
	_run()


func _resume_capture() -> void:
	if is_instance_valid(_level):
		_level.resume.call_deferred()


func _run() -> void:
	await _wait(1)
	if OS.get_cmdline_user_args().has("--capture"):
		AudioServer.set_bus_mute(0, true)
	if OS.get_cmdline_user_args().has("tr"):
		TranslationServer.set_locale("tr")
	_make_ai_deterministic()
	await _wait(30)
	if OS.get_cmdline_user_args().has("--umbrella-only"):
		await _test_umbrella()
		print("DONE: %d failure(s)" % _failures)
		quit(1 if _failures > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--wall-revenge-only"):
		await _test_wall_revenge_target()
		await _test_wall_revenge()
		print("DONE: %d failure(s)" % _failures)
		quit(1 if _failures > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--fake-finish-only"):
		await _test_fake_finish()
		print("DONE: %d failure(s)" % _failures)
		quit(1 if _failures > 0 else 0)
		return
	await _test_snap_timing()
	await _test_spring_launch()
	await _expect("Wall", 400.0, false, "AI jumps a far wall")
	await _expect("Wall", 200.0, false, "AI reacts early enough to a close wall")
	_check(_combos.is_empty(), "lone close wall is no combo (%s)" % [_combos])
	await _expect("Saw", 400.0, false, "AI slides under a far saw")
	await _expect("Saw", 180.0, false, "AI reacts early enough to a close saw")
	await _expect("Pit", 300.0, false, "AI jumps a pit at 300")
	await _test_slippery_combo()
	await _test_spring_trap()
	await _test_jumper_spring()
	await _test_snap_trap()
	await _test_magnet_pull()
	await _test_magnet_trap()
	await _test_nearest_traps()
	await _test_seesaw()
	await _test_fake_finish()
	await _test_wall_revenge_target()
	await _test_wall_revenge()
	await _test_umbrella()
	print("DONE: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


## Same pit distance that was dodged above now hits because the runner is on a slippery floor.
func _test_snap_timing() -> void:
	var snap = load("res://scenes/traps/snap.tscn").instantiate()
	snap.position = Vector2(-1000.0, 600.0)
	_level._track.add_child(snap)
	snap.set_physics_process(false)
	var lives_before := _runner.lives
	snap._on_body_entered(_runner)
	_check(_runner.lives == lives_before, "waiting snap does not hurt")
	snap._physics_process(0.49)
	_check(not snap.is_active and not snap.consumed, "snap waits for its delay")
	snap._physics_process(0.02)
	_check(snap.is_active, "snap closes after delay")
	snap._physics_process(0.18)
	_check(snap.consumed and not snap.is_active, "missed snap expires")
	snap._on_body_entered(_runner)
	_check(_runner.lives == lives_before, "expired snap is harmless")
	snap.queue_free()
	await process_frame


func _test_spring_launch() -> void:
	var lives_before := _runner.lives
	var jumps_before := _runner.get_air_jumps_left()
	_check(_runner.slide(), "slide before spring launch")
	_check(_runner.launch_from_spring(650.0), "spring launches grounded runner")
	_check(not _runner.is_sliding(), "spring ends slide")
	_check(_runner.lives == lives_before, "spring launch does not hurt")
	_check(_runner.get_air_jumps_left() == jumps_before, "spring preserves air jumps")
	_check(not _runner.jump() and not _runner.slide(), "AI cannot override pending spring launch")
	await _wait(5)
	_check(not _runner.is_on_floor() and _runner.velocity.y < 0.0, "spring runner rises")
	_check(not _runner.launch_from_spring(650.0), "airborne runner cannot trigger another spring")
	_check(_runner.is_spring_combo_active(), "spring flight opens combo window")
	for frame in 180:
		if _runner.is_on_floor():
			break
		await physics_frame
	_check(_runner.is_on_floor(), "spring runner lands")
	_check(_runner.is_spring_combo_active(), "spring combo remains briefly after landing")
	await _wait(30)
	_check(not _runner.is_spring_combo_active(), "spring combo expires after landing")
	_check(not _runner.launch_from_spring(0.0), "invalid spring strength rejected")
	_runner.take_hit()
	_check(not _runner.launch_from_spring(650.0), "hurt runner cannot trigger spring")
	await _wait(100)
	_runner.lives = lives_before


func _test_slippery_combo() -> void:
	await _start_trap_level(2)
	_level.energy = _level.level_data.max_energy
	_check(_place("Slippery", 300.0), "place slippery floor")
	for i in 120:
		if _runner.speed_multiplier > 1.0:
			break
		await physics_frame
	_check(_runner.speed_multiplier > 1.0, "slippery speeds runner up")
	await _expect("Pit", 300.0, true, "slippery + pit combo hits at 300")
	_check(_combos.back() == "slippery", "slippery combo counted (%s)" % [_combos])


func _test_spring_trap() -> void:
	await _start_trap_level()
	var landings: Array[Dictionary] = []
	_runner.landed.connect(func(impact_speed: float, from_spring: bool): landings.append({"speed": impact_speed, "spring": from_spring}))
	_check(_place("Spring", 300.0), "place spring through card")
	var spring: Trap = _level._placed_traps.back()
	_check(is_equal_approx(_level.energy, _level.level_data.max_energy - spring.energy_cost), "spring costs energy")
	await _capture_trap("spring-ready")
	await _wait_for_spring(spring)
	_check(_runner.lives == 3 and _combos.is_empty(), "spring contact causes no damage or free combo")
	var launch_velocity := _runner.velocity.y
	spring._on_body_entered(_runner)
	_check(_runner.velocity.y == launch_velocity, "consumed spring cannot launch twice")
	await _wait(120)
	_check(_runner.lives == 3 and _runner.is_on_floor(), "spring alone lands safely")
	_check(landings.size() == 1 and landings[0].speed > 400.0 and landings[0].spring, "spring landing reports impact speed and source once")
	_check(not _runner.is_spring_combo_active(), "spring combo expires without damage")

	await _start_trap_level()
	_check(_place("Spring", 300.0), "place spring for landing combo")
	spring = _level._placed_traps.back()
	await _wait_for_spring(spring)
	await _wait(8)
	var vertical_speed := _runner.velocity.y
	var drop := 600.0 - _runner.position.y
	var time_to_land := (-vertical_speed + sqrt(vertical_speed * vertical_speed + 2.0 * _runner.gravity * drop)) / _runner.gravity
	var landing_distance := _runner.profile.run_speed * time_to_land
	_level.energy = _level.level_data.max_energy
	_check(_place("Pit", landing_distance), "place pit on spring landing spot")
	await _capture_trap("spring-flight")
	for frame in 150:
		if _runner.lives < 3:
			break
		await physics_frame
	_check(_runner.lives == 2, "spring landing pit hits runner with AI enabled")
	_check(_combos == ["spring"], "spring landing hit awards exactly one spring combo")
	_check(is_equal_approx(_level.energy, _level.level_data.max_energy), "spring combo restores two energy up to the cap")
	_check(not _runner.is_spring_combo_active(), "hit consumes spring combo eligibility")
	_check(_level.spring_combo_count == 1, "real spring landing hit advances spring challenge")
	await _capture_trap("spring-combo")


func _test_jumper_spring() -> void:
	await _start_trap_level(6, false, false)
	_check(_runner.profile.max_jumps == 2, "level 7 uses double-jump runner")
	_check(_place("Spring", 300.0), "place spring on level 7")
	var spring: Trap = _level._placed_traps.back()
	await _capture_trap("jumper-ready")
	await _wait_for_spring(spring)
	await _wait(8)
	_check(_runner.get_air_jumps_left() == 1, "spring preserves jumper's air jump")
	var vertical_speed := _runner.velocity.y
	var drop := 600.0 - _runner.position.y
	var time_to_land := (-vertical_speed + sqrt(vertical_speed * vertical_speed + 2.0 * _runner.gravity * drop)) / _runner.gravity
	_level.energy = _level.level_data.max_energy
	_check(_place("Pit", _runner.profile.run_speed * time_to_land), "place pit on jumper's spring landing spot")
	var used_air_jump := false
	for frame in 150:
		used_air_jump = used_air_jump or _runner.get_air_jumps_left() == 0
		if _runner.is_on_floor():
			break
		await physics_frame
	_check(used_air_jump, "jumper AI uses air jump to change spring landing")
	_check(_runner.is_on_floor() and _runner.lives == 3, "jumper lands safely beyond pit")
	_check(_combos.is_empty(), "successful air dodge awards no damage combo")
	await _wait(30)
	_check(not _runner.is_spring_combo_active(), "jumper spring combo window expires after landing")


func _test_snap_trap() -> void:
	await _start_trap_level(4, true)
	_check(_place("Snap", 200.0), "place timed snap near fast runner")
	var snap: Trap = _level._placed_traps.back()
	_check(is_equal_approx(_level.energy, _level.level_data.max_energy - 2.0), "snap costs two energy")
	await _capture_trap("snap-ready")
	for frame in 90:
		if snap.consumed:
			break
		await physics_frame
	_check(_runner.lives == 2, "well-timed snap hits with AI enabled")
	_check(snap.consumed, "snap is spent after hit")
	_check(_combos.is_empty(), "lone snap does not award a combo")
	await _capture_trap("snap-closed")
	_runner._invulnerable_time_left = 0.0
	snap._on_body_entered(_runner)
	_check(_runner.lives == 2, "spent snap cannot hit twice")

	await _start_trap_level(4, true)
	_check(_place("Snap", 650.0), "place snap too early")
	snap = _level._placed_traps.back()
	await _wait(130)
	_check(snap.consumed and _runner.lives == 3, "early snap expires before runner arrives")

	await _start_trap_level(4, true)
	_runner.ai.enabled = false
	_check(_place("Snap", 200.0), "place snap for airborne escape")
	snap = _level._placed_traps.back()
	await _wait(10)
	_check(_runner.jump(), "runner jumps before snap closes")
	await _wait(90)
	_check(snap.consumed and _runner.lives == 3, "runner can jump over closing snap")

	await _start_trap_level(4, true)
	_runner.ai.enabled = false
	_runner.set_physics_process(false)
	_check(_place("Snap", 300.0), "place snap for standing overlap")
	snap = _level._placed_traps.back()
	_runner.position.x = snap.position.x
	await _wait(10)
	_check(_runner.lives == 3, "standing in open snap is harmless")
	var elapsed_before: float = snap.elapsed
	_level.pause()
	for frame in 20:
		await process_frame
	_check(is_equal_approx(snap.elapsed, elapsed_before), "paused snap countdown stays frozen")
	_level.resume()
	await _capture_trap("snap-waiting")
	for frame in 50:
		if snap.consumed:
			break
		await physics_frame
	_check(_runner.lives == 2, "closing snap detects runner already inside")
	_level.energy = _level.level_data.max_energy
	_check(_place("Snap", 300.0), "place snap while runner is invulnerable")
	snap = _level._placed_traps.back()
	_runner.position.x = snap.position.x
	await _wait(50)
	_check(snap.consumed and _runner.lives == 2, "snap respects invulnerability and still expires")


func _test_magnet_pull() -> void:
	await _start_trap_level(4)
	var magnet_hits: Array[bool] = []
	_runner.magnet_hit.connect(magnet_hits.append.bind(true))
	var lives_before := _runner.lives
	_check(not _runner.pull_from_magnet(0.0, 0.65), "invalid magnet strength rejected")
	_check(_runner.slide(), "slide before magnet pull")
	_check(_runner.pull_from_magnet(240.0, 0.65), "magnet starts pull")
	_check(not _runner.is_sliding(), "magnet ends slide")
	_check(not _runner.pull_from_magnet(240.0, 0.65), "magnet pulls cannot stack")
	_check(not _runner.jump() and not _runner.slide() and not _runner.stop(), "actions cannot override magnetic pull")
	var start_x := _runner.position.x
	await _wait(20)
	_check(_runner.position.x < start_x - 50.0, "magnet moves runner backward")
	var paused_x := _runner.position.x
	_level.pause()
	for frame in 15:
		await process_frame
	_check(_runner.position.x == paused_x and _runner.is_magnet_pulled(), "pause freezes magnetic pull")
	_level.resume()
	await _wait(25)
	_check(not _runner.is_magnet_pulled() and _runner.velocity.x > 0.0, "runner resumes forward motion after pull")
	_check(_runner.lives == lives_before, "magnet alone causes no damage")
	_check(magnet_hits.is_empty(), "pull without damage emits no magnet hit")
	_check(_runner.jump(), "runner can jump after magnet releases")
	await _wait(5)
	var vertical_speed := _runner.velocity.y
	var air_jumps := _runner.get_air_jumps_left()
	_check(_runner.pull_from_magnet(240.0, 0.65), "later pull can start")
	_check(_runner.velocity.y == vertical_speed and _runner.get_air_jumps_left() == air_jumps, "airborne pull preserves vertical motion and air jumps")
	_check(_runner.take_hit(), "runner remains vulnerable during pull")
	_check(magnet_hits.size() == 1, "damage during pull emits one magnet hit")
	_check(not _runner.is_magnet_pulled(), "damage cancels magnetic pull")
	_check(not _runner.pull_from_magnet(240.0, 0.65), "hurt runner rejects pull")
	_check(not _runner.take_hit() and magnet_hits.size() == 1, "ignored damage does not duplicate magnet hit")
	await _wait(100)
	_check(_runner.take_hit() and magnet_hits.size() == 1, "damage after pull does not count as magnet hit")


func _test_magnet_trap() -> void:
	await _start_trap_level(4)
	_check(_place("Magnet", 300.0), "place magnet through card")
	var magnet: Trap = _level._placed_traps.back()
	_check(is_equal_approx(_level.energy, _level.level_data.max_energy - 3.0), "magnet costs three energy")
	await _capture_trap("magnet-ready")
	for frame in 120:
		if magnet.consumed:
			break
		await physics_frame
	_check(magnet.consumed and _runner.is_magnet_pulled(), "magnet activates after runner passes")
	_check(_runner.position.x > magnet.position.x, "magnet is behind runner on activation")
	var start_x := _runner.position.x
	await _wait(15)
	_check(_runner.position.x < start_x, "magnet contact pulls runner back")
	await _capture_trap("magnet-pulling")
	await _wait(100)
	_check(_runner.lives == 3 and _combos.is_empty(), "magnet alone awards no damage or combo")
	_check(_level.magnet_hit_count == 0, "magnet alone does not advance challenge")
	_check(not _runner.is_magnet_pulled() and _runner.velocity.x > 0.0, "single-use magnet cannot trap runner in a loop")

	await _start_trap_level(4)
	_check(_place("Magnet", 300.0), "place magnet for return trap")
	_check(_place("Saw", 300.0), "surface magnet overlaps saw")
	for frame in 180:
		if _runner.lives < 3:
			break
		await physics_frame
	_check(_runner.lives == 2, "magnet pulls runner back into dodged saw")
	_check(_combos == ["chain"], "return hit earns one chain combo")
	_check(_level.magnet_hit_count == 1, "real magnet return hit advances challenge once")
	_check(not _runner.is_magnet_pulled(), "saw hit releases magnetic pull")
	await _capture_trap("magnet-return-hit")


func _test_nearest_traps() -> void:
	for level_index in root.get_node("GameState").LEVELS.size():
		for trap_name: String in ["Pit", "Wall", "Saw"]:
			await _start_trap_level(level_index)
			for card: TrapCard in _level._cards:
				if card.trap_info.display_name == trap_name:
					var nearest_distance: float = _level.MIN_PLACE_AHEAD + card.trap_info.width / 2.0 + 1.0
					await _expect(trap_name, nearest_distance, false, "level %d dodges nearest lone %s" % [level_index + 1, trap_name])
					break


func _test_seesaw() -> void:
	await _start_trap_level(6)
	var seesaw = _level.get_node("Track/Seesaw")
	var seesaw_screen: Vector2 = root.get_canvas_transform() * seesaw.global_position
	_check(root.get_visible_rect().encloses(Rect2(seesaw_screen - Vector2(seesaw.FOOTPRINT / 2.0, 80.0), Vector2(seesaw.FOOTPRINT, 100.0))), "raised seesaw and ramps are fully visible at start of level 7")
	_check(seesaw._beam.position.y == -44.0, "seesaw beam stands above ground rather than blending into it")
	var distance: float = seesaw.position.x - _runner.position.x
	var energy_before: float = _level.energy
	_check(not _place("Pit", distance) and not _place("Spring", distance), "seesaw reserves its footprint from trap placement")
	_check(_level.energy == energy_before and _level.traps_used == 0, "seesaw blocked drops cost no energy or challenge progress")
	await _capture_trap("seesaw-start")
	var captured_ready := false
	for frame in 600:
		if not captured_ready and _runner.position.x >= seesaw.position.x - 180.0:
			captured_ready = true
			await _capture_trap("seesaw-ready")
		if _runner.position.x > seesaw.position.x + 180.0:
			break
		await physics_frame
	_check(_runner.position.x > seesaw.position.x + 180.0 and _runner.lives == 3, "runner crosses seesaw without damage or blocking")
	_check(not seesaw.activated and _combos.is_empty(), "normal crossing neither launches nor awards a combo")
	_check(_level.seesaw_launch_count == 0, "normal crossing does not advance seesaw challenge")

	await _start_trap_level(6)
	seesaw = _level.get_node("Track/Seesaw")
	_runner.position.x = seesaw.position.x - _runner.profile.run_speed * 2.0 * absf(_runner.profile.jump_velocity) / _runner.gravity
	_check(_runner.jump(), "ordinary jump before seesaw")
	await _wait(120)
	_check(not seesaw.activated and _runner.lives == 3, "ordinary jump landing does not activate seesaw")
	_check(_level.seesaw_launch_count == 0, "ordinary jump does not advance seesaw challenge")

	await _start_trap_level(6)
	seesaw = _level.get_node("Track/Seesaw")
	var spring_flight_distance: float = _runner.profile.run_speed * 2.0 * 650.0 / _runner.gravity
	var spring_x: float = seesaw.position.x - spring_flight_distance
	_check(_place("Spring", spring_x - _runner.position.x), "place spring before seesaw")
	for frame in 600:
		if seesaw.activated:
			break
		await physics_frame
	_check(seesaw.activated and _runner.velocity.y < -700.0, "spring landing on seesaw triggers stronger second launch")
	_check(_level.seesaw_launch_count == 1, "real spring-to-seesaw launch advances challenge")
	_check(_runner.lives == 3 and _combos.is_empty(), "seesaw launch is harmless and awards no free combo")
	_check(_runner.get_air_jumps_left() == 1, "seesaw preserves jumper air jump")
	await _capture_trap("seesaw-launch")
	var launch_velocity := _runner.velocity
	seesaw._on_runner_landed(650.0, true)
	_check(_runner.velocity == launch_velocity, "spent seesaw cannot retrigger launch")
	_check(_level.seesaw_launch_count == 1, "spent seesaw does not count twice")
	_level.pause()
	var paused_position := _runner.position
	var paused_tilt: float = seesaw._beam.rotation
	for frame in 15:
		await process_frame
	_check(_runner.position == paused_position and seesaw._beam.rotation == paused_tilt, "pause freezes seesaw and runner")
	_level.resume()
	await _wait(150)
	_check(_runner.is_on_floor() and _runner.lives == 3, "seesaw flight lands safely without looping")
	await _start_trap_level(6)
	_check(not _level.get_node("Track/Seesaw").activated, "new attempt resets seesaw")
	_check(_level.seesaw_launch_count == 0, "new attempt resets seesaw challenge counter")


func _start_trap_level(index := 3, with_snap := false, with_seesaw := true) -> void:
	_level.queue_free()
	await process_frame
	var game_state := root.get_node("GameState")
	game_state.current_level_index = index
	_level = load("res://scenes/level.tscn").instantiate()
	if with_snap or not with_seesaw:
		_level.level_data = game_state.get_level(index).duplicate()
	if not with_seesaw:
		var empty_positions: Array[float] = []
		_level.level_data.seesaw_positions = empty_positions
	if with_snap:
		_level.level_data.available_traps = _level.level_data.available_traps.duplicate()
		_level.level_data.available_traps[3] = load("res://scenes/traps/snap.tscn")
	root.add_child(_level)
	_runner = _level.get_node("Runner")
	_combos.clear()
	_level.combo_landed.connect(_combos.append)
	await _wait(30)
	_make_ai_deterministic()
	_level.energy = _level.level_data.max_energy
	_check(_level._cards.size() == _level.level_data.available_traps.size(), "level offers its configured trap cards")


func _test_fake_finish() -> void:
	await _start_trap_level(8)
	var lives_before := _runner.lives
	_check(_place("Fake finish", 300.0), "place fake finish on level 9")
	var finish: Trap = _level._placed_traps.back()
	var card: TrapCard = _level._cards.back()
	_check(is_equal_approx(_level.energy, _level.level_data.max_energy - 2.0), "fake finish costs two energy")
	_check(card.exhausted and not card.affordable and card._cost_label.text == tr("Used"), "used fake finish card is disabled and labelled")
	var energy_after: float = _level.energy
	_check(not _place("Fake finish", 550.0), "second fake finish is rejected")
	_check(_level.energy == energy_after and _level.traps_used == 1, "rejected fake finish does not spend energy or count")
	await _wait(20)
	await _capture_trap("fake-finish-ready")
	for frame in 120:
		if finish.consumed:
			break
		await physics_frame
	_check(finish.consumed and _runner.is_celebrating(), "physical crossing triggers celebration")
	_check(not _level._game_over and _runner.lives == lives_before and _combos.is_empty(), "fake finish neither ends level nor deals damage or combo")
	await _wait(2)
	_check(is_equal_approx(_runner.velocity.x, _runner.profile.run_speed * Runner.FAKE_FINISH_SLOWDOWN), "celebration slows physical movement")
	await _capture_trap("fake-finish-celebration")
	_level.pause()
	var time_before := _runner._celebration_time_left
	await _wait(10)
	_check(_runner._celebration_time_left == time_before, "pause freezes fake finish celebration")
	_level.resume()
	for frame in 150:
		if not _runner.is_celebrating():
			break
		await physics_frame
	_check(_runner._fake_finish_boost_left > 0.0 and _runner.can_act(), "surviving deception restores dodging with boost")
	_check(is_equal_approx(_runner.velocity.x, _runner.profile.run_speed * Runner.FAKE_FINISH_SPEEDUP), "deceived runner physically speeds up")
	await _capture_trap("fake-finish-angry")
	_level.pause()
	time_before = _runner._fake_finish_boost_left
	await _wait(10)
	_check(_runner._fake_finish_boost_left == time_before, "pause freezes fake finish boost")
	_level.resume()
	await _wait(120)
	_check(is_equal_approx(_runner.velocity.x, _runner.profile.run_speed), "speed returns to normal")
	finish._on_body_entered(_runner)
	_check(not _runner.is_celebrating(), "spent fake finish cannot retrigger")

	await _start_trap_level(8)
	_check(not _level._cards.back().exhausted and not _runner.is_celebrating(), "restart resets card and celebration")
	_check(_place("Fake finish", 300.0), "fresh run allows fake finish again")
	finish = _level._placed_traps.back()
	for frame in 120:
		if finish.consumed:
			break
		await physics_frame
	await _wait(12)
	_level.energy = _level.level_data.max_energy
	_check(_place("Pit", 200.0), "place real pit during celebration")
	for frame in 120:
		if _runner.lives < lives_before:
			break
		await physics_frame
	_check(_runner.lives == lives_before - 1, "celebrating runner hits follow-up pit with AI enabled")
	_check(not _runner.is_celebrating() and not _runner._body.celebrating and _runner._fake_finish_boost_left == 0.0, "damage cancels celebration and pending boost")
	await _wait(120)
	_check(_runner._fake_finish_boost_left == 0.0, "cancelled celebration cannot start delayed boost")
	_runner._invulnerable_time_left = 1.0
	_check(not _runner.celebrate_fake_finish(), "invulnerable runner ignores fake finish")
	_runner._invulnerable_time_left = 0.0
	_check(_runner.jump(), "runner jumps for airborne fake finish check")
	await _wait(2)
	_check(not _runner.celebrate_fake_finish(), "airborne runner ignores fake finish")
	await _wait(120)
	_check(_runner.celebrate_fake_finish(), "grounded runner can start another isolated state test")
	_runner._update_fake_finish(Runner.FAKE_FINISH_CELEBRATION)
	_check(_runner.take_hit() and _runner._fake_finish_boost_left == 0.0, "hit during speed boost cancels boost")
	_runner._invulnerable_time_left = 0.0
	_runner._stun_time_left = 0.0
	_check(_runner.celebrate_fake_finish(), "last-life runner celebrates")
	_check(_runner.take_hit() and _runner.is_down and not _runner._body.celebrating, "knockout cancels celebration and raised arms")
	_check(not _runner.celebrate_fake_finish(), "knocked-out runner cannot celebrate")


func _test_umbrella() -> void:
	await _start_trap_level(10)
	_check(_runner.umbrella_enabled, "level 11 enables last-life umbrella")
	_check(not _runner.is_umbrella_open(), "umbrella stays closed at full health")
	_check(_runner.take_hit(), "first hit for umbrella trial")
	await _wait(100)
	_check(not _runner.is_umbrella_open() and not _runner.umbrella_used, "two lives do not trigger umbrella")
	_check(_runner.take_hit() and _runner.lives == 1, "second hit leaves last life")
	await _wait(30)
	_check(not _runner.is_umbrella_open(), "umbrella waits for damage recovery")
	await _wait(90)
	_check(_runner.is_umbrella_open() and _runner.umbrella_used, "last-life runner opens umbrella once")
	_check(not _runner.is_on_floor() and _runner.position.y < 570.0, "umbrella lifts runner above pits")
	await _capture_trap("umbrella-open")
	_check(not _runner.jump() and not _runner.slide(), "gliding cannot be overridden by evasion")
	_level.energy = _level.level_data.max_energy
	_check(_place("Pit", 170.0), "place pit under gliding runner")
	await _wait(40)
	_check(_runner.lives == 1 and _runner.is_umbrella_open(), "gliding runner crosses pit without losing last life")
	_check(_place("Wall", 180.0), "place wall ahead of gliding runner")
	await _wait(40)
	_check(_runner.lives == 1 and _runner.is_umbrella_open() and _runner.position.y < 530.0, "gliding runner clears wall height without closing umbrella")
	_check(_place("Saw", 200.0), "place saw to close umbrella")
	var saw: Trap = _level._placed_traps.back()
	for frame in 100:
		if saw.consumed:
			break
		await physics_frame
	_check(saw.consumed and not _runner.is_umbrella_open(), "physical saw contact closes umbrella")
	_check(_runner.lives == 1 and not _level._game_over and _combos.is_empty(), "closing umbrella causes no damage or free combo")
	saw._on_body_entered(_runner)
	_check(_runner.lives == 1, "spent saw cannot also damage runner")
	await _capture_trap("umbrella-closed")
	await _wait(60)
	_check(_runner.is_on_floor() and not _runner.is_umbrella_open(), "runner lands without reopening umbrella")
	_runner.ai.enabled = false
	_level.energy = _level.level_data.max_energy
	_check(_place("Wall", 180.0), "place wall after umbrella closes")
	await _wait(50)
	_check(_runner.is_down and not _runner._body.umbrella_open, "wall can defeat runner after umbrella closes")

	await _start_trap_level(10)
	_check(not _runner.umbrella_used and not _runner.is_umbrella_open(), "restart resets umbrella")
	_runner.lives = 1
	await _wait(40)
	_level.pause()
	var position_before := _runner.position
	await _wait(15)
	_check(_runner.is_umbrella_open() and _runner.position == position_before and _runner._body.umbrella_open, "pause preserves umbrella and freezes movement")
	_level.resume()
	await _wait(420)
	_check(_runner.is_umbrella_open() and _runner._body.umbrella_open and not _runner.is_on_floor(), "umbrella stays open beyond twice the old timeout")
	_check(_runner.lives == 1 and not _level._game_over and _runner.umbrella_used, "uninterrupted gliding preserves last life")

	await _start_trap_level(10)
	_runner.lives = 1
	await _wait(40)
	_check(_place("Saw", 300.0), "place saw for umbrella counterattack")
	saw = _level._placed_traps.back()
	_check(_place("Pit", 450.0), "place pit after umbrella-closing saw")
	for frame in 150:
		if _runner.is_down:
			break
		await physics_frame
	_check(saw.consumed and _runner.is_down and _level._game_over, "saw then landing pit defeats glider with AI enabled")
	_check(_level._end_stars.filled > 0 and not _level._next_button.visible, "level 11 win grants stars and has no next button")
	await _capture_trap("umbrella-counterattack")

	await _start_trap_level(10)
	_runner.lives = 1
	await _wait(2)
	_check(_runner.is_umbrella_open(), "umbrella opens before ascent completes")
	_check(_place("Wall", 140.0), "place nearest wall during umbrella ascent")
	await _wait(40)
	_check(_runner.lives == 1 and _runner.is_umbrella_open(), "wall cannot break umbrella during ascent")
	_check(not _runner.take_hit() and not _runner.is_down and _runner.is_umbrella_open(), "ordinary damage cannot close umbrella")

	await _start_trap_level(10)
	_runner.ai.enabled = false
	await _expect("Saw", 200.0, true, "raised saw still damages grounded runner without umbrella")

	root.get_node("GameState").continue_run = true
	await _start_trap_level(10)
	_check(_runner.lives == 2 and not _runner.umbrella_used, "ad replay starts with two lives and unused umbrella")
	_check(_runner.take_hit(), "ad replay reaches last life")
	await _wait(120)
	_check(_runner.is_umbrella_open(), "ad replay can trigger its own umbrella")
	_runner.position.x = _level.level_data.track_length + 10.0
	await _wait(2)
	_check(_level._game_over and not _runner.is_umbrella_open() and not _runner._body.umbrella_open, "real finish cancels umbrella and ends level")


func _test_wall_revenge() -> void:
	await _start_trap_level(9)
	_level.set_physics_process(false)
	_check(_place("Wall", 300.0), "place first wall for revenge")
	var wall: Trap = _level._placed_traps.back()
	var energy_after: float = _level.energy
	_check(wall.consumed and _level._revenge_pending, "first wall is reserved from damage and AI")
	for frame in 100:
		_level._update_wall_revenge()
		if _level._revenge_target.active:
			break
		await physics_frame
	_check(_level._revenge_target.active and not wall.visible, "runner uproots first nearby wall")
	_check(_runner.lives == 3 and not _level._game_over and _combos.is_empty(), "throw is harmless and awards no combo")
	_check(_runner._body.throw_time_left > 0.0, "runner shows throwing gesture")
	await _wait(30)
	await _capture_trap("wall-revenge-airborne")
	_level.pause()
	var elapsed_before: float = _level._revenge_target.elapsed
	await _wait(10)
	_check(_level._revenge_target.elapsed == elapsed_before, "pause freezes thrown wall catch window")
	_level.resume()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(20.0, 180.0)
	root.push_input(touch, true)
	await process_frame
	_check(_level._revenge_target.active, "touch outside thrown wall does not catch it")
	touch.pressed = false
	root.push_input(touch, true)
	touch.pressed = true
	touch.position = _level._revenge_target.get_global_rect().get_center()
	root.push_input(touch, true)
	await process_frame
	touch.pressed = false
	root.push_input(touch, true)
	_check(not _level._revenge_target.active and wall.visible and not wall.consumed, "viewport touch sends wall back into track")
	_check(_level.energy == energy_after and _level.traps_used == 1, "returned wall costs no extra energy or placement")
	await _wait(8)
	_level.pause()
	var return_position := wall.position
	await _wait(10)
	_check(wall.position == return_position, "pause freezes returning wall")
	_level.resume()
	await _capture_trap("wall-revenge-return")
	await _wait(50)
	_check(_runner.lives == 2, "returned falling wall physically hits runner")
	_check(wall.consumed and _combos.is_empty(), "returned wall hits once without free combo")
	_check(_place("Wall", 300.0), "later wall can be placed normally")
	_check(not _level._placed_traps.back().consumed and not _level._revenge_pending, "second wall is ordinary")

	await _start_trap_level(9)
	_level.set_physics_process(false)
	_check(not _level._revenge_used, "restart resets wall revenge opportunity")
	_check(_place("Wall", 300.0), "new run offers revenge again")
	wall = _level._placed_traps.back()
	energy_after = _level.energy
	for frame in 100:
		_level._update_wall_revenge()
		if _level._revenge_target.active:
			break
		await physics_frame
	_level._revenge_target._process(_level._revenge_target.CATCH_DURATION)
	_check(not _level._revenge_target.active and not wall.visible and wall.consumed, "missed wall disappears")
	_check(_runner.lives == 3 and _level.energy == energy_after and _level.traps_used == 1, "missing adds no health or energy penalty")
	_check(_place("Wall", 300.0) and not _level._revenge_pending, "missing cannot grant another revenge attempt")

	await _start_trap_level(9)
	_check(_place("Wall", 180.0), "place wall with normal level processing")
	wall = _level._placed_traps.back()
	for frame in 100:
		if _level._revenge_target.active:
			break
		await physics_frame
	_check(_level._revenge_target.active, "normal gameplay launches revenge without test driving")
	_level._end_game(false)
	_check(not _level._revenge_target.active and not _level._revenge_target.visible, "level end cancels catch target")
	_level._return_revenge_wall()
	_check(not wall.visible, "late return cannot attack after level end")

	await _start_trap_level(9)
	_check(_place("Wall", 180.0), "place wall before cancelled return")
	wall = _level._placed_traps.back()
	for frame in 100:
		if _level._revenge_target.active:
			break
		await physics_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _level._revenge_target.get_global_rect().get_center()
	root.push_input(click, true)
	await process_frame
	click.pressed = false
	root.push_input(click, true)
	_check(not _level._revenge_target.active and wall.visible, "mouse click also returns revenge wall")
	_level._end_game(false)
	return_position = wall.position
	await _wait(50)
	_check(wall.position == return_position and wall.consumed and _runner.lives == 3, "level end cancels return movement and damage")

	root.get_node("GameState").continue_run = true
	await _start_trap_level(9)
	_check(_runner.lives == 2 and not _level._revenge_used and not _level._revenge_target.active, "ad replay starts a fresh revenge opportunity")


func _test_wall_revenge_target() -> void:
	var target = load("res://scripts/ui/wall_revenge.gd").new()
	_level.get_node("HUD").add_child(target)
	var returns: Array[bool] = []
	var misses: Array[bool] = []
	target.returned.connect(func(): returns.append(true))
	target.missed.connect(func(): misses.append(true))
	target.launch(Vector2(200.0, 350.0))
	_check(target.active and target.visible, "revenge target opens catch window")
	target._process(0.4)
	_check(root.get_visible_rect().encloses(target.get_global_rect()), "revenge target stays inside viewport")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = target.size / 2.0
	target._gui_input(touch)
	_check(returns.size() == 1 and not target.active and not target.visible, "touch returns wall once")
	target._gui_input(touch)
	_check(returns.size() == 1, "duplicate touch cannot return wall twice")
	target.launch(Vector2(200.0, 350.0))
	target._process(target.CATCH_DURATION)
	_check(misses.size() == 1 and not target.active, "untouched revenge wall expires")
	target._gui_input(touch)
	_check(returns.size() == 1, "late touch cannot recover missed wall")
	target.launch(Vector2(200.0, 350.0))
	root.get_tree().paused = true
	target._gui_input(touch)
	_check(target.active and returns.size() == 1, "paused revenge target rejects touch")
	root.get_tree().paused = false
	var drag_card: TrapCard = _level._cards[0]
	drag_card.force_drag(drag_card, Control.new())
	_check(root.gui_is_dragging() and target.mouse_filter == Control.MOUSE_FILTER_IGNORE, "card drag passes through revenge target")
	target._gui_input(touch)
	_check(target.active and returns.size() == 1, "card drag cannot catch revenge wall")
	root.gui_cancel_drag()
	_check(target.mouse_filter == Control.MOUSE_FILTER_STOP, "target accepts touches again after card drag")
	target.cancel()
	_check(not target.active and returns.size() == 1 and misses.size() == 1, "cancel clears target without return or penalty")
	target.queue_free()
	await process_frame


func _wait_for_spring(spring: Trap) -> void:
	for frame in 180:
		if spring.consumed:
			break
		await physics_frame
	_check(spring.consumed, "ground contact activates spring once")
	_check(_runner.velocity.y < 0.0, "spring contact launches runner upward")


func _capture_trap(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(not image.is_empty(), "trap screenshot renders")
	if label == "umbrella-open":
		var screen_position: Vector2 = root.get_canvas_transform() * _runner.global_position
		var canopy := Rect2(screen_position + Vector2(-46.0, -128.0), Vector2(102.0, 46.0))
		_check(root.get_visible_rect().encloses(canopy), "umbrella canopy stays inside viewport")
		var image_scale := Vector2(image.get_size()) / root.get_visible_rect().size
		var top_left := canopy.position * image_scale
		var bottom_right := canopy.end * image_scale
		var teal_pixels := 0
		var yellow_pixels := 0
		for pixel_y in range(maxi(0, int(top_left.y)), mini(image.get_height(), int(bottom_right.y))):
			for pixel_x in range(maxi(0, int(top_left.x)), mini(image.get_width(), int(bottom_right.x))):
				var pixel := image.get_pixel(pixel_x, pixel_y)
				if pixel.is_equal_approx(Color("26a69a")):
					teal_pixels += 1
				if pixel.is_equal_approx(Color("ffca28")):
					yellow_pixels += 1
		_check(teal_pixels > 100 and yellow_pixels > 100, "both umbrella canopy panels visibly render")
	if label == "wall-revenge-airborne":
		var target: Control = _level._revenge_target
		var target_rect := target.get_global_rect()
		_check(root.get_visible_rect().encloses(target_rect), "thrown wall target fits viewport")
		_check(not target_rect.intersects(_level._card_bar.get_global_rect()), "thrown wall does not overlap cards")
		_check(not target_rect.intersects(_level._pause_button.get_global_rect()), "thrown wall does not overlap pause")
		var image_scale := Vector2(image.get_size()) / root.get_visible_rect().size
		var top_left := target_rect.position * image_scale
		var bottom_right := target_rect.end * image_scale
		var brick_pixels := 0
		var ring_pixels := 0
		for pixel_y in range(maxi(0, int(top_left.y)), mini(image.get_height(), int(bottom_right.y))):
			for pixel_x in range(maxi(0, int(top_left.x)), mini(image.get_width(), int(bottom_right.x))):
				var pixel := image.get_pixel(pixel_x, pixel_y)
				if pixel.is_equal_approx(Color("b76b50")):
					brick_pixels += 1
				if pixel.is_equal_approx(Color("ffca28")):
					ring_pixels += 1
		_check(brick_pixels > 100 and ring_pixels > 50, "revenge brick and countdown ring visibly render")
	if label == "fake-finish-ready":
		var finish: Trap = _level._placed_traps.back()
		var screen_position: Vector2 = root.get_canvas_transform() * finish.global_position
		var image_scale := Vector2(image.get_size()) / root.get_visible_rect().size
		var top_left := (screen_position + Vector2(-50.0, -126.0)) * image_scale
		var bottom_right := (screen_position + Vector2(50.0, -102.0)) * image_scale
		var dark_pixels := 0
		var light_pixels := 0
		for pixel_y in range(maxi(0, int(top_left.y)), mini(image.get_height(), int(bottom_right.y))):
			for pixel_x in range(maxi(0, int(top_left.x)), mini(image.get_width(), int(bottom_right.x))):
				var pixel := image.get_pixel(pixel_x, pixel_y)
				if pixel.is_equal_approx(Color("263238")):
					dark_pixels += 1
				if pixel.is_equal_approx(Color.WHITE):
					light_pixels += 1
		_check(dark_pixels > 100 and light_pixels > 100, "fake finish checkered banner visibly renders")
		for card: TrapCard in _level._cards:
			for text_label: Node in card.find_children("*", "Label", true, false):
				_check(card.get_global_rect().encloses(text_label.get_global_rect()), "fake finish trial card text fits")
	if label == "seesaw-start":
		var seesaw = _level.get_node("Track/Seesaw")
		var screen_position: Vector2 = root.get_canvas_transform() * seesaw.global_position
		var image_scale := Vector2(image.get_size()) / root.get_visible_rect().size
		var top_left := (screen_position + Vector2(-seesaw.WIDTH / 2.0, -80.0)) * image_scale
		var bottom_right := (screen_position + Vector2(seesaw.WIDTH / 2.0, -8.0)) * image_scale
		var beam_pixels := 0
		var support_pixels := 0
		for pixel_y in range(maxi(0, int(top_left.y)), mini(image.get_height(), int(bottom_right.y))):
			for pixel_x in range(maxi(0, int(top_left.x)), mini(image.get_width(), int(bottom_right.x))):
				var pixel := image.get_pixel(pixel_x, pixel_y)
				if pixel.is_equal_approx(Color("efb45b")):
					beam_pixels += 1
				if pixel.is_equal_approx(Color("26a69a")):
					support_pixels += 1
		_check(beam_pixels > 100 and support_pixels > 100, "seesaw beam and support visibly render above ground (%d/%d pixels)" % [beam_pixels, support_pixels])
	for card: TrapCard in _level._cards:
		_check(root.get_visible_rect().encloses(card.get_global_rect()), "trial card stays inside viewport")
	_check(image.save_png("/tmp/runner-trap-%dx%d-%s.png" % [image.get_width(), image.get_height(), label]) == OK, "trap screenshot saved")


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
