extends Node2D
## Runs a single level: builds the track, starts the runner, follows it with the camera,
## manages energy and turns dropped cards into traps.

## kind is "chain" (hit right after a dodge) or "slippery" (hit on a slippery floor).
signal combo_landed(kind: String)

const GROUND_Y := 600.0
## Deep enough to fill the screen below the ground surface on tall aspect ratios.
const GROUND_DEPTH := 600.0
const RUNNER_START_X := 100.0
## Extra ground before the start and after the finish line.
const TRACK_MARGIN := 1500.0
const MARKER_SPACING := 250.0
## Runner is kept at this fraction of the screen width so the track ahead is visible.
const CAMERA_LEAD := 0.2
## Camera center height; puts the ground surface at screen y=480, above the card bar.
const CAMERA_Y := 480.0
## Traps can't be dropped right under the runner's feet.
const MIN_PLACE_AHEAD := 120.0
const MIN_TRAP_GAP := 20.0

const GROUND_COLOR := Color("6d4c41")
const MARKER_COLOR := Color("8d6e63")
const GRASS_COLOR := Color("7cb342")
const GRASS_DEPTH := 10.0
const FINISH_POLE_COLOR := Color("455a64")
const FINISH_DARK := Color("263238")
const FINISH_LIGHT := Color.WHITE
const FINISH_CELL := 16.0
const GHOST_VALID_COLOR := Color(0.3, 0.8, 0.4, 0.5)
const GHOST_INVALID_COLOR := Color(0.9, 0.3, 0.3, 0.5)
const GHOST_HEIGHT := 60.0

## A hit counts as a chain combo if the runner dodged another trap this recently.
const COMBO_WINDOW := 1.0
const COMBO_ENERGY_BONUS := 2.0
const COMBO_COLOR := Color("ff7043")

## Camera shake strength (px) on a hit and on the knockout, and how fast it fades (px/s).
const SHAKE_HIT := 10.0
const SHAKE_KNOCKOUT := 22.0
const SHAKE_DECAY := 60.0
## Brief slow motion when the runner goes down.
const KNOCKOUT_TIME_SCALE := 0.35
const KNOCKOUT_SLOWMO_DURATION := 0.5
const DUST_COLOR := Color("90a4ae")
const END_JINGLE_DELAY := 0.5

## Leave empty to play GameState's current level.
@export var level_data: LevelData

var energy := 0.0
var combo_count := 0

var _game_over := false
var _time := 0.0
var _shake := 0.0
var _last_dodge_time := -INF
var _placed_traps: Array[Trap] = []
## Traps the runner got past without being hit, so each dodge is counted once.
var _dodged_traps: Dictionary = {}
var _cards: Array[TrapCard] = []
var _ghost: ColorRect

@onready var _track: Node2D = $Track
@onready var _runner: Runner = $Runner
@onready var _camera: Camera2D = $Camera2D
@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _drop_zone: DropZone = $HUD/DropZone
@onready var _energy_bar: ProgressBar = $HUD/BottomPanel/EnergyRow/EnergyBar
@onready var _energy_label: Label = $HUD/BottomPanel/EnergyRow/EnergyLabel
@onready var _card_bar: HBoxContainer = $HUD/BottomPanel/CardBar
@onready var _end_panel: Control = $HUD/EndPanel
@onready var _end_title: Label = $HUD/EndPanel/Box/Title
@onready var _end_stars: StarRow = $HUD/EndPanel/Box/Stars
@onready var _levels_button: Button = $HUD/EndPanel/Box/Buttons/Levels
@onready var _retry_button: Button = $HUD/EndPanel/Box/Buttons/Retry
@onready var _next_button: Button = $HUD/EndPanel/Box/Buttons/Next


