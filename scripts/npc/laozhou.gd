extends "res://scripts/npc/interactable.gd"

## 码头老周（第三关）：按 GameState 货物完整度触发 3 档验货对话，随后通关到 04。

const TIER_NODES := {
	"完好": "laozhou_good",
	"受损": "laozhou_damaged",
	"严重受损": "laozhou_bad",
}

func on_interact(_player: Node) -> void:
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds == null:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var tier := str(gs.call("get_result_tier"))
	var node_name: String = TIER_NODES.get(tier, "laozhou_good")
	ds.call("load_data", "res://assets/dialogue_level3.json")
	if not ds.is_connected("ended", _on_dialogue_ended):
		ds.connect("ended", _on_dialogue_ended)
	ds.call("start_dialogue", node_name)

func _on_dialogue_ended() -> void:
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null and ds.is_connected("ended", _on_dialogue_ended):
		ds.disconnect("ended", _on_dialogue_ended)
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null:
		lm.call("complete")
