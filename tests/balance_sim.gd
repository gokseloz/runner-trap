extends SceneTree
## Balance report, not a pass/fail test. Bot players with different skill play every level:
## godot --headless --fixed-fps 60 -s res://tests/balance_sim.gd -- [runs=20] [levels=1,2,...]

const SKILLS := {
	# Drop distance range ahead of the runner and pause between drops, in seconds.
	"casual": {"min_distance": 200.0, "max_distance": 500.0, "min_pause": 0.6, "max_pause": 1.6},
	"good": {"min_distance": 140.0, "max_distance": 320.0, "min_pause": 0.3, "max_pause": 0.9},
}
const MAX_FRAMES := 60 * 90

var _game_state: Node
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_run()


func _run() -> void:
	var args := _parse_args()
	var runs: int = args.get("runs", 20)
	var levels: Array = args.get("levels", range(_game_state.LEVELS.size()))
	print("level   runner        skill   win%  stars  lives_left  traps")
	for index: int in levels:
		for skill: String in SKILLS:
			var wins := 0
			var stars := 0
			var lives_left := 0
			var traps := 0
			for i in runs:
				_rng.seed = i * 7919 + index
				var result: Dictionary = await _play(index, SKILLS[skill], i)
				wins += 1 if result.won else 0
				stars += result.stars
				lives_left += result.lives
				traps += result.traps
			var level: LevelData = _game_state.get_level(index)
			print("%-7s %-13s %-7s %4d%%  %5.2f  %10.2f  %5.1f" % [
				str(index + 1), level.runner.display_name, skill, 100 * wins / runs,
				float(stars) / runs, float(lives_left) / runs, float(traps) / runs])
	quit()


func _play(index: int, skill: Dictionary, seed: int) -> Dictionary:
	_game_state.current_level_index = index
	var level: Node = load("res://scenes/level.tscn").instantiate()
	root.add_child(level)
	var runner: Runner = level.get_node("Runner")
	await physics_frame
	runner.ai.rng.seed = seed
	var pause := _rng.randf_range(skill.min_pause, skill.max_pause)
	for frame in MAX_FRAMES:
		await physics_frame
		if level._game_over:
			break
		pause -= 1.0 / 60.0
		if pause <= 0.0 and _try_drop(level, runner, skill):
			pause = _rng.randf_range(skill.min_pause, skill.max_pause)
	var result := {
		"won": runner.is_down,
		"stars": level._end_stars.filled,
		"lives": runner.lives,
		"traps": level._placed_traps.size(),
	}
	level.queue_free()
	await process_frame
	return result


## Drops a random affordable card at a random distance, like an impatient human.
func _try_drop(level: Node, runner: Runner, skill: Dictionary) -> bool:
	# Wait until the blinking stops, a hit now would be wasted.
	if runner._invulnerable_time_left > 0.2:
		return false
	var affordable: Array[TrapCard] = []
	for card: TrapCard in level._cards:
		if level.energy >= card.trap_info.energy_cost:
			affordable.append(card)
	if affordable.is_empty():
		return false
	var card: TrapCard = affordable[_rng.randi() % affordable.size()]
	var distance := _rng.randf_range(skill.min_distance, skill.max_distance)
	var screen_pos: Vector2 = root.get_canvas_transform() * Vector2(runner.position.x + distance, 600.0)
	return level.place_card(card, screen_pos)


func _parse_args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=")
		if parts.size() != 2:
			continue
		match parts[0]:
			"runs":
				result.runs = int(parts[1])
			"levels":
				result.levels = Array(parts[1].split(",")).map(func(s: String) -> int: return int(s) - 1)
	return result
