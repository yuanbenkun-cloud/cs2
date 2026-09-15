extends SceneTree
## 第四关剧情开场原生截图。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://Build/Game/codex_story_v2_level4_intro.png"))
	print("[CAPTURE] res://Build/Game/codex_story_v2_level4_intro.png")
	quit()
