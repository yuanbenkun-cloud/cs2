extends CharacterBody2D
## 追赶阿姨：追逐玩家，贴近扣心烦值（有冷却），可被人群路障挡住。

const GRAVITY: float = 700.0
var speed: float = 112.0
var active: bool = false
var _player: Node = null
var _cd: float = 0.0

func activate(p: Node) -> void:
	active = true
	_player = p
	visible = true

func _physics_process(delta: float) -> void:
	if not active or _player == null or not is_instance_valid(_player):
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var dir := 1.0 if _player.global_position.x > global_position.x else -1.0
	velocity.x = dir * speed
	move_and_slide()
	_cd -= delta
	if _cd <= 0.0 and global_position.distance_to(_player.global_position) < 20.0:
		_cd = 1.2
		var cur := get_tree().current_scene
		if cur != null:
			var hs := cur.find_child("HeartSystem", true, false)
			if hs != null:
				hs.call("take_damage")
		if _player.has_method("knock"):
			_player.call("knock", -dir * 160.0)
