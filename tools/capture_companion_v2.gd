extends SceneTree
## 渝灯自动讲解与紧凑对话框视觉回归截图。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://Build/Game/codex_companion_auto_speech_v2.png")
	)
	print("[CAPTURE] res://Build/Game/codex_companion_auto_speech_v2.png")
	quit()
