class_name LevelSelect
extends Control
## Grid of level buttons with best stars. Locked levels are shown but can't be opened.

const BUTTON_SIZE := Vector2(190, 140)
const LOCKED_ALPHA := 0.4

var buttons: Array[Button] = []

@onready var _grid: GridContainer = $Center/Box/Grid


func _ready() -> void:
	for i in GameState.LEVELS.size():
		var button := _make_button(i)
		_grid.add_child(button)
		buttons.append(button)


func _make_button(index: int) -> Button:
	var level := GameState.get_level(index)
	var unlocked := GameState.is_level_unlocked(index)

	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_NONE
	if not unlocked:
		button.modulate.a = LOCKED_ALPHA
	button.pressed.connect(GameState.play_level.bind(index))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var number := Label.new()
	number.text = str(index + 1)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", 44)
	box.add_child(number)

	var runner_name := Label.new()
	runner_name.text = level.runner.display_name if unlocked else "Locked"
	runner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	runner_name.add_theme_font_size_override("font_size", 16)
	box.add_child(runner_name)

	var stars := StarRow.new()
	stars.star_radius = 12.0
	stars.filled = GameState.get_level_stars(level.level_id)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stars)
	return button
