extends SceneTree
## Plays a scripted round and saves frames for Play Store screenshots into /tmp/runner-trap-store/.
## Needs a window (not --headless):
## godot --path . --resolution 1920x1080 --fixed-fps 60 -s res://tools/capture_store.gd

const OUT_DIR := "/tmp/runner-trap-store/"
const LEVEL_INDEX := 1
const FEATURE_RUNNER_COLOR := Color(1, 0.6, 0.2)
const FEATURE_SIZE := Vector2i(1024, 500)

var _game_state: Node


func _initialize() -> void:
	_game_state = root.get_node("GameState")
	_game_state.persist = false
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run()


func _run() -> void:
	await process_frame
	var language: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "en"
	TranslationServer.set_locale(language)
	_game_state.level_stars = {"level_01": 3, "level_02": 2, "level_03": 3, "level_04": 1}

	var select: Node = load("res://scenes/level_select.tscn").instantiate()
	root.add_child(select)
	await _frames(20)
	_save("select")
	select.queue_free()

	_game_state.current_level_index = LEVEL_INDEX
	var level: Node = load("res://scenes/level.tscn").instantiate()
	root.add_child(level)
	await _frames(40)
	var runner: Runner = level.get_node("Runner")
	level.energy = level.level_data.max_energy
	# Saw and pit ahead, placed through the same path as a real drop.
	_place(level, "saw", runner.position.x + 520.0)
	_place(level, "pit", runner.position.x + 900.0)
	var wall := _card(level, "wall")
	var ghost_x := runner.position.x + 1150.0
	for i in 60:
		await _frames(4)
		# Show the drop preview of a card being dragged, then drop a wall late.
		if i < 25:
			level._on_drag_hovered(wall, _to_screen(level, ghost_x), true)
		elif i == 25:
			level._ghost.hide()
			_place(level, "wall", runner.position.x + 260.0)
		_save("play_%02d" % i)

	# Finish the runner off for the win panel.
	while not runner.is_down:
		runner._invulnerable_time_left = 0.0
		runner.take_hit()
		await _frames(10)
	await _frames(50)
	_save("win")
	level.queue_free()
	await _save_feature_graphic()
	quit()


## Play Store feature graphic (1024x500): a staged scene with a big runner and the title.
func _save_feature_graphic() -> void:
	var ground_y := 540.0
	var scene := Node2D.new()
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -1
	sky_layer.add_child(Backdrop.make_sky())
	scene.add_child(sky_layer)
	scene.add_child(Backdrop.make_hills(ground_y, 230.0, Backdrop.FAR_HILL_COLOR, 2))
	scene.add_child(Backdrop.make_hills(ground_y, 140.0, Backdrop.NEAR_HILL_COLOR, 3))
	for rect: Array in [[Rect2(0, ground_y, 1400, 300), Color("6d4c41")], [Rect2(0, ground_y, 1400, 10), Color("7cb342")]]:
		var color_rect := ColorRect.new()
		color_rect.position = rect[0].position
		color_rect.size = rect[0].size
		color_rect.color = rect[1]
		scene.add_child(color_rect)
	# Traps at double size, with the runner leaping over the saw.
	for trap: Array in [["saw", 560.0], ["pit", 820.0], ["wall", 1060.0]]:
		var node: Node2D = load("res://scenes/traps/%s.tscn" % trap[0]).instantiate()
		node.position = Vector2(trap[1], ground_y)
		node.scale = Vector2(2, 2)
		node.process_mode = Node.PROCESS_MODE_DISABLED
		scene.add_child(node)
	var runner := RunnerVisual.new()
	runner.color = FEATURE_RUNNER_COLOR
	runner.airborne = true
	runner.position = Vector2(330, 470)
	runner.rotation = 0.15
	runner.scale = Vector2(3, 3)
	scene.add_child(runner)

	var title := Label.new()
	title.text = "Runner Trap"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("263238"))
	title.add_theme_constant_override("outline_size", 24)
	title.position = Vector2(560, 90)
	scene.add_child(title)
	root.add_child(scene)
	await _frames(3)

	# Crop to the 1024:500 aspect, keeping the ground in view.
	var image := root.get_texture().get_image()
	var height := int(image.get_width() * FEATURE_SIZE.y / float(FEATURE_SIZE.x))
	image = image.get_region(Rect2i(0, image.get_height() - height - image.get_height() / 12, image.get_width(), height))
	image.resize(FEATURE_SIZE.x, FEATURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(OUT_DIR + "feature_graphic.png")
	scene.queue_free()


func _place(level: Node, trap_type: String, world_x: float) -> void:
	level.place_card(_card(level, trap_type), _to_screen(level, world_x))


func _card(level: Node, trap_type: String) -> TrapCard:
	for card: TrapCard in level._cards:
		if card.trap_info.trap_type == trap_type:
			return card
	return null


func _to_screen(level: Node, world_x: float) -> Vector2:
	return level.get_viewport().get_canvas_transform() * Vector2(world_x, level.GROUND_Y - 20.0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(name: String) -> void:
	root.get_texture().get_image().save_png(OUT_DIR + TranslationServer.get_locale() + "_" + name + ".png")
