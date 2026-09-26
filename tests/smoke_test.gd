extends SceneTree
## Headless smoke test: godot --headless -s res://tests/smoke_test.gd

var _level: Node
var _runner: Runner
var _frame := 0
var _failures := 0


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
			_runner.jump()
		70:
			_check(not _runner.is_on_floor(), "runner is airborne after jump")
		150:
			_check(_runner.is_on_floor(), "runner lands after jump")
			_runner.slide()
			_check(_runner.is_sliding(), "runner slides")
		200:
			_runner.take_hit()
			_check(_runner.lives == 2, "hit removes a life")
			_runner.take_hit()
			_check(_runner.lives == 2, "invulnerable right after hit")
		320:
			_runner.take_hit()
			_runner._invulnerable_time_left = 0.0
			_runner.take_hit()
			_check(_runner.is_down, "runner knocked out after 3 hits")
		330:
			print("DONE: %d failure(s)" % _failures)
			return true
	return false


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
