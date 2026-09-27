extends Trap
## Hanging saw blade at head height. Standing runners get hit, sliding runners pass under.

const TEETH := 10
const SPIN_SPEED := TAU * 1.5
const HUB_COLOR := Color("cfd8dc")

@export var blade_radius := 20.0

@onready var _blade: Polygon2D = $Blade


func _ready() -> void:
	super()
	var points := PackedVector2Array()
	for i in TEETH * 2:
		var radius := blade_radius if i % 2 == 0 else blade_radius * 0.7
		points.append(Vector2.from_angle(TAU * i / (TEETH * 2)) * radius)
	_blade.polygon = points

	var hub := Polygon2D.new()
	var hub_points := PackedVector2Array()
	for i in 12:
		hub_points.append(Vector2.from_angle(TAU * i / 12) * blade_radius * 0.3)
	hub.polygon = hub_points
	hub.color = HUB_COLOR
	_blade.add_child(hub)


func _process(delta: float) -> void:
	if not consumed:
		_blade.rotation += SPIN_SPEED * delta
