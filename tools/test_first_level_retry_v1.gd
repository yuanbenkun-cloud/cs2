extends SceneTree
## 第一关失败后必须从街口完整重开，不能恢复到追逐触发器之后。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var lm := root.get_node("LevelManager")
	var old_scene := current_scene
	var old_player := old_scene.find_child("zhujue", true, false) as Node2D
	var old_flyer := old_scene.find_child("chuandanayi", true, false) as Node2D
	_check(old_player != null and old_flyer != null, "第一关初始存在玩家和传单阿姨")
	lm.call("register_checkpoint", Vector2(140, old_player.global_position.y))
	lm.call("respawn")
	await process_frame
	await process_frame
	await process_frame
	var new_player := current_scene.find_child("zhujue", true, false) as Node2D
	var new_flyer := current_scene.find_child("chuandanayi", true, false) as Node2D
	_check(new_player != null and new_flyer != null, "失败重载后传单阿姨重新生成")
	_check(new_player != null and new_player.global_position.x < -500.0, "失败后回到街口而不是越过追逐触发器")
	var chase_start := current_scene.find_child("ChaseStart", true, false)
	_check(chase_start != null and not bool(chase_start.get("_used")), "新的追逐触发器处于可用状态")
	if chase_start != null and new_player != null:
		chase_start.call("_on_body_entered", new_player)
	await process_frame
	_check(new_flyer != null and bool(new_flyer.get("_started")), "重来后追逐仍能正常启动")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition
