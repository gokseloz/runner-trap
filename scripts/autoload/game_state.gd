extends Node
## Global game state. Persists progress to user://save.cfg.

const SAVE_PATH := "user://save.cfg"
const LEVELS: Array[String] = [
	"res://resources/levels/level_01.tres",
	"res://resources/levels/level_02.tres",
	"res://resources/levels/level_03.tres",
	"res://resources/levels/level_04.tres",
	"res://resources/levels/level_05.tres",
	"res://resources/levels/level_06.tres",
	"res://resources/levels/level_07.tres",
	"res://resources/levels/level_08.tres",
	"res://resources/levels/level_09.tres",
	"res://resources/levels/level_10.tres",
	"res://resources/levels/level_11.tres",
]
const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"
## Supported locales -> name shown on the language button (in that language).
const LANGUAGES := {"en": "English", "tr": "Türkçe"}
const FALLBACK_LANGUAGE := "en"

var current_level_index := 0
## level_id -> best star count (0-3)
var level_stars: Dictionary = {}
var challenge_badges: Dictionary = {}
var ads_removed := false
## Chosen locale, empty until the player picks one (then the system language is used).
var language := ""
var sound_enabled := true
## Set before reloading a lost level after a rewarded ad: the runner starts with
## one life less, and that run can't be continued again.
var continue_run := false
## Tests turn this off so they don't touch the real save file.
var persist := true


func _ready() -> void:
	load_game()
	TranslationServer.set_locale(language if not language.is_empty() else _system_language())
	_apply_sound()


func get_current_level() -> LevelData:
	return get_level(current_level_index)


func get_level(index: int) -> LevelData:
	return load(LEVELS[index])


## A level opens once the one before it has at least one star.
func is_level_unlocked(index: int) -> bool:
	return index == 0 or get_level_stars(get_level(index - 1).level_id) > 0


func play_level(index: int) -> void:
	current_level_index = index
	get_tree().change_scene_to_file(LEVEL_SCENE)


func open_level_select() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func get_language() -> String:
	return TranslationServer.get_locale()


func get_next_language() -> String:
	var codes: Array = LANGUAGES.keys()
	return codes[(codes.find(get_language()) + 1) % codes.size()]


func set_language(code: String) -> void:
	language = code
	TranslationServer.set_locale(code)
	save_game()


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound()
	save_game()


func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)


## OS locale reduced to a supported language code, e.g. "tr_TR" -> "tr".
func _system_language() -> String:
	var code := OS.get_locale_language()
	return code if LANGUAGES.has(code) else FALLBACK_LANGUAGE


func has_next_level() -> bool:
	return current_level_index + 1 < LEVELS.size()


func set_level_stars(level_id: String, stars: int) -> void:
	if stars > level_stars.get(level_id, 0):
		level_stars[level_id] = stars
		save_game()


func get_level_stars(level_id: String) -> int:
	return level_stars.get(level_id, 0)


func has_challenge_badge(level_id: String) -> bool:
	return challenge_badges.get(level_id, false)


func award_challenge_badge(level_id: String) -> void:
	if has_challenge_badge(level_id):
		return
	challenge_badges[level_id] = true
	save_game()


func save_game(save_path := SAVE_PATH) -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for level_id in level_stars:
		cfg.set_value("stars", level_id, level_stars[level_id])
	for level_id in challenge_badges:
		cfg.set_value("challenges", level_id, challenge_badges[level_id])
	cfg.set_value("shop", "ads_removed", ads_removed)
	cfg.set_value("settings", "language", language)
	cfg.set_value("settings", "sound", sound_enabled)
	cfg.save(save_path)


func load_game(save_path := SAVE_PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	if cfg.has_section("stars"):
		for level_id in cfg.get_section_keys("stars"):
			level_stars[level_id] = cfg.get_value("stars", level_id, 0)
	challenge_badges.clear()
	if cfg.has_section("challenges"):
		for level_id in cfg.get_section_keys("challenges"):
			challenge_badges[level_id] = cfg.get_value("challenges", level_id, false)
	ads_removed = cfg.get_value("shop", "ads_removed", false)
	language = cfg.get_value("settings", "language", "")
	sound_enabled = cfg.get_value("settings", "sound", true)
