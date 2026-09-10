class_name PathMover
extends Node2D

## 路径移动（SPEC 8.1）：索道/航船沿 points 循环移动。

@export var points: Array[Vector2] = []
@export var speed: float = 40.0

var _i: int = 0

func _process(delta: float) -> void:
	if points.size() < 2:
		return
	var target: Vector2 = points[_i]
	global_position = global_position.move_toward(target, speed * delta)
	if global_position.distance_to(target) < 2.0:
		_i = (_i + 1) % points.size()
