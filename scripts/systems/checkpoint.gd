class_name Checkpoint
extends Area2D

## 存档点（SPEC Phase 1/6）：玩家触碰 → LevelManager.register_checkpoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("set_look_dir"):
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("register_checkpoint", global_position)
