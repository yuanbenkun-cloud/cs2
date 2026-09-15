extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	var portal := ArrivalPortal.new()
	current_scene.add_child(portal)
	portal.play_arrival(player)
	await create_timer(0.34).timeout
	await RenderingServer.frame_post_draw
	var output := "res://Build/Game/codex_arrival_portal_v1.png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	print("[CAPTURE] " + output)
	quit()
