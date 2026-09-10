extends RefCounted
## 第 5 关（洪崖洞·归来）构建（Phase 7）：步行模拟 + 4 触发点，无失败条件。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)
	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	var gsh := CollisionShape2D.new()
	var grec := RectangleShape2D.new()
	grec.size = Vector2(3200, 40)
	gsh.shape = grec
	ground.add_child(gsh)
	var gv := ColorRect.new()
	gv.color = Color("#a8a08a")
	gv.size = Vector2(3200, 40)
	gv.position = Vector2(-1600, -20)
	ground.add_child(gv)

	var player: CharacterBody2D = b.add_node(root, "CharacterBody2D", "zhujue")
	player.position = Vector2(60, 200)
	b.bind_script(player, "res://scripts/player/player_controller.gd")
	var psh := CollisionShape2D.new()
	var prec := RectangleShape2D.new()
	prec.size = Vector2(24, 26)
	psh.shape = prec
	psh.position = Vector2(0, -13)
	player.add_child(psh)
	var pv := ColorRect.new()
	pv.color = Color("#E8B04B")
	pv.size = Vector2(32, 32)
	pv.position = Vector2(-16, -32)
	player.add_child(pv)
	var pf := ColorRect.new()
	pf.name = "FaceRect"
	pf.color = Color.WHITE
	pf.size = Vector2(4, 4)
	pf.position = Vector2(10, -30)
	player.add_child(pf)
	var zone: Area2D = b.add_node(player, "Area2D", "zhujue_jiaohuquyu")
	var zsh := CollisionShape2D.new()
	var zrec := RectangleShape2D.new()
	zrec.size = Vector2(36, 42)
	zsh.shape = zrec
	zsh.position = Vector2(0, -18)
	zone.add_child(zsh)
	var cam: Camera2D = b.add_node(player, "Camera2D", "zhujue_shexiangji")
	b.bind_script(cam, "res://scripts/systems/camera_rig.gd")
	cam.position_smoothing_enabled = true
	cam.offset = Vector2(0, -140)
	var anim := Node.new()
	anim.name = "zhujue_anim_kongzhi"
	b.bind_script(anim, "res://scripts/player/player_animator.gd")
	player.add_child(anim)
	# --- 主角动画（帧表 AnimatedSprite2D）---
	for c3 in player.get_children():
		if c3 is ColorRect:
			c3.visible = false
	var hero := AnimatedSprite2D.new()
	hero.name = "zhujue_donghua"
	hero.centered = false
	b.bind_script(hero, "res://scripts/player/hero_anim.gd")
	player.add_child(hero)

	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# 交互物工厂
	var triggers := [
		["diwuguan_mupai", 260, "#8a6a3b", 40, "board", "res://scripts/npc/npc_base.gd"],
		["jianglishilaoren", 480, "#b8b0a0", 38, "old_man", "res://scripts/npc/npc_base.gd"],
		["diwuguan_jingguandian", 760, "#7fa8c9", 26, "view_spot", "res://scripts/npc/npc_base.gd"],
		["diwuguan_zhaoxiangdian", 1080, "#c9a27f", 26, "photo", "res://scripts/npc/photo_spot.gd"],
	]
	for t in triggers:
		var nm: String = t[0]
		var px: float = t[1]
		var col: Color = Color(t[2])
		var h: float = t[3]
		var dnode: String = t[4]
		var script_p: String = t[5]
		var a: Area2D = b.add_node(root, "Area2D", nm)
		a.position = Vector2(px, 215)
		b.bind_script(a, script_p)
		var ash := CollisionShape2D.new()
		var arec := RectangleShape2D.new()
		arec.size = Vector2(34, 46)
		ash.shape = arec
		ash.position = Vector2(0, -23)
		a.add_child(ash)
		var avis := ColorRect.new()
		avis.color = col
		avis.size = Vector2(34, 44)
		avis.position = Vector2(-17, -44)
		a.add_child(avis)
		var pr := ColorRect.new()
		pr.name = "Prompt"
		pr.color = Color("#7fd4ff")
		pr.size = Vector2(12, 12)
		pr.position = Vector2(-6, -56)
		a.add_child(pr)
		a.set("dialogue_file", "res://assets/dialogue_level5.json")
		a.set("dialogue_node", dnode)

	# 传单阿姨（内心 OS 触发点，纯文本）
	var flyer: Area2D = b.add_node(root, "Area2D", "chuandanayi")
	flyer.position = Vector2(640, 215)
	b.bind_script(flyer, "res://scripts/npc/npc_base.gd")
	var fsh := CollisionShape2D.new()
	var frect := RectangleShape2D.new()
	frect.size = Vector2(24, 40)
	fsh.shape = frect
	fsh.position = Vector2(0, -20)
	flyer.add_child(fsh)
	var fvis := ColorRect.new()
	fvis.color = Color("#b56576")
	fvis.size = Vector2(24, 38)
	fvis.position = Vector2(-12, -38)
	flyer.add_child(fvis)
	var fpr := ColorRect.new()
	fpr.name = "Prompt"
	fpr.color = Color("#7fd4ff")
	fpr.size = Vector2(12, 12)
	fpr.position = Vector2(-6, -50)
	flyer.add_child(fpr)
	flyer.set("dialogue_file", "res://assets/dialogue_level5.json")
	flyer.set("dialogue_node", "flyer_lady_os")

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#d8e2ef"), Color("#cfe0d8"), Color("#f0d9a0"), Color("#b7c49a"), Color("#8f9480")])
	b.add_scene_art(pbg, ground, "05")
	b.make_environment(root, Color("#f0d9a0"))
	b.make_light_rig(root, Color(0.95, 0.93, 0.88), [[300, 130, "#fff3d6", 0.4, 60], [900, 60, "#ffeecb", 0.5, 70]])

	# 地图两端边界墙
	for ew in [[-712, -1], [2512, 1]]:
		var ew2 := StaticBody2D.new()
		ew2.name = "EdgeWall"
		ew2.position = Vector2(ew[0], 140)
		var esh2 := CollisionShape2D.new()
		var erec2 := RectangleShape2D.new()
		erec2.size = Vector2(40, 320)
		esh2.shape = erec2
		ew2.add_child(esh2)
		root.add_child(ew2)
	# 地面向下填充（640x360 视口底部不露空）
	var gfill := ColorRect.new()
	gfill.name = "GroundFill"
	gfill.color = Color("#232a33")
	gfill.size = Vector2(3200, 130)
	gfill.position = Vector2(-1600, 0)
	ground.add_child(gfill)

	b.add_object_behind(ground, "res://assets/objects/dock.png", 1100.0, 130.0)

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/05_hongyadong_return.tscn")
	root.free()
	return ok