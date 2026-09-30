extends SceneTree
## TR/EN coverage and switching: godot --headless -s res://tests/translation_test.gd

const CSV_PATH := "res://locale/translations.csv"
const TRAP_SCENES := ["pit", "wall", "saw", "slippery", "spring", "snap", "magnet", "fake_finish"]

var _game_state: Node
var _failures := 0


func _initialize() -> void:
	# Autoloads aren't visible by name to -s scripts at compile time.
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	_run()


func _run() -> void:
	var rows := _read_csv()
	for key: String in rows:
		var row: PackedStringArray = rows[key]
		_check(row.size() == 3 and not row[1].is_empty() and not row[2].is_empty(), "'%s' has en and tr" % key)

	# Every name shown in the game must be in the table.
	var names: Array[String] = ["Runner down!", "Runner escaped!", "Lives: %d", "Cost %d", "Retry", "Next", "Levels", "Locked", "Combo! +%d", "Sound On", "Sound Off", "Watch ad: runner -1 life", "Retry: runner -1 life", "Paused", "Resume", "Restart"]
	names.append_array(["Efficient trapper", "Combo master", "One weapon", "Win with at most %d traps", "Win with at least %d combos", "Win using only one trap type", "Traps: %d/%d", "Combos: %d/%d", "Trap types: %d/1", "Optional: %s", "Challenge complete!", "Challenge not completed", "Challenge: fresh run required"])
	names.append_array(["Spring master", "Win with at least %d spring combos", "Spring combos: %d/%d"])
	names.append_array(["Magnet master", "Win with at least %d hits during a magnet pull", "Magnet hits: %d/%d"])
	names.append_array(["Full arsenal", "Win using at least %d trap types", "Trap types: %d/%d"])
	names.append_array(["Seesaw master", "Win with at least %d spring-to-seesaw launches", "Seesaw launches: %d/%d"])
	names.append_array(["Quick hunter", "Win within the first %d%% of the track", "Track: %d%% / %d%%"])
	names.append("Used")
	names.append("Level 11")
	for trap_name in TRAP_SCENES:
		var trap: Trap = load("res://scenes/traps/%s.tscn" % trap_name).instantiate()
		names.append(trap.display_name)
		trap.free()
	for i in _game_state.LEVELS.size():
		var level: LevelData = _game_state.get_level(i)
		names.append(level.display_name)
		names.append(level.runner.display_name)
	for text in names:
		_check(rows.has(text), "'%s' is translated" % text)

	_game_state.set_language("tr")
	_check(tr("Retry") == "Tekrar", "tr: Retry -> %s" % tr("Retry"))
	_check(tr("Lives: %d") % 2 == "Can: 2", "tr: lives format")
	_check(tr("Track: %d%% / %d%%") % [25, 50] == "Parkur: %25 / %50", "tr: track percentage format")
	_check(tr("Win within the first %d%% of the track") % 50 == "Parkurun ilk %50'lik kısmında kazan", "tr: quick hunter description format")
	_check(_game_state.get_next_language() == "en", "tr: button offers English")
	_game_state.set_language("en")
	_check(tr("Retry") == "Retry", "en: Retry -> %s" % tr("Retry"))
	_check(_game_state.get_next_language() == "tr", "en: button offers Turkish")
	_check(_game_state.language == "en", "choice stored for saving")

	print("DONE: %d failure(s)" % _failures)
	quit()


## key -> full CSV row (key, en, tr)
func _read_csv() -> Dictionary:
	var rows := {}
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 0 and not row[0].is_empty():
			rows[row[0]] = row
	return rows


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
