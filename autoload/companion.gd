extends Node

## 渝灯：右上角可拖动互动桌宠，承担新手引导与重庆时代背景补充。

const LEVEL_SPEECH := {
	1: [
		"先往右走。人群会挡路，踩到墙脚石扣才会唤醒出口。",
		"洪崖洞依山临江，传统吊脚楼会顺着陡坡层层架起。",
		"山城道路高低交错，旧时挑夫常沿石梯运送货物。",
	],
	2: [
		"先找老人准备工具，凿开石壁后再完成窑火节奏。",
		"旧时磁器口依嘉陵江水运兴盛，是重庆重要的水陆码头。",
		"窑火、商铺和船帮相互依存，一次水患就可能断掉整条生计。",
	],
	3: [
		"护住染布走完全程，送到码头老周手里才算完成。",
		"重庆开埠以后，布匹等货物常由码头转运，再送往沿江各地。",
		"山城坡陡巷窄，许多货物要靠背夫和挑夫完成最后一段运输。",
	],
	4: [
		"警报响起后跟紧挡板，把所有群众安全带到洞口。",
		"抗战时期，重庆作为战时首都，长期遭受日军空袭。",
		"山体中的防空洞曾庇护大量市民，警报和引路灯都是生死信号。",
	],
	5: [
		"收集四段城市记忆，再到观景台决定是否留下照片。",
		"今天的洪崖洞仍保留山地建筑层叠临江的空间印象。",
		"重庆的码头、石梯和吊脚楼，记录着山城依江而生的日常。",
	],
}
const CLICK_GREETINGS := [
	"嘿，我在这儿。山城的路慢慢走，才看得清。",
	"要是迷路就问我，坡坎再多也有路。",
	"灯还亮着，我们继续走嘛。",
]
const DRAG_GREETINGS := [
	"新位置不错，这里看得更清楚。",
	"谢谢你帮我挪地方，我不会挡着你。",
	"晃一晃也精神，我们接着走。",
]
const AUTO_SPEECH_INTERVAL := 5.2
const POSITION_SAVE := "user://companion_position.cfg"
const SAFE_MARGIN := 8.0

var _layer: CanvasLayer
var _root: Control
var _avatar: Control
var _bubble: PanelContainer
var _label: Label
var _hint: Label
var _button: Button
var _auto_timer: Timer
var _auto_lines: Array[String] = []
var _auto_index := 0
var _last_scene := ""
var _visible_state := false
var _expanded := false
var _dragging := false
var _drag_moved := false
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	_build_ui()
	_update_context()

func _process(_delta: float) -> void:
	_update_context()

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_state or _dialogue_active():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_show_greeting(false)

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "CompanionLayer"
	_layer.layer = 18
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_root = Control.new()
	_root.name = "YudengCompanion"
	_root.size = Vector2(286, 104)
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)
	var avatar_script := load("res://scripts/ui/companion_avatar.gd") as Script
	_avatar = avatar_script.new() as Control if avatar_script != null else Control.new()
	_avatar.name = "CompanionAvatar"
	_avatar.position = Vector2(216, 0)
	_avatar.size = Vector2(68, 72)
	_root.add_child(_avatar)
	_button = Button.new()
	_button.name = "CompanionButton"
	_button.position = Vector2(214, 0)
	_button.size = Vector2(72, 74)
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.tooltip_text = "渝灯：点击打招呼，按住可拖动"
	_button.gui_input.connect(_on_drag_input)
	_root.add_child(_button)
	_bubble = PanelContainer.new()
	_bubble.name = "CompanionSpeechBubble"
	_bubble.position = Vector2(0, 34)
	_bubble.size = Vector2(216, 64)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.085, 0.94)
	style.border_color = Color("#d69a43")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	_bubble.add_theme_stylebox_override("panel", style)
	_root.add_child(_bubble)
	_label = Label.new()
	_label.name = "CompanionText"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color("#f1e6cf"))
	_bubble.add_child(_label)
	_hint = Label.new()
	_hint.name = "CompanionHint"
	_hint.text = "点击问候 · 拖动挪位"
	_hint.position = Vector2(94, 84)
	_hint.size = Vector2(188, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color("#edbd65"))
	_root.add_child(_hint)
	_auto_timer = Timer.new()
	_auto_timer.name = "CompanionAutoSpeechTimer"
	_auto_timer.one_shot = true
	_auto_timer.wait_time = AUTO_SPEECH_INTERVAL
	_auto_timer.timeout.connect(_advance_auto_line)
	add_child(_auto_timer)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_restore_or_default_position()

