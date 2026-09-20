extends SceneTree
## 音频诊断：录制开场视频原声与新主界面 BGM 的叠加效果。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/opening_video.tscn")
	await create_timer(8.0).timeout
	quit()
