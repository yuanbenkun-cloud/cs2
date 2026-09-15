extends Node

## LevelManager（SPEC 6.2）：关卡状态 / 失败 / 重生 / 切换。
## fail → 暂停1.5s 显示文案 → respawn；complete/travel_to → SceneTransition 切换。

const SCENES: Array[String] = [
	"res://scenes/guanqia/01_hongyadong.tscn",
	"res://scenes/guanqia/02_ciqikou.tscn",
	"res://scenes/guanqia/03_zhongshan.tscn",
	"res://scenes/guanqia/04_fangdong.tscn",
	"res://scenes/guanqia/05_hongyadong_return.tscn",
]

const TRANSITION_CAPTIONS := {
	3: "他凿开的不只是一道岩壁。水声退去，市声迎面而来。",
	4: "货包的绳结还在掌心，远处忽然响起防空警报。",
	5: "他把最后一个人带到光里。再睁眼，山城已经天亮。",
}

var current_level: int = 1
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_scene: String = ""
var checkpoint_state: Dictionary = {}
var _fail_layer: CanvasLayer = null
var _fail_label: Label = null
var _failing := false

func _ready() -> void:
	_build_fail_ui()
	var gs := get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("has_continue")):
		current_level = int(gs.call("get_continue_level"))

func _build_fail_ui() -> void:
	_fail_layer = CanvasLayer.new()
	_fail_layer.layer = 40
	_fail_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fail_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fail_layer.add_child(bg)
	_fail_label = Label.new()
	_fail_label.set_anchors_preset(Control.PRESET_CENTER)
	_fail_label.size = Vector2(380, 60)
	_fail_label.position = Vector2(-190, -30)
	_fail_label.add_theme_font_size_override("font_size", 13)
	_fail_label.add_theme_color_override("font_color", Color(1, 0.85, 0.75))
	_fail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fail_label.visible = false
	_fail_layer.add_child(_fail_label)
	bg.visible = false

func fail(reason: String) -> void:
	## 暂停 1.5s 显示失败文案 → respawn()
	if _failing:
		return
	_failing = true
	_fail_label.text = reason
	_fail_label.visible = true
	_fail_layer.get_child(0).visible = true
	get_tree().paused = true
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(1.5)
	tw.tween_callback(func() -> void:
		get_tree().paused = false
		_fail_label.visible = false
		_fail_layer.get_child(0).visible = false
		respawn())

func complete() -> void:
	## 通关 → 下一场景（含穿越转场）
	if current_level >= SCENES.size():
		return
	current_level += 1
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if current_level == 3:
			gs.call("reset_goods")
		gs.call("save_progress", current_level)
	_go(SCENES[current_level - 1], str(TRANSITION_CAPTIONS.get(current_level, "")))

func travel_to(level: int, caption: String = "") -> void:
	## 穿越跳关（第 1 关松动地砖 → 02 等）
	if level < 1 or level > SCENES.size():
		return
	current_level = level
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("save_progress", current_level)
	_go(SCENES[level - 1], caption)

func start_new_story() -> void:
	current_level = 1
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("begin_new_story")
	var director := get_node_or_null("/root/StoryDirector")
	if director != null:
		director.call("play_prologue", Callable(self, "_open_first_level"))
	else:
		_open_first_level()

func _open_first_level() -> void:
	travel_to(1, "洪崖洞 · 迷途")

func continue_story() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not bool(gs.call("has_continue")):
		start_new_story()
		return
	current_level = int(gs.call("get_continue_level"))
	_go(SCENES[current_level - 1], "继续旅程 · 第 %d 章" % current_level)

func start_chapter(level: int) -> void:
	if level < 1 or level > SCENES.size():
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		var unlocked := int(gs.get("highest_unlocked_level"))
		if level > unlocked:
			return
		gs.call("begin_from_chapter", level)
	current_level = level
	_go(SCENES[level - 1], "重温旅程 · 第 %d 章" % level)

func finish_story(choice: String = "observe") -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("mark_story_complete", choice)
	_go("res://scenes/jieju.tscn", "天亮了。他终于知道这一程该留下什么。")

func return_to_title() -> void:
	current_level = 1
	_go("res://scenes/kaishi.tscn", "故事走到这里，但看见才刚刚开始。")

func register_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	var scene := get_tree().current_scene
	checkpoint_scene = scene.scene_file_path if scene != null else ""
	checkpoint_state.clear()
	if scene != null:
		for shield in scene.find_children("BlastShield*", "Node2D", true, false):
			if shield.has_method("get_checkpoint_state"):
				checkpoint_state[str(shield.name)] = shield.call("get_checkpoint_state")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "ui_confirm", 1.1, -2.0)

func respawn() -> void:
	## 重载保证机制处于确定状态；若本关登记过检查点，再恢复位置与可存档对象。
	var dialogue := get_node_or_null("/root/DialogueSystem")
	if dialogue != null and dialogue.has_method("cancel_for_scene_change"):
		dialogue.call("cancel_for_scene_change")
	var scene := get_tree().current_scene
	var can_restore := scene != null and checkpoint_pos != Vector2.ZERO and checkpoint_scene == scene.scene_file_path
	# 第一关的检查点位于追逐触发器之后。直接恢复会让玩家越过传单阿姨和 ChaseStart，
	# 看起来就像追兵消失了；追逐战失败时应从街口完整重开。
	if scene != null and scene.scene_file_path in [SCENES[0], SCENES[3]]:
		can_restore = false
	get_tree().reload_current_scene()
	_restore_after_reload.call_deferred(can_restore)

func _restore_after_reload(can_restore: bool) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_failing = false
	if not can_restore:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.find_child("zhujue", true, false) as Node2D
	if player != null:
		player.global_position = checkpoint_pos
	var group := scene.find_child("GroupFollower", true, false)
	if group != null and group.has_method("restore_at"):
		group.call("restore_at", checkpoint_pos)
	for node_name: String in checkpoint_state:
		var target := scene.find_child(node_name, true, false)
		if target != null and target.has_method("restore_checkpoint_state"):
			target.call("restore_checkpoint_state", checkpoint_state[node_name])
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "ui_confirm", 0.9, -3.0)

func _go(path: String, caption: String = "") -> void:
	var dialogue := get_node_or_null("/root/DialogueSystem")
	if dialogue != null and dialogue.has_method("cancel_for_scene_change"):
		dialogue.call("cancel_for_scene_change")
	checkpoint_pos = Vector2.ZERO
	checkpoint_scene = ""
	checkpoint_state.clear()
	var director := get_node_or_null("/root/StoryDirector")
	if director != null:
		director.call("play_transition", path, current_level, caption)
		return
	## 无导演时使用轻量黑幕回退，保证场景切换仍可用。
	var transition: Node = load("res://scripts/systems/scene_transition.gd").new()
	get_tree().root.add_child(transition)
	transition.call("play", path, caption)
