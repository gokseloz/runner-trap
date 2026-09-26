class_name LevelData
extends Resource
## Level definition. Add a level by creating a new .tres and listing it in GameState.LEVELS.

@export var level_id := "level_01"
@export var display_name := "Level 1"
@export var track_length := 5000.0
@export var runner: RunnerProfile
## Trap scenes offered as cards in this level.
@export var available_traps: Array[PackedScene] = []
@export var max_energy := 10.0
@export var energy_regen_per_sec := 1.0
@export var starting_energy := 5.0
## Share of the track still ahead of the runner at knockout needed for 2 and 3 stars.
@export_range(0.0, 1.0) var two_star_threshold := 0.25
@export_range(0.0, 1.0) var three_star_threshold := 0.5


func get_stars(remaining_ratio: float) -> int:
	if remaining_ratio >= three_star_threshold:
		return 3
	if remaining_ratio >= two_star_threshold:
		return 2
	return 1
