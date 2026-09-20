extends SceneTree
## 剧情回归：第四关开场、护送启动、结局去向与跨关领悟记录。

var failed := 0

func _check(condition: bool, message: String) -> void:
	print("[%s] %s" % ["PASS" if condition else "FAIL", message])
	if not condition:
		failed += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false)
	var intro := current_scene.find_child("StoryIntroPanel", true, false)
	var follower := current_scene.find_child("GroupFollower", true, false)
	_check(intro != null and not bool(player.get("frozen")), "第四关：章节过场后出现非阻塞目标提示")
	await create_timer(2.5).timeout
	_check(not bool(player.get("frozen")) and bool(follower.get("_enabled")), "第四关：六人护送正式启动且不重复锁定操作")
	var members: Array = follower.get("followers")
	_check(members.size() == 6 and follower.get("_leader") == player, "第四关：六名群众和主角已绑定至护送组件")
	if not members.is_empty():
		var first := members[0] as Node2D
		var before := first.global_position.x
		player.global_position.x += 100.0
		await create_timer(0.55).timeout
		_check(first.global_position.x > before + 20.0, "第四关：主角移动后群众实际跟随")
		var warning := current_scene.find_child("BombWarning", true, false)
		if warning != null:
			warning.call("stop")
		Input.action_press("move_right")
		await create_timer(6.5).timeout
		Input.action_release("move_right")
		var tail := members[members.size() - 1] as Node2D
		_check(player.global_position.x - tail.global_position.x < 190.0, "第四关：持续行走时六人队伍不会被甩出镜头")
	var gs: Node = root.get_node_or_null("GameState")
	gs.call("reset_story")
	gs.call("record_insight", "labor", 720)
	gs.call("record_insight", "trust", "完好")
	gs.call("record_insight", "responsibility", true)
	_check(gs.get("insight_flags").size() == 3, "跨关剧情领悟被记录")
	_check(root.get_node("LevelManager").has_method("finish_story"), "结局返回标题页接口存在")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
