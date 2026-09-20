extends SceneTree
## 实时时间戳与临时爆炸照明视觉回归。

func _init() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false)
	if player != null and player.has_method("freeze"):
		player.call("freeze", true)
	var bomb := current_scene.find_child("BombWarning", true, false)
	bomb.call("_spawn_explosion", Vector2(325, 220), false)
	await create_timer(0.10).timeout
	await _capture("res://Build/Game/codex_bomb_grounded_contact_v3.png")
	await create_timer(1.0).timeout
	print("[PASS] 临时爆炸反馈已清除" if current_scene.find_child("ExplosionFeedback", true, false) == null else "[FAIL] 爆炸反馈残留")

	root.get_node("DialogueSystem").call("cancel_for_scene_change")
	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await process_frame
	await process_frame
	var ds := root.get_node("DialogueSystem")
	ds.call("load_data", "res://assets/dialogue_level5.json")
	ds.call("start_dialogue", "photo")
	ds.call("_on_advance")
	ds.call("_on_advance")
	ds.call("choose", 0)
	await create_timer(0.45).timeout
	await _capture("res://Build/Game/codex_photo_realtime_timestamp_v1.png")
	quit()
