extends Node
## 第一关追逐战：阿姨对话后触发，多名 chaseayi 开始追赶玩家。

var chasing: bool = false
var _chasers: Array[Node] = []
var _player: Node = null

func _ready() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	_player = cur.find_child("zhujue", true, false)
	for c in cur.get_children():
		if str(c.name).begins_with("chaseayi"):
			_chasers.append(c)

func begin() -> void:
	if chasing:
		return
	chasing = true
	for c in _chasers:
		if c != null and c.has_method("activate"):
			c.call("activate", _player)
	var cur := get_tree().current_scene
	if cur != null:
		var n := cur.find_child("UI_Notice", true, false) as Label
		if n != null:
			n.text = "“扫码关注一下吧……怎么跑了？”——快跑！"
			n.visible = true
			get_tree().create_timer(3.0).timeout.connect(func() -> void:
				if is_instance_valid(n):
					n.visible = false)
