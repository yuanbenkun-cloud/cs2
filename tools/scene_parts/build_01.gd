extends RefCounted
## 第 1 关（洪崖洞·迷途）v2：大地图 + 阿姨对话开追逐战 + 人群路障。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)
	# 地面（-600..2000，宽 2600）
	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	var gsh := CollisionShape2D.new()
	var grec := RectangleShape2D.new()
	grec.size = Vector2(3200, 40)
	gsh.shape = grec
	ground.add_child(gsh)
	var gv := ColorRect.new()
	gv.color = Color("#39424e")
	gv.size = Vector2(3200, 40)
	gv.position = Vector2(-1600, -20)
	ground.add_child(gv)

	# 地图两端边界墙（防坠出地图）
	for ew in [[-712, -1], [2512, 1]]:
		var eb := StaticBody2D.new()
		eb.name = "EdgeWall"
		eb.position = Vector2(ew[0], 140)
		var esh := CollisionShape2D.new()
		var erec := RectangleShape2D.new()
		erec.size = Vector2(40, 320)
		esh.shape = erec
		eb.add_child(esh)
		root.add_child(eb)

	# 主角
	var player: CharacterBody2D = b.add_node(root, "CharacterBody2D", "zhujue")
	player.position = Vector2(-680, 200)
	b.bind_script(player, "res://scripts/player/player_controller.gd")
	var psh := CollisionShape2D.new()
	var prec := RectangleShape2D.new()
	prec.size = Vector2(24, 26)
	psh.shape = prec
	psh.position = Vector2(0, -13)
	player.add_child(psh)
	var pv := ColorRect.new()
	pv.name = "BodyRect"
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

	# HeartSystem + UI
	var heart: Node = b.add_node(root, "Node", "HeartSystem")
	b.bind_script(heart, "res://scripts/systems/heart_system.gd")
	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var hearts := Label.new()
	hearts.name = "UI_Hearts"
	hearts.text = "♥♥♥"
	hearts.position = Vector2(8, 4)
	hearts.add_theme_font_size_override("font_size", 18)
	hearts.add_theme_color_override("font_color", Color("#ff5c5c"))
	ui.add_child(hearts)
	var notice := Label.new()
	notice.name = "UI_Notice"
	notice.text = ""
	notice.position = Vector2(8, 30)
	notice.size = Vector2(464, 40)
	notice.add_theme_font_size_override("font_size", 12)
	notice.add_theme_color_override("font_color", Color("#ffe9c7"))
	notice.visible = false
	ui.add_child(notice)
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# 存档点
	var cp: Area2D = b.add_node(root, "Area2D", "Checkpoint")
	cp.position = Vector2(140, 215)
	b.bind_script(cp, "res://scripts/systems/checkpoint.gd")
	var cpsh := CollisionShape2D.new()
	var cprec := RectangleShape2D.new()
	cprec.size = Vector2(30, 60)
	cpsh.shape = cprec
	cpsh.position = Vector2(0, -30)
	cp.add_child(cpsh)

	# 传单阿姨（对话 → 追逐战）
	var flyer: Area2D = b.add_node(root, "Area2D", "chuandanayi")
	flyer.position = Vector2(250, 210)
	b.bind_script(flyer, "res://scripts/npc/flyer_lady.gd")
	var fsh := CollisionShape2D.new()
	var frect := RectangleShape2D.new()
	frect.size = Vector2(26, 40)
	fsh.shape = frect
	fsh.position = Vector2(0, -20)
	flyer.add_child(fsh)
	var fvis := ColorRect.new()
	fvis.color = Color("#b56576")
	fvis.size = Vector2(26, 38)
	fvis.position = Vector2(-13, -38)
	flyer.add_child(fvis)
	var fpr := ColorRect.new()
	fpr.name = "Prompt"
	fpr.color = Color("#7fd4ff")
	fpr.size = Vector2(12, 12)
	fpr.position = Vector2(-6, -50)
	flyer.add_child(fpr)

	# 追逐管理器 + 多名追赶阿姨（暂歇，追逐开始后激活）
	var cm: Node = b.add_node(root, "Node", "ChaseManager")
	b.bind_script(cm, "res://scripts/systems/chase_manager.gd")
	for i in range(1, 5):
		var cl: CharacterBody2D = b.add_node(root, "CharacterBody2D", "chaseayi_%02d" % i)
		cl.position = Vector2([320, 560, 1350, 1650][i - 1], 215)
		b.bind_script(cl, "res://scripts/npc/chaser_lady.gd")
		var clsh := CollisionShape2D.new()
		var clrec := RectangleShape2D.new()
		clrec.size = Vector2(20, 42)
		clsh.shape = clrec
		clsh.position = Vector2(0, -21)
		cl.add_child(clsh)
		var ctex: Texture2D = load("res://assets/generated/npc_flyerlady.png")
		if ctex != null:
			var csp := Sprite2D.new()
			csp.texture = ctex
			csp.centered = false
			csp.position = Vector2(-16, -48)
			cl.add_child(csp)

	# 人群路障（替换掩体；物理阻挡，绕行/跳跃通过）
	b.make_crowd(root, 1, 780, 84, 50)
	b.make_crowd(root, 2, 1000, 64, 46)
	b.make_crowd(root, 3, 1220, 92, 52)
	b.make_crowd(root, 4, 1460, 72, 46)

	# 装饰灯笼
	for lp in [[600, 96], [1750, 96]]:
		var ltex: Texture2D = load("res://assets/generated/obj_lantern.png")
		if ltex != null:
			var lsp := Sprite2D.new()
			lsp.name = "OBJ_Lantern"
			lsp.texture = ltex
			lsp.centered = false
			lsp.position = Vector2(lp[0] - 16.0, lp[1])
			root.add_child(lsp)

	# 历史木牌（对话，信息节点 info_board）
	var board: Area2D = b.add_node(root, "Area2D", "diyiguan_mupai")
	board.position = Vector2(1820, 210)
	b.bind_script(board, "res://scripts/npc/npc_base.gd")
	var bsh := CollisionShape2D.new()
	var brect := RectangleShape2D.new()
	brect.size = Vector2(40, 40)
	bsh.shape = brect
	bsh.position = Vector2(0, -20)
	board.add_child(bsh)
	var bvis := ColorRect.new()
	bvis.color = Color("#8a6a3b")
	bvis.size = Vector2(40, 40)
	bvis.position = Vector2(-20, -40)
	board.add_child(bvis)
	var bpr := ColorRect.new()
	bpr.name = "Prompt"
	bpr.color = Color("#7fd4ff")
	bpr.size = Vector2(12, 12)
	bpr.position = Vector2(-6, -50)
	board.add_child(bpr)
	board.set("dialogue_file", "res://assets/dialogue_level1.json")
	board.set("dialogue_node", "info_board")

	# 松动地砖（终点：踩到 → 穿越 02）
	var tile: Area2D = b.add_node(root, "Area2D", "diyiguan_husongdizhuan")
	tile.position = Vector2(1930, 240)
	b.bind_script(tile, "res://scripts/systems/loose_tile.gd")
	var tsh := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(34, 8)
	tsh.shape = trect
	tile.add_child(tsh)
	var tvis := ColorRect.new()
	tvis.color = Color("#c0392b")
	tvis.size = Vector2(34, 6)
	tvis.position = Vector2(-17, -3)
	tile.add_child(tvis)

	# 背景系统
	var pbg = b.make_background(root, [Color("#0a0f22"), Color("#14204a"), Color("#3a4f8f"), Color("#6b4a6b"), Color("#23273f")])
	b.add_scene_art(pbg, ground, "01")
	b.make_environment(root, Color("#0a0f22"))
	b.make_light_rig(root, Color(1.0, 0.9, 0.75), [[540, 70, "#ff8fb3", 0.9, 60], [1000, 60, "#7fd4ff", 0.7, 60], [1600, 80, "#ffd166", 0.6, 40]])

	# 地面向下填充（640x360 视口底部不露空）
	var gfill := ColorRect.new()
	gfill.name = "GroundFill"
	gfill.color = Color("#232a33")
	gfill.size = Vector2(3200, 130)
	gfill.position = Vector2(-1600, 0)
	ground.add_child(gfill)

	b.add_object_behind(ground, "res://assets/objects/stilt.png", 2050.0, 210.0)

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/01_hongyadong.tscn")
	root.free()
	return ok