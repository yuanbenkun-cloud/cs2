extends RefCounted
## 第 2 关（磁器口·生存之重）构建（Phase 4）。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)
	# 地面
	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	b.bind_script(ground, "res://scripts/background/prop_grounding.gd")
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

	# 主角使用独立 PackedScene；碰撞、相机与动画只维护一份。
	var player: CharacterBody2D = b.instantiate_scene(
		root, "res://scenes/renwu/zhujue/zhujue.tscn", "zhujue", Vector2(80, 200)
	) as CharacterBody2D

	# UI：DialoguePanel + 计时 + 提示
	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var timer_lb := Label.new()
	timer_lb.name = "UI_Timer"
	timer_lb.text = "⏳ 105"
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
	b.instantiate_npc(
		root, "laojiangren", "laojiangren", Vector2(300, 240),
		"res://scripts/npc/npc_base.gd",
		{"dialogue_file": "res://assets/dialogue_level2.json", "dialogue_node": "old_artisan"}
	)

	var porridge: Area2D = b.add_node(root, "Area2D", "di_erguan_huzhou")
	porridge.position = Vector2(430, 210)
	b.bind_script(porridge, "res://scripts/npc/npc_base.gd")
	var posh := CollisionShape2D.new()
	var porec := RectangleShape2D.new()
	porec.size = Vector2(24, 20)
	posh.shape = porec
	porridge.add_child(posh)
	var porridge_tex: Texture2D = load("res://assets/production/props/gameplay/porridge-pot-runtime.png")
	if porridge_tex != null:
		var povis := Sprite2D.new()
		b.bind_script(povis, "res://scripts/background/interactive_prop_grounding.gd")
		povis.texture = porridge_tex
		povis.scale = Vector2.ONE * (44.0 / float(porridge_tex.get_width()))
		povis.position = Vector2(0, -4)
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
	var wood_tex: Texture2D = load("res://assets/production/props/gameplay/log-bundle-runtime.png")
	if wood_tex != null:
		var wvis := Sprite2D.new()
		b.bind_script(wvis, "res://scripts/background/interactive_prop_grounding.gd")
		wvis.texture = wood_tex
		wvis.scale = Vector2.ONE * (74.0 / float(wood_tex.get_width()))
		wvis.position = Vector2(0, -5)
		wood.add_child(wvis)
	var wprompt := ColorRect.new()
	wprompt.name = "Prompt"
	wprompt.color = Color("#7fd4ff")
	wprompt.size = Vector2(12, 12)
	wprompt.position = Vector2(-6, -22)
	wood.add_child(wprompt)

	b.instantiate_npc(
		root, "aming", "aming", Vector2(720, 240),
		"res://scripts/npc/npc_base.gd",
		{"dialogue_file": "res://assets/dialogue_level2.json", "dialogue_node": "aming"}
	)

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

	# 岩壁：正式交互素材 + 三道裂纹反馈。
	var wall: Area2D = b.add_node(root, "Area2D", "di_erguan_yanbi")
	wall.position = Vector2(1250, 250)
	b.bind_script(wall, "res://scripts/npc/forge_wall.gd")
	var wsh2 := CollisionShape2D.new()
	var wrec2 := RectangleShape2D.new()
	wrec2.size = Vector2(120, 110)
	wsh2.shape = wrec2
	wsh2.position = Vector2(0, -55)
	wall.add_child(wsh2)
	var wall_tex: Texture2D = load("res://assets/production/props/gameplay/forge-wall-runtime.png")
	if wall_tex != null:
		var wall_vis := Sprite2D.new()
		wall_vis.name = "WallVisual"
		wall_vis.texture = wall_tex
		wall_vis.scale = Vector2.ONE * (130.0 / float(wall_tex.get_height()))
		wall_vis.position = Vector2(0, -65)
		wall.add_child(wall_vis)
	for i in range(3):
		var crack := Line2D.new()
		crack.name = "Crack%d" % (i + 1)
		crack.width = 2.0
		crack.default_color = Color("#ffd08a")
		crack.points = PackedVector2Array([Vector2(-35 + i * 28, -95), Vector2(-22 + i * 25, -70), Vector2(-30 + i * 31, -42), Vector2(-12 + i * 28, -18)])
		crack.visible = false
		wall.add_child(crack)
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

	# 锻造完成后才开启的关底传送门。
	var exit_area: Area2D = b.add_node(root, "Area2D", "dierguan_chukou")
	exit_area.position = Vector2(1400, 215)
	b.bind_script(exit_area, "res://scripts/systems/locked_exit_portal.gd")
	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()
	exit_rect.size = Vector2(50, 90)
	exit_shape.shape = exit_rect
	exit_shape.position = Vector2(0, -45)
	exit_area.add_child(exit_shape)
	b.add_goal_portal_visual(exit_area, false)

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#33140f"), Color("#6b2f1e"), Color("#9d5430"), Color("#c98a4a"), Color("#5c3a22")], "02")
	b.add_scene_art(pbg, ground, "02")
	b.make_environment(root, Color("#33140f"))
	b.make_light_rig(root, Color(1.0, 0.8, 0.6), [[1250, 120, "#ff9c5b", 1.2, 90], [700, 60, "#ffb066", 0.5, 50]])

	# 岩壁实体阻挡（可交互 Area2D 之上再加物理墙体，防穿行/坠落）
	var wall_body := StaticBody2D.new()
	wall_body.name = "di_erguan_yanbi_qiangti"
	wall_body.position = Vector2(1250, 250)
	var wbs := CollisionShape2D.new()
	var wbr := RectangleShape2D.new()
	wbr.size = Vector2(120, 130)
	wbs.shape = wbr
	wbs.position = Vector2(0, -65)
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

	b.add_object_behind(ground, "res://assets/production/props/kiln/kiln-right-v2.png", 1000.0, 180.0)

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/02_ciqikou.tscn")
	root.free()
	return ok
