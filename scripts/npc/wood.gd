extends "res://scripts/npc/interactable.gd"

## 大木头（第二关）：主角抬不动（freeze + 减速模拟）+ 提示文本。

func on_interact(player: Node) -> void:
	if player != null and player.has_method("freeze"):
		player.call("freeze", true)
	var cur := get_tree().current_scene
	if cur != null:
		var n := cur.find_child("UI_Notice", true, false) as Label
		if n != null:
			n.text = "太重了，根本抬不动……（陈默的手在发抖）"
			n.visible = true
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(player) and player.has_method("freeze"):
		player.call("freeze", false)
	if cur != null:
		var n := cur.find_child("UI_Notice", true, false) as Label
		if n != null:
			n.visible = false