func _update_context() -> void:
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene != null else ""
	var level := _level_from_path(path)
	var should_show := level > 0 and not _dialogue_active()
	if path != _last_scene:
		_last_scene = path
		if level > 0:
			_start_auto_speech(level)
		else:
			_auto_timer.stop()
			_auto_lines.clear()
	if should_show != _visible_state:
		_visible_state = should_show
		_root.visible = should_show
	if _bubble != null:
		_bubble.visible = _expanded and should_show
		_hint.visible = should_show and not _expanded
		_avatar.talking = _expanded

func _on_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_moved = false
			_drag_offset = get_viewport().get_mouse_position() - _root.position
		elif _dragging:
			_dragging = false
			if _drag_moved:
				_save_position()
				_show_greeting(true)
			else:
				_show_greeting(false)
	elif event is InputEventMouseMotion and _dragging:
		var desired := get_viewport().get_mouse_position() - _drag_offset
		if desired.distance_to(_root.position) >= 2.0:
			_drag_moved = true
		_root.position = _clamp_position(desired)

func _clamp_position(value: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		clampf(value.x, SAFE_MARGIN, maxf(SAFE_MARGIN, viewport_size.x - _root.size.x - SAFE_MARGIN)),
		clampf(value.y, SAFE_MARGIN, maxf(SAFE_MARGIN, viewport_size.y - _root.size.y - SAFE_MARGIN))
	)

func _restore_or_default_position() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var usable := Vector2(maxf(1.0, viewport_size.x - _root.size.x), maxf(1.0, viewport_size.y - _root.size.y))
	var cfg := ConfigFile.new()
	if cfg.load(POSITION_SAVE) == OK:
		var ratio := Vector2(
			float(cfg.get_value("position", "x_ratio", 1.0)),
			float(cfg.get_value("position", "y_ratio", 0.04))
		)
		_root.position = _clamp_position(ratio * usable)
	else:
		_root.position = _clamp_position(Vector2(viewport_size.x - _root.size.x - 10.0, 10.0))

func _save_position() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var usable := Vector2(maxf(1.0, viewport_size.x - _root.size.x), maxf(1.0, viewport_size.y - _root.size.y))
	var ratio := Vector2(_root.position.x / usable.x, _root.position.y / usable.y)
	var cfg := ConfigFile.new()
	cfg.set_value("position", "x_ratio", clampf(ratio.x, 0.0, 1.0))
	cfg.set_value("position", "y_ratio", clampf(ratio.y, 0.0, 1.0))
	cfg.save(POSITION_SAVE)

func _on_viewport_size_changed() -> void:
	_restore_or_default_position()

func _start_auto_speech(level: int) -> void:
	_auto_lines.clear()
	for line in LEVEL_SPEECH.get(level, []):
		_auto_lines.append(str(line))
	_auto_index = 0
	_expanded = not _auto_lines.is_empty()
	if _expanded:
		_label.text = _auto_lines[0]
		_auto_timer.start(AUTO_SPEECH_INTERVAL)

func _advance_auto_line() -> void:
	if _auto_lines.is_empty():
		return
	if _dialogue_active():
		_auto_timer.start(1.0)
		return
	if _auto_index >= _auto_lines.size() - 1:
		return
	_auto_index += 1
	_expanded = true
	_label.text = _auto_lines[_auto_index]
	_apply_speech_visibility()
	_auto_timer.start(AUTO_SPEECH_INTERVAL)

func _show_greeting(from_drag: bool) -> void:
	if not _visible_state or _dialogue_active():
		return
	var greetings: Array = DRAG_GREETINGS if from_drag else CLICK_GREETINGS
	_expanded = true
	_label.text = str(greetings.pick_random())
	_apply_speech_visibility()
	# 打招呼后继续尚未讲完的关卡科普。
	if _auto_index < _auto_lines.size() - 1:
		_auto_timer.start(3.8)

func _apply_speech_visibility() -> void:
	_bubble.visible = _expanded and _visible_state
	_hint.visible = _visible_state and not _expanded
	_avatar.talking = _expanded

func _dialogue_active() -> bool:
	var ds := get_node_or_null("/root/DialogueSystem")
	return ds != null and bool(ds.get("active"))

func _level_from_path(path: String) -> int:
	for i in range(1, 6):
		if path.contains("%02d_" % i):
			return i
	return 0
