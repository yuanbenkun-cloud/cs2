class_name BombWarning
extends Node

## 第四关空袭：预警落点 → 可见导弹下落 → 挡板拦截或地面爆炸。
enum Phase { COOLDOWN, WARNING, FALLING, RESOLVE }

const GROUND_Y := 226.0
const WARNING_TIME := 0.82
const INITIAL_COOLDOWN := 3.0
const EARLY_COOLDOWN_MIN := 2.3
const EARLY_COOLDOWN_MAX := 3.0
const LATE_COOLDOWN_MIN := 0.35
const LATE_COOLDOWN_MAX := 0.70
const RAMP_STRIKES := 3
const RESOLVE_DELAY := 0.35
const MISSILE_START_Y := -38.0
const BLAST_RADIUS := 54.0

var _phase: int = Phase.COOLDOWN
var _cooldown := INITIAL_COOLDOWN
var _warn_left := 0.0
var _pending_x := 0.0
var _fall_speed := 165.0
var _strike_count := 0
var _active := false
var _flash: ColorRect
var _marker: Node2D
var _marker_rect: ColorRect
var _missile: Node2D
var _missile_flame: Polygon2D
var _status: Label
var _shields: Array[Node] = []

func _ready() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	_flash = cur.find_child("UI_BombFlash", true, false) as ColorRect
	_status = cur.find_child("UI_BombStatus", true, false) as Label
	_shields.assign(cur.find_children("BlastShield*", "Node2D", true, false))
	_build_marker(cur)
	_build_missile(cur)
	await get_tree().process_frame
	_active = true

func _process(delta: float) -> void:
	if not _active:
		return
	match _phase:
		Phase.COOLDOWN:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_start_warning()
		Phase.WARNING:
			_warn_left -= delta
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.026)
			_marker.scale = Vector2.ONE * (0.92 + pulse * 0.18)
			_marker_rect.modulate.a = 0.55 + pulse * 0.45
			if _flash != null:
				var access := get_node_or_null("/root/Accessibility")
				var flash_scale := float(access.get("flash_scale")) if access != null else 1.0
				_flash.modulate.a = (0.05 + pulse * 0.08) * flash_scale
			if _warn_left <= 0.0:
				_launch_missile()
		Phase.FALLING:
			_fall_speed += 230.0 * delta
			_missile.position.y += _fall_speed * delta
			_missile_flame.scale.y = 0.78 + randf_range(0.0, 0.45)
			var shield := _shield_at(_pending_x)
			var impact_y := GROUND_Y
			if shield != null:
				impact_y = float(shield.call("get_impact_y"))
			if _missile.position.y >= impact_y:
				_explode(shield)

func stop() -> void:
	_active = false
	if _marker != null:
		_marker.visible = false
	if _missile != null:
		_missile.visible = false
	if _flash != null:
		_flash.visible = false
	if _status != null:
		_status.visible = false

func _start_warning() -> void:
	var cur := get_tree().current_scene
	var player := cur.find_child("zhujue", true, false) as Node2D
	var base := 180.0 if player == null else player.global_position.x
	_pending_x = clampf(base + randf_range(-42.0, 72.0), 130.0, 1260.0)
	_phase = Phase.WARNING
	_warn_left = WARNING_TIME
	_marker.visible = true
	_marker.global_position = Vector2(_pending_x, GROUND_Y)
	_marker_rect.color = Color("#ff4e35")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "alert", 0.82, -1.0)
	if _flash != null:
		_flash.visible = true
	if _status != null:
		_status.text = "空袭预警！进入挡板下方，或离开红色落点"
		_status.visible = true

func _launch_missile() -> void:
	_phase = Phase.FALLING
	_fall_speed = 165.0
	_missile.global_position = Vector2(_pending_x, MISSILE_START_Y)
	_missile.visible = true
	if _status != null:
		_status.text = "航弹下落！"

func _explode(shield: Node) -> void:
	_phase = Phase.RESOLVE
	var impact_pos := _missile.global_position
	_missile.visible = false
	_marker.visible = false
	if _flash != null:
		_flash.visible = false
	_spawn_explosion(impact_pos, shield != null)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "explosion", 0.78 if shield != null else 0.68, -1.0 if shield != null else 1.5)
	var camera := get_tree().current_scene.find_child("Camera2D", true, false)
	if camera != null and camera.has_method("shake"):
		camera.call("shake", 6.5 if shield == null else 4.0, 0.32)
	if shield != null:
		shield.call("absorb_hit")
		if _status != null:
			_status.text = "挡板接住了冲击，但耐久正在下降"
	else:
		if _hit_anyone(Vector2(_pending_x, GROUND_Y), BLAST_RADIUS):
			var lm := get_node_or_null("/root/LevelManager")
			if lm != null:
				lm.call("fail", "落弹穿过了掩体空隙——队伍里有人没能走出去。")
		if _status != null:
			_status.text = "爆炸！下一轮空袭即将到来"
	get_tree().create_timer(RESOLVE_DELAY).timeout.connect(_reset_cycle)

