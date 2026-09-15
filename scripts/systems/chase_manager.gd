extends Node
## 第一关追逐战导演：单一主追兵、距离压力 HUD、动态路人节奏点。

var chasing: bool = false
var _chaser: Node = null
var _player: Node = null
var _hud: Label = null

func _ready() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		cur = get_parent()
	_player = cur.find_child("zhujue", true, false)
	_chaser = cur.find_child("chuandanayi", true, false)
	_hud = cur.find_child("UI_Chase", true, false) as Label

func _process(_delta: float) -> void:
	if not chasing or not is_instance_valid(_player) or not is_instance_valid(_chaser):
		return
	var gap: float = maxf(_player.global_position.x - _chaser.global_position.x, 0.0)
	var danger := clampf(1.0 - gap / 250.0, 0.0, 1.0)
	var filled := int(round(danger * 8.0))
	if _hud != null:
		_hud.text = "追逐  %s%s" % ["▰".repeat(filled), "▱".repeat(8 - filled)]
		_hud.add_theme_color_override("font_color", Color("#ff6464") if danger > 0.68 else Color("#ffd27a"))

func begin() -> void:
	if chasing:
		return
	chasing = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "alert", 1.08, -3.0)
	if _chaser != null and _chaser.has_method("activate"):
		_chaser.call("activate", _player)
	if _hud != null:
		_hud.visible = true
	var cur := get_tree().current_scene
	if cur != null:
		var n := cur.find_child("UI_Notice", true, false) as Label
		if n != null:
			n.text = "“扫码关注一下吧……怎么跑了？”——快跑！"
			n.visible = true
			# 计时器跟随提示节点销毁，失败重载时不会留下捕获旧场景节点的回调。
			var hide_timer := Timer.new()
			hide_timer.one_shot = true
			hide_timer.wait_time = 3.0
			n.add_child(hide_timer)
			hide_timer.timeout.connect(func() -> void:
				if is_instance_valid(n):
					n.visible = false)
			hide_timer.start()

func finish() -> void:
	chasing = false
	if _hud != null:
		_hud.visible = false
