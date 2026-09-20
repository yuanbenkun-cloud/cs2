extends SceneTree
## 渝灯互动精灵：位置、关卡文案、输入和对话互斥回归。

var _ok := true

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await create_timer(0.35).timeout
	var companion := root.get_node_or_null("Companion")
	var root_ui := companion.get_node_or_null("CompanionLayer/YudengCompanion") if companion != null else null
	var avatar := root_ui.get_node_or_null("CompanionAvatar") if root_ui != null else null
	var sprite := avatar.get_node_or_null("YudengSprite") as AnimatedSprite2D if avatar != null else null
	var button := root_ui.get_node_or_null("CompanionButton") as Button if root_ui != null else null
	var bubble := root_ui.get_node_or_null("CompanionSpeechBubble") if root_ui != null else null
	_check(companion != null and root_ui != null and root_ui.visible, "进入关卡后渝灯显示")
	var right_top := companion.call("_clamp_position", Vector2(9999, -999)) as Vector2 if companion != null else Vector2.ZERO
	_check(root_ui != null and right_top.x > 300.0 and right_top.y >= 8.0, "渝灯默认位于右上安全区")
	_check(sprite != null and sprite.sprite_frames.get_frame_count(&"hover") == 4 and sprite.is_playing(), "渝灯使用四帧正式像素悬浮动画")
	_check(button != null and button.tooltip_text.contains("拖动"), "渝灯支持鼠标拖动并提示操作")
	_check(bubble != null and bubble.visible, "进入关卡后自动显示背景提示对话框")
	var label := root_ui.get_node_or_null("CompanionSpeechBubble/CompanionText") as Label if root_ui != null else null
	_check(label != null and label.text.contains("老人"), "进入第二关无需点击就自动给出玩法引导")
	_check(bubble != null and bubble.size.x <= 216.0 and bubble.size.y <= 64.0, "对话框已缩小以减少遮挡")
	_check(label != null and label.get_theme_font_size("font_size") <= 9, "精灵对话字号已缩小")
	if companion != null:
		companion.call("_advance_auto_line")
	_check(label != null and label.text.contains("磁器口") and label.text.contains("嘉陵江"), "自动轮播重庆时代背景科普")
	if companion != null:
		companion.call("_show_greeting", false)
	_check(label != null and (label.text.contains("山城") or label.text.contains("迷路") or label.text.contains("灯还亮")), "点击精灵会主动打招呼")
	if companion != null:
		companion.call("_show_greeting", true)
	_check(label != null and (label.text.contains("位置") or label.text.contains("挪地方") or label.text.contains("晃一晃")), "拖动精灵后会回应玩家")
	var ds := root.get_node_or_null("DialogueSystem")
	if ds != null:
		ds.set("active", true)
		await create_timer(0.05).timeout
		_check(root_ui != null and not root_ui.visible, "正式人物对话时渝灯自动让出画面")
		ds.set("active", false)
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
