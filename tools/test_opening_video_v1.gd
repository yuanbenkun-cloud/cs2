extends SceneTree
## 启动影片导入、跳过与菜单衔接回归。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _run() -> void:
	_check(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/opening_video.tscn", "游戏启动场景为渝灯影片")
	var stream := load("res://assets/video/edit/opening-yudeng-history-new-bgm.ogv") as VideoStream
	_check(stream != null, "Godot 可读取保留原声并混入新 BGM 的 Ogg Theora 片头")
	change_scene_to_file("res://scenes/opening_video.tscn")
	await create_timer(0.35).timeout
	var intro := current_scene
	var player := intro.get_node_or_null("HistoryFilm") as VideoStreamPlayer if intro != null else null
	_check(player != null and player.stream == stream and player.bus == &"Music" and player.is_playing(), "片头视频正在音乐总线上播放")
	var audio := root.get_node_or_null("AudioManager")
	var music := audio.find_child("MusicPlayer", true, false) as AudioStreamPlayer if audio != null else null
	_check(music != null and music.playing and str(audio.get("current_music_path")).ends_with("主界面-新配乐.ogg") and music.volume_db < -35.0, "片头新 BGM 来自视频混音，后台播放器静音待续")
	var music_before_skip := music.get_playback_position() if music != null else 0.0
	_check(intro != null and intro.get_node_or_null("SkipHint") != null, "片头显示跳过提示")
	var companion := root.get_node_or_null("Companion")
	var companion_ui := companion.get_node_or_null("CompanionLayer/YudengCompanion") as Control if companion != null else null
	_check(companion_ui != null and not companion_ui.visible, "片头不重复叠加关卡互动精灵")
	if intro != null:
		intro.call("_finish", true)
	await create_timer(0.85).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/kaishi.tscn", "跳过后进入可操作菜单")
	_check(music != null and music.playing and music.get_playback_position() > music_before_skip, "进入菜单后同一条 BGM 继续播放而非重头开始")
	var start_button := current_scene.find_child("StartButton", true, false) as Button if current_scene != null else null
	_check(start_button != null and not start_button.disabled, "片尾显示的是真正可点击的开始按钮")
	_check(not has_meta("opening_video_just_finished"), "菜单接收并清除淡入标记")
	change_scene_to_file("res://scenes/opening_video.tscn")
	await create_timer(26.0).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/kaishi.tscn", "影片自然播完后自动进入菜单")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
