extends SceneTree
## 模拟跨关时「新场景已进入树，但 current_scene 仍指向旧关」的装配顺序。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await process_frame
	await process_frame
	var next_level := (load("res://scenes/guanqia/04_fangdong.tscn") as PackedScene).instantiate()
	root.add_child(next_level)
	var follower := next_level.find_child("GroupFollower", true, false)
	var player := next_level.find_child("zhujue", true, false)
	_check(follower != null and follower.get("_leader") == player, "第四关跟随组件绑定新关主角，而非当前旧场景")
	_check(follower != null and (follower.get("followers") as Array).size() == 6, "第四关跟随组件绑定全部六名群众")
	next_level.queue_free()
	await process_frame
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
