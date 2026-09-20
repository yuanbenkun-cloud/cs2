extends SceneTree
## 第一关石扣/门牌/传送门与第二关窑炉深接地截图。

func _init() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)

func _place_player(x: float) -> Node2D:
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = Vector2(x, 240.0)
	if player.has_method("freeze"):
		player.call("freeze", true)
	return player

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await create_timer(0.3).timeout
	var player := _place_player(1870.0)
	await create_timer(0.2).timeout
	await _capture("res://Build/Game/codex_level1_stone_before_v1.png")
	var stone := current_scene.find_child("diyiguan_husongdizhuan", true, false)
	stone.call("_on_body_entered", player)
	await create_timer(0.5).timeout
	await _capture("res://Build/Game/codex_level1_stone_portal_v1.png")

	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await create_timer(0.3).timeout
	_place_player(970.0)
	await create_timer(0.2).timeout
	await _capture("res://Build/Game/codex_kiln_deeper_v3.png")
	quit()
