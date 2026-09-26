class_name Trap
extends Area2D
## Base class for all traps. Origin sits on the ground surface, centered horizontally.
## Subclasses override _on_runner_hit() for custom effects.

signal runner_hit(trap: Trap)

## Identifier used by the runner's learning system.
@export var trap_type := "trap"
@export var display_name := "Trap"
@export var energy_cost := 2.0
## What the runner AI should do to avoid this trap: "jump", "slide", "stop".
@export var counter_action := "jump"
## Horizontal footprint on the track, used for placement and the drag ghost.
@export var width := 80.0
@export var card_color := Color.WHITE
## Disable the trap after it lands a hit.
@export var one_shot := true

var consumed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if consumed or not body is Runner:
		return
	if not _on_runner_hit(body):
		return
	runner_hit.emit(self)
	if one_shot:
		_consume()


## Returns true if the trap actually hurt the runner.
func _on_runner_hit(runner: Runner) -> bool:
	return runner.take_hit()


func _consume() -> void:
	consumed = true
	set_deferred("monitoring", false)
	create_tween().tween_property(self, "modulate:a", 0.35, 0.3)
