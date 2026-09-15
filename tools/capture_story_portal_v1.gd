extends SceneTree
## 四段时空裂隙过场的原生 640×360 截图。

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
		await create_timer(1.55).timeout
		await RenderingServer.frame_post_draw
		var path := ProjectSettings.globalize_path("res://Build/Game/codex_portal_story_%d.png" % level)
		root.get_texture().get_image().save_png(path)
		print("[CAPTURE] " + path)
		director.set("_skip_all", true)
		while bool(director.get("busy")):
			await process_frame
		await create_timer(0.1).timeout
	quit()
