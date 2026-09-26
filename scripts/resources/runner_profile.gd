class_name RunnerProfile
extends Resource
## Tunable runner parameters. One .tres per runner type.

@export var display_name := "Runner"
@export var run_speed := 300.0
@export var jump_velocity := -600.0
@export var max_jumps := 1
## Seconds between seeing a trap and reacting.
@export var reaction_time := 0.35
## How much reaction_time shrinks each time the same trap type is seen again.
@export_range(0.0, 1.0) var learning_rate := 0.1
@export var can_wall_climb := false
@export var lives := 3
@export var color := Color("4fc3f7")
