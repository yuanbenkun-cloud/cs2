extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _capture(output: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	print("[CAPTURE] " + output)

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(510.0, 240.0)
	if player.has_method("freeze"):
		player.call("freeze", true)
	await create_timer(0.2).timeout
	await _capture("res://Build/Game/codex_prop_grounding_level2_v2.png")

	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await process_frame
	await process_frame
	player = current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(920.0, 240.0)
	if player.has_method("freeze"):
		player.call("freeze", true)
	await create_timer(0.2).timeout
	await _capture("res://Build/Game/codex_prop_grounding_level5_v2.png")
	quit()
