extends SceneTree
## 难度升级后的第五关人物与双结局画面核对。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	var aunt := current_scene.find_child("chuandanayi", true, false) as Node2D
	player.global_position = Vector2(720, 240)
	aunt.global_position = Vector2(640, 240)
	if player.has_method("freeze"):
		player.call("freeze", true)
	await create_timer(0.25).timeout
	await _capture("res://Build/Game/codex_difficulty_final_aunt.png")

	var gs := root.get_node("GameState")
	var ds := root.get_node("DialogueSystem")
	ds.call("load_data", "res://assets/dialogue_level5.json")
	ds.call("start_dialogue", "photo")
	ds.call("_on_advance")
	ds.call("_on_advance")
	ds.call("choose", 0)
	await create_timer(0.65).timeout
	await _capture("res://Build/Game/codex_photo_timestamp_dialogue.png")
	ds.call("cancel_for_scene_change")
	ds.call("load_data", "res://assets/dialogue_level5.json")
	ds.call("start_dialogue", "photo_not")
	await create_timer(0.65).timeout
	await _capture("res://Build/Game/codex_no_photo_picture_first.png")
	ds.call("cancel_for_scene_change")
	gs.set("insight_flags", {"labor": 720, "trust": "完好", "responsibility": true})
	gs.set("ending_choice", "photo")
	change_scene_to_file("res://scenes/jieju.tscn")
	await process_frame
	await process_frame
	await create_timer(1.9).timeout
	await _capture("res://Build/Game/codex_ending_hongyadong_photo.png")

	gs.set("ending_choice", "observe")
	change_scene_to_file("res://scenes/jieju.tscn")
	await process_frame
	await process_frame
	await create_timer(1.9).timeout
	await _capture("res://Build/Game/codex_ending_hongyadong_people.png")

	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await process_frame
	await process_frame
	var player3 := current_scene.find_child("zhujue", true, false) as Node2D
	player3.global_position = Vector2(900, 240)
	if player3.has_method("freeze"):
		player3.call("freeze", true)
	await create_timer(0.2).timeout
	await _capture("res://Build/Game/codex_level3_no_fishing_boat.png")
	quit()

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)
