extends SceneTree
## 生成关卡 1/2 实机截图，供原生视觉检查。

func _init() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Build/Game"))
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(830, 200)
	var chaser := current_scene.find_child("chuandanayi", true, false) as Node2D
	chaser.global_position = Vector2(715, 210)
	current_scene.find_child("ChaseManager", true, false).call("begin")
	await create_timer(0.7).timeout
	await _capture("res://Build/Game/codex_gameplay_v3_chase.png")

	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var hero := current_scene.find_child("zhujue", true, false) as Node2D
	hero.global_position = Vector2(1160, 200)
	current_scene.find_child("ForgeSequence", true, false).call("advance")
	await create_timer(0.45).timeout
	await _capture("res://Build/Game/codex_gameplay_v3_forge.png")
	current_scene.find_child("ForgeTimingPanel", true, false).visible = false
	hero.global_position = Vector2(1180, 200)
	await create_timer(0.3).timeout
	await _capture("res://Build/Game/codex_grounding_wall_v2.png")
	hero.global_position = Vector2(500, 200)
	await create_timer(0.3).timeout
	await _capture("res://Build/Game/codex_gameplay_v3_props.png")

	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var tile_player := current_scene.find_child("zhujue", true, false) as Node2D
	tile_player.global_position = Vector2(1840, 200)
	await create_timer(0.3).timeout
	await _capture("res://Build/Game/codex_gameplay_v3_tile.png")
	quit()
