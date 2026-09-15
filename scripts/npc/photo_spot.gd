extends "res://scripts/npc/interactable.gd"

## 观景台拍照点（第五关）：拍照/不拍二选一 → 完整结局 → 返回标题页。

func on_interact(_player: Node) -> void:
	var route := get_tree().current_scene.find_child("MemoryRoute", true, false)
	if route != null and not bool(route.call("can_finish")):
		route.call("show_missing")
		return
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds == null:
		return
	ds.call("load_data", "res://assets/dialogue_level5.json")
	if not ds.is_connected("ended", _on_ended):
		ds.connect("ended", _on_ended)
	ds.call("start_dialogue", "photo")

func _on_ended() -> void:
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null and ds.is_connected("ended", _on_ended):
		ds.disconnect("ended", _on_ended)
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null:
		var choice := "photo" if ds != null and str(ds.get("last_choice_next")) == "photo_take" else "observe"
		lm.call("finish_story", choice)
