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
	for level_index in 10:
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

	await _start_trap_level(6)
	seesaw = _level.get_node("Track/Seesaw")
	_runner.position.x = seesaw.position.x - _runner.profile.run_speed * 2.0 * absf(_runner.profile.jump_velocity) / _runner.gravity
	_check(_runner.jump(), "ordinary jump before seesaw")
	await _wait(120)
	_check(not seesaw.activated and _runner.lives == 3, "ordinary jump landing does not activate seesaw")

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
	_check(_runner.lives == 3 and _combos.is_empty(), "seesaw launch is harmless and awards no free combo")
	_check(_runner.get_air_jumps_left() == 1, "seesaw preserves jumper air jump")
	await _capture_trap("seesaw-launch")
	var launch_velocity := _runner.velocity
	seesaw._on_runner_landed(650.0, true)
	_check(_runner.velocity == launch_velocity, "spent seesaw cannot retrigger launch")
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
