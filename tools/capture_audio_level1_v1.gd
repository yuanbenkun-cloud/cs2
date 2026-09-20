extends SceneTree
## 音频诊断：进入第一关，录制静止状态下的配乐与环境声。

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await create_timer(8.0).timeout
	quit()
