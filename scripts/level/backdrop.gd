class_name Backdrop
extends RefCounted
## Flat scenery built from code: sky gradient, clouds and two rows of parallax hills.

const SKY_TOP := Color("7ec8f5")
const SKY_BOTTOM := Color("e6f4fb")
const FAR_HILL_COLOR := Color("b3dcc3")
const NEAR_HILL_COLOR := Color("8cc9a0")
const CLOUD_COLOR := Color.WHITE
## Width after which each layer repeats; hill waves must divide it evenly.
const TILE_WIDTH := 1600.0


## Adds the scenery to a level. Parallax layers are placed behind everything else.
static func build_level(level: Node2D, ground_y: float) -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	sky_layer.add_child(make_sky())
	level.add_child(sky_layer)

	var layers: Array[Parallax2D] = [
		_make_layer(0.1, _make_clouds(ground_y - 520.0)),
		_make_layer(0.25, make_hills(ground_y, 170.0, FAR_HILL_COLOR, 2)),
		_make_layer(0.5, make_hills(ground_y, 100.0, NEAR_HILL_COLOR, 3)),
	]
	for i in layers.size():
		level.add_child(layers[i])
		level.move_child(layers[i], i)


## Full-screen vertical gradient.
static func make_sky() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, SKY_TOP)
	gradient.set_color(1, SKY_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = texture
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sky


## One tile of rolling hills standing on base_y. `waves` full sine periods per tile.
static func make_hills(base_y: float, height: float, color: Color, waves: int) -> Polygon2D:
	var points := PackedVector2Array()
	var steps := 64
	for i in steps + 1:
		var x := TILE_WIDTH * i / steps
		var t := TAU * x / TILE_WIDTH
		var wave := 0.65 + 0.35 * sin(t * waves) + 0.15 * sin(t * waves * 2 + 1.3)
		points.append(Vector2(x, base_y - height * wave))
	points.append(Vector2(TILE_WIDTH, base_y + 20.0))
	points.append(Vector2(0.0, base_y + 20.0))
	var hills := Polygon2D.new()
	hills.polygon = points
	hills.color = color
	return hills


static func _make_clouds(top_y: float) -> Node2D:
	var clouds := Node2D.new()
	var spots := [Vector2(120, 60), Vector2(560, 10), Vector2(980, 90), Vector2(1350, 30)]
	for spot: Vector2 in spots:
		clouds.add_child(_make_cloud(Vector2(spot.x, top_y + spot.y)))
	return clouds


## Three overlapping circles on a flat bottom.
static func _make_cloud(center: Vector2) -> Node2D:
	var cloud := Node2D.new()
	cloud.position = center
	for puff: Vector3 in [Vector3(-40, 0, 28), Vector3(0, -14, 38), Vector3(42, 2, 26)]:
		cloud.add_child(_make_circle(Vector2(puff.x, puff.y), puff.z, CLOUD_COLOR))
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(60, 0), Vector2(60, 26), Vector2(-60, 26)])
	base.position.y = 2.0
	base.color = CLOUD_COLOR
	cloud.add_child(base)
	return cloud


static func _make_circle(center: Vector2, radius: float, color: Color) -> Polygon2D:
	var points := PackedVector2Array()
	for i in 24:
		points.append(center + Vector2.RIGHT.rotated(TAU * i / 24) * radius)
	var circle := Polygon2D.new()
	circle.polygon = points
	circle.color = color
	return circle


static func _make_layer(scroll: float, content: Node2D) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(scroll, 1.0)
	layer.repeat_size = Vector2(TILE_WIDTH, 0.0)
	layer.repeat_times = 3
	layer.add_child(content)
	return layer
