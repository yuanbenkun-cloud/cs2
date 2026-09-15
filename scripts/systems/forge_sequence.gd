class_name ForgeSequence
extends Node

## 移动游标进入目标区时按 E。烤热、淬水、凿击三种节奏，3 轮共 9 次成功。
enum Step { HEAT, QUENCH, CHISEL }
const ROUNDS := 3
const TIME_LIMIT := 105.0
const STEP_NAMES := ["烤热", "淬水", "凿击"]
const STEP_HINTS := ["火候要稳：宽区间、慢节奏", "水到正好：区间会偏移", "看准裂纹：窄区间、快节奏"]
const CURSOR_SPEEDS := [1.05, 1.34, 1.68]
const TARGET_WIDTHS := [0.25, 0.20, 0.15]

var current_step: int = Step.HEAT
var current_round := 0
var time_left := TIME_LIMIT
var score := 0
var combo := 0
var best_combo := 0
var _active := true
var _timing := false
var _resolving := false
var _cursor_value := 0.05
var _cursor_dir := 1.0
var _target_center := 0.5
var _wall: Node
var _timer_label: Label
var _notice: Label
var _player: Node
var _panel: Panel
var _title: Label
var _hint: Label
var _target: ColorRect
var _perfect: ColorRect
var _cursor: ColorRect
var _result: Label
var _progress: Label
var _bar: ColorRect
var _story_paused := false

func _ready() -> void:
	_acquire_refs()
	_build_timing_ui()
	_refresh_timer()
	_show_notice("走到岩壁前按 E，开始三轮锻造")

func _acquire_refs() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		cur = get_parent()
	_wall = cur.find_child("di_erguan_yanbi", true, false)
	_timer_label = cur.find_child("UI_Timer", true, false) as Label
	_notice = cur.find_child("UI_Notice", true, false) as Label
	_player = cur.find_child("zhujue", true, false)

func _process(delta: float) -> void:
	if not _active:
		return
	var director := get_node_or_null("/root/StoryDirector")
	if _story_paused or (director != null and bool(director.get("busy"))):
		return
	time_left = maxf(0.0, time_left - delta)
	_refresh_timer()
	if time_left <= 0.0:
		_fail_timeout()
		return
	if _timing and not _resolving:
		_cursor_value += _cursor_dir * _current_speed() * delta
		if _cursor_value >= 1.0:
			_cursor_value = 1.0
			_cursor_dir = -1.0
		elif _cursor_value <= 0.0:
			_cursor_value = 0.0
			_cursor_dir = 1.0
		_layout_cursor()

func _unhandled_input(event: InputEvent) -> void:
	if _timing and not _resolving and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_judge()

func advance() -> void:
	if not _active or _timing:
		return
	_timing = true
	if _notice != null:
		_notice.visible = false
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", true)
	_panel.visible = true
	_prepare_attempt()

func set_story_paused(value: bool) -> void:
	_story_paused = value

func interact_heat() -> void:
	advance()
func interact_quench() -> void:
	advance()
func interact_chisel() -> void:
	advance()

func _prepare_attempt() -> void:
	_resolving = false
	_cursor_value = 0.04 if _cursor_dir > 0.0 else 0.96
	_target_center = randf_range(0.29, 0.71)
	_title.text = "第 %d/3 轮 · %s" % [current_round + 1, STEP_NAMES[current_step]]
	_hint.text = STEP_HINTS[current_step] + "　｜　指针进色块时按 E"
	_result.text = ""
	_update_progress()
	_layout_target()
	_layout_cursor()

func _judge() -> void:
	_resolving = true
	var audio := get_node_or_null("/root/AudioManager")
	var distance := absf(_cursor_value - _target_center)
	var half_width: float = _current_width() * 0.5
	if distance <= 0.035:
		score += 100
		combo += 1
		best_combo = maxi(best_combo, combo)
		time_left = minf(TIME_LIMIT, time_left + 1.5)
		_show_result("完美！ +100  连击 x%d" % combo, Color("#fff0a6"))
		if audio != null: audio.call("play_event", "forge", 1.12, 0.0)
		_apply_success(true)
	elif distance <= half_width:
		score += 65
		combo += 1
		best_combo = maxi(best_combo, combo)
		_show_result("成功！ +65  连击 x%d" % combo, Color("#9ff0bd"))
		if audio != null: audio.call("play_event", "forge", 0.96, -1.0)
		_apply_success(false)
	else:
		combo = 0
		time_left = maxf(0.0, time_left - 5.0)
		_show_result("偏了！时间 -5 秒，稳住再来", Color("#ff8585"))
		if audio != null: audio.call("play_event", "ui_error", 0.8, -1.0)
		_feedback_shake(3.0)
		get_tree().create_timer(0.72).timeout.connect(func() -> void:
			if is_instance_valid(self) and _active:
				_prepare_attempt())

