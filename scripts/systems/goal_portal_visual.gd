class_name GoalPortalVisual
extends Node2D
## 统一关卡终点门：贴地的椭圆能量门，可由关卡目标完成后激活。

@export var active := true
var _phase := 0.0
var _energy := 1.0

func _ready() -> void:
	z_index = 24
	set_active(active, false)

func _process(delta: float) -> void:
	if not visible:
		return
	_phase += delta * 2.5
	queue_redraw()

func activate() -> void:
	set_active(true, true)

func set_active(value: bool, animate: bool = true) -> void:
	active = value
	if not value:
		visible = false
		_energy = 0.0
		return
	visible = true
	if animate:
		_energy = 0.0
		scale = Vector2(0.08, 0.35)
		modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 1.0, 0.22)
		tween.tween_method(_set_energy, 0.0, 1.0, 0.34)
	else:
		_energy = 1.0
		scale = Vector2.ONE
		modulate.a = 1.0
	queue_redraw()

func _set_energy(value: float) -> void:
	_energy = value
	queue_redraw()

func _draw() -> void:
	var center := Vector2(0, -38)
	draw_colored_polygon(_ellipse(center, 21, 36, 44, 0.0), Color(0.015, 0.025, 0.08, 0.9 * _energy))
	for ring_index in range(3):
		var points := _ellipse(center, 24.0 + ring_index * 3.2, 40.0 + ring_index * 4.0, 48, _phase * (1.0 if ring_index % 2 == 0 else -0.8) + ring_index)
		points.append(points[0])
		draw_polyline(points, Color(0.35 + ring_index * 0.1, 0.72, 1.0, (0.9 - ring_index * 0.16) * _energy), 2.3 - ring_index * 0.35, true)
	for spark_index in range(10):
		var angle := _phase * 0.8 + float(spark_index) * TAU / 10.0
		var radius := 29.0 + sin(_phase * 1.8 + spark_index) * 4.0
		var point := center + Vector2(cos(angle) * radius, sin(angle) * radius * 1.5)
		draw_circle(point, 1.0, Color(0.58, 0.88, 1.0, 0.8 * _energy))
	# 接触光压在地面线上，避免传送门浮空。
	draw_arc(Vector2.ZERO, 24.0, PI, TAU, 30, Color(0.42, 0.8, 1.0, 0.62 * _energy), 2.2, true)

func _ellipse(center: Vector2, radius_x: float, radius_y: float, segments: int, wobble_phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := float(i) * TAU / float(segments)
		var wobble := 1.0 + sin(angle * 5.0 + wobble_phase) * 0.025
		points.append(center + Vector2(cos(angle) * radius_x * wobble, sin(angle) * radius_y * wobble))
	return points
