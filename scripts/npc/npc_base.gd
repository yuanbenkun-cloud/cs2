extends "res://scripts/npc/interactable.gd"

## NPC 基类：交互触发对话（通过导出字段指定对话文件与节点）。
## （headless 下无全局类缓存，因此用路径 extends Interactable）

@export var dialogue_file: String = ""
@export var dialogue_node: String = ""
var _completed := false

func on_interact(_player: Node) -> void:
	if _completed or dialogue_file == "" or dialogue_node == "":
		return
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null:
		set_meta("talking", true)
		if not ds.is_connected("ended", _on_dialogue_ended):
			ds.connect("ended", _on_dialogue_ended)
		ds.call("load_data", dialogue_file)
		ds.call("start_dialogue", dialogue_node)

func _on_dialogue_ended() -> void:
	set_meta("talking", false)
	_completed = true
	disable_interaction()
	var ds := get_node_or_null("/root/DialogueSystem")
	if ds != null and ds.is_connected("ended", _on_dialogue_ended):
		ds.disconnect("ended", _on_dialogue_ended)
