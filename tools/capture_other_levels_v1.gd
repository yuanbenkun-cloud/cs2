extends SceneTree
## 第三、第五关新玩法 HUD 视觉回归。

func _init() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await process_frame
	await process_frame
	var trade := current_scene.find_child("ChoiceSystem", true, false)
	trade.call("advance_stage", 1)
	root.get_node("GameState").call("apply_goods_event", "stolen")
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_level3_trade_route_v1.png")

	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await process_frame
	await process_frame
	var memory := current_scene.find_child("MemoryRoute", true, false)
	memory.call("collect", "board")
	memory.call("collect", "old_man")
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_level5_memory_route_v1.png")
	quit()
