class_name ChoiceSystem
extends Node

## 选择系统（SPEC Phase 5）：选项 → 回调 → 写 GameState。
## 实际分支由 DialogueSystem + JSON 的 options/goods_event 驱动；本组件提供集中入口。

func apply_event(name: String) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("apply_goods_event", name)

func tier() -> String:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return "完好"
	return str(gs.call("get_result_tier"))
