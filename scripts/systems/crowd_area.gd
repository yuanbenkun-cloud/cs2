class_name CrowdArea
extends Area2D

## 人流区（第一关）：玩家停留累计 2 秒 -1；在掩体（组 covers）内则免受伤害。

const TICK_TIME: float = 2.0
var _acc: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_inside_tree():
		return
	_acc += delta
	if _acc >= TICK_TIME:
		_acc = 0.0
		if not _protected():
			var cur := get_tree().current_scene
			if cur != null:
				var hs := cur.find_child("HeartSystem", true, false)
				if hs != null:
					hs.call("take_damage")

func _on_enter(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("set_look_dir"):
		_player = body as Node2D

func _on_exit(body: Node) -> void:
	if body == _player:
		_player = null
		_acc = 0.0

func _protected() -> bool:
	if _player == null:
		return false
	for cov in get_tree().get_nodes_in_group("covers"):
		if cov is Area2D and (cov as Area2D).get_overlapping_bodies().has(_player):
			return true
	return false
