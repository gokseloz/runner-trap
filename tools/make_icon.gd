extends SceneTree
## Draws the app icon in the game's flat style: a jumping runner over a saw blade.
## Writes the full icon plus Android adaptive layers into res://assets/icon/.
## Run after changing it: godot --headless -s res://tools/make_icon.gd && godot --headless --import

const OUT_DIR := "res://assets/icon/"
## Everything is drawn on a 432 unit canvas (the adaptive icon size), then scaled.
const CANVAS := 432.0
## Drawn this many times larger, then downscaled so edges are smooth.
const SUPERSAMPLE := 4

const SKY_TOP := Color("7ec8f5")
const SKY_BOTTOM := Color("e6f4fb")
const HILL_COLOR := Color("8cc9a0")
const GROUND_COLOR := Color("6d4c41")
const GRASS_COLOR := Color("7cb342")
const RUNNER_COLOR := Color(1, 0.6, 0.2)
const SAW_COLOR := Color(0.9, 0.22, 0.21)
const HUB_COLOR := Color("cfd8dc")
const EYE_COLOR := Color.WHITE
const PUPIL_COLOR := Color("263238")
const GROUND_Y := 330.0

var _image: Image
var _scale := 1.0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save("icon", 512, true, true)
	_save("icon_192", 192, true, true)
	_save("adaptive_background", 432, true, false)
	_save("adaptive_foreground", 432, false, true)
	print("DONE")
	quit()


func _save(file: String, size: int, background: bool, foreground: bool) -> void:
	var big := size * SUPERSAMPLE
	_image = Image.create_empty(big, big, false, Image.FORMAT_RGBA8)
	_scale = big / CANVAS
	if background:
		_draw_background()
	if foreground:
		# Adaptive launchers crop to a circle of ~2/3 the canvas, so the full icon
		# uses the same centered layout.
		_draw_saw(Vector2(262, 318), 70.0)
		_draw_runner(Vector2(180, 262), 0.2)
	_image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	_image.save_png(OUT_DIR + file + ".png")


func _draw_background() -> void:
	var rows := _image.get_height()
	for y in rows:
		var color := SKY_TOP.lerp(SKY_BOTTOM, float(y) / rows)
		_image.fill_rect(Rect2i(0, y, _image.get_width(), 1), color)
	for x in int(CANVAS):
		var top := GROUND_Y - 60.0 - 30.0 * sin(x / CANVAS * TAU * 1.5 + 0.6)
		_fill_rect(Rect2(x, top, 1.5, CANVAS - top), HILL_COLOR)
	_fill_rect(Rect2(0, GROUND_Y, CANVAS, CANVAS - GROUND_Y), GROUND_COLOR)
	_fill_rect(Rect2(0, GROUND_Y, CANVAS, 14), GRASS_COLOR)


