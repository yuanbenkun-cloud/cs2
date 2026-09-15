class_name ArrivalPortal
extends Node2D

## 场景内的时空门：玩家从门中走出后，门体坍缩并消失。

var _phase := 0.0
var _energy := 0.0

func _ready() -> void:
	z_index = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	scale = Vector2(0.06, 0.22)
	modulate.a = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta * 2.8
	queue_redraw()

func play_arrival(player: Node2D) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	var destination := player.global_position
	var original_modulate := player.modulate
	global_position = destination - Vector2(38.0, 0.0)
	player.global_position = global_position + Vector2(3.0, 0.0)
	player.modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.0)

	var opening := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	opening.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	opening.tween_property(self, "scale", Vector2.ONE, 0.30)
	opening.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	opening.parallel().tween_method(_set_energy, 0.0, 1.0, 0.30)
	await opening.finished

	var emerge := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	emerge.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	emerge.tween_property(player, "modulate:a", original_modulate.a, 0.16)
	emerge.parallel().tween_property(player, "global_position", destination, 0.48)
	await emerge.finished

	var closing := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	closing.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	closing.tween_property(self, "scale", Vector2(0.035, 1.14), 0.28)
	closing.parallel().tween_property(self, "modulate:a", 0.0, 0.26)
	closing.parallel().tween_method(_set_energy, 1.0, 0.0, 0.28)
	await closing.finished
	player.global_position = destination
	player.modulate = original_modulate
	queue_free()

func _set_energy(value: float) -> void:
	_energy = value
	queue_redraw()

func _draw() -> void:
	var center := Vector2(0.0, -37.0)
	var core := _ellipse(center, 20.0, 35.0, 40, 0.05)
	draw_colored_polygon(core, Color(0.015, 0.025, 0.08, 0.86 * _energy))
	for ring_index in range(3):
		var ring_phase := _phase * (1.0 if ring_index % 2 == 0 else -0.8) + float(ring_index) * 1.7
		var points := _ellipse(center, 23.0 + ring_index * 3.2, 39.0 + ring_index * 4.0, 48, ring_phase)
		points.append(points[0])
		var color := Color(0.32 + ring_index * 0.12, 0.68 + ring_index * 0.07, 1.0, (0.88 - ring_index * 0.16) * _energy)
		draw_polyline(points, color, 2.2 - ring_index * 0.35, true)
	for spark_index in range(9):
		var angle := _phase * (0.7 + spark_index * 0.025) + float(spark_index) * TAU / 9.0
		var radius := 28.0 + sin(_phase * 1.9 + spark_index) * 4.0
		var point := center + Vector2(cos(angle) * radius, sin(angle) * radius * 1.55)
		draw_circle(point, 0.8 + float(spark_index % 3) * 0.35, Color(0.55, 0.86, 1.0, 0.76 * _energy))
	# 门脚嵌入地面，留下接触光，避免“悬空特效”。
	draw_arc(Vector2(0.0, 0.0), 23.0, PI, TAU, 30, Color(0.42, 0.78, 1.0, 0.55 * _energy), 2.0, true)

func _ellipse(center: Vector2, radius_x: float, radius_y: float, segments: int, wobble_phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := float(i) * TAU / float(segments)
		var wobble := 1.0 + sin(angle * 5.0 + wobble_phase) * 0.025
		points.append(center + Vector2(cos(angle) * radius_x * wobble, sin(angle) * radius_y * wobble))
	return points
