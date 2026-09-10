extends AnimatedSprite2D
## 主角帧表动画（归一化 8 帧条）：待机/行走/跳跃/交互。
## 按帧表实际高度统一缩放到 ~48 世界单位；帧表高度各不同 → 播放时动态缩放对齐。

const SHEETS := {
	"idle": { "path": "res://assets/player_frames_norm/idle_n.png", "fw": 264, "fh": 691, "fps": 5 },
	"walk": { "path": "res://assets/player_frames_norm/walk_n.png", "fw": 1152, "fh": 1946, "fps": 8 },
	"jump": { "path": "res://assets/player_frames_norm/jump_n.png", "fw": 264, "fh": 701, "fps": 10 },
	"interact": { "path": "res://assets/player_frames_norm/interact_n.png", "fw": 264, "fh": 814, "fps": 8 },
}
const TARGET_H := 48.0

var _cur := "idle"
var _last_move := 1

func _ready() -> void:
	centered = false
	_build_frames()
	_apply_anim("idle")

func _build_frames() -> void:
	var sf := SpriteFrames.new()
	for anim in SHEETS:
		var m: Dictionary = SHEETS[anim]
		var tex: Texture2D = load(m["path"])
		if tex == null:
			continue
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(m["fps"]))
		sf.set_animation_loop(anim, anim != "interact")
		var count := 8
		for i in range(count):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(float(i) * float(m["fw"]), 0.0, float(m["fw"]), float(m["fh"]))
			sf.add_frame(anim, at)
	sprite_frames = sf

func _physics_process(_delta: float) -> void:
	if _interacting > 0.0:
		_interacting -= _delta
		if _interacting <= 0.0:
			_apply_anim("idle")
		return
	var p := get_parent()
	if p == null:
		return
	var vel := Vector2.ZERO
	if "velocity" in p:
		vel = p.get("velocity")
	var on_floor := true
	if p.has_method("is_on_floor"):
		on_floor = p.is_on_floor()
	var moving: bool = absf(vel.x) > 12.0
	var target := "idle"
	if not on_floor:
		target = "jump"
	elif moving:
		target = "walk"
		_last_move = 1 if vel.x > 0.0 else -1
	flip_h = _last_move < 0
	if target != _cur:
		_apply_anim(target)


func trigger_interact() -> void:
	# 交互动画播放一次后回待机（跳过 _physics_process 覆盖保护）
	_interacting = 1.0
	_apply_anim("interact")

var _interacting := 0.0

func _apply_anim(name: String) -> void:
	if not SHEETS.has(name):
		return
	_cur = name
	var m: Dictionary = SHEETS[name]
	var s := TARGET_H / float(m["fh"])
	scale = Vector2(s, s)
	position = Vector2(-float(m["fw"]) * s * 0.5, -float(m["fh"]) * s)
	if sprite_frames != null and sprite_frames.has_animation(name):
		play(name)