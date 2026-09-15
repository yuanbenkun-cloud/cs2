extends SceneTree
## 第二至第五章四格因果漫画的原生分辨率视觉检查。

const TARGETS := {
	2: "res://scenes/guanqia/02_ciqikou.tscn",
	3: "res://scenes/guanqia/03_zhongshan.tscn",
	4: "res://scenes/guanqia/04_fangdong.tscn",
	5: "res://scenes/guanqia/05_hongyadong_return.tscn",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	var director := root.get_node("StoryDirector")
	for level in [2, 3, 4, 5]:
		director.call("play_transition", TARGETS[level], level, "")
		await create_timer(0.45).timeout
		var comic := director.find_child("StoryComic", true, false)
		if comic != null:
			for index in 4:
				comic.set("_guard_until", 0)
				comic.call("_request_advance")
				await create_timer(0.25).timeout
			await _capture("res://Build/Game/codex_story_comic_level%d.png" % level)
			comic.set("_guard_until", 0)
			comic.call("_request_advance")
		director.set("_skip_all", true)
		var deadline := Time.get_ticks_msec() + 3500
		while bool(director.get("busy")) and Time.get_ticks_msec() < deadline:
			await process_frame
		director.set("_skip_all", false)
	quit()

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] " + path)
