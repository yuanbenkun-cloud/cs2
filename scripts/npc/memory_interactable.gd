extends "res://scripts/npc/interactable.gd"
## 第五关记忆交互：对话结束后点亮一块记忆拼图。

@export var dialogue_file := "res://assets/dialogue_level5.json"
@export var dialogue_node := ""
@export var memory_id := ""
var _completed := false

func on_interact(_player: Node) -> void:
	if _completed:
		return
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds == null: return
	if not ds.is_connected("ended", _on_ended):
		ds.connect("ended", _on_ended)
	ds.call("load_data", dialogue_file)
	ds.call("start_dialogue", dialogue_node)

func _on_ended() -> void:
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null and ds.is_connected("ended", _on_ended):
		ds.disconnect("ended", _on_ended)
	var route := get_tree().current_scene.find_child("MemoryRoute", true, false)
	if route != null:
		route.call("collect", memory_id)
	_completed = true
	# 完成回忆后保持人物原色；旧的淡黄色乘色会让最终关的阿姨看起来半透明。
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	var visual := find_child("SkinAnim", true, false) as CanvasItem
	if visual != null:
		visual.modulate = Color.WHITE
		visual.self_modulate = Color.WHITE
	disable_interaction()