func _reset_cycle() -> void:
	if _status != null:
		_status.visible = false
	_phase = Phase.COOLDOWN
	var bounds := _current_cooldown_bounds()
	_cooldown = randf_range(bounds.x, bounds.y)
	_strike_count += 1

func _current_cooldown_bounds() -> Vector2:
	var pressure := clampf(float(_strike_count) / float(RAMP_STRIKES), 0.0, 1.0)
	return Vector2(
		lerpf(EARLY_COOLDOWN_MIN, LATE_COOLDOWN_MIN, pressure),
		lerpf(EARLY_COOLDOWN_MAX, LATE_COOLDOWN_MAX, pressure)
	)

func _shield_at(world_x: float) -> Node:
	for shield in _shields:
		if is_instance_valid(shield) and shield.has_method("covers_x") and bool(shield.call("covers_x", world_x)):
			return shield
	return null

func _hit_anyone(pos: Vector2, radius: float) -> bool:
	var cur := get_tree().current_scene
	if cur == null:
		return false
	var targets: Array[Node2D] = []
	var player := cur.find_child("zhujue", true, false) as Node2D
	if player != null:
		targets.append(player)
	var container := cur.find_child("NPC_Group", true, false)
	if container != null:
		for child in container.get_children():
			if child is Node2D:
				targets.append(child as Node2D)
	for target in targets:
		if target.global_position.distance_to(pos) < radius:
			return true
	return false

func _build_marker(cur: Node) -> void:
	_marker = Node2D.new()
	_marker.name = "BombMarker"
	_marker.z_index = 35
	_marker_rect = ColorRect.new()
	_marker_rect.color = Color("#ff4e35")
	_marker_rect.size = Vector2(76, 7)
	_marker_rect.position = Vector2(-38, -3.5)
	_marker.add_child(_marker_rect)
	cur.add_child.call_deferred(_marker)
	_marker.visible = false

func _build_missile(cur: Node) -> void:
	_missile = Node2D.new()
	_missile.name = "FallingMissile"
	_missile.z_index = 40
	var missile_material := CanvasItemMaterial.new()
	missile_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_missile.material = missile_material
	var body := Sprite2D.new()
	body.use_parent_material = true
	body.texture = load("res://assets/production/props/gameplay/aerial-bomb.png")
	_missile.add_child(body)
	_missile_flame = Polygon2D.new()
	_missile_flame.use_parent_material = true
	_missile_flame.polygon = PackedVector2Array([Vector2(-4, -19), Vector2(4, -19), Vector2(0, -31)])
	_missile_flame.color = Color(0.88, 0.72, 0.43, 0.72)
	_missile.add_child(_missile_flame)
	cur.add_child.call_deferred(_missile)
	_missile.visible = false

func _spawn_explosion(pos: Vector2, blocked: bool) -> void:
	var burst := Polygon2D.new()
	burst.name = "ExplosionBurst"
	burst.z_index = 42
	var points := PackedVector2Array()
	for i in range(16):
		var radius := 18.0 if i % 2 == 0 else 8.0
		var angle := TAU * float(i) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	burst.polygon = points
	burst.color = Color("#ffd166") if blocked else Color("#ff6a3d")
	burst.global_position = pos
	get_tree().current_scene.add_child(burst)
	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2.ONE * 2.4, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.38)
	tween.tween_callback(burst.queue_free)
	var debris := CPUParticles2D.new()
	debris.name = "ExplosionDebris"
	debris.z_index = 41
	debris.global_position = pos
	debris.amount = 18 if blocked else 28
	debris.lifetime = 0.85
	debris.one_shot = true
	debris.explosiveness = 0.95
	debris.direction = Vector2(0, -1)
	debris.spread = 72.0
	debris.gravity = Vector2(0, 150)
	debris.initial_velocity_min = 60.0
	debris.initial_velocity_max = 150.0
	debris.scale_amount_min = 1.5
	debris.scale_amount_max = 3.8
	debris.color = Color(0.55, 0.48, 0.4, 0.82) if blocked else Color(0.24, 0.22, 0.22, 0.9)
	get_tree().current_scene.add_child(debris)
	debris.emitting = true
	get_tree().create_timer(1.2).timeout.connect(debris.queue_free)