## Runner body like RunnerVisual, 3x its in-game size, tilted by angle (radians).
func _draw_runner(feet: Vector2, angle: float) -> void:
	var s := 2.6
	var width := 40.0 * s
	var body_height := 50.0 * s
	var leg_length := 14.0 * s
	var leg_color := RUNNER_COLOR.darkened(0.45)
	var band_color := RUNNER_COLOR.darkened(0.35)
	var point := func(local: Vector2) -> Vector2: return feet + local.rotated(angle)

	# Legs mid-stride.
	for swing in [0.7, -0.5]:
		var hip: Vector2 = Vector2(signf(swing) * 9.0 * s, -leg_length - 4.0 * s)
		var foot: Vector2 = hip + Vector2(0, leg_length + 6.0 * s).rotated(swing)
		_fill_line(point.call(hip), point.call(foot), 6.0 * s, leg_color)
		_fill_circle(point.call(foot), 3.0 * s, leg_color)

	# Rounded body, as a polygon so it can be rotated.
	var top := -leg_length - body_height
	var corners: PackedVector2Array = []
	var radius := 10.0 * s
	for corner in [Vector2(width / 2 - radius, top + radius), Vector2(width / 2 - radius, -leg_length - radius),
			Vector2(-width / 2 + radius, -leg_length - radius), Vector2(-width / 2 + radius, top + radius)]:
		corners.append(corner)
	var outline: PackedVector2Array = []
	for i in 4:
		for step in 9:
			var a: float = -PI / 2 + i * PI / 2 + step * PI / 16
			outline.append(point.call(corners[i] + Vector2(cos(a), sin(a)) * radius))
	_fill_polygon(outline, RUNNER_COLOR)

	# Headband with a tail streaming back.
	var band_y := top + 10.0 * s
	_fill_polygon(_quad(point, Rect2(-width / 2, band_y, width, 6.0 * s)), band_color)
	_fill_polygon(PackedVector2Array([point.call(Vector2(-width / 2, band_y)), point.call(Vector2(-width / 2 - 34, band_y - 16)),
			point.call(Vector2(-width / 2 - 30, band_y + 4)), point.call(Vector2(-width / 2, band_y + 6.0 * s))]), band_color)

	var eye: Vector2 = point.call(Vector2(8.0 * s, band_y + 14.0 * s))
	_fill_circle(eye, 6.0 * s, EYE_COLOR)
	_fill_circle(eye + Vector2(2.0 * s, 0).rotated(angle), 3.0 * s, PUPIL_COLOR)


func _draw_saw(center: Vector2, radius: float) -> void:
	var teeth := 12
	var outline: PackedVector2Array = []
	for i in teeth * 2:
		var r := radius if i % 2 == 0 else radius * 0.78
		var a := i * PI / teeth + 0.2
		outline.append(center + Vector2(cos(a), sin(a)) * r)
	_fill_polygon(outline, SAW_COLOR)
	_fill_circle(center, radius * 0.3, HUB_COLOR)


func _quad(point: Callable, rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([point.call(rect.position), point.call(Vector2(rect.end.x, rect.position.y)),
			point.call(rect.end), point.call(Vector2(rect.position.x, rect.end.y))])


func _fill_rect(rect: Rect2, color: Color) -> void:
	var r := Rect2i(Vector2i(rect.position * _scale), Vector2i((rect.size * _scale).ceil()))
	_image.fill_rect(r, color)


func _fill_circle(center: Vector2, radius: float, color: Color) -> void:
	var c := center * _scale
	var r := radius * _scale
	for y in range(int(c.y - r), int(c.y + r) + 1):
		var half := sqrt(maxf(r * r - (y - c.y) * (y - c.y), 0.0))
		_image.fill_rect(Rect2i(int(c.x - half), y, int(half * 2.0) + 1, 1), color)


func _fill_line(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var side := (to - from).orthogonal().normalized() * width / 2.0
	_fill_polygon(PackedVector2Array([from + side, to + side, to - side, from - side]), color)


## Scanline fill of a polygon given in canvas units.
func _fill_polygon(points: PackedVector2Array, color: Color) -> void:
	var scaled: PackedVector2Array = []
	var min_y := INF
	var max_y := -INF
	for p in points:
		scaled.append(p * _scale)
		min_y = minf(min_y, p.y * _scale)
		max_y = maxf(max_y, p.y * _scale)
	for y in range(int(min_y), int(max_y) + 1):
		var scan := y + 0.5
		var crossings: Array[float] = []
		for i in scaled.size():
			var a := scaled[i]
			var b := scaled[(i + 1) % scaled.size()]
			if (a.y <= scan) != (b.y <= scan):
				crossings.append(a.x + (scan - a.y) / (b.y - a.y) * (b.x - a.x))
		crossings.sort()
		for i in range(0, crossings.size() - 1, 2):
			var x0 := int(crossings[i])
			_image.fill_rect(Rect2i(x0, y, int(crossings[i + 1]) - x0 + 1, 1), color)
