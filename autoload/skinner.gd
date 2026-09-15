extends Node
## 皮肤注入 v3：把 NPC 占位替换为 NPC 帧表待机动画（AnimatedSprite2D，8-? 帧循环）。
## 帧元数据读 assets/npc_anim/meta.json；缺失时回退旧静态立绘。

const META_PATH := "res://assets/npc_anim/meta.json"
const FALLBACK := {
	"NPC_FlyerLady": "res://assets/generated/npc_flyerlady.png",
	"NPC_OldArtisan": "res://assets/generated/npc_oldartisan.png",
	"NPC_AMing": "res://assets/generated/npc_aming.png",
	"NPC_OldShopkeeper": "res://assets/generated/npc_oldshopkeeper.png",
	"NPC_FatTeahouse": "res://assets/generated/npc_teahouse.png",
	"NPC_Helper": "res://assets/generated/npc_helper.png",
	"NPC_LaoZhou": "res://assets/generated/npc_laozhou.png",
	"NPC_OldMan": "res://assets/generated/npc_oldman.png",
}
const NPCS := {
	"chuandanayi": "flyer_lady",
	"laojiangren": "old_artisan",
	"aming": "aming",
	"laozhanggui": "old_shopkeeper",
	"pangzhanggui": "fat_teahouse",
	"banggong": "helper",
	"laozhou": "laozhou",
	"jianglishilaoren": "old_man",
}
const FOLLOWER_KEYS := ["helper", "old_man", "aming"]
const NPC_IDLE_FPS := 2.5
const NPC_WALK_FPS := 4.0

var _meta: Dictionary = {}
var _last_scene: Node = null
var _facing_records: Array[Dictionary] = []

func _ready() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_meta = parsed

func _process(delta: float) -> void:
	var sc := get_tree().current_scene
	if sc == null:
		return
	if sc != _last_scene:
		_last_scene = sc
		_facing_records.clear()
		_apply(sc)
	_update_facing_and_motion(sc, delta)

func _apply(sc: Node) -> void:
	for npc_name: String in NPCS:
		var n := sc.find_child(npc_name, true, false)
		if n != null:
			_skin(n, NPCS[npc_name])
	var grp := sc.find_child("NPC_Group", true, false)
	if grp != null:
		var idx := 0
		for c in grp.get_children():
			if str(c.name).begins_with("NPC_Follower"):
				_skin(c as Node2D, FOLLOWER_KEYS[idx % FOLLOWER_KEYS.size()])
				idx += 1

func _skin(n: Node2D, key: String) -> void:
	if n == null or not is_instance_valid(n):
		return
	if n.find_child("SkinAnim", false, false) != null:
		return
	_add_ground_shadow(n)
	for c in n.get_children():
		if c is ColorRect and str(c.name) != "Prompt":
			c.visible = false
	var visual_parent := n.get_node_or_null("VisualPivot") as Node2D
	if visual_parent == null:
		visual_parent = n
	var m: Dictionary = _meta.get(key, {})
	if m.is_empty():
		var fb: String = FALLBACK.get(str(n.name), "")
		if fb == "":
			return
		var tex: Texture2D = load(fb)
		if tex == null:
			return
		var spr := Sprite2D.new()
		spr.name = "SkinAnim"
		spr.texture = tex
		spr.centered = false
		spr.position = Vector2(-16, -48)
		visual_parent.add_child(spr)
		_register_facing(n, spr)
		return
	var sheet: Texture2D = load(str(m["file"]))
	if sheet == null:
		return
	var fw: int = int(m["fw"])
	var fh: int = int(m["fh"])
	var count: int = int(m["count"])
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", NPC_IDLE_FPS)
	sf.set_animation_loop("idle", true)
	sf.add_animation("walk")
	sf.set_animation_speed("walk", NPC_WALK_FPS)
	sf.set_animation_loop("walk", true)
	for i in range(mini(count, 3)):
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(float(i) * float(fw), 0.0, float(fw), float(fh))
		sf.add_frame("idle", at)
	var walk_sheet: Texture2D = load(str(m.get("walk_file", m["file"])))
	var walk_fw := int(m.get("walk_fw", fw))
	var walk_fh := int(m.get("walk_fh", fh))
	var walk_count := int(m.get("walk_count", count))
	var walk_cols := int(m.get("walk_cols", walk_count))
	for i in range(walk_count):
		var walk_at := AtlasTexture.new()
		walk_at.atlas = walk_sheet
		walk_at.region = Rect2(float(i % walk_cols) * float(walk_fw), float(floori(float(i) / float(walk_cols))) * float(walk_fh), float(walk_fw), float(walk_fh))
		sf.add_frame("walk", walk_at)
	var anim := AnimatedSprite2D.new()
	anim.name = "SkinAnim"
	anim.centered = key == "flyer_lady"
	anim.sprite_frames = sf
	anim.material = null
	anim.self_modulate = Color.WHITE
	if key == "flyer_lady":
		# 阿姨的深色服装在第五关晨雾与灯光下会显得被背景透过；保持原图实色。
		var opaque_shader := Shader.new()
		opaque_shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){ vec4 c = texture(TEXTURE, UV); if(c.a < 0.08){ discard; } COLOR = vec4(c.rgb, 1.0); }"
		var opaque_material := ShaderMaterial.new()
		opaque_material.shader = opaque_shader
		anim.material = opaque_material
		n.modulate = Color.WHITE
		n.self_modulate = Color.WHITE
		visual_parent.modulate = Color.WHITE
		visual_parent.self_modulate = Color.WHITE
	var s := 60.0 / float(fh)
	anim.scale = Vector2(s, s)
	anim.position = Vector2(0.0, -30.0) if anim.centered else Vector2(-float(fw) * s * 0.5, -float(fh) * s)
	visual_parent.add_child(anim)
	anim.play("idle")
	_register_facing(n, anim)

func _register_facing(actor: Node2D, visual: Node2D) -> void:
	for record in _facing_records:
		if record.get("actor") == actor:
			return
	_facing_records.append({
		"actor": actor,
		"visual": visual,
		"last_x": actor.global_position.x,
		"facing": -1,
		"base_position": visual.position,
		"base_scale": visual.scale,
		"phase": randf_range(0.0, TAU),
		"motion_blend": 0.0,
		"moving_grace": 0.0,
	})
	visual.set("flip_h", false)
	actor.set_meta("facing_direction", -1)

func _update_facing_and_motion(scene: Node, delta: float) -> void:
	var player := scene.find_child("zhujue", true, false) as Node2D
	for i in range(_facing_records.size() - 1, -1, -1):
		var record: Dictionary = _facing_records[i]
		var actor := record.get("actor") as Node2D
		var visual := record.get("visual") as Node2D
		if not is_instance_valid(actor) or not is_instance_valid(visual):
			_facing_records.remove_at(i)
			continue
		if str(actor.name) == "chuandanayi":
			actor.modulate = Color.WHITE
			actor.self_modulate = Color.WHITE
			visual.modulate = Color.WHITE
			visual.self_modulate = Color.WHITE
		var current_x := actor.global_position.x
		var movement_x := current_x - float(record.get("last_x", current_x))
		var movement_speed := absf(movement_x) / maxf(delta, 0.0001)
		var direction := int(record.get("facing", -1))
		# 追逐/跟随时优先服从实际移动方向；静止时在近距离看向玩家。
		if movement_speed > 4.0:
			direction = 1 if movement_x > 0.0 else -1
		elif is_instance_valid(player):
			var player_dx := player.global_position.x - current_x
			if absf(player_dx) > 5.0 and absf(player_dx) < 300.0:
				direction = 1 if player_dx > 0.0 else -1
		visual.set("flip_h", direction > 0)
		actor.set_meta("facing_direction", direction)
		# 物理帧之间可能穿插多个渲染帧；短暂保留移动状态，防止 walk/idle 闪烁。
		var moving_grace := float(record.get("moving_grace", 0.0))
		if movement_speed > 4.0:
			moving_grace = 0.14
		else:
			moving_grace = maxf(0.0, moving_grace - delta)
		var moving := moving_grace > 0.0
		var target_blend := 1.0 if moving else 0.0
		var blend := move_toward(float(record.get("motion_blend", 0.0)), target_blend, delta * 5.0)
		var phase := float(record.get("phase", 0.0)) + delta * (7.0 if moving else 1.8)
		var stride := absf(sin(phase)) * blend
		var talking := bool(actor.get_meta("talking", false))
		var talk_bob := absf(sin(phase * 0.72)) * 0.75 if talking and not moving else 0.0
		var base_position: Vector2 = record.get("base_position", visual.position)
		var base_scale: Vector2 = record.get("base_scale", visual.scale)
		visual.position = base_position + Vector2(0.0, -stride * 1.15 - talk_bob)
		visual.scale = Vector2(base_scale.x * (1.0 + stride * 0.012), base_scale.y * (1.0 - stride * 0.017))
		if visual is AnimatedSprite2D:
			var animated := visual as AnimatedSprite2D
			var wanted_animation := &"walk" if moving else &"idle"
			if animated.animation != wanted_animation:
				animated.play(wanted_animation)
			animated.speed_scale = 1.0
		record["last_x"] = current_x
		record["facing"] = direction
		record["phase"] = phase
		record["motion_blend"] = blend
		record["moving_grace"] = moving_grace
		_facing_records[i] = record

func _add_ground_shadow(actor: Node2D) -> void:
	if actor.has_node("GroundShadow"):
		return
	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-11, 0), Vector2(-8, -2), Vector2(-4, -3), Vector2(4, -3),
		Vector2(8, -2), Vector2(11, 0), Vector2(8, 2), Vector2(4, 3),
		Vector2(-4, 3), Vector2(-8, 2),
	])
	shadow.color = Color(0.015, 0.02, 0.03, 0.24)
	shadow.z_index = 19
	actor.add_child(shadow)
