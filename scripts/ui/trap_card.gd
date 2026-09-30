class_name TrapCard
extends PanelContainer
## Hand card for one trap type. Drag it onto the track to place the trap.

const CARD_SIZE := Vector2(110, 110)

var trap_scene: PackedScene
## Instance kept outside the tree, only used to read the trap's exported values.
var trap_info: Trap
var _cost_label: Label
var exhausted := false:
	set(value):
		exhausted = value
		if is_instance_valid(_cost_label):
			_cost_label.text = tr("Used") if value else tr("Cost %d") % trap_info.energy_cost
var affordable := true:
	set(value):
		affordable = value
		modulate = Color.WHITE if value else Color(1, 1, 1, 0.4)


func setup(scene: PackedScene) -> void:
	trap_scene = scene
	trap_info = scene.instantiate()
	custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(12)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	var icon := TrapIcon.new()
	icon.trap_type = trap_info.trap_type
	icon.color = trap_info.card_color
	icon.custom_minimum_size = Vector2(0, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	box.add_child(_make_label(tr(trap_info.display_name), 18))
	_cost_label = _make_label(tr("Cost %d") % trap_info.energy_cost, 16)
	box.add_child(_cost_label)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(trap_info):
		trap_info.free()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not affordable:
		return null
	var preview_rect := ColorRect.new()
	preview_rect.color = trap_info.card_color
	preview_rect.size = Vector2(trap_info.width, 40)
	preview_rect.position = -preview_rect.size / 2.0
	preview_rect.modulate.a = 0.7
	# Wrapper so the preview is centered on the finger instead of hanging off it.
	var preview := Control.new()
	preview.add_child(preview_rect)
	set_drag_preview(preview)
	return self


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.25))
	return label
