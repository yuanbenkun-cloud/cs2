extends SceneTree
## 走完整玩家输入链：靠近阿姨、按 E、失败，并连续重来两次。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await physics_frame
	await _approach_and_interact("初次进入")
	await _finish_and_fail()
	await _approach_and_interact("第一次重来")
	await _finish_and_fail()
	await _approach_and_interact("第二次重来")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)

func _approach_and_interact(label: String) -> void:
	var player := current_scene.find_child("zhujue", true, false)
	var flyer := current_scene.find_child("chuandanayi", true, false)
	var ds := root.get_node("DialogueSystem")
	_check(player != null and flyer != null, "%s：玩家和阿姨存在" % label)
	player.global_position = flyer.global_position + Vector2(-64, 0)
	await physics_frame
	await physics_frame
	_check((player.get("nearby") as Array).has(flyer), "%s：阿姨进入玩家交互候选" % label)
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	root.push_input(key_event)
	await process_frame
	var panel := current_scene.find_child("DialoguePanel", true, false)
	_check(bool(ds.get("active")), "%s：按 E 启动阿姨对白" % label)
	_check(panel != null and panel.visible, "%s：对话框可见" % label)

func _finish_and_fail() -> void:
	var ds := root.get_node("DialogueSystem")
	ds.call("_finish")
	await process_frame
	var hearts := current_scene.find_child("HeartSystem", true, false)
	hearts.call("take_damage", 3)
	await create_timer(1.7, true, false, true).timeout
	await process_frame
	await physics_frame

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition
