extends Control
## 开始界面：标题 + 开始按钮 + 按键提示。Enter/Space/点击 均可开始。

var _started := false

func _ready() -> void:
	# 全屏背景
	var bg := ColorRect.new()
	bg.color = Color("#10131f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 远景色带
	for i in range(4):
		var band := ColorRect.new()
		band.color = Color(0.08, 0.1, 0.18, 0.5)
		band.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(band)
	# 标题
	var title := Label.new()
	title.text = "洞  见"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("#E8B04B"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-90, -110)
	title.size = Vector2(180, 70)
	add_child(title)
	var sub := Label.new()
	sub.text = "你以为你只是在旅游。其实你是在走一条路。"
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(-320, -50)
	sub.size = Vector2(640, 20)
	add_child(sub)
	# 开始按钮
	var btn := Button.new()
	btn.text = "开 始 游 戏（Enter）"
	btn.set_anchors_preset(Control.PRESET_CENTER)
	btn.position = Vector2(-110, 20)
	btn.size = Vector2(220, 44)
	btn.pressed.connect(_start)
	add_child(btn)
	var tip := Label.new()
	tip.text = "操作：A/D 移动 · Space 跳 · E 交互  （窗口 640×360，全屏可拉伸）"
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", Color(0.6, 0.63, 0.7))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.set_anchors_preset(Control.PRESET_CENTER)
	tip.position = Vector2(-320, 160)
	tip.size = Vector2(640, 20)
	add_child(tip)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or event is InputEventKey:
		if not _started:
			_start()

func _start() -> void:
	if _started:
		return
	_started = true
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null:
		lm.call("travel_to", 1, "洪崖洞 · 迷途")
	else:
		get_tree().change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
