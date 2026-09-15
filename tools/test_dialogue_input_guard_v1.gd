extends SceneTree
## 对话 E 键去串键：一次按下只能“补全文字”或“进入下一句”其中之一。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var ds := root.get_node("DialogueSystem")
	ds.call("load_data", "res://assets/dialogue_level1.json")
	ds.call("start_dialogue", "test_npc")
	var panel := current_scene.find_child("DialoguePanel", true, false)
	_check(panel != null and bool(panel.get("_typing")), "第一句开始打字")

	panel.set("_input_guard_until", 0)
	var queue_before: int = (ds.get("_queue") as Array).size()
	_check(bool(panel.call("_consume_advance_press")), "第一次按 E 只补全当前句")
	_check(not bool(panel.get("_typing")) and bool(panel.get("_waiting")), "补全后停在当前句等待")
	_check((ds.get("_queue") as Array).size() == queue_before, "补全文字没有顺带推进下一句")
	_check(not bool(panel.call("_consume_advance_press")), "同一保护期内的重复输入被拦截")
	_check((ds.get("_queue") as Array).size() == queue_before, "同一次按下最多消费一个状态")

	panel.set("_input_guard_until", 0)
	_check(bool(panel.call("_consume_advance_press")), "松开并重新按下后进入下一句")
	_check(bool(ds.get("active")) and bool(panel.get("_typing")), "下一句正常打字且不会被同次输入跳过")
	_check(not bool(panel.call("_consume_advance_press")), "新句的短保护期继续拦截串键")
	panel.set("_input_guard_until", 0)
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	root.push_input(key_event)
	await process_frame
	_check(not bool(panel.get("_typing")) and bool(panel.get("_waiting")), "真实 E 键事件会立即补全当前句")
	ds.call("_finish")

	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var npc := current_scene.find_child("laojiangren", true, false) as Area2D
	var player := current_scene.find_child("zhujue", true, false)
	player.call("_on_zone_entered", npc)
	npc.call("on_interact", player)
	_check(bool(ds.get("active")), "普通 NPC 对话可以正常开始")
	ds.call("_finish")
	await process_frame
	_check(not bool(npc.call("is_interaction_available")), "普通 NPC 对话结束后关闭交互")
	_check(not (player.get("nearby") as Array).has(npc), "已完成 NPC 从玩家交互候选中移除")
	npc.call("on_interact", player)
	_check(not bool(ds.get("active")), "连续按 E 不会重新开始同一段对话")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition
