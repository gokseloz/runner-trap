extends SceneTree
## TR/EN coverage and switching: godot --headless -s res://tests/translation_test.gd

const CSV_PATH := "res://locale/translations.csv"
const TRAP_SCENES := ["pit", "wall", "saw", "slippery"]

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
