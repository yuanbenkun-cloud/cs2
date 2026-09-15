extends SceneTree
## 漫画过场专属环境轨、淡入淡出和逐格关键音效回归。

const SCENE_TRACKS := {
	2: ["res://scenes/guanqia/02_ciqikou.tscn", "kiln-fire-cc0.mp3", 30.0],
	3: ["res://scenes/guanqia/03_zhongshan.tscn", "cloth-market-cc0.mp3", 20.0],
	4: ["res://scenes/guanqia/04_fangdong.tscn", "air-raid-siren-cc0.mp3", 100.0],
}

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _run() -> void:
	await process_frame
	var audio := root.get_node_or_null("AudioManager")
	_check(audio != null, "AudioManager 已加载")
	var ambient_player := audio.find_child("AmbientPlayer", true, false) as AudioStreamPlayer
	_check(ambient_player != null and ambient_player.bus == "Ambient", "关卡环境轨位于 Ambient 总线")
	for level: int in SCENE_TRACKS:
		var route: Array = SCENE_TRACKS[level]
		var scene_path := str(route[0])
		var filename := str(route[1])
		var stream := load("res://assets/audio/field/%s" % filename) as AudioStream
		_check(stream != null and stream.get_length() > float(route[2]), "第 %d 章环境录音完整可读取" % level)
		change_scene_to_file(scene_path)
		await create_timer(0.45).timeout
		_check(ambient_player.playing, "第 %d 章加载后环境录音开始播放" % level)
		_check(str(audio.get("current_ambient_path")).ends_with(filename), "第 %d 章真实环境录音路由正确" % level)
		if level == 4:
			await create_timer(1.3).timeout
			_check(ambient_player.volume_db > -12.0, "第四关防空警报使用清晰可闻的独立混音电平")
			audio.call("set_dialogue_active", true)
			await create_timer(0.3).timeout
			_check(ambient_player.volume_db > -13.0, "第四关对白期间警报仍可辨认")
			audio.call("set_dialogue_active", false)
			await create_timer(0.3).timeout
			_check(ambient_player.volume_db > -10.0, "第四关对白结束后警报恢复专属音量")

	var director_script := FileAccess.get_file_as_string("res://autoload/story_director.gd")
	_check(director_script.contains('"sfx": "forge"'), "窑场漫画包含窑火/工具关键音")
	_check(director_script.contains('"sfx": "cloth"'), "布匹漫画包含布料关键音")
	_check(director_script.contains('"sfx": "alert"') and director_script.contains('"sfx": "explosion"'), "防空洞漫画包含警报与爆炸关键音")
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
