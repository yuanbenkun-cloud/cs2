extends SceneTree
## 叙事系统冒烟测试：自动加载、序章可跳过、片尾场景和存档 API。

var _prologue_finished := false
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	_check(root.get_node_or_null("StoryDirector") != null, "StoryDirector 已自动加载")
	_check(root.get_node_or_null("GameState") != null, "GameState 已自动加载")
	var director := root.get_node_or_null("StoryDirector")
	if director != null:
		director.call("play_prologue", Callable(self, "_on_prologue_finished"))
		await process_frame
		_check(bool(director.get("busy")), "序章进入播放状态")
		director.set("_skip_all", true)
		await create_timer(1.5).timeout
		_check(_prologue_finished, "序章可跳过并安全回调")
		_check(not bool(director.get("busy")), "序章结束后释放控制")
		director.call("play_transition", "res://scenes/guanqia/02_ciqikou.tscn", 2, "测试时代转场")
		await create_timer(0.65).timeout
		director.set("_skip_all", true)
		await create_timer(3.0).timeout
		_check(current_scene != null and current_scene.scene_file_path.ends_with("02_ciqikou.tscn"), "时代转场完成场景切换")
		_check(not bool(director.get("busy")), "时代转场结束后释放控制")
	var gs := root.get_node_or_null("GameState")
	if gs != null:
		var snapshot := {
			"goods_integrity": gs.get("goods_integrity"),
			"insight_flags": (gs.get("insight_flags") as Dictionary).duplicate(true),
			"saved_level": gs.get("saved_level"),
			"highest_unlocked_level": gs.get("highest_unlocked_level"),
			"story_completed": gs.get("story_completed"),
			"ending_choice": gs.get("ending_choice"),
		}
		gs.call("begin_new_story")
		gs.call("save_progress", 3)
		_check(bool(gs.call("has_continue")) and int(gs.call("get_continue_level")) == 3, "自动存档可恢复到最近章节")
		gs.call("mark_story_complete", "photo")
		_check(not bool(gs.call("has_continue")) and str(gs.get("ending_choice")) == "photo", "通关后记录结局并关闭普通继续入口")
		for key in snapshot:
			gs.set(key, snapshot[key])
		gs.call("_save_story")
		gs.set("ending_choice", "photo")
		gs.set("insight_flags", {"labor": 700, "trust": "完好", "responsibility": true})
	var err := change_scene_to_file("res://scenes/jieju.tscn")
	_check(err == OK, "片尾场景可切换")
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.name == "EndingScene", "片尾场景已实例化")
	_check(current_scene != null and current_scene.find_child("EndingContent", true, false) != null, "片尾内容已构建")
	_check(current_scene != null and current_scene.find_child("Credits", true, false) != null, "制作人员页已构建")
	print("[RESULT] " + ("PASS" if _failed == 0 else "FAIL"))
	quit(0 if _failed == 0 else 1)

func _on_prologue_finished() -> void:
	_prologue_finished = true

func _check(ok: bool, label: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + label)
	if not ok:
		_failed += 1
