class_name GroupFollower
extends Node

## 队伍跟随（SPEC 6.6，第四关）：leader 历史位置环形缓冲（0.5s 采样），
## 每个 NPC 移向历史点；人数越多间距越大、转弯越难。

var followers: Array[Node2D] = []
var history: Array[Vector2] = []
var sample_interval: float = 0.2
var max_history: int = 40
var _acc: float = 0.0
var _leader: Node2D = null
var _step: int = 1          # 紧凑队形才能整体进入挡板覆盖范围
var _enabled: bool = false

func _ready() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	_leader = cur.find_child("zhujue", true, false) as Node2D
	var container := cur.find_child("NPC_Group", true, false)
	if container != null:
		for c in container.get_children():
			if c is Node2D and str(c.name).begins_with("NPC_Follower"):
				add_follower(c as Node2D)

func add_follower(npc: Node2D) -> void:
	followers.append(npc)

func start_following() -> void:
	_enabled = true

func restore_at(pos: Vector2) -> void:
	history.clear()
	for i in range(max_history):
		history.append(pos - Vector2(float(i) * 2.0, 0.0))
	for i in followers.size():
		followers[i].global_position = pos - Vector2(18.0 + i * 18.0, 0.0)
	_enabled = true

func _physics_process(delta: float) -> void:
	if not _enabled or _leader == null:
		return
	_acc += delta
	if _acc >= sample_interval:
		_acc = 0.0
		history.append(_leader.global_position)
		if history.size() > max_history:
			history.remove_at(0)
	if history.is_empty():
		return
	for i in followers.size():
		var npc: Node2D = followers[i]
		if npc == null or not is_instance_valid(npc):
			continue
		var idx: int = maxi(0, history.size() - 1 - i * _step)
		var tgt: Vector2 = history[idx]
		var speed: float = maxf(98.0, 120.0 - i * 4.0)
		npc.global_position = npc.global_position.move_toward(tgt, speed * delta)
