extends SceneTree
## 开始界面视觉回归截图。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/kaishi.tscn")
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	var wash := current_scene.find_child("CinematicWash", true, false) as ColorRect
	var bg := current_scene.find_child("NightBackdrop", true, false) as TextureRect
	var valid := wash != null and bg != null and wash.color.a <= 0.41 and wash.color.a >= 0.35
	print("[PASS] 开始界面背景遮罩已减淡" if valid else "[FAIL] 开始界面背景遮罩异常")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://Build/Game/codex_start_wash_lighter.png"))
	quit(0 if valid else 1)
