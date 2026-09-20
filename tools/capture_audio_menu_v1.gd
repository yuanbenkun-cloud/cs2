extends SceneTree
## 音频诊断：录制开始界面的配乐与环境声。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/kaishi.tscn")
	await create_timer(8.0).timeout
	quit()
