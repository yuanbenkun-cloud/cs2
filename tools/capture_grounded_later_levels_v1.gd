extends SceneTree

const LEVELS := [
	"res://scenes/guanqia/02_ciqikou.tscn",
	"res://scenes/guanqia/03_zhongshan.tscn",
	"res://scenes/guanqia/04_fangdong.tscn",
	"res://scenes/guanqia/05_hongyadong_return.tscn",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for index in range(LEVELS.size()):
		change_scene_to_file(LEVELS[index])
		await process_frame
		await process_frame
		await create_timer(0.18).timeout
		await RenderingServer.frame_post_draw
		var output := "res://Build/Game/codex_grounded_later_%02d.png" % (index + 2)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
		print("[CAPTURE] " + output)
	quit()
