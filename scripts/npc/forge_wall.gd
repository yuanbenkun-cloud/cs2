extends "res://scripts/npc/interactable.gd"

## 岩壁（第二关）：E 开始移动条锻造；火/水覆盖与三道裂纹反馈结果。

var _rounds_shown: int = 0

func on_interact(_player: Node) -> void:
	var fs := get_tree().current_scene.find_child("ForgeSequence", true, false)
	if fs != null:
		fs.call("advance")

func mark_heat() -> void:
	_toggle_overlay("OverlayHeat", true)
	_toggle_overlay("OverlayQuench", false)

func mark_quench() -> void:
	_toggle_overlay("OverlayQuench", true)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_toggle_overlay("OverlayQuench", false))

func crack() -> void:
	_rounds_shown += 1
	var crack_line := get_node_or_null("Crack%d" % _rounds_shown)
	if crack_line != null:
		crack_line.visible = true
		crack_line.modulate.a = 0.0
		create_tween().tween_property(crack_line, "modulate:a", 1.0, 0.18)
	_toggle_overlay("OverlayHeat", false)

func celebrate_breakthrough() -> void:
	set_prompt_visible(false)
	# 裂纹是独立的 Line2D，不能只淡出 WallVisual，否则墙消失后会留下发光条纹。
	for crack_line in find_children("Crack*", "Line2D", false, false):
		(crack_line as Line2D).visible = false
	_toggle_overlay("OverlayHeat", false)
	_toggle_overlay("OverlayQuench", false)
	for shape in find_children("*", "CollisionShape2D", true, false):
		(shape as CollisionShape2D).set_deferred("disabled", true)
	var scene := get_tree().current_scene
	if scene != null:
		var blocking_wall := scene.find_child("di_erguan_yanbi_qiangti", true, false)
		if blocking_wall != null:
			for shape in blocking_wall.find_children("*", "CollisionShape2D", true, false):
				(shape as CollisionShape2D).set_deferred("disabled", true)
	var wall := get_node_or_null("WallVisual") as CanvasItem
	if wall != null:
		var tween := create_tween()
		tween.tween_property(wall, "scale", Vector2(0.54, 0.46), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(wall, "position:y", 22.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(wall, "modulate:a", 0.0, 0.55)
	_spawn_break_dust()

func _spawn_break_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.name = "BreakthroughDust"
	dust.position = Vector2(0, -42)
	dust.amount = 28
	dust.lifetime = 1.15
	dust.one_shot = true
	dust.explosiveness = 0.92
	dust.direction = Vector2(0, -1)
	dust.spread = 78.0
	dust.gravity = Vector2(0, 86)
	dust.initial_velocity_min = 42.0
	dust.initial_velocity_max = 105.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 5.5
	dust.color = Color(0.68, 0.58, 0.45, 0.82)
	add_child(dust)
	dust.emitting = true
	get_tree().create_timer(1.5).timeout.connect(dust.queue_free)

func _toggle_overlay(nm: String, on: bool) -> void:
	var o := get_node_or_null(nm)
	if o != null:
		o.visible = on
