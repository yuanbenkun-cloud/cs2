extends "res://scripts/npc/interactable.gd"
## 传单阿姨（第一关开场）：对话后触发追逐战（ChaseManager.begin）。

var _started: bool = false

func on_interact(_player: Node) -> void:
	if _started:
		return
	_started = true
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds == null:
		return
	ds.call("load_data", "res://assets/dialogue_level1.json")
	if not ds.is_connected("ended", _on_ended):
		ds.connect("ended", _on_ended)
	ds.call("start_dialogue", "flyer_lady")

func _on_ended() -> void:
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null and ds.is_connected("ended", _on_ended):
		ds.disconnect("ended", _on_ended)
	var cur := get_tree().current_scene
	if cur != null:
		var cm := cur.find_child("ChaseManager", true, false)
		if cm != null:
			cm.call("begin")
