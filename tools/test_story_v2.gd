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
	var gs: Node = root.get_node_or_null("GameState")
	gs.call("reset_story")
	gs.call("record_insight", "labor", 720)
	gs.call("record_insight", "trust", "完好")
	gs.call("record_insight", "responsibility", true)
	_check(gs.get("insight_flags").size() == 3, "跨关剧情领悟被记录")
	_check(root.get_node("LevelManager").has_method("finish_story"), "结局返回标题页接口存在")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
