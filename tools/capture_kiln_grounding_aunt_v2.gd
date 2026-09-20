extends SceneTree
## 窑炉、人物接地、石壁消失与第五关阿姨实色回归截图。

func _init() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)

func _place_player(x: float) -> void:
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(x, 240.0)
	if player.has_method("freeze"):
		player.call("freeze", true)

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await create_timer(0.25).timeout
	_place_player(495.0)
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_level2_props_restored_v2.png")

	_place_player(970.0)
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_kiln_right_v2.png")

	_place_player(1240.0)
	var wall := current_scene.find_child("di_erguan_yanbi", true, false)
	wall.call("crack")
	wall.call("crack")
	wall.call("crack")
	wall.call("celebrate_breakthrough")
	await create_timer(0.85).timeout
	await _capture("res://Build/Game/codex_wall_no_stripes_v2.png")

	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await create_timer(0.25).timeout
	_place_player(560.0)
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_aunt_opaque_grounded_v2.png")
	quit()
