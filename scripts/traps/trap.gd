class_name Trap
extends Area2D
## Base class for all traps. Subclasses override _on_runner_hit().

signal runner_hit(trap: Trap)

## Identifier used by the runner's learning system.
@export var trap_type := "trap"
@export var energy_cost := 2.0
## What the runner AI should do to avoid this trap: "jump", "slide", "stop".
@export var counter_action := "jump"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("runner"):
		_on_runner_hit(body)
		runner_hit.emit(self)


func _on_runner_hit(_runner: Node2D) -> void:
	pass
