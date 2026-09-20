class_name LockedExitPortal
extends Area2D
## 第二、三关目标完成后开启；玩家进入才正式切换下一关。

@export var starts_active := false
var _active := false
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(starts_active)

func activate() -> void:
	set_active(true)

func set_active(value: bool) -> void:
	_active = value
	# 第一关石扣会在 body_entered 中激活本门，碰撞状态必须延迟修改。
	set_deferred("monitoring", value)
	set_deferred("monitorable", value)
	var visual := get_node_or_null("GoalPortalVisual")
	if visual != null:
		if value and visual.has_method("activate"):
			visual.call("activate")
		else:
			visual.call("set_active", false, false)

func _on_body_entered(body: Node) -> void:
	if not _active or _used:
		return
	if body is CharacterBody2D and body.has_method("set_look_dir"):
		_used = true
		body.call("freeze", true)
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("complete")
