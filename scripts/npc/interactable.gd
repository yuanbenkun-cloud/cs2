class_name Interactable
extends Area2D

## 交互物基类（SPEC Phase 1 / 4.4）：Area2D + 提示圈。
## 子类覆盖 on_interact(player)。玩家靠近显示 Prompt，按 E 触发。

func _prompt() -> Node:
	for c in get_children():
		var nm := str(c.name)
		if nm == "Prompt" or nm.ends_with("_tishi"):
			return c
	return null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var pp := _prompt()
	if pp != null:
		pp.visible = false

func on_interact(_player: Node) -> void:
	pass

## 用鸭子类型判断主角（不依赖全局类缓存；headless --script 场景下类缓存可能缺失）
func _is_player(body: Node) -> bool:
	return body is CharacterBody2D and body.has_method("set_look_dir")

func _on_body_entered(body: Node) -> void:
	if _is_player(body):
		var pp := _prompt()
		if pp != null:
			pp.visible = true

func _on_body_exited(body: Node) -> void:
	if _is_player(body):
		var pp := _prompt()
		if pp != null:
			pp.visible = false