func _ready() -> void:
	if level_data == null:
		level_data = GameState.get_current_level()
	_end_panel.hide()
	for button: Button in [_levels_button, _retry_button, _next_button]:
		button.pressed.connect(Audio.play.bind("click"))
	_levels_button.pressed.connect(GameState.open_level_select)
	_retry_button.pressed.connect(get_tree().reload_current_scene)
	_next_button.pressed.connect(_go_to_next_level)

	Backdrop.build_level(self, GROUND_Y)
	_build_track()
	_build_ghost()
	_build_cards()

	_runner.position = Vector2(RUNNER_START_X, GROUND_Y)
	# Move the runner before the camera follows it each physics frame.
	_runner.process_physics_priority = -1
	_runner.hit.connect(_on_runner_hit)
	_runner.knocked_out.connect(_on_runner_knocked_out)
	_runner.jumped.connect(Audio.play.bind("jump", 0.08))
	_runner.slid.connect(Audio.play.bind("slide", 0.08))
	_runner.setup(level_data.runner)

	energy = level_data.starting_energy
	_energy_bar.max_value = level_data.max_energy

	_drop_zone.can_drop_at = _can_place_card
	_drop_zone.drag_hovered.connect(_on_drag_hovered)
	_drop_zone.dropped.connect(place_card)
	_drop_zone.drag_ended.connect(_ghost.hide)

	_update_lives_label()
	_update_energy_ui()
	_update_camera()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, SHAKE_DECAY * delta)
	_update_camera()
	if _game_over:
		return
	_time += delta
	_track_dodges()
	energy = minf(energy + level_data.energy_regen_per_sec * delta, level_data.max_energy)
	_update_energy_ui()
	if not _runner.is_down and _runner.position.x >= level_data.track_length:
		_end_game(false)
		_runner.set_physics_process(false)


func _unhandled_input(event: InputEvent) -> void:
	# Debug controls.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			GameState.open_level_select()
		KEY_A:
			_runner.ai.enabled = not _runner.ai.enabled
			_runner.set_alert(false)
			print("Runner AI ", "on" if _runner.ai.enabled else "off")
		KEY_SPACE, KEY_UP:
			_runner.jump()
		KEY_DOWN:
			_runner.slide()
		KEY_S:
			_runner.stop()
		KEY_H:
			_runner.take_hit()
		KEY_R:
			get_tree().reload_current_scene()
		KEY_N:
			GameState.current_level_index = (GameState.current_level_index + 1) % GameState.LEVELS.size()
			get_tree().reload_current_scene()


## Places the card's trap at the dropped screen position. Returns false if not allowed.
func place_card(card: TrapCard, screen_pos: Vector2) -> bool:
	if not _can_place_card(card, screen_pos):
		return false
	energy -= card.trap_info.energy_cost
	var trap: Trap = card.trap_scene.instantiate()
	trap.position = Vector2(_screen_to_world(screen_pos).x, GROUND_Y)
	_track.add_child(trap)
	Fx.pop_in(trap)
	Fx.burst(_track, trap.position, DUST_COLOR, 10, 150.0)
	Audio.play("drop", 0.1)
	trap.runner_hit.connect(_on_trap_hit)
	_placed_traps.append(trap)
	_update_energy_ui()
	return true


func _can_place_card(card: TrapCard, screen_pos: Vector2) -> bool:
	if _game_over or energy < card.trap_info.energy_cost:
		return false
	var x := _screen_to_world(screen_pos).x
	var half_width := card.trap_info.width / 2.0
	if x - half_width < _runner.position.x + MIN_PLACE_AHEAD:
		return false
	if x + half_width > level_data.track_length:
		return false
	for trap in _placed_traps:
		if trap.is_surface != card.trap_info.is_surface:
			continue
		if absf(trap.position.x - x) < (trap.width / 2.0 + half_width + MIN_TRAP_GAP):
			return false
	return true


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _end_game(player_won: bool) -> void:
	_game_over = true
	_runner.ai.enabled = false
	_runner.set_alert(false)
	_ghost.hide()
	for card in _cards:
		card.affordable = false

	var stars := 0
	if player_won:
		var remaining := clampf(1.0 - _runner.position.x / level_data.track_length, 0.0, 1.0)
		stars = level_data.get_stars(remaining)
		GameState.set_level_stars(level_data.level_id, stars)
	_end_title.text = tr("Runner down!") if player_won else tr("Runner escaped!")
	_end_stars.filled = stars
	_next_button.visible = player_won and GameState.has_next_level()
	_end_panel.show()
	# Let the knockout sound finish before the jingle.
	var jingle := "win" if player_won else "lose"
	get_tree().create_timer(END_JINGLE_DELAY, true, false, true).timeout.connect(Audio.play.bind(jingle))


func _go_to_next_level() -> void:
	GameState.current_level_index += 1
	get_tree().reload_current_scene()


func _update_camera() -> void:
	var view_width := get_viewport_rect().size.x
	_camera.position = Vector2(_runner.position.x + view_width * (0.5 - CAMERA_LEAD), CAMERA_Y)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake


func _update_lives_label() -> void:
	_lives_label.text = "%s  ·  %s" % [tr(level_data.display_name), tr("Lives: %d") % _runner.lives]


