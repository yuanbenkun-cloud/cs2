class_name LightRig
extends Node2D

## 时代色调灯组（SPEC 6.7 / Phase 8）：CanvasModulate 全局色调 + 点光源组。
## builder 已放入 CanvasModulate 与点光源子节点；本脚本提供运行时接口。

func set_tone(global_color: Color, _global_energy: float) -> void:
	var cm := get_node_or_null("CanvasModulate")
	if cm != null:
		cm.color = global_color

func add_point_light(pos: Vector2, color: Color, energy: float, radius: float) -> PointLight2D:
	var p := PointLight2D.new()
	p.position = pos
	p.color = color
	p.energy = energy
	p.texture_scale = radius / 32.0
	add_child(p)
	return p
