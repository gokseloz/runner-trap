class_name RunnerProfile
extends Resource
## Tunable runner parameters. One .tres per runner type.

@export var display_name := "Runner"
@export var run_speed := 300.0
@export var jump_velocity := -600.0
@export var max_jumps := 1
@export var can_wall_climb := false
@export var lives := 3
@export var color := Color("4fc3f7")

@export_group("AI")
## How far ahead (px) the runner notices traps.
@export var vision_range := 600.0
## Seconds between spotting a trap and being able to react.
@export var reaction_time := 0.55
## Random +/- seconds added to each reaction.
@export var reaction_jitter := 0.1
## Random +/- px error on where the counter action starts.
@export var timing_error := 20.0
## Chance to completely ignore a spotted trap.
@export_range(0.0, 1.0) var mistake_chance := 0.05
## Fraction reaction_time shrinks each time the same trap type is seen again.
@export_range(0.0, 1.0) var learning_rate := 0.1
## Learning never pushes reaction below this.
@export var min_reaction_time := 0.15
