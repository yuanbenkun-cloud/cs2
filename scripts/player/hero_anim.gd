extends AnimatedSprite2D

## 陈默正式角色动画。每组动作由独立多行原图生成、严格 QC 后拆成 128×128 透明帧；
## Godot 只读取单帧文件，避免依赖不规则旧图集的手工切片尺寸。

const ANIMATIONS := {
	"idle": {
		"dir": "res://assets/production/hero/idle",
		"prefix": "idle",
		"count": 4,
		"fps": 3.5,
		"loop": true,
		"origin_y": 116.0,
	},
	"walk": {
		"dir": "res://assets/production/hero/walk",
		"prefix": "walk",
		"count": 6,
		"fps": 5.5,
		"loop": true,
		"origin_y": 116.0,
	},
	"jump": {
		"dir": "res://assets/production/hero/jump",
		"prefix": "jump",
		"count": 4,
		"fps": 5.0,
		"loop": false,
		"origin_y": 104.0,
	},
	"interact": {
		"dir": "res://assets/production/hero/interact",
		"prefix": "interact",
		"count": 4,
		"fps": 5.0,
		"loop": false,
		"origin_y": 116.0,
	},
}

const FRAME_SIZE := 128.0
const REFERENCE_SUBJECT_HEIGHT := 102.0
const TARGET_HEIGHT := 64.0
const DISPLAY_SCALE := TARGET_HEIGHT / REFERENCE_SUBJECT_HEIGHT

var _current_animation := "idle"
var _last_move := 1
var _interacting := 0.0

func _ready() -> void:
	centered = false
	material = null
	_add_ground_shadow()
	_build_frames()
	_apply_animation("idle")

func _add_ground_shadow() -> void:
	var actor := get_parent().get_parent() as Node2D
	if actor == null or actor.has_node("GroundShadow"):
		return
	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-13, 0), Vector2(-10, -2), Vector2(-5, -3), Vector2(5, -3),
		Vector2(10, -2), Vector2(13, 0), Vector2(10, 2), Vector2(5, 3),
		Vector2(-5, 3), Vector2(-10, 2),
	])
	shadow.color = Color(0.015, 0.02, 0.03, 0.28)
	shadow.z_index = 19
	actor.add_child.call_deferred(shadow)

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	for animation_name: String in ANIMATIONS:
		var config: Dictionary = ANIMATIONS[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(config["fps"]))
		frames.set_animation_loop(animation_name, bool(config["loop"]))
		for frame_index in range(1, int(config["count"]) + 1):
			var frame_path := "%s/%s-%d.png" % [config["dir"], config["prefix"], frame_index]
			var texture: Texture2D = load(frame_path)
			if texture != null:
				frames.add_frame(animation_name, texture)
	sprite_frames = frames

func _physics_process(delta: float) -> void:
	if _interacting > 0.0:
		_interacting -= delta
		if _interacting <= 0.0:
			_apply_animation("idle")
		return
	var player := get_parent().get_parent() as CharacterBody2D
	if player == null:
		return
	var moving := absf(player.velocity.x) > 12.0
	var target := "idle"
	if not player.is_on_floor():
		target = "jump"
	elif moving:
		target = "walk"
		_last_move = 1 if player.velocity.x > 0.0 else -1
	flip_h = _last_move < 0
	if target != _current_animation:
		_apply_animation(target)

func trigger_interact() -> void:
	_interacting = float(ANIMATIONS["interact"]["count"]) / float(ANIMATIONS["interact"]["fps"])
	_apply_animation("interact")
	var feedback := get_parent().get_parent().get_node_or_null("FeedbackAnimationPlayer")
	if feedback != null:
		feedback.play("interact")

func _apply_animation(animation_name: String) -> void:
	if not ANIMATIONS.has(animation_name):
		return
	_current_animation = animation_name
	var config: Dictionary = ANIMATIONS[animation_name]
	scale = Vector2.ONE * DISPLAY_SCALE
	# 鞋底压入地面 6px，让角色真正站进路面而非贴在背景边缘上。
	position = Vector2(-FRAME_SIZE * 0.5 * DISPLAY_SCALE, -float(config["origin_y"]) * DISPLAY_SCALE + 6.0)
	if sprite_frames != null and sprite_frames.has_animation(animation_name):
		play(animation_name)
