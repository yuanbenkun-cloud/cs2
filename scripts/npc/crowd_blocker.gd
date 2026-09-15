extends AnimatableBody2D
## 第一关移动人流：平时在街面缓慢穿行，追逐中预警后逆向切入玩家路线。

enum State { STROLL, WARN, INTERCEPT, HOLD, LEAVE, PASSED }

const CROWD_FPS := 2.5
const PEOPLE := [
	{"file": "res://assets/npc_anim/tourist.png", "fw": 520, "fh": 484, "count": 6, "height": 53.0},
	{"file": "res://assets/npc_anim/aming.png", "fw": 198, "fh": 437, "count": 8, "height": 57.0},
	{"file": "res://assets/npc_anim/helper.png", "fw": 216, "fh": 475, "count": 8, "height": 55.0},
]

@export var trigger_distance := 190.0
@export var warning_time := 0.48
@export var block_time := 0.92
@export var stroll_span := 24.0
@export var stroll_speed := 0.58
@export var intercept_distance := 74.0
@export var intercept_speed := 62.0
@export var chaser_slow_radius := 66.0

var _state: int = State.STROLL
var _player: Node2D
var _manager: Node
var _origin_x := 0.0
var _timer := 0.0
var _phase := 0.0
var _warning: Label
var _visuals: Array[AnimatedSprite2D] = []

func _ready() -> void:
	_origin_x = position.x
	_phase = float(_crowd_index()) * 1.37
	var cur := get_tree().current_scene
	if cur == null:
		cur = get_parent()
	_player = cur.find_child("zhujue", true, false) as Node2D
	_manager = cur.find_child("ChaseManager", true, false)
	_build_crowd_model()
	_build_warning()
	_update_facing(-1)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	match _state:
		State.STROLL:
			_phase += delta * stroll_speed
			var previous_x := position.x
			position.x = _origin_x + sin(_phase) * stroll_span
			_update_facing(1 if position.x > previous_x else -1)
			if _manager != null and bool(_manager.get("chasing")) and global_position.x - _player.global_position.x < trigger_distance:
				_state = State.WARN
				_timer = warning_time
				_warning.visible = true
		State.WARN:
			_timer -= delta
			_warning.modulate.a = 0.5 + absf(sin(Time.get_ticks_msec() * 0.015)) * 0.5
			if _timer <= 0.0:
				_state = State.INTERCEPT
				_warning.visible = false
		State.INTERCEPT:
			_update_facing(-1)
			position.x = move_toward(position.x, _origin_x - intercept_distance, intercept_speed * delta)
			if is_equal_approx(position.x, _origin_x - intercept_distance):
				_state = State.HOLD
				_timer = block_time
		State.HOLD:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.LEAVE
		State.LEAVE:
			_update_facing(-1)
			position.x = move_toward(position.x, _origin_x - intercept_distance - 54.0, intercept_speed * 1.15 * delta)
			if is_equal_approx(position.x, _origin_x - intercept_distance - 54.0):
				_state = State.PASSED
				_phase = PI
		State.PASSED:
			_phase += delta * stroll_speed * 0.72
			var previous_x := position.x
			position.x = _origin_x - intercept_distance - 54.0 + sin(_phase) * 14.0
			_update_facing(1 if position.x > previous_x else -1)

func _build_crowd_model() -> void:
	for child in get_children():
		if child is Sprite2D:
			(child as Sprite2D).visible = false
	var offsets := [-46.0, -23.0, 0.0, 23.0, 46.0]
	var seed := _crowd_index()
	for i in range(5):
		var spec: Dictionary = PEOPLE[(seed + i) % PEOPLE.size()]
		var sheet: Texture2D = load(str(spec["file"]))
		if sheet == null:
			continue
		var frames := SpriteFrames.new()
		frames.add_animation("walk")
		frames.set_animation_speed("walk", CROWD_FPS)
		frames.set_animation_loop("walk", true)
		for frame_index in range(int(spec["count"])):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(float(frame_index * int(spec["fw"])), 0.0, float(spec["fw"]), float(spec["fh"]))
			frames.add_frame("walk", atlas)
		var actor := AnimatedSprite2D.new()
		actor.name = "CrowdActor%d" % (i + 1)
		actor.sprite_frames = frames
		actor.centered = false
		actor.z_index = 20 + i
		var scale_factor := float(spec["height"]) / float(spec["fh"])
		actor.scale = Vector2.ONE * scale_factor
		actor.position = Vector2(offsets[i] - float(spec["fw"]) * scale_factor * 0.5, 25.0 - float(spec["fh"]) * scale_factor)
		actor.frame = (seed + i * 2) % int(spec["count"])
		actor.play("walk")
		add_child(actor)
		_visuals.append(actor)
		_add_shadow(Vector2(offsets[i], 24.0), i)

func _build_warning() -> void:
	_warning = Label.new()
	_warning.name = "FlowWarning"
	_warning.text = "人流!"
	_warning.position = Vector2(-23, -51)
	_warning.size = Vector2(46, 18)
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.add_theme_font_size_override("font_size", 10)
	_warning.add_theme_color_override("font_color", Color("#fff0bd"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#8f342f")
	box.border_color = Color("#ffd27b")
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	_warning.add_theme_stylebox_override("normal", box)
	_warning.visible = false
	_warning.z_index = 30
	add_child(_warning)

func _add_shadow(at: Vector2, index: int) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "CrowdShadow%d" % index
	shadow.position = at
	shadow.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(-7, -2), Vector2(7, -2), Vector2(10, 0), Vector2(7, 2), Vector2(-7, 2)])
	shadow.color = Color(0.01, 0.015, 0.025, 0.3)
	shadow.z_index = 19
	add_child(shadow)

func _update_facing(direction: int) -> void:
	for i in range(_visuals.size()):
		_visuals[i].flip_h = direction > 0 if i != 1 else direction < 0

func _crowd_index() -> int:
	var suffix := str(name).get_slice("_", str(name).count("_"))
	return maxi(int(suffix), 1)

func get_state_name() -> String:
	return State.keys()[_state]

func slows_chaser_at(world_position: Vector2) -> bool:
	## 五个人形成的拥挤区域；阿姨穿入时被人流拖慢，离开边界立即恢复追速。
	return absf(world_position.x - global_position.x) <= chaser_slow_radius \
		and absf(world_position.y - global_position.y) <= 62.0
