extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	var flyer := current_scene.find_child("chuandanayi", true, false) as Node2D
	if player.has_method("freeze"):
		player.call("freeze", true)
	player.global_position = Vector2(650.0, 240.0)
	flyer.global_position = Vector2(500.0, 240.0)
	for crowd_name in ["diyiguan_renqun_01", "diyiguan_renqun_02", "diyiguan_renqun_03", "diyiguan_renqun_04"]:
		var crowd := current_scene.find_child(crowd_name, true, false)
		if crowd != null:
			crowd.visible = false
	flyer.call("activate", player)
	await create_timer(0.22).timeout
	var visual := flyer.find_child("SkinAnim", true, false) as CanvasItem
	print("[AUDIT] actor visible=%s modulate=%s self=%s" % [flyer.visible, flyer.modulate, flyer.self_modulate])
	print("[AUDIT] visual visible=%s modulate=%s self=%s animation=%s" % [visual.visible, visual.modulate, visual.self_modulate, visual.get("animation")])
	await RenderingServer.frame_post_draw
	var output := "res://Build/Game/codex_flyer_walk_fixed_v2.png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	print("[CAPTURE] " + output)
	quit()
