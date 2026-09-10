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
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, 0.5)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file.call_deferred(to_path))
	tw.tween_interval(0.2)
	tw.tween_property(_rect, "modulate:a", 0.0, 0.5)
	if caption_text != "":
		tw.parallel().tween_property(_caption, "modulate:a", 1.0, 0.5)
