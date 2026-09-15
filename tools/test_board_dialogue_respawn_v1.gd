extends SceneTree
## 复现：追逐中阅读终点木牌，失败重载后对话系统不能残留 active 状态。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await physics_frame
	var player := current_scene.find_child("zhujue", true, false)
	var flyer := current_scene.find_child("chuandanayi", true, false)
	var board := current_scene.find_child("diyiguan_mupai", true, false)
	var ds := root.get_node("DialogueSystem")
	current_scene.find_child("ChaseManager", true, false).call("begin")
	player.global_position = board.global_position + Vector2(-52, 30)
	await physics_frame
	await physics_frame
	_check((player.get("nearby") as Array).has(board), "追逐中木牌进入交互范围")
	_press_e()
	await process_frame
	_check(bool(ds.get("active")) and bool(player.get("frozen")), "木牌对话正常打开并冻结玩家")
	var before: Vector2 = flyer.global_position
	await create_timer(0.25).timeout
	_check(flyer.global_position.distance_to(before) < 0.1, "木牌对话期间追兵完全暂停")

	# 强制覆盖最坏情况：对话尚未结束时发生失败重载。
	root.get_node("LevelManager").call("respawn")
	await process_frame
	await process_frame
	await physics_frame
	_check(not bool(ds.get("active")), "重载前清理旧对话 active 状态")
	player = current_scene.find_child("zhujue", true, false)
	board = current_scene.find_child("diyiguan_mupai", true, false)
	player.global_position = board.global_position + Vector2(-52, 30)
	await physics_frame
	await physics_frame
	_press_e()
	await process_frame
	_check(bool(ds.get("active")), "重来后按 E 仍能重新打开木牌")
	_check(current_scene.find_child("DialoguePanel", true, false).visible, "重来后木牌对话框可见")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)

func _press_e() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	root.push_input(event)

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition
