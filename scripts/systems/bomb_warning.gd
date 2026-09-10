class_name BombWarning
extends Node

## 轰炸预警（SPEC 6.6，第四关）：周期轰炸 —— 红色警示闪现 → 落点高亮 1.5s → 爆炸。
## 玩家或任一 NPC 在落点内 → fail()（存档点重来）。

var _cooldown: float = 5.0
var _active: bool = false
var _flash: ColorRect = null
var _marker: Node2D = null
var _marker_rect: ColorRect = null
var _warning_time: float = 1.5
var _warn_left: float = 0.0
var _pending_pos: Vector2 = Vector2.ZERO
var _phase: int = 0   # 0 空闲 / 1 预警 / 2 爆炸判定

func _ready() -> void:
	_active = true
	var cur := get_tree().current_scene
	if cur == null:
		return
	_flash = cur.find_child("UI_BombFlash", true, false) as ColorRect
	_marker = Node2D.new()
	_marker.name = "BombMarker"
	_marker_rect = ColorRect.new()
	_marker_rect.color = Color(1.0, 0.2, 0.2, 0.9)
	_marker_rect.size = Vector2(26, 6)
	_marker_rect.position = Vector2(-13, -3)
	_marker.add_child(_marker_rect)
	cur.add_child(_marker)
	_marker.visible = false

func _process(delta: float) -> void:
	if not _active:
		return
	match _phase:
		0:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_start_warning()
		1:
			_warn_left -= delta
			if _flash != null:
				_flash.modulate.a = 0.35 + 0.3 * sin(Time.get_ticks_msec() * 0.03)
			if _warn_left <= 0.0:
				_explode()
		2:
			_active = false

func _start_warning() -> void:
	var cur := get_tree().current_scene
	var player := cur.find_child("zhujue", true, false) as Node2D
	var base: float = 100.0 if player == null else player.global_position.x
	_pending_pos = Vector2(base + randf_range(80.0, 300.0), 226.0)
	_pending_pos.x = clampf(_pending_pos.x, 120.0, 1240.0)
	_phase = 1
	_warn_left = _warning_time
	_marker.visible = true
	_marker.global_position = _pending_pos
	_marker_rect.modulate.a = 1.0
	if _flash != null:
		_flash.visible = true
	_flash_alert()

func _flash_alert() -> void:
	if _flash != null:
		_flash.modulate.a = 0.6
		get_tree().create_timer(_warning_time).timeout.connect(func() -> void:
			if is_instance_valid(_flash):
				_flash.visible = false)

func _explode() -> void:
	_phase = 2
	_marker_rect.color = Color(1.0, 0.6, 0.2)
	if _flash != null:
		_flash.modulate.a = 0.0
	# 判定：玩家或任一 NPC 在爆炸半径内
	if _hit_anyone(_pending_pos, 34.0):
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("fail", "轰炸……有人因为你没能走出去。")
	_marker.visible = false
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		_active = true
		_phase = 0
		_cooldown = randf_range(6.0, 10.0))

func _hit_anyone(pos: Vector2, radius: float) -> bool:
	var cur := get_tree().current_scene
	if cur == null:
		return false
	var targets: Array[Node2D] = []
	var player := cur.find_child("zhujue", true, false) as Node2D
	if player != null:
		targets.append(player)
	var container := cur.find_child("NPC_Group", true, false)
	if container != null:
		for c in container.get_children():
			if c is Node2D:
				targets.append(c as Node2D)
	for t in targets:
		if t != null and t.global_position.distance_to(pos) < radius:
			return true
	return false