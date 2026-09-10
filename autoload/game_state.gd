extends Node
## GameState（全局单例）：跨关数据（货物完整度、历史领悟等）。SPEC Phase 5。

var goods_integrity: int = 100
var insight_flags: Dictionary = {}   # 历史领悟（第五关等使用）

func reset_goods() -> void:
	goods_integrity = 100

func apply_goods_event(name: String) -> void:
	## stolen -30 / cheated -30 / robbed -40 / safe 0
	match name:
		"stolen":
			goods_integrity -= 30
		"cheated":
			goods_integrity -= 30
		"robbed":
			goods_integrity -= 40
		_:
			pass  # safe / 空
	goods_integrity = clampi(goods_integrity, 0, 100)

func get_result_tier() -> String:
	## ≥70 完好 / 40-69 受损 / <40 严重受损
	if goods_integrity >= 70:
		return "完好"
	if goods_integrity >= 40:
		return "受损"
	return "严重受损"