func _apply_success(perfect_hit: bool) -> void:
	match current_step:
		Step.HEAT:
			if _wall != null: _wall.call("mark_heat")
		Step.QUENCH:
			if _wall != null: _wall.call("mark_quench")
		Step.CHISEL:
			if _wall != null: _wall.call("crack")
			_feedback_shake(5.5 if perfect_hit else 4.0)
	current_step += 1
	if current_step > Step.CHISEL:
		current_step = Step.HEAT
		current_round += 1
	if current_round >= ROUNDS:
		_finish_forge()
		return
	get_tree().create_timer(0.62).timeout.connect(func() -> void:
		if is_instance_valid(self) and _active:
			_prepare_attempt())

func _finish_forge() -> void:
	_active = false
	_timing = false
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("record_insight", "labor", score)
	_result.text = "岩壁贯通！总分 %d · 最高连击 x%d" % [score, best_combo]
	_hint.text = "老匠人：水退了。记着，城是人一锤一锤守下来的。"
	if _wall != null and _wall.has_method("celebrate_breakthrough"):
		_wall.call("celebrate_breakthrough")
	var portal := get_tree().current_scene.find_child("dierguan_chukou", true, false)
	if portal != null and portal.has_method("activate"):
		portal.call("activate")
	_feedback_shake(7.0)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "explosion", 1.22, -5.0)
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		if is_instance_valid(_panel):
			_panel.visible = false
		if is_instance_valid(_player) and _player.has_method("freeze"):
			_player.call("freeze", false)
		_show_notice("时空门已经开启，穿过它继续前行"))

func _fail_timeout() -> void:
	_active = false
	_timing = false
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", false)
	_show_notice("一炷香燃尽了……")
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null: lm.call("fail", "一炷香燃尽了。")

func _show_result(text: String, color: Color) -> void:
	_result.text = text
	_result.add_theme_color_override("font_color", color)
	_result.pivot_offset = _result.size * 0.5
	_result.scale = Vector2(0.82, 0.82)
	create_tween().tween_property(_result, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_update_progress()

func _feedback_shake(strength: float) -> void:
	var camera := get_tree().current_scene.find_child("Camera2D", true, false)
	if camera != null and camera.has_method("shake"):
		camera.call("shake", strength, 0.22)

func _layout_target() -> void:
	var width: float = _current_width() * _bar.size.x
	_target.position.x = _target_center * _bar.size.x - width * 0.5
	_target.size.x = width
	_perfect.position.x = _target_center * _bar.size.x - 0.035 * _bar.size.x
	_perfect.size.x = 0.07 * _bar.size.x

func _layout_cursor() -> void:
	_cursor.position.x = _cursor_value * _bar.size.x - _cursor.size.x * 0.5

func _current_speed() -> float:
	return CURSOR_SPEEDS[current_step] * (1.0 + current_round * 0.15)

func _current_width() -> float:
	return TARGET_WIDTHS[current_step] * (1.0 - current_round * 0.09)

func _update_progress() -> void:
	_progress.text = "工序 %d/9　分数 %d　连击 x%d" % [current_round * 3 + current_step, score, combo]

func _refresh_timer() -> void:
	if _timer_label != null:
		_timer_label.text = "⏳ %d" % int(ceil(time_left))

func _show_notice(text: String) -> void:
	if _notice == null: return
	_notice.text = text
	_notice.visible = true
	get_tree().create_timer(2.6).timeout.connect(func() -> void:
		if is_instance_valid(_notice): _notice.visible = false)

func _build_timing_ui() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		cur = get_parent()
	var ui := cur.find_child("UI_Base", true, false)
	if ui == null: return
	_panel = Panel.new()
	_panel.name = "ForgeTimingPanel"
	_panel.position = Vector2(92, 210)
	_panel.size = Vector2(456, 138)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#17161ce8")
	box.border_color = Color("#d69752")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", box)
	ui.add_child(_panel)
	_title = _label(Vector2(18, 10), Vector2(220, 24), 16, Color("#ffd59a"))
	_hint = _label(Vector2(18, 34), Vector2(420, 20), 11, Color("#d9d2c5"))
	_bar = ColorRect.new()
	_bar.name = "TimingBar"
	_bar.color = Color("#353440")
	_bar.position = Vector2(22, 64)
	_bar.size = Vector2(412, 22)
	_panel.add_child(_bar)
	_target = ColorRect.new()
	_target.color = Color("#5cbf78")
	_target.size.y = 22
	_bar.add_child(_target)
	_perfect = ColorRect.new()
	_perfect.color = Color("#ffe67b")
	_perfect.size.y = 22
	_bar.add_child(_perfect)
	_cursor = ColorRect.new()
	_cursor.color = Color("#fffaf0")
	_cursor.position.y = -5
	_cursor.size = Vector2(4, 32)
	_bar.add_child(_cursor)
	_result = _label(Vector2(22, 92), Vector2(270, 22), 13, Color.WHITE)
	_progress = _label(Vector2(285, 94), Vector2(150, 20), 11, Color("#b8ac9c"))
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.visible = false

func _label(pos: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_panel.add_child(label)
	return label
