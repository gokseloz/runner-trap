class_name LevelSelect
extends Control
## Grid of level buttons with best stars. Locked levels are shown but can't be opened.

const BUTTON_SIZE := Vector2(190, 140)
const LOCKED_ALPHA := 0.8
const BUTTON_COLOR := Color("37474f")
const BUTTON_HOVER_COLOR := Color("455a64")
const BUTTON_PRESSED_COLOR := Color("263238")
const LOCKED_COLOR := Color("78909c")
const SOUND_BUTTON_SHIFT := 180.0

var buttons: Array[Button] = []
var sound_button: Button

@onready var _grid: GridContainer = $Center/Box/Grid
@onready var _language_button: Button = $LanguageButton


func _ready() -> void:
	_build_backdrop()
	for i in GameState.LEVELS.size():
		var button := _make_button(i)
		_grid.add_child(button)
		buttons.append(button)
	# The button names the language it switches to, in that language.
	var other := GameState.get_next_language()
	_language_button.text = GameState.LANGUAGES[other]
	_language_button.pressed.connect(_on_language_pressed.bind(other))
	_build_sound_button()
	for button: Button in buttons + [_language_button]:
		button.pressed.connect(Audio.play.bind("click"))


func _build_backdrop() -> void:
	var scenery := Control.new()
	scenery.set_anchors_preset(Control.PRESET_FULL_RECT)
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scenery.add_child(Backdrop.make_sky())
	var bottom := get_viewport_rect().size.y
	for tile in 2:
		for hills: Polygon2D in [
			Backdrop.make_hills(bottom, 220.0, Backdrop.FAR_HILL_COLOR, 2),
			Backdrop.make_hills(bottom, 130.0, Backdrop.NEAR_HILL_COLOR, 3),
		]:
			hills.position.x = tile * Backdrop.TILE_WIDTH
			scenery.add_child(hills)
	add_child(scenery)
	move_child(scenery, 0)


## Toggle left of the language button, labelled with the current state.
func _build_sound_button() -> void:
	var button := _language_button.duplicate(0) as Button
	button.name = "SoundButton"
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.offset_left -= SOUND_BUTTON_SHIFT
	button.offset_right -= SOUND_BUTTON_SHIFT
	button.text = tr("Sound On") if GameState.sound_enabled else tr("Sound Off")
	button.pressed.connect(_on_sound_pressed.bind(button))
	add_child(button)
	sound_button = button


func _on_sound_pressed(button: Button) -> void:
	GameState.set_sound_enabled(not GameState.sound_enabled)
	button.text = tr("Sound On") if GameState.sound_enabled else tr("Sound Off")
	Audio.play("click")


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	return style


func _on_language_pressed(language: String) -> void:
	GameState.set_language(language)
	get_tree().reload_current_scene()


func _make_button(index: int) -> Button:
	var level := GameState.get_level(index)
	var unlocked := GameState.is_level_unlocked(index)

	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_style(BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _make_style(BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _make_style(BUTTON_PRESSED_COLOR))
	button.add_theme_stylebox_override("disabled", _make_style(LOCKED_COLOR))
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
	runner_name.text = tr(level.runner.display_name) if unlocked else tr("Locked")
	runner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	runner_name.add_theme_font_size_override("font_size", 16)
	box.add_child(runner_name)

	var stars := StarRow.new()
	stars.star_radius = 12.0
	stars.filled = GameState.get_level_stars(level.level_id)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stars)
	return button
