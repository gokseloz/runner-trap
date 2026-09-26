class_name LevelData
extends Resource
## Level definition. Add a level by creating a new .tres, no code needed.

@export var level_id := "level_01"
@export var track_length := 5000.0
@export var runner: RunnerProfile
## Trap scenes offered as cards in this level.
@export var available_traps: Array[PackedScene] = []
@export var max_energy := 10.0
@export var energy_regen_per_sec := 1.0
@export var starting_energy := 5.0
## Remaining-energy ratio thresholds for 2 and 3 stars.
@export var two_star_threshold := 0.3
@export var three_star_threshold := 0.6
