class_name LevelData
extends Resource
## Level definition. Add a level by creating a new .tres and listing it in GameState.LEVELS.

enum Challenge { NONE, MAX_TRAPS, MIN_COMBOS, SINGLE_TYPE, MIN_SPRING_COMBOS, MIN_MAGNET_HITS, MIN_TRAP_TYPES }

@export var challenge := Challenge.NONE
@export var challenge_target := 0
@export var level_id := "level_01"
@export var display_name := "Level 1"
@export var track_length := 5000.0
@export var runner: RunnerProfile
## Trap scenes offered as cards in this level.
@export var available_traps: Array[PackedScene] = []
@export var max_energy := 10.0
@export var energy_regen_per_sec := 1.0
@export var starting_energy := 5.0
@export var seesaw_positions: Array[float] = []
## Share of the track still ahead of the runner at knockout needed for 2 and 3 stars.
@export_range(0.0, 1.0) var two_star_threshold := 0.25
@export_range(0.0, 1.0) var three_star_threshold := 0.5


func is_challenge_completed(won: bool, traps_used: int, combos: int, trap_types: int, continued := false, spring_combos := 0, magnet_hits := 0) -> bool:
	if not won or continued or traps_used <= 0:
		return false
	match challenge:
		Challenge.MAX_TRAPS:
			return traps_used <= challenge_target
		Challenge.MIN_COMBOS:
			return combos >= challenge_target
		Challenge.SINGLE_TYPE:
			return trap_types == 1
		Challenge.MIN_SPRING_COMBOS:
			return spring_combos >= challenge_target
		Challenge.MIN_MAGNET_HITS:
			return magnet_hits >= challenge_target
		Challenge.MIN_TRAP_TYPES:
			return trap_types >= challenge_target
	return false


func get_challenge_name() -> String:
	match challenge:
		Challenge.MAX_TRAPS:
			return tr("Efficient trapper")
		Challenge.MIN_COMBOS:
			return tr("Combo master")
		Challenge.SINGLE_TYPE:
			return tr("One weapon")
		Challenge.MIN_SPRING_COMBOS:
			return tr("Spring master")
		Challenge.MIN_MAGNET_HITS:
			return tr("Magnet master")
		Challenge.MIN_TRAP_TYPES:
			return tr("Full arsenal")
	return ""


func get_challenge_description() -> String:
	match challenge:
		Challenge.MAX_TRAPS:
			return tr("Win with at most %d traps") % challenge_target
		Challenge.MIN_COMBOS:
			return tr("Win with at least %d combos") % challenge_target
		Challenge.SINGLE_TYPE:
			return tr("Win using only one trap type")
		Challenge.MIN_SPRING_COMBOS:
			return tr("Win with at least %d spring combos") % challenge_target
		Challenge.MIN_MAGNET_HITS:
			return tr("Win with at least %d hits during a magnet pull") % challenge_target
		Challenge.MIN_TRAP_TYPES:
			return tr("Win using at least %d trap types") % challenge_target
	return ""


func get_challenge_progress(traps_used: int, combos: int, trap_types: int, spring_combos := 0, magnet_hits := 0) -> String:
	match challenge:
		Challenge.MAX_TRAPS:
			return tr("Traps: %d/%d") % [traps_used, challenge_target]
		Challenge.MIN_COMBOS:
			return tr("Combos: %d/%d") % [combos, challenge_target]
		Challenge.SINGLE_TYPE:
			return tr("Trap types: %d/1") % trap_types
		Challenge.MIN_SPRING_COMBOS:
			return tr("Spring combos: %d/%d") % [spring_combos, challenge_target]
		Challenge.MIN_MAGNET_HITS:
			return tr("Magnet hits: %d/%d") % [magnet_hits, challenge_target]
		Challenge.MIN_TRAP_TYPES:
			return tr("Trap types: %d/%d") % [trap_types, challenge_target]
	return ""


func get_stars(remaining_ratio: float) -> int:
	if remaining_ratio >= three_star_threshold:
		return 3
	if remaining_ratio >= two_star_threshold:
		return 2
	return 1
