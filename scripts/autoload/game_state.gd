extends Node
## Global game state. Persists progress to user://save.cfg.

const SAVE_PATH := "user://save.cfg"

## level_id -> best star count (0-3)
var level_stars: Dictionary = {}
var ads_removed := false


func _ready() -> void:
	load_game()


func set_level_stars(level_id: String, stars: int) -> void:
	if stars > level_stars.get(level_id, 0):
		level_stars[level_id] = stars
		save_game()


func get_level_stars(level_id: String) -> int:
	return level_stars.get(level_id, 0)


func save_game() -> void:
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
