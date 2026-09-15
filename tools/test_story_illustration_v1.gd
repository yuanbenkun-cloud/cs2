extends SceneTree
## 第二关剧情插画触发、暂停与释放控制回归。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var trigger := current_scene.find_child("WallStoryTrigger", true, false)
	var player := current_scene.find_child("zhujue", true, false)
	var forge := current_scene.find_child("ForgeSequence", true, false)
	_check(trigger != null and trigger.get("illustration") != null, "第二关已配置剧情插画")
	var before: float = float(forge.get("time_left"))
	trigger.call("_on_body_entered", player)
	await create_timer(0.2).timeout
	_check(current_scene.find_child("StoryIllustration", true, false) != null, "接近石壁前显示插画过场")
	_check(bool(forge.get("_story_paused")), "插画期间暂停锻造倒计时")
	await create_timer(0.25).timeout
	_check(absf(float(forge.get("time_left")) - before) < 0.05, "观看插画不会损失关卡时间")
	trigger.set("_can_close_at", 0)
	trigger.call("_close")
	await create_timer(0.4).timeout
	_check(not bool(forge.get("_story_paused")), "插画结束后恢复关卡计时")
	_check(current_scene.find_child("StoryIllustration", true, false) == null, "插画层已安全释放")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

