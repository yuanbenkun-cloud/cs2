extends "res://scripts/npc/interactable.gd"

## 观景台拍照点（第五关）：拍照/不拍二选一 → 结尾独白 → 重开第一关。

func on_interact(_player: Node) -> void:
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
		lm.call("travel_to", 1, "（五关走完，重新出发）")
