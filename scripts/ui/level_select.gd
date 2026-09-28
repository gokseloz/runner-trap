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
var privacy_button: Button

@onready var _grid: GridContainer = $Center/Box/Grid
@onready var _language_button: Button = $LanguageButton


func _ready() -> void:
	_build_backdrop()
	for i in GameState.LEVELS.size():
		var button := _make_button(i)
		_grid.add_child(button)
		buttons.append(button)
	_fit_buttons.call_deferred()
	# The button names the language it switches to, in that language.
	var other := GameState.get_next_language()
	_language_button.text = GameState.LANGUAGES[other]
	_language_button.pressed.connect(_on_language_pressed.bind(other))
	_build_sound_button()
	_build_privacy_button()
	for button: Button in buttons + [_language_button]:
		button.pressed.connect(Audio.play.bind("click"))


func _fit_buttons() -> void:
	for button: Button in buttons:
		var box := button.get_node("Content") as VBoxContainer
		button.custom_minimum_size = BUTTON_SIZE.max(box.get_combined_minimum_size() + Vector2(16.0, 20.0))


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


## Opens the ad consent form again. Only shown where the player must be able to change it.
func _build_privacy_button() -> void:
	var button := _language_button.duplicate(0) as Button
	button.name = "PrivacyButton"
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.offset_left -= 2 * SOUND_BUTTON_SHIFT
	button.offset_right -= 2 * SOUND_BUTTON_SHIFT
	button.text = tr("Privacy")
	button.pressed.connect(Ads.show_privacy_options)
	button.pressed.connect(Audio.play.bind("click"))
	add_child(button)
	privacy_button = button
	# Consent info arrives shortly after launch, possibly after this screen is up.
	_update_privacy_button()
	Ads.consent_updated.connect(_update_privacy_button)


func _update_privacy_button() -> void:
	privacy_button.visible = Ads.is_privacy_options_required()


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
	box.name = "Content"
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8.0
	box.offset_right = -8.0
	box.offset_top = 10.0
	box.offset_bottom = -10.0
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
	if level.challenge != LevelData.Challenge.NONE:
		var badge := ChallengeBadge.new()
		badge.name = "ChallengeBadge"
		badge.earned = GameState.has_challenge_badge(level.level_id)
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-42.0, 6.0)
		button.add_child(badge)
		var challenge_name := Label.new()
		challenge_name.text = level.get_challenge_name()
		challenge_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		challenge_name.add_theme_font_size_override("font_size", 16)
		challenge_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(challenge_name)
		button.tooltip_text = level.get_challenge_description()
	return button
