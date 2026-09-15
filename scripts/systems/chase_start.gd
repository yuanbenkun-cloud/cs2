extends Area2D
## 防止玩家漏掉开场交互：越过阿姨时自动触发追逐。

var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used or not (body is CharacterBody2D and body.has_method("set_look_dir")):
		return
	_used = true
	var cm := get_tree().current_scene.find_child("ChaseManager", true, false)
	if cm != null:
		cm.call("begin")
