class_name PlayerAnimator
extends Node

## 角色表现层：方向、起跳/落地压缩回弹与交互反馈。
## AnimationPlayer 只驱动 VisualPivot，不接触碰撞体与物理位置。

var _face: ColorRect = null
var _hero: Sprite2D = null
var _player: CharacterBody2D = null
var _feedback: AnimationPlayer = null
var _was_on_floor := false

func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		return
	_face = _player.get_node_or_null("FaceRect") as ColorRect
	_hero = _player.get_node_or_null("VisualPivot/zhujue_donghua") as Sprite2D
	if _hero == null:
		_hero = _player.get_node_or_null("KenneyHero") as Sprite2D
	_feedback = _player.get_node_or_null("FeedbackAnimationPlayer") as AnimationPlayer
	_was_on_floor = _player.is_on_floor()

func _physics_process(_delta: float) -> void:
	if _player == null or _feedback == null:
		return
	var on_floor := _player.is_on_floor()
	if _was_on_floor and not on_floor and _player.velocity.y < 0.0:
		_feedback.play("jump_takeoff")
	elif not _was_on_floor and on_floor:
		_feedback.play("land")
	_was_on_floor = on_floor

func set_look(dir: int) -> void:
	if _hero != null:
		_hero.flip_h = dir < 0
		return
	if _face != null:
		_face.position.x = 10.0 if dir > 0 else -14.0

func play_interact_feedback() -> void:
	if _feedback != null:
		_feedback.play("interact")
