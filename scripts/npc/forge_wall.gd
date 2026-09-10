extends "res://scripts/npc/interactable.gd"

## 岩壁（第二关）：交互目标。多块 ColorRect 逐轮变色/裂开；E 推进锻造状态机。

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
	# 每轮裂开一段（seg 索引随轮次隐藏）
	var seg := get_node_or_null("Seg%d" % (_rounds_shown * 2 - 1))
	if seg != null:
		seg.visible = false

func _toggle_overlay(nm: String, on: bool) -> void:
	var o := get_node_or_null(nm)
	if o != null:
		o.visible = on
