extends Control
## 启动片头：播放渝灯穿行四个时代的影片，结束或跳过后进入可操作菜单。

const VIDEO_PATH := "res://assets/video/edit/opening-yudeng-history-new-bgm.ogv"
const MENU_PATH := "res://scenes/kaishi.tscn"
const VIEW_SIZE := Vector2(640, 360)
const VIDEO_LENGTH := 24.6

var _video: VideoStreamPlayer
var _veil: ColorRect
var _ending := false

func _ready() -> void:
	_build_screen()
	var stream := load(VIDEO_PATH) as VideoStream
	if stream == null:
		push_warning("片头影片无法加载，直接进入菜单：%s" % VIDEO_PATH)
		call_deferred("_open_menu")
		return
	_video.stream = stream
	_video.finished.connect(_on_video_finished)
	_video.play()
	# 解码异常时也不能让玩家被困在片头。
	var watchdog := Timer.new()
	watchdog.name = "PlaybackWatchdog"
	watchdog.one_shot = true
	watchdog.wait_time = 27.0
	watchdog.timeout.connect(_on_video_finished)
	add_child(watchdog)
	watchdog.start()

func _build_screen() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "BlackBackdrop"
	backdrop.color = Color.BLACK
	backdrop.size = VIEW_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_video = VideoStreamPlayer.new()
	_video.name = "HistoryFilm"
	_video.size = VIEW_SIZE
	_video.expand = true
	_video.bus = &"Music"
	_video.volume_db = 3.0
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_video)

	_veil = ColorRect.new()
	_veil.name = "FadeToBlack"
	_veil.color = Color.BLACK
	_veil.modulate.a = 0.0
	_veil.size = VIEW_SIZE
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)

	var hint := Label.new()
	hint.name = "SkipHint"
	hint.text = "SPACE / ENTER / ESC / 点击　跳过"
	hint.position = Vector2(423, 333)
	hint.size = Vector2(205, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.74))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func _input(event: InputEvent) -> void:
	if _ending:
		return
	var skip: bool = event is InputEventKey and event.pressed and not event.echo
	skip = skip or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	skip = skip or (event is InputEventJoypadButton and event.pressed)
	if skip:
		get_viewport().set_input_as_handled()
		_finish(true)

func _on_video_finished() -> void:
	_finish(false)

func _finish(skipped: bool) -> void:
	if _ending:
		return
	_ending = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		var video_time := clampf(_video.stream_position, 0.0, VIDEO_LENGTH) if skipped else VIDEO_LENGTH
		audio.call("handoff_opening_music", video_time, skipped)
	var transition := create_tween()
	transition.set_parallel(true)
	transition.tween_property(_veil, "modulate:a", 1.0, 0.28 if skipped else 0.14)
	if skipped and _video.is_playing():
		transition.tween_property(_video, "volume_db", -48.0, 0.28)
	await transition.finished
	_open_menu()

func _open_menu() -> void:
	if _video != null:
		_video.stop()
	get_tree().set_meta("opening_video_just_finished", true)
	get_tree().change_scene_to_file(MENU_PATH)
