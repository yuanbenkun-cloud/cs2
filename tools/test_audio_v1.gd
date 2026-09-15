extends SceneTree
## 原创 BGM / 环境循环、关卡路由与五路音量设置回归。

const ROUTES := {
	"res://scenes/guanqia/01_hongyadong.tscn": ["music-01-night.wav", "ambient-01-rain.wav"],
	"res://scenes/guanqia/02_ciqikou.tscn": ["music-02-forge.wav", "kiln-fire-cc0.mp3"],
	"res://scenes/guanqia/03_zhongshan.tscn": ["music-03-old-town.wav", "cloth-market-cc0.mp3"],
	"res://scenes/guanqia/04_fangdong.tscn": ["music-04-shelter.wav", "air-raid-siren-cc0.mp3"],
	"res://scenes/guanqia/05_hongyadong_return.tscn": ["music-05-dawn.wav", "ambient-05-dawn.wav"],
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
	_check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("Ambient") >= 0, "音乐与环境声总线已建立")
	var generated := DirAccess.get_files_at("res://assets/audio/generated")
	var wav_count := 0
	for file_name in generated:
		if file_name.ends_with(".wav"):
			wav_count += 1
			var stream := load("res://assets/audio/generated/" + file_name) as AudioStream
			_check(stream != null and absf(stream.get_length() - 24.0) < 0.1, "%s 是 24 秒可用循环" % file_name)
	_check(wav_count == 13, "十三条原创音乐、环境与过场循环均已导入")

	for scene_path: String in ROUTES:
		change_scene_to_file(scene_path)
		await create_timer(0.45).timeout
		var expected: Array = ROUTES[scene_path]
		_check(str(audio.get("current_music_path")).ends_with(str(expected[0])), "%s 配乐路由正确" % scene_path.get_file())
		_check(str(audio.get("current_ambient_path")).ends_with(str(expected[1])), "%s 环境声路由正确" % scene_path.get_file())

	var access := root.get_node_or_null("Accessibility")
	access.call("_toggle_menu")
	await process_frame
	for slider_name in ["MasterSlider", "MusicSlider", "AmbientSlider", "SFXSlider", "UISlider"]:
		_check(access.find_child(slider_name, true, false) is HSlider, "设置菜单包含 %s" % slider_name)
	access.call("_close_menu")

	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
