extends SceneTree
## 第二关剧情插画原生 640×360 截图。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var trigger := current_scene.find_child("WallStoryTrigger", true, false)
	var player := current_scene.find_child("zhujue", true, false)
	trigger.call("_on_body_entered", player)
	await create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://Build/Game/codex_story_illustration_level2.png")
	image.save_png(path)
	print("[CAPTURE] " + path)
	quit()
