extends SceneTree
## 前四关终点传送门与第五关阿姨/对白残留的视觉回归。

func _init() -> void:
	call_deferred("_run")

func _load_level(path: String) -> void:
	var dialogue := root.get_node("DialogueSystem")
	dialogue.call("cancel_for_scene_change")
	change_scene_to_file(path)
	await process_frame
	await process_frame

func _place_player(pos: Vector2) -> void:
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	player.global_position = pos
	if player.has_method("freeze"):
		player.call("freeze", true)
	await create_timer(0.35).timeout

func _run() -> void:
	await _load_level("res://scenes/guanqia/01_hongyadong.tscn")
	await _place_player(Vector2(1870, 240))
	await _capture("res://Build/Game/codex_portal_level1.png")

	await _load_level("res://scenes/guanqia/02_ciqikou.tscn")
	current_scene.find_child("dierguan_chukou", true, false).call("activate")
	await _place_player(Vector2(1335, 240))
	await _capture("res://Build/Game/codex_portal_level2.png")

	await _load_level("res://scenes/guanqia/03_zhongshan.tscn")
	current_scene.find_child("disanguan_chukou", true, false).call("activate")
	await _place_player(Vector2(970, 240))
	await _capture("res://Build/Game/codex_portal_level3.png")

	await _load_level("res://scenes/guanqia/04_fangdong.tscn")
	await _place_player(Vector2(1250, 240))
	await _capture("res://Build/Game/codex_portal_level4.png")

	await _load_level("res://scenes/guanqia/05_hongyadong_return.tscn")
	await _place_player(Vector2(720, 240))
	await _capture("res://Build/Game/codex_final_aunt_opaque.png")

	var panel := current_scene.find_child("DialoguePanel", true, false) as Control
	panel.call("play_line", "传单阿姨", "先前对话")
	panel.call("reset_portraits")
	panel.call("play_line", "陈默", "这一刻，应该由我来决定是否按下快门。")
	panel.visible = true
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_photo_dialogue_clean_portrait.png")
	quit()

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)
