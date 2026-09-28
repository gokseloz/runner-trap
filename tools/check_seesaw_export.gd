extends SceneTree


func _initialize() -> void:
	root.get_node("GameState").persist = false
	var source = load("res://resources/levels/level_07.tres")
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
		if path.ends_with("-level_07.res"):
			var temporary_path := "user://seesaw_export_check.res"
			var output := FileAccess.open(temporary_path, FileAccess.WRITE)
			output.store_buffer(archive.read_file(path))
			output.close()
			var level = ResourceLoader.load(temporary_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			print("APK level 7 seesaws: ", level.seesaw_positions if level != null else "LOAD FAILED")
			var valid: bool = level != null and not source.seesaw_positions.is_empty() and level.seesaw_positions == source.seesaw_positions
			DirAccess.remove_absolute(temporary_path)
			archive.close()
			quit(0 if valid else 1)
			return
	push_error("APK has no exported level 7 resource")
	quit(1)