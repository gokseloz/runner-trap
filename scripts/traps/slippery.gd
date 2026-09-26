extends Trap
## Surface trap: speeds the runner up, so it covers more ground during its reaction time
## and reacts too late to the next trap. Doesn't hurt on its own.

@export var speed_boost := 1.7


func _ready() -> void:
	super()
	body_exited.connect(_on_body_exited)


func _on_runner_hit(runner: Runner) -> bool:
	runner.speed_multiplier = speed_boost
	return false


func _on_body_exited(body: Node2D) -> void:
	if body is Runner:
		body.speed_multiplier = 1.0
