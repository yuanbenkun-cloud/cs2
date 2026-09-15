class_name LooseTile
extends Area2D

## 松动地砖（第一关）：踩到 → 穿越转场到第 2 关（只触发一次）。

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body is CharacterBody2D and body.has_method("set_look_dir"):
		_triggered = true
		var cm := get_tree().current_scene.find_child("ChaseManager", true, false)
		if cm != null and cm.has_method("finish"):
			cm.call("finish")
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("travel_to", 2, "脚下一空。霓虹沉入江水，百年前的窑火迎面亮起。")
