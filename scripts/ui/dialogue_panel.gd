class_name DialoguePanel
extends Control

## 双立绘对话框（V2）：底部文字框 + 左右两侧角色立绘。
## 说话方高亮；另一方变暗；旁白/独白等叙述行两侧变灰。

signal advance_requested

const BOX_TOP := 270.0
const PT_W := 116.0
const PT_H := 158.0

const PORTRAITS := {
	"陈默": ["res://assets/portraits/chenmo.png", true],
	"传单阿姨": ["res://assets/portraits/flyer_lady.png", false],
	"游客甲": ["res://assets/portraits/tourist.png", false],
	"游客": ["res://assets/portraits/tourist.png", false],
	"摊贩": ["res://assets/portraits/vendor.png", false],
	"讲历史老人": ["res://assets/portraits/old_man.png", false],
	"老人": ["res://assets/portraits/old_man.png", false],
	"老匠人": ["res://assets/portraits/old_artisan.png", false],
	"阿明": ["res://assets/portraits/aming.png", false],
	"老掌柜": ["res://assets/portraits/old_shopkeeper.png", false],
	"胖掌柜": ["res://assets/portraits/fat_teahouse.png", false],
	"码头帮工": ["res://assets/portraits/helper.png", false],
	"帮工": ["res://assets/portraits/helper.png", false],
	"老周": ["res://assets/portraits/laozhou.png", false],
	"避难群众": ["res://assets/portraits/crowd.png", false],
}

var _typing: bool = false
var _line_full: String = ""
var _shown: int = 0
var _waiting: bool = false
var _opts_shown: bool = false

var _bg: ColorRect
var _name_lb: Label
var _text_lb: Label
var _opts_box: VBoxContainer
var _timer: Timer
var _pt_left: TextureRect      # NPC 侧
var _pt_right: TextureRect     # 陈默侧
var _pt_left_tex: Texture2D = null
var _pt_right_tex: Texture2D = null

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -BOX_TOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.08, 0.92)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_pt_left = _make_portrait(Vector2(16.0, BOX_TOP - PT_H - 8.0), false)
	_pt_right = _make_portrait(Vector2(640.0 - 16.0 - PT_W, BOX_TOP - PT_H - 8.0), true)
	_name_lb = Label.new()
	_name_lb.position = Vector2(10, 4)
	_name_lb.add_theme_font_size_override("font_size", 13)
	_name_lb.add_theme_color_override("font_color", Color("#E8B04B"))
	add_child(_name_lb)
	_text_lb = Label.new()
	_text_lb.position = Vector2(14, 24)
	_text_lb.size = Vector2(612, 40)
	_text_lb.add_theme_font_size_override("font_size", 12)
	_text_lb.add_theme_color_override("font_color", Color.WHITE)
	_text_lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text_lb)
	_opts_box = VBoxContainer.new()
	_opts_box.position = Vector2(14, -66)
	_opts_box.size = Vector2(612, 0)
	_opts_box.add_theme_constant_override("separation", 2)
	_opts_box.visible = false
	add_child(_opts_box)
	_timer = Timer.new()
	_timer.wait_time = 0.03
	_timer.one_shot = false
	_timer.timeout.connect(_type_tick)
	add_child(_timer)

func _make_portrait(pos: Vector2, hero_side: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.position = pos
	tr.size = Vector2(PT_W, PT_H)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.flip_h = hero_side
	tr.modulate = Color(1, 1, 1, 0.45)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr

func set_name_label(s: String) -> void:
	if _name_lb != null:
		_name_lb.text = s

func play_line(speaker: String, text: String) -> void:
	if _name_lb != null:
		_name_lb.text = speaker
	_set_portraits(speaker)
	_line_full = text
	_shown = 0
	_waiting = false
	_opts_shown = false
	if _opts_box != null:
		_opts_box.visible = false
	_text_lb.text = ""
	_typing = true
	_timer.start()

func _set_portraits(speaker: String) -> void:
	var info: Array = PORTRAITS.get(speaker, [])
	if info.is_empty():
		_pt_left.modulate = Color(1, 1, 1, 0.5)
		_pt_right.modulate = Color(1, 1, 1, 0.5)
		return
	var tex: Texture2D = load(str(info[0]))
	var is_hero: bool = info[1]
	if is_hero:
		_pt_right_tex = tex
		if tex != null:
			_pt_right.texture = tex
		_pt_right.modulate = Color(1, 1, 1, 1.0)
		_pt_left.modulate = Color(1, 1, 1, 0.45)
	else:
		_pt_left_tex = tex
		if tex != null:
			_pt_left.texture = tex
		_pt_left.modulate = Color(1, 1, 1, 1.0)
		_pt_right.modulate = Color(1, 1, 1, 0.45)
	if _pt_left.texture == null and _pt_left_tex != null:
		_pt_left.texture = _pt_left_tex
	if _pt_right.texture == null and _pt_right_tex != null:
		_pt_right.texture = _pt_right_tex

func _type_tick() -> void:
	_shown += 1
	_text_lb.text = _line_full.substr(0, _shown)
	if _shown >= _line_full.length():
		_timer.stop()
		_typing = false
		_waiting = true

func show_options(opts: Array) -> void:
	_opts_shown = true
	for c in _opts_box.get_children():
		c.queue_free()
	var idx := 0
	for opt: Dictionary in opts:
		var btn := Button.new()
		btn.text = str(opt.get("label", ""))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var i := idx
		btn.pressed.connect(func() -> void:
			var ds := get_node_or_null("/root/DialogueSystem")
			if ds != null:
				ds.call("choose", i))
		_opts_box.add_child(btn)
		idx += 1
	_opts_box.visible = true
	_opts_box.move_to_front()
	if _opts_box.get_child_count() > 0:
		(_opts_box.get_child(0) as Button).grab_focus()

func has_options() -> bool:
	return _opts_shown

func hide_panel() -> void:
	_timer.stop()
	_opts_shown = false
	_waiting = false
	visible = false

func _process(_delta: float) -> void:
	if not visible or _opts_shown:
		return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		if _typing:
			_timer.stop()
			_text_lb.text = _line_full
			_shown = _line_full.length()
			_typing = false
			_waiting = true
		elif _waiting:
			_waiting = false
			advance_requested.emit()
