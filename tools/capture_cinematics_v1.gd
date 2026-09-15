extends SceneTree
## 新叙事演出的原生 640×360 截图。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/kaishi.tscn")
	await process_frame
	await process_frame
	var director := root.get_node("StoryDirector")
	director.call("play_prologue")
	await create_timer(0.55).timeout
	var comic := director.find_child("StoryComic", true, false)
	if comic != null:
		for index in 4:
			comic.set("_guard_until", 0)
			comic.call("_request_advance")
			await create_timer(0.26).timeout
	await _capture("res://Build/Game/codex_cinematic_prologue.png")
	if comic != null:
		comic.set("_guard_until", 0)
		comic.call("_request_advance")
	await create_timer(0.6).timeout
	var gs := root.get_node("GameState")
	gs.set("ending_choice", "photo")
	gs.set("insight_flags", {"labor": 720, "trust": "完好", "responsibility": true})
	change_scene_to_file("res://scenes/jieju.tscn")
	await process_frame
	await process_frame
	await create_timer(2.6).timeout
	await _capture("res://Build/Game/codex_cinematic_ending.png")
	current_scene.call("_show_credits")
	await create_timer(0.7).timeout
	await _capture("res://Build/Game/codex_cinematic_credits.png")
	quit()

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)
