class_name HeartSystem
extends Node

## 心烦值系统（SPEC 6.3，第一关）：3 点心烦值，归零 → LevelManager.fail(放弃文案)。
## 触发：碰传单阿姨 / 人流停留累计 2s / 被堵超时（人流重复计时即“被堵”）。

signal changed(current: int)

var current: int = 3
var _hud_label: Label = null

func _ready() -> void:
	var cur := get_tree().current_scene
	if cur != null:
		_hud_label = cur.find_child("UI_Hearts", true, false) as Label
	_refresh()

func take_damage(amount: int = 1) -> void:
	if current <= 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current)
	_refresh()
	if current <= 0:
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("fail", "你放弃了洪崖洞的旅程。但有些路，该走还是要走。")

func _refresh() -> void:
	if _hud_label != null:
		_hud_label.text = "♥".repeat(current)
