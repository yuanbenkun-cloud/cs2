extends RefCounted
## 第 3 关（中山古镇·规矩与诚信）构建（Phase 5）。

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
	gv.color = Color("#5a6470")
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

	# ChoiceSystem 组件
	var cs: Node = b.add_node(root, "Node", "ChoiceSystem")
	b.bind_script(cs, "res://scripts/systems/choice_system.gd")

	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# NPC 工厂：四段式
	var npcs := [
		["laozhanggui", 180, "#7e8b99", "old_shopkeeper", 26],
		["pangzhanggui", 430, "#5d7d5a", "teahouse", 30],
		["banggong", 660, "#4d5d6e", "helper", 24],
	]
	for n in npcs:
		var nm: String = n[0]
		var px: float = n[1]
		var col: Color = Color(n[2])
		var dnode: String = n[3]
		var h: float = n[4]
		var npc: Area2D = b.add_node(root, "Area2D", nm)
		npc.position = Vector2(px, 210)
		if nm == "laozhou":
			b.bind_script(npc, "res://scripts/npc/laozhou.gd")
		else:
			b.bind_script(npc, "res://scripts/npc/npc_base.gd")
		var nsh := CollisionShape2D.new()
		var nrec := RectangleShape2D.new()
		nrec.size = Vector2(24, h + 6)
		nsh.shape = nrec
		nsh.position = Vector2(0, -h / 2 - 3)
		npc.add_child(nsh)
		var nvis := ColorRect.new()
		nvis.color = col
		nvis.size = Vector2(24, h)
		nvis.position = Vector2(-12, -h)
		npc.add_child(nvis)
		var pr := ColorRect.new()
		pr.name = "Prompt"
		pr.color = Color("#7fd4ff")
		pr.size = Vector2(12, 12)
		pr.position = Vector2(-6, -h - 8)
		npc.add_child(pr)
		npc.set("dialogue_file", "res://assets/dialogue_level3.json")
		npc.set("dialogue_node", dnode)

	# --- 装饰：灯笼 ---
	for lp in [[260, 70], [520, 88], [880, 96]]:
		var ltex: Texture2D = load("res://assets/generated/obj_lantern.png")
		if ltex != null:
			var lsp := Sprite2D.new()
			lsp.name = "OBJ_Lantern"
			lsp.texture = ltex
			lsp.centered = false
			lsp.position = Vector2(lp[0] - 16.0, lp[1])
			root.add_child(lsp)

	# 老周（验货，独立脚本）
	var laozhou: Area2D = b.add_node(root, "Area2D", "laozhou")
	laozhou.position = Vector2(920, 210)
	b.bind_script(laozhou, "res://scripts/npc/laozhou.gd")
	var lsh := CollisionShape2D.new()
	var lrec := RectangleShape2D.new()
	lrec.size = Vector2(28, 44)
	lsh.shape = lrec
	lsh.position = Vector2(0, -22)
	laozhou.add_child(lsh)
	var lvis := ColorRect.new()
	lvis.color = Color("#3f5f6b")
	lvis.size = Vector2(28, 42)
	lvis.position = Vector2(-14, -42)
	laozhou.add_child(lvis)
	var lpr := ColorRect.new()
	lpr.name = "Prompt"
	lpr.color = Color("#7fd4ff")
	lpr.size = Vector2(12, 12)
	lpr.position = Vector2(-6, -54)
	laozhou.add_child(lpr)

	# 货包（交互查看）
	var bag: Area2D = b.add_node(root, "Area2D", "disanguan_huobao")
	bag.position = Vector2(300, 215)
	b.bind_script(bag, "res://scripts/npc/npc_base.gd")
	var bsh := CollisionShape2D.new()
	var brec := RectangleShape2D.new()
	brec.size = Vector2(26, 18)
	bsh.shape = brec
	bag.add_child(bsh)
	var bvis := ColorRect.new()
	bvis.color = Color("#8a6a3b")
	bvis.size = Vector2(26, 16)
	bvis.position = Vector2(-13, -8)
	bag.add_child(bvis)
	var bpr := ColorRect.new()
	bpr.name = "Prompt"
	bpr.color = Color("#7fd4ff")
	bpr.size = Vector2(12, 12)
	bpr.position = Vector2(-6, -22)
	bag.add_child(bpr)
	bag.set("dialogue_file", "res://assets/dialogue_level3.json")
	bag.set("dialogue_node", "goods_bag")

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#5b6670"), Color("#7e8b99"), Color("#9aa88f"), Color("#b7c0a8"), Color("#4f5a4a")])
	b.add_scene_art(pbg, ground, "03")
	b.make_environment(root, Color("#5b6670"))
	b.make_light_rig(root, Color(0.85, 0.88, 0.9), [[640, 120, "#ffd9a0", 0.8, 80], [300, 120, "#ffcf8a", 0.5, 60], [900, 120, "#ffcf8a", 0.5, 60]])

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

	b.add_object_behind(ground, "res://assets/objects/teahouse.png", 430.0, 205.0)
	b.add_object_behind(ground, "res://assets/objects/dock.png", 920.0, 130.0)

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/03_zhongshan.tscn")
	root.free()
	return ok