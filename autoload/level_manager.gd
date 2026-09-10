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

var current_level: int = 1
var checkpoint_pos: Vector2 = Vector2.ZERO
var _fail_layer: CanvasLayer = null
var _fail_label: Label = null

func _ready() -> void:
	_build_fail_ui()

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
	_go(SCENES[current_level - 1])

func travel_to(level: int, caption: String = "") -> void:
	## 穿越跳关（第 1 关松动地砖 → 02 等）
	if level < 1 or level > SCENES.size():
		return
	current_level = level
	_go(SCENES[level - 1], caption)

func register_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos

func respawn() -> void:
	## 玩家回 checkpoint_pos、重置本关机制（确定性实现：重载当前场景）
	## （实现细节偏离：见 DEV_LOG —— 以重载场景实现“关卡重置/从存档点重来”）
	get_tree().reload_current_scene()

func _go(path: String, caption: String = "") -> void:
	## 进入第三关时重置本局货物完整度
	if path == SCENES[2]:
		var gs := get_node_or_null("/root/GameState")
		if gs != null:
			gs.call("reset_goods")
	## 按路径加载转场（避免依赖全局类缓存/类名解析）
	var tr: Node = load("res://scripts/systems/scene_transition.gd").new()
	get_tree().root.add_child(tr)
	tr.call("play", path, caption)