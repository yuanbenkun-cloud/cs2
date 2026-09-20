class_name GroupFollower
extends Node

## 第四关护送队伍：按主角的历史横向位置排队，保持落后而不掉队。

const MIN_FOLLOW_SPEED := 155.0
const TRAIL_SPACING := 26.0

var followers: Array[Node2D] = []
var history: Array[Vector2] = []
var sample_interval: float = 0.2
var max_history: int = 40
var _acc: float = 0.0
var _leader: Node2D = null
var _step: int = 1          # 紧凑队形才能整体进入挡板覆盖范围
var _enabled: bool = false

func _ready() -> void:
	# 场景切换期间 current_scene 可能仍是上一关；只从所属关卡根节点绑定。
	var level_root := get_parent()
	_leader = level_root.get_node_or_null("zhujue") as Node2D
	var container := level_root.get_node_or_null("NPC_Group")
	if container != null:
		for c in container.get_children():
			if c is Node2D and str(c.name).begins_with("NPC_Follower"):
				add_follower(c as Node2D)

func add_follower(npc: Node2D) -> void:
	followers.append(npc)

func start_following() -> void:
	if _leader == null:
		return
	if history.is_empty():
		_seed_history(_leader.global_position)
	_enabled = true

func restore_at(pos: Vector2) -> void:
	_seed_history(pos)
	for i in followers.size():
		followers[i].global_position.x = pos.x - TRAIL_SPACING * float(i + 1)
	_enabled = true

func _seed_history(pos: Vector2) -> void:
	history.clear()
	_acc = 0.0
	for i in range(max_history):
		history.append(pos - Vector2(TRAIL_SPACING * float(max_history - 1 - i), 0.0))

func _physics_process(delta: float) -> void:
	if not _enabled and _can_start_following():
		start_following()
	if not _enabled or _leader == null:
		return
	_acc += delta
	if _acc >= sample_interval:
		_acc -= sample_interval
		history.append(_leader.global_position)
		if history.size() > max_history:
			history.remove_at(0)
	if history.is_empty():
		return
	for i in followers.size():
		var npc: Node2D = followers[i]
		if npc == null or not is_instance_valid(npc):
			continue
		var idx: int = maxi(0, history.size() - 1 - (i + 1) * _step)
		var next_idx: int = mini(idx + 1, history.size() - 1)
		var tgt: Vector2 = history[idx].lerp(history[next_idx], clampf(_acc / sample_interval, 0.0, 1.0))
		# 主角跳跃时群众仍沿地面走，不追随主角的垂直坐标。
		tgt.y = npc.global_position.y
		var gap := absf(tgt.x - npc.global_position.x)
		var speed := MIN_FOLLOW_SPEED + minf(maxf(gap - TRAIL_SPACING, 0.0) * 0.45, 85.0)
		npc.global_position = npc.global_position.move_toward(tgt, speed * delta)

func _can_start_following() -> bool:
	if _leader == null or not is_instance_valid(_leader) or followers.is_empty():
		return false
	if get_tree().current_scene != get_parent():
		return false
	var director := get_node_or_null("/root/StoryDirector")
	if director != null and bool(director.get("busy")):
		return false
	return not bool(_leader.get("frozen"))
