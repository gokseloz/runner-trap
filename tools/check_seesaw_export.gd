extends SceneTree


func _initialize() -> void:
	root.get_node("GameState").persist = false
	var level_id := "level_08" if OS.get_cmdline_user_args().has("--level-8") else "level_07"
	if OS.get_cmdline_user_args().has("--level-9"):
		level_id = "level_09"
	if OS.get_cmdline_user_args().has("--level-10"):
		level_id = "level_10"
	if OS.get_cmdline_user_args().has("--level-11"):
		level_id = "level_11"
	var source = load("res://resources/levels/%s.tres" % level_id)
	print("Source seesaws: ", source.seesaw_positions)
	var round_trip_path := "user://seesaw_round_trip.res"
	ResourceSaver.save(source, round_trip_path)
	var round_trip = ResourceLoader.load(round_trip_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	print("Saved/reloaded seesaws: ", round_trip.seesaw_positions)
	DirAccess.remove_absolute(round_trip_path)
	var archive := ZIPReader.new()
	if archive.open("res://build/runner-trap.apk") != OK:
		push_error("Cannot open debug APK")
		quit(1)
		return
	for path in archive.get_files():
		if path.ends_with("-%s.res" % level_id):
			var temporary_path := "user://seesaw_export_check.res"
			var output := FileAccess.open(temporary_path, FileAccess.WRITE)
			output.store_buffer(archive.read_file(path))
			output.close()
			var level = ResourceLoader.load(temporary_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			print("APK ", level_id, " seesaws: ", level.seesaw_positions if level != null else "LOAD FAILED")
			var valid: bool = level != null and level.seesaw_positions == source.seesaw_positions
			if level_id == "level_07":
				valid = valid and not source.seesaw_positions.is_empty()
			if level != null:
				print("APK ", level_id, " challenge: ", level.challenge, " target: ", level.challenge_target)
				valid = valid and level.challenge == source.challenge and level.challenge_target == source.challenge_target
				print("APK ", level_id, " wall revenge: ", level.wall_revenge)
				valid = valid and level.wall_revenge == source.wall_revenge
				if level_id == "level_10":
					valid = valid and level.wall_revenge
				print("APK ", level_id, " last-life umbrella: ", level.last_life_umbrella)
				valid = valid and level.last_life_umbrella == source.last_life_umbrella
				if level_id == "level_11":
					valid = valid and level.last_life_umbrella and level.level_id == "level_11"
					valid = valid and _check_umbrella_saw(archive)
				var source_cards: Array[String] = []
				var exported_cards: Array[String] = []
				for scene: PackedScene in source.available_traps:
					source_cards.append(scene.resource_path)
				for scene: PackedScene in level.available_traps:
					exported_cards.append(scene.resource_path)
				print("APK ", level_id, " cards: ", exported_cards)
				valid = valid and exported_cards == source_cards
				if level_id == "level_09":
					valid = valid and exported_cards.has("res://scenes/traps/fake_finish.tscn")
					var has_finish_scene := false
					for entry in archive.get_files():
						if entry.ends_with("-fake_finish.scn"):
							has_finish_scene = true
					valid = valid and has_finish_scene
			DirAccess.remove_absolute(temporary_path)
			archive.close()
			quit(0 if valid else 1)
			return
	push_error("APK has no exported %s resource" % level_id)
	quit(1)


func _check_umbrella_saw(archive: ZIPReader) -> bool:
	for entry in archive.get_files():
		if not entry.ends_with("-umbrella_saw.scn"):
			continue
		var temporary_path := "user://umbrella_saw_export_check.scn"
		var output := FileAccess.open(temporary_path, FileAccess.WRITE)
		output.store_buffer(archive.read_file(entry))
		output.close()
		var scene := ResourceLoader.load(temporary_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		DirAccess.remove_absolute(temporary_path)
		if scene == null:
			return false
		var saw := scene.instantiate()
		var collision := saw.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var blade := saw.get_node_or_null("Blade") as Polygon2D
		var valid := collision != null and blade != null
		if valid:
			print("APK umbrella saw heights: ", collision.position.y, " / ", blade.position.y)
			valid = collision.position.y == -72.0 and blade.position.y == -72.0
		saw.free()
		return valid
	return false