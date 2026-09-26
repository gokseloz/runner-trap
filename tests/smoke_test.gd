extends SceneTree
## Headless smoke test: godot --headless -s res://tests/smoke_test.gd

var _level: Node
var _runner: Runner
var _frame := 0
var _failures := 0
var _pit_x := 0.0


func _initialize() -> void:
	_level = load("res://scenes/level.tscn").instantiate()
	root.add_child(_level)
	_runner = _level.get_node("Runner")


func _physics_process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		60:
			_check(_runner.is_on_floor(), "runner lands on ground")
			_check(_runner.position.x > 150.0, "runner moves right (x=%.0f)" % _runner.position.x)
			_test_placement()
		150:
			_check(_runner.lives == 2, "pit hits runner (lives=%d)" % _runner.lives)
			_check(_level._placed_traps[0].consumed, "pit consumed after hit")
		240:
			_runner.jump()
		250:
			_check(not _runner.is_on_floor(), "runner is airborne after jump")
		330:
			_check(_runner.is_on_floor(), "runner lands after jump")
			_runner.slide()
			_check(_runner.is_sliding(), "runner slides")
		380:
			_check(_runner.take_hit(), "hit lands")
			_check(_runner.lives == 1, "hit removes a life")
			_check(not _runner.take_hit(), "invulnerable right after hit")
		500:
			_check(_runner.take_hit(), "final hit lands")
			_check(_runner.is_down, "runner knocked out after 3 hits")
			_check(_level._game_over, "game over after knockout")
		510:
			print("DONE: %d failure(s)" % _failures)
			return true
	return false


func _test_placement() -> void:
	var card: TrapCard = _level._cards[0]
	var cost := card.trap_info.energy_cost
	var energy_before: float = _level.energy

	_check(not _level.place_card(card, _world_to_screen(_runner.position.x - 100.0)), "can't place behind runner")
	_check(not _level.place_card(card, _world_to_screen(_runner.position.x + 50.0)), "can't place under runner")

	_pit_x = _runner.position.x + 300.0
	_check(_level.place_card(card, _world_to_screen(_pit_x)), "place pit ahead of runner")
	_check(is_equal_approx(_level.energy, energy_before - cost), "energy spent (%.1f -> %.1f)" % [energy_before, _level.energy])
	_check(not _level.place_card(card, _world_to_screen(_pit_x + 30.0)), "can't overlap existing trap")

	_level.energy = 0.0
	_check(not _level.place_card(card, _world_to_screen(_pit_x + 400.0)), "can't place without energy")
	_level.energy = energy_before - cost


func _world_to_screen(world_x: float) -> Vector2:
	return root.get_canvas_transform() * Vector2(world_x, 600.0)


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
