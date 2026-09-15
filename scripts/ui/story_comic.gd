class_name StoryComic
extends Control
## 2×2 逐格漫画：鼠标左键、E 或空格每次揭开一格，全部揭开后再按一次结束。

const VIEW_SIZE := Vector2(640, 360)
const PANEL_POSITIONS := [Vector2(14, 36), Vector2(326, 36), Vector2(14, 188), Vector2(326, 188)]
const PANEL_SIZE := Vector2(300, 142)
const INPUT_GUARD_MSEC := 140

var complete_requested := false
var _panels: Array[Control] = []
var _revealed := 0
var _animating := false
var _guard_until := 0
var _hint: Label
var _finish_text := "点击继续"
var _beat_cues: Array[String] = []

func configure(header_text: String, beats: Array, finish_text: String) -> void:
	position = Vector2.ZERO
	size = VIEW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_finish_text = finish_text
	_build_backdrop()
	var header := Label.new()
	header.text = header_text
	header.position = Vector2(16, 7)
	header.size = Vector2(608, 24)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color("#f1c46d"))
	add_child(header)
	for index in mini(4, beats.size()):
		var beat := beats[index] as Dictionary
		_panels.append(_make_panel(beat, index))
		_beat_cues.append(str(beat.get("sfx", "")))
	_hint = Label.new()
	_hint.text = "点击 / E / SPACE　揭开第一格"
	_hint.position = Vector2(180, 337)
	_hint.size = Vector2(444, 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 10)
	_hint.add_theme_color_override("font_color", Color("#d9d2c5"))
	add_child(_hint)
	_guard_until = Time.get_ticks_msec() + 420

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#080b12")
	bg.size = VIEW_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var top_glow := ColorRect.new()
	top_glow.color = Color("#18243a")
	top_glow.position = Vector2(0, 0)
	top_glow.size = Vector2(640, 34)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

func _make_panel(beat: Dictionary, index: int) -> Control:
	var panel := Panel.new()
	panel.position = PANEL_POSITIONS[index]
	panel.size = PANEL_SIZE
	panel.pivot_offset = PANEL_SIZE * 0.5
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate.a = 0.0
	panel.visible = false
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#12151c")
	frame.border_color = Color("#e6d6b5")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", frame)
	add_child(panel)

	var art := TextureRect.new()
	art.name = "ComicArt%d" % (index + 1)
	art.position = Vector2(3, 3)
	art.size = PANEL_SIZE - Vector2(6, 6)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.texture = _cropped_texture(str(beat.get("art", "")), beat.get("crop", Rect2(0, 0, 1, 1)) as Rect2)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	for actor_data: Dictionary in beat.get("actors", []):
		panel.add_child(_make_actor(actor_data))

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.022, 0.035, 0.88)
	shade.position = Vector2(3, 88)
	shade.size = Vector2(294, 51)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(shade)
	var title := Label.new()
	title.text = str(beat.get("title", ""))
	title.position = Vector2(10, 91)
	title.size = Vector2(278, 18)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("#f2bc5e"))
	panel.add_child(title)
	var body := Label.new()
	body.text = str(beat.get("body", ""))
	body.position = Vector2(10, 108)
	body.size = Vector2(278, 29)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 9)
	body.add_theme_color_override("font_color", Color("#eee9df"))
	panel.add_child(body)
	return panel

func _make_actor(data: Dictionary) -> TextureRect:
	var actor := TextureRect.new()
	var actor_scale := float(data.get("scale", 1.0))
	var actor_size := Vector2(112, 112) * actor_scale
	var anchor := data.get("pos", Vector2(0.5, 0.9)) as Vector2
	actor.position = Vector2(anchor.x * PANEL_SIZE.x - actor_size.x * 0.5, anchor.y * PANEL_SIZE.y - actor_size.y)
	actor.size = actor_size
	actor.texture = load(str(data.get("texture", ""))) as Texture2D
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	actor.flip_h = bool(data.get("flip_h", false))
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return actor

func _cropped_texture(path: String, normalized_crop: Rect2) -> Texture2D:
	var source := load(path) as Texture2D
	if source == null:
		return null
	if normalized_crop == Rect2(0, 0, 1, 1):
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var source_size := Vector2(source.get_width(), source.get_height())
	atlas.region = Rect2(normalized_crop.position * source_size, normalized_crop.size * source_size)
	return atlas

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_request_advance()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		_request_advance()
		get_viewport().set_input_as_handled()

func _request_advance() -> void:
	if complete_requested or _animating or Time.get_ticks_msec() < _guard_until:
		return
	_guard_until = Time.get_ticks_msec() + INPUT_GUARD_MSEC
	if _revealed >= _panels.size():
		complete_requested = true
		return
	var panel := _panels[_revealed]
	_revealed += 1
	panel.visible = true
	_animating = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void: _animating = false)
	_play_tick()
	_play_beat_cue(_revealed - 1)
	if _revealed < _panels.size():
		_hint.text = "点击 / E / SPACE　揭开下一格　%d/%d" % [_revealed, _panels.size()]
	else:
		_hint.text = _finish_text

func finish_immediately() -> void:
	for panel in _panels:
		panel.visible = true
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	complete_requested = true

func _play_tick() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "ui_tick", 0.92 + _revealed * 0.025, -7.0)

func _play_beat_cue(index: int) -> void:
	if index < 0 or index >= _beat_cues.size() or _beat_cues[index].is_empty():
		return
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", _beat_cues[index], 0.96 + index * 0.02, -3.0)
