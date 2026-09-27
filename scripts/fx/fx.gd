class_name Fx
extends RefCounted
## Small reusable visual effects built from code, so they need no assets.


## One-shot particle burst that frees itself when done.
static func burst(parent: Node, pos: Vector2, color: Color, amount := 16, speed := 260.0) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.z_index = 15
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.6
	particles.direction = Vector2.UP
	particles.spread = 80.0
	particles.gravity = Vector2(0.0, 900.0)
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = color
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = fade
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


## Scales a node in from nothing with a slight overshoot.
static func pop_in(node: Node2D, duration := 0.25) -> void:
	node.scale = Vector2(0.2, 0.2)
	node.create_tween().tween_property(node, "scale", Vector2.ONE, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Squashes or stretches a node, then springs back.
static func squash(node: Node2D, amount: Vector2, duration := 0.2) -> void:
	node.scale = amount
	node.create_tween().tween_property(node, "scale", Vector2.ONE, duration) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
