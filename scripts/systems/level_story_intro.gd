extends Node
## 第四关目标提示：章节过场结束后再显示，避免与全局叙事导演重叠。

func _ready() -> void:
	call_deferred("_play_intro")

func _play_intro() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		cur = get_parent()
	var director := get_node_or_null("/root/StoryDirector")
	while director != null and bool(director.get("busy")):
		await get_tree().process_frame
	var follower := cur.find_child("GroupFollower", true, false)
	if follower != null:
		follower.call("start_following")
	var layer := CanvasLayer.new()
	layer.name = "StoryIntroLayer"
	layer.layer = 28
	cur.add_child(layer)
	var panel := ColorRect.new()
	panel.name = "StoryIntroPanel"
	panel.color = Color("#090a0dcc")
	panel.position = Vector2(110, 22)
	panel.size = Vector2(420, 72)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var title := Label.new()
	title.text = "护送目标 · 六人，一个都不能少"
	title.position = Vector2(18, 10)
	title.size = Vector2(384, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#e8b04b"))
	panel.add_child(title)
	var story := Label.new()
	story.text = "跟紧灯光，利用挡板躲避落弹，把所有人带到出口。"
	story.position = Vector2(18, 36)
	story.size = Vector2(384, 22)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 11)
	story.add_theme_color_override("font_color", Color("#e6dfd2"))
	panel.add_child(story)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.35)
	tween.tween_interval(1.7)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	layer.queue_free()
