extends Node
## Global game state. Persists progress to user://save.cfg.

const SAVE_PATH := "user://save.cfg"
const LEVELS: Array[String] = [
	"res://resources/levels/level_01.tres",
	"res://resources/levels/level_02.tres",
	"res://resources/levels/level_03.tres",
]

var current_level_index := 0
## level_id -> best star count (0-3)
var level_stars: Dictionary = {}
var ads_removed := false
## Tests turn this off so they don't touch the real save file.
var persist := true


func _ready() -> void:
	load_game()


func get_current_level() -> LevelData:
	return load(LEVELS[current_level_index])


func has_next_level() -> bool:
	return current_level_index + 1 < LEVELS.size()


func set_level_stars(level_id: String, stars: int) -> void:
	if stars > level_stars.get(level_id, 0):
		level_stars[level_id] = stars
		save_game()


func get_level_stars(level_id: String) -> int:
	return level_stars.get(level_id, 0)


func save_game() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for level_id in level_stars:
		cfg.set_value("stars", level_id, level_stars[level_id])
	cfg.set_value("shop", "ads_removed", ads_removed)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if cfg.has_section("stars"):
		for level_id in cfg.get_section_keys("stars"):
			level_stars[level_id] = cfg.get_value("stars", level_id, 0)
	ads_removed = cfg.get_value("shop", "ads_removed", false)
