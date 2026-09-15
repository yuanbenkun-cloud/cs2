extends SceneTree
## 捕获第四关导弹下落与挡板布局。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(315, 200)
	await create_timer(0.9).timeout
	var intro := current_scene.find_child("StoryIntroLayer", true, false)
	if intro != null: intro.visible = false
	var bomb := current_scene.find_child("BombWarning", true, false)
	bomb.set("_pending_x", 315.0)
	bomb.call("_launch_missile")
	await create_timer(0.43).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://Build/Game/codex_bomb_shield_v1.png"))
	print("[CAPTURE] res://Build/Game/codex_bomb_shield_v1.png")
	quit()
