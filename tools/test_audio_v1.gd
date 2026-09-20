extends SceneTree
## 原创 BGM / 环境循环、关卡路由与五路音量设置回归。

const ROUTES := {
	"res://scenes/opening_video.tscn": ["主界面-新配乐.ogg", ""],
	"res://scenes/kaishi.tscn": ["主界面-新配乐.ogg", "主界面-洪崖背景.ogg"],
	"res://scenes/guanqia/01_hongyadong.tscn": ["第1关-追逐.ogg", "第1关-江岸汽笛.ogg"],
	"res://scenes/guanqia/02_ciqikou.tscn": ["第2关-窑洞.ogg", "第2关-窑火.ogg"],
	"res://scenes/guanqia/03_zhongshan.tscn": ["第3关-古镇.ogg", "第3关-河流.ogg"],
	"res://scenes/guanqia/04_fangdong.tscn": ["第4关-防空洞.ogg", "第4关-洞内环境.ogg"],
	"res://scenes/guanqia/05_hongyadong_return.tscn": ["第5关-归来.ogg", "第1关-江岸汽笛.ogg"],
	"res://scenes/jieju.tscn": ["结尾-新配乐.ogg", "第1关-江岸汽笛.ogg"],
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
	var music_paths: Dictionary = {}
	for route: Array in ROUTES.values():
		music_paths[str(route[0])] = true
	_check(music_paths.size() == 7, "菜单、五关及结尾共七条不同配乐")
	for file_name: String in music_paths:
		var stream := load("res://assets/audio/user_music/" + file_name) as AudioStream
		_check(stream != null and stream.get_length() > 0.09, "%s 已导入并可读取" % file_name)

	for scene_path: String in ROUTES:
		change_scene_to_file(scene_path)
		await create_timer(0.45).timeout
		var expected: Array = ROUTES[scene_path]
		_check(str(audio.get("current_music_path")).ends_with(str(expected[0])), "%s 配乐路由正确" % scene_path.get_file())
		_check(str(audio.get("current_ambient_path")).ends_with(str(expected[1])), "%s 环境声路由正确" % scene_path.get_file())

	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await create_timer(1.4).timeout
	var hammer_layer := audio.find_child("SceneLayer1", true, false) as AudioStreamPlayer
	_check(hammer_layer != null and hammer_layer.playing and str(audio.get("_scene_layer_paths")[1]).contains("锤陶土"), "第二关用户锤陶土录音持续播放")
	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await create_timer(1.4).timeout
	_check(hammer_layer.playing and str(audio.get("_scene_layer_paths")[1]).contains("船夫吆喝"), "第三关用户船夫吆喝录音持续播放")
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await create_timer(1.4).timeout
	var bomb_layer := audio.find_child("SceneLayer0", true, false) as AudioStreamPlayer
	_check(bomb_layer != null and bomb_layer.playing and str(audio.get("_scene_layer_paths")[0]).contains("远处轰炸"), "第四关用户远处轰炸环境音持续播放")
	var accent := audio.find_child("SceneAccentPlayer", true, false) as AudioStreamPlayer
	await create_timer(2.0).timeout
	_check(accent.stream != null and accent.stream.resource_path.contains("防空警报"), "第四关间断警报已触发")
	change_scene_to_file("res://scenes/guanqia/05_hongyadong_return.tscn")
	await create_timer(0.2).timeout
	_check(not accent.playing, "离开防空洞后警报停止")

	var access := root.get_node_or_null("Accessibility")
	access.call("_toggle_menu")
	await process_frame
	for slider_name in ["MasterSlider", "MusicSlider", "AmbientSlider", "SFXSlider", "UISlider"]:
		_check(access.find_child(slider_name, true, false) is HSlider, "设置菜单包含 %s" % slider_name)
	access.call("_close_menu")

	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
