class_name DropZone
extends Control
## Full-screen drop target that receives trap cards dragged over the track.
## Positions are reported in screen (viewport) coordinates.

signal drag_hovered(card: TrapCard, screen_pos: Vector2, valid: bool)
signal dropped(card: TrapCard, screen_pos: Vector2)
signal drag_ended

## (card: TrapCard, screen_pos: Vector2) -> bool
var can_drop_at: Callable


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is TrapCard or not can_drop_at.is_valid():
		return false
	var screen_pos := get_global_transform() * at_position
	var valid: bool = can_drop_at.call(data, screen_pos)
	drag_hovered.emit(data, screen_pos, valid)
	return valid


func _drop_data(at_position: Vector2, data: Variant) -> void:
	dropped.emit(data, get_global_transform() * at_position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()
