class_name SceneTransition
extends CanvasLayer

## 场景切换转场（SPEC Phase 1）：黑屏渐变 + change_scene_to_file。
## 由 LevelManager 创建并调用 play(to_path, caption)。

var _rect: ColorRect
var _caption: Label

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_CENTER)
	_caption.add_theme_font_size_override("font_size", 16)
	_caption.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_caption)

func play(to_path: String, caption_text: String = "") -> void:
	_caption.text = caption_text
	_caption.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(_rect, "modulate:a", 1.0, 0.42)
	if caption_text != "":
		fade_in.parallel().tween_property(_caption, "modulate:a", 1.0, 0.32)
	await fade_in.finished

	var err := get_tree().change_scene_to_file(to_path)
	if err != OK:
		push_error("场景切换失败：%s（错误码 %d）" % [to_path, err])
	# 场景资源较大时，等新场景至少完成一帧装配后再揭开遮罩。
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_out := create_tween()
	fade_out.tween_interval(0.12)
	fade_out.tween_property(_rect, "modulate:a", 0.0, 0.5)
	if caption_text != "":
		fade_out.parallel().tween_property(_caption, "modulate:a", 0.0, 0.28)
	await fade_out.finished
	queue_free()
