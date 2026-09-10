class_name ExitPortal
extends Area2D

## 关底出口（04→05 等）：玩家到达即通关（队伍跟在身后）。

var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used:
		return
	if body is CharacterBody2D and body.has_method("set_look_dir"):
		_used = true
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("complete")