func _update_energy_ui() -> void:
	_energy_bar.value = energy
	_energy_label.text = "%d / %d" % [floori(energy), level_data.max_energy]
	if _game_over:
		return
	for card in _cards:
		card.affordable = energy >= card.trap_info.energy_cost


func _build_track() -> void:
	var start_x := -TRACK_MARGIN
	var width := level_data.track_length + TRACK_MARGIN * 2.0

	var ground := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, GROUND_DEPTH)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(start_x + width / 2.0, GROUND_Y + GROUND_DEPTH / 2.0)
	ground.add_child(collision)
	_track.add_child(ground)

	_add_rect(Rect2(start_x, GROUND_Y, width, GROUND_DEPTH), GROUND_COLOR)
	_add_rect(Rect2(start_x, GROUND_Y, width, GRASS_DEPTH), GRASS_COLOR)

	# Distance markers so movement is visible on the flat ground.
	var x := 0.0
	while x < level_data.track_length:
		_add_rect(Rect2(x, GROUND_Y + 24.0, 30.0, 6.0), MARKER_COLOR)
		x += MARKER_SPACING

	_build_finish_flag(level_data.track_length)


## Pole with a checkered flag at the finish line.
func _build_finish_flag(x: float) -> void:
	_add_rect(Rect2(x, GROUND_Y - 200.0, 8.0, 200.0), FINISH_POLE_COLOR)
	for row in 3:
		for column in 4:
			var color := FINISH_DARK if (row + column) % 2 == 0 else FINISH_LIGHT
			_add_rect(Rect2(x + 8.0 + column * FINISH_CELL, GROUND_Y - 200.0 + row * FINISH_CELL, FINISH_CELL, FINISH_CELL), color)


func _build_ghost() -> void:
	_ghost = _add_rect(Rect2(0, GROUND_Y - GHOST_HEIGHT, 0, GHOST_HEIGHT), GHOST_VALID_COLOR)
	_ghost.z_index = 10
	_ghost.hide()


func _build_cards() -> void:
	for scene in level_data.available_traps:
		var card := TrapCard.new()
		card.setup(scene)
		_card_bar.add_child(card)
		_cards.append(card)


func _add_rect(rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(color_rect)
	return color_rect


func _on_drag_hovered(card: TrapCard, screen_pos: Vector2, valid: bool) -> void:
	var width := card.trap_info.width
	_ghost.position.x = _screen_to_world(screen_pos).x - width / 2.0
	_ghost.size.x = width
	_ghost.color = GHOST_VALID_COLOR if valid else GHOST_INVALID_COLOR
	_ghost.show()


func _track_dodges() -> void:
	var runner_back := _runner.position.x - Runner.SIZE.x / 2.0
	for trap in _placed_traps:
		if trap.consumed or trap.is_surface or _dodged_traps.has(trap):
			continue
		if trap.position.x + trap.width / 2.0 < runner_back:
			_dodged_traps[trap] = true
			_last_dodge_time = _time


func _on_trap_hit(_trap: Trap) -> void:
	var kind := ""
	if _runner.speed_multiplier > 1.0:
		kind = "slippery"
	elif _time - _last_dodge_time <= COMBO_WINDOW:
		kind = "chain"
	if kind.is_empty():
		return
	combo_count += 1
	energy = minf(energy + COMBO_ENERGY_BONUS, level_data.max_energy)
	_update_energy_ui()
	_show_combo_popup()
	Audio.play("combo")
	combo_landed.emit(kind)


func _show_combo_popup() -> void:
	var label := Label.new()
	label.text = tr("Combo! +%d") % COMBO_ENERGY_BONUS
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", COMBO_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size.x = 240.0
	label.position = _runner.position + Vector2(-label.size.x / 2.0, -140.0)
	label.z_index = 20
	_track.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 60.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func _on_runner_hit(lives_left: int) -> void:
	if lives_left > 0:
		Audio.play("hit", 0.1)
	_update_lives_label()
	_shake = SHAKE_HIT
	Fx.burst(_track, _runner.position + Vector2(0.0, -Runner.SIZE.y / 2.0), _runner.profile.color)
	Input.vibrate_handheld(40)


func _on_runner_knocked_out() -> void:
	_shake = SHAKE_KNOCKOUT
	Audio.play("knockout")
	Fx.burst(_track, _runner.position + Vector2(0.0, -Runner.SIZE.y / 2.0), _runner.profile.color.darkened(0.3), 30, 380.0)
	Input.vibrate_handheld(150)
	Engine.time_scale = KNOCKOUT_TIME_SCALE
	get_tree().create_timer(KNOCKOUT_SLOWMO_DURATION, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	_end_game(true)
