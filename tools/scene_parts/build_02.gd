extends RefCounted
## 第 2 关（磁器口·生存之重）构建（Phase 4）。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)
	# 地面
	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	var gshape := CollisionShape2D.new()
	var gr := RectangleShape2D.new()
	gr.size = Vector2(3200, 40)
	gshape.shape = gr
	ground.add_child(gshape)
	var gvis := ColorRect.new()
	gvis.color = Color("#5c4433")
	gvis.size = Vector2(3200, 40)
	gvis.position = Vector2(-1600, -20)
	ground.add_child(gvis)

	# 主角
	var player: CharacterBody2D = b.add_node(root, "CharacterBody2D", "zhujue")
	player.position = Vector2(80, 200)
	b.bind_script(player, "res://scripts/player/player_controller.gd")
	var pshape := CollisionShape2D.new()
	var prec := RectangleShape2D.new()
	prec.size = Vector2(24, 26)
	pshape.shape = prec
	pshape.position = Vector2(0, -13)
	player.add_child(pshape)
	var pvis := ColorRect.new()
	pvis.color = Color("#E8B04B")
	pvis.size = Vector2(32, 32)
	pvis.position = Vector2(-16, -32)
	player.add_child(pvis)
	var pface := ColorRect.new()
	pface.name = "FaceRect"
	pface.color = Color.WHITE
	pface.size = Vector2(4, 4)
	pface.position = Vector2(10, -30)
	player.add_child(pface)
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

	# UI：DialoguePanel + 计时 + 提示
	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var timer_lb := Label.new()
	timer_lb.name = "UI_Timer"
	timer_lb.text = "⏳ 180"
	timer_lb.position = Vector2(200, 6)
	timer_lb.add_theme_font_size_override("font_size", 16)
	timer_lb.add_theme_color_override("font_color", Color("#ffd9a0"))
	ui.add_child(timer_lb)
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

	# ForgeSequence（计时/状态机）
	var forge: Node = b.add_node(root, "Node", "ForgeSequence")
	b.bind_script(forge, "res://scripts/systems/forge_sequence.gd")

	# NPC 老匠人 / 糊粥 / 大木头 / 阿明
	var artisan: Area2D = b.add_node(root, "Area2D", "laojiangren")
	artisan.position = Vector2(300, 210)
	b.bind_script(artisan, "res://scripts/npc/npc_base.gd")
	var ash := CollisionShape2D.new()
	var arec := RectangleShape2D.new()
	arec.size = Vector2(24, 38)
	ash.shape = arec
	ash.position = Vector2(0, -19)
	artisan.add_child(ash)
	var avis := ColorRect.new()
	avis.color = Color("#c96f4a")
	avis.size = Vector2(24, 36)
	avis.position = Vector2(-12, -36)
	artisan.add_child(avis)
	var aprompt := ColorRect.new()
	aprompt.name = "Prompt"
	aprompt.color = Color("#7fd4ff")
	aprompt.size = Vector2(12, 12)
	aprompt.position = Vector2(-6, -46)
	artisan.add_child(aprompt)
	artisan.set("dialogue_file", "res://assets/dialogue_level2.json")
	artisan.set("dialogue_node", "old_artisan")

	var porridge: Area2D = b.add_node(root, "Area2D", "di_erguan_huzhou")
	porridge.position = Vector2(430, 210)
	b.bind_script(porridge, "res://scripts/npc/npc_base.gd")
	var posh := CollisionShape2D.new()
	var porec := RectangleShape2D.new()
	porec.size = Vector2(24, 20)
	posh.shape = porec
	porridge.add_child(posh)
	var povis := ColorRect.new()
	povis.color = Color("#7a4a2b")
	povis.size = Vector2(24, 16)
	povis.position = Vector2(-12, -8)
	porridge.add_child(povis)
	var poprompt := ColorRect.new()
	poprompt.name = "Prompt"
	poprompt.color = Color("#7fd4ff")
	poprompt.size = Vector2(12, 12)
	poprompt.position = Vector2(-6, -24)
	porridge.add_child(poprompt)
	porridge.set("dialogue_file", "res://assets/dialogue_level2.json")
	porridge.set("dialogue_node", "porridge")

	var wood: Area2D = b.add_node(root, "Area2D", "di_erguan_mutou")
	wood.position = Vector2(560, 215)
	b.bind_script(wood, "res://scripts/npc/wood.gd")
	var wsh := CollisionShape2D.new()
	var wrec := RectangleShape2D.new()
	wrec.size = Vector2(60, 16)
	wsh.shape = wrec
	wsh.position = Vector2(0, -8)
	wood.add_child(wsh)
	var wvis := ColorRect.new()
	wvis.color = Color("#8a5a33")
	wvis.size = Vector2(60, 14)
	wvis.position = Vector2(-30, -7)
	wood.add_child(wvis)
	var wprompt := ColorRect.new()
	wprompt.name = "Prompt"
	wprompt.color = Color("#7fd4ff")
	wprompt.size = Vector2(12, 12)
	wprompt.position = Vector2(-6, -22)
	wood.add_child(wprompt)

	var aming: Area2D = b.add_node(root, "Area2D", "aming")
	aming.position = Vector2(720, 210)
	b.bind_script(aming, "res://scripts/npc/npc_base.gd")
	var msh := CollisionShape2D.new()
	var mrec := RectangleShape2D.new()
	mrec.size = Vector2(22, 34)
	msh.shape = mrec
	msh.position = Vector2(0, -17)
	aming.add_child(msh)
	var mvis := ColorRect.new()
	mvis.color = Color("#d98a4a")
	mvis.size = Vector2(22, 32)
	mvis.position = Vector2(-11, -32)
	aming.add_child(mvis)
	var mprompt := ColorRect.new()
	mprompt.name = "Prompt"
	mprompt.color = Color("#7fd4ff")
	mprompt.size = Vector2(12, 12)
	mprompt.position = Vector2(-6, -42)
	aming.add_child(mprompt)
	aming.set("dialogue_file", "res://assets/dialogue_level2.json")
	aming.set("dialogue_node", "aming")

	# 存档点（岩壁前）
	var cp: Area2D = b.add_node(root, "Area2D", "Checkpoint")
	cp.position = Vector2(1100, 215)
	b.bind_script(cp, "res://scripts/systems/checkpoint.gd")
	var cpsh := CollisionShape2D.new()
	var cprec := RectangleShape2D.new()
	cprec.size = Vector2(30, 60)
	cpsh.shape = cprec
	cpsh.position = Vector2(0, -30)
	cp.add_child(cpsh)

	# 岩壁（交互目标 di_erguan_yanbi + 色块逐轮裂开）
	var wall: Area2D = b.add_node(root, "Area2D", "di_erguan_yanbi")
	wall.position = Vector2(1250, 150)
	b.bind_script(wall, "res://scripts/npc/forge_wall.gd")
	var wsh2 := CollisionShape2D.new()
	var wrec2 := RectangleShape2D.new()
	wrec2.size = Vector2(120, 110)
	wsh2.shape = wrec2
	wsh2.position = Vector2(0, -55)
	wall.add_child(wsh2)
	var seg_colors := ["#8a4a38", "#9d5a40", "#8a4a38", "#a6653f", "#7e4232", "#94503a"]
	for i in range(6):
		var seg := ColorRect.new()
		seg.name = "Seg%d" % i
		seg.color = Color(seg_colors[i])
		seg.size = Vector2(19, 110)
		seg.position = Vector2(-57 + i * 19, -110)
		wall.add_child(seg)
	var oh := ColorRect.new()
	oh.name = "OverlayHeat"
	oh.color = Color(1.0, 0.5, 0.2, 0.35)
	oh.size = Vector2(114, 106)
	oh.position = Vector2(-57, -108)
	oh.visible = false
	wall.add_child(oh)
	var oq := ColorRect.new()
	oq.name = "OverlayQuench"
	oq.color = Color(0.3, 0.6, 1.0, 0.4)
	oq.size = Vector2(114, 106)
	oq.position = Vector2(-57, -108)
	oq.visible = false
	wall.add_child(oq)
	var wprompt2 := ColorRect.new()
	wprompt2.name = "Prompt"
	wprompt2.color = Color("#7fd4ff")
	wprompt2.size = Vector2(12, 12)
	wprompt2.position = Vector2(-6, -120)
	wall.add_child(wprompt2)

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#33140f"), Color("#6b2f1e"), Color("#9d5430"), Color("#c98a4a"), Color("#5c3a22")])
	b.add_scene_art(pbg, ground, "02")
	b.make_environment(root, Color("#33140f"))
	b.make_light_rig(root, Color(1.0, 0.8, 0.6), [[1250, 120, "#ff9c5b", 1.2, 90], [700, 60, "#ffb066", 0.5, 50]])

	# 岩壁实体阻挡（可交互 Area2D 之上再加物理墙体，防穿行/坠落）
	var wall_body := StaticBody2D.new()
	wall_body.name = "di_erguan_yanbi_qiangti"
	wall_body.position = Vector2(1250, 150)
	var wbs := CollisionShape2D.new()
	var wbr := RectangleShape2D.new()
	wbr.size = Vector2(120, 130)
	wbs.shape = wbr
	wall_body.add_child(wbs)
	root.add_child(wall_body)

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

	b.add_object_behind(ground, "res://assets/objects/kiln.png", 1000.0, 180.0)

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/02_ciqikou.tscn")
	root.free()
	return ok