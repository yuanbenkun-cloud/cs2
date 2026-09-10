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

var _meta: Dictionary = {}
var _last_scene: Node = null

func _ready() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_meta = parsed

func _process(_delta: float) -> void:
	var sc := get_tree().current_scene
	if sc == null:
		return
	if sc != _last_scene:
		_last_scene = sc
		_apply(sc)

func _apply(sc: Node) -> void:
	for name: String in NPCS:
		var n := sc.find_child(name, true, false)
		if n != null:
			_skin(n, NPCS[name])
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
	for c in n.get_children():
		if c is ColorRect and str(c.name) != "Prompt":
			c.visible = false
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
		n.add_child(spr)
		return
	var sheet: Texture2D = load(str(m["file"]))
	if sheet == null:
		return
	var fw: int = int(m["fw"])
	var fh: int = int(m["fh"])
	var count: int = int(m["count"])
	var fps: int = int(m.get("fps", 6))
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", float(fps))
	sf.set_animation_loop("idle", true)
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(float(i) * float(fw), 0.0, float(fw), float(fh))
		sf.add_frame("idle", at)
	var anim := AnimatedSprite2D.new()
	anim.name = "SkinAnim"
	anim.centered = false
	anim.sprite_frames = sf
	var s := 48.0 / float(fh)
	anim.scale = Vector2(s, s)
	anim.position = Vector2(-float(fw) * s * 0.5, -float(fh) * s)
	n.add_child(anim)
	anim.play("idle")