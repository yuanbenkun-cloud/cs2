extends SceneTree
## 第一/二关增强与第三/五关重构回归。

var failed := 0
func _check(condition: bool, message: String) -> void:
	print("[%s] %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failed += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var forge := current_scene.find_child("ForgeSequence", true, false)
	var speed_round_1: float = forge.call("_current_speed")
	var width_round_1: float = forge.call("_current_width")
	forge.set("current_round", 2)
	_check(float(forge.call("_current_speed")) > speed_round_1 and float(forge.call("_current_width")) < width_round_1, "第二关：后续轮次加速并缩窄判定区")

	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await process_frame
	await process_frame
	var trade := current_scene.find_child("ChoiceSystem", true, false)
	var laozhou := current_scene.find_child("laozhou", true, false)
	laozhou.call("on_interact", current_scene.find_child("zhujue", true, false))
	_check(int(trade.get("stage")) == 0 and not bool(root.get_node("DialogueSystem").get("active")), "第三关：不能跳过护货路线直接交货")
	trade.call("advance_stage", 1)
	root.get_node("GameState").call("reset_goods")
	root.get_node("GameState").call("apply_goods_event", "stolen")
	await process_frame
	var cargo_bar := current_scene.find_child("UI_CargoIntegrity", true, false) as ProgressBar
	_check(int(cargo_bar.value) == 70, "第三关：货损即时同步到完整度 HUD")
	trade.call("advance_stage", 3)
	_check(bool(trade.call("can_use", 3)), "第三关：完成前置节点后解锁老周")

	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await process_frame
	await process_frame
	var memory := current_scene.find_child("MemoryRoute", true, false)
	var photo := current_scene.find_child("diwuguan_zhaoxiangdian", true, false)
	photo.call("on_interact", current_scene.find_child("zhujue", true, false))
	_check(not bool(root.get_node("DialogueSystem").get("active")), "第五关：记忆未集齐时观景台保持锁定")
	for memory_id in ["board", "old_man", "flyer", "view"]:
		memory.call("collect", memory_id)
	_check(bool(memory.call("can_finish")), "第五关：四段城市记忆全部点亮后解锁结局")
	var memory_label := current_scene.find_child("UI_MemoryProgress", true, false) as Label
	_check(memory_label.text.contains("4/4"), "第五关：记忆 HUD 显示完整进度")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
