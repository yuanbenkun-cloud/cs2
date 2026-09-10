class_name ForgeSequence
extends Node

## 锻造状态机：HEAT→QUENCH→CHISEL ×3 轮；岩壁多块色块逐轮裂开；180s 超时 fail。

enum Step { HEAT, QUENCH, CHISEL }
const ROUNDS: int = 3
const TIME_LIMIT: float = 180.0
const OPERATION_TIME: float = 1.0

var current_step: int = Step.HEAT
var current_round: int = 0
var time_left: float = TIME_LIMIT

var _active: bool = false
var _busy: bool = false
var _wall: Node = null
var _timer_label: Label = null
var _notice: Label = null
var _player: Node = null

func _ready() -> void:
	_active = true
	_acquire_refs()
	_refresh_timer()

func _acquire_refs() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	_wall = cur.find_child("di_erguan_yanbi", true, false)
	_timer_label = cur.find_child("UI_Timer", true, false) as Label
	_notice = cur.find_child("UI_Notice", true, false) as Label
	_player = cur.find_child("zhujue", true, false)

func _process(delta: float) -> void:
	if not _active:
		return
	time_left -= delta
	_refresh_timer()
	if time_left <= 0.0:
		time_left = 0.0
		_active = false
		_show_notice("一炷香燃尽了……")
		var lm := get_node_or_null("/root/LevelManager")
		if lm != null:
			lm.call("fail", "一炷香燃尽了。")

func interact_heat() -> void:
	_try_step(Step.HEAT)

func interact_quench() -> void:
	_try_step(Step.QUENCH)

func interact_chisel() -> void:
	_try_step(Step.CHISEL)

func advance() -> void:
	_try_step(current_step)

func _try_step(s: int) -> void:
	if not _active or _busy:
		return
	if s != current_step:
		_show_notice("顺序不对！要先烤热、再浇水、最后凿击。")
		return
	_busy = true
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", true)
	var step_text: String = ["生火烤岩壁…", "浇水冷却…", "铁楔凿击…"][current_step]
	_show_notice(step_text)
	var tw := create_tween()
	tw.tween_interval(OPERATION_TIME)
	tw.tween_callback(_finish_step)

func _finish_step() -> void:
	_busy = false
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", false)
	match current_step:
		Step.HEAT:
			if _wall != null and _wall.has_method("mark_heat"):
				_wall.call("mark_heat")
			current_step = Step.QUENCH
		Step.QUENCH:
			if _wall != null and _wall.has_method("mark_quench"):
				_wall.call("mark_quench")
			current_step = Step.CHISEL
		Step.CHISEL:
			current_round += 1
			if _wall != null and _wall.has_method("crack"):
				_wall.call("crack")
			if current_round >= ROUNDS:
				_active = false
				_show_notice("岩壁裂开了！引水改道，窑场得救。")
				var lm := get_node_or_null("/root/LevelManager")
				if lm != null:
					lm.call("complete")
				return
			current_step = Step.HEAT
			_show_notice("第 %d 轮完成，继续！" % current_round)

func _refresh_timer() -> void:
	if _timer_label != null:
		_timer_label.text = "⏳ %d" % int(ceil(time_left))

func _show_notice(t: String) -> void:
	if _notice != null:
		_notice.text = t
		_notice.visible = true
		get_tree().create_timer(2.4).timeout.connect(func() -> void:
			if is_instance_valid(_notice):
				_notice.visible = false)
