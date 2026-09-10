extends RefCounted
## 第 4 关（防空洞·黑暗中的脊梁）构建（Phase 6）。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)	# 洞顶/洞壁（视觉）
	b.make_color_rect(Vector2(1700, 26), Color("#26262c"), Vector2(-100, 0), root)
	b.make_color_rect(Vector2(1700, 14), Color("#26262c"), Vector2(-100, 256), root)

	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	var gsh := CollisionShape2D.new()
	var grec := RectangleShape2D.new()
	grec.size = Vector2(3200, 40)
	gsh.shape = grec
	ground.add_child(gsh)
	var gv := ColorRect.new()
	gv.color = Color("#3a3a42")
	gv.size = Vector2(3200, 40)
	gv.position = Vector2(-1600, -20)
	ground.add_child(gv)

	# 主角 + 唯一煤油灯点光源跟随（全局极暗由 LightRig tone 提供）
	var player: CharacterBody2D = b.add_node(root, "CharacterBody2D", "zhujue")
	player.position = Vector2(80, 200)
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
	var light: PointLight2D = b.add_node(player, "PointLight2D", "PointLight2D")
	light.color = Color(1.0, 0.85, 0.6)
	light.energy = 1.4
	light.texture_scale = 6.0
	light.position = Vector2(0, -20)
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

	# UI（DialoguePanel + 轰炸红色警示）
	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var flash := ColorRect.new()
	flash.name = "UI_BombFlash"
	flash.color = Color(1.0, 0.1, 0.1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.0
	flash.visible = false
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# 队伍容器（NPC_Group：6 个跟随者）
	var group := Node2D.new()
	group.name = "NPC_Group"
	root.add_child(group)
	var fcols := ["#4d5d6e", "#5d6b4d", "#6e4d5d", "#5d4d6e", "#6e6e4d", "#4d6e6e"]
	for i in range(6):
		var f := Node2D.new()
		f.name = "NPC_Follower%d" % (i + 1)
		f.position = Vector2(50 - i * 14, 212)
		group.add_child(f)
		var fv := ColorRect.new()
		fv.color = Color(fcols[i])
		fv.size = Vector2(18, 26)
		fv.position = Vector2(-9, -26)
		f.add_child(fv)

	# GroupFollower 组件（start_following 由关卡逻辑触发——玩家起步后）
	var gf: Node = b.add_node(root, "Node", "GroupFollower")
	b.bind_script(gf, "res://scripts/npc/group_follower.gd")

	# BombWarning 组件
	var bw: Node = b.add_node(root, "Node", "BombWarning")
	b.bind_script(bw, "res://scripts/systems/bomb_warning.gd")

	# 存档点（洞中途）
	var cp: Area2D = b.add_node(root, "Area2D", "Checkpoint")
	cp.position = Vector2(700, 215)
	b.bind_script(cp, "res://scripts/systems/checkpoint.gd")
	var csh := CollisionShape2D.new()
	var crec := RectangleShape2D.new()
	crec.size = Vector2(30, 60)
	csh.shape = crec
	csh.position = Vector2(0, -30)
	cp.add_child(csh)

	# 出口（洞口光）
	var exit_area: Area2D = b.add_node(root, "Area2D", "disiguan_chukou")
	exit_area.position = Vector2(1320, 215)
	b.bind_script(exit_area, "res://scripts/systems/exit_portal.gd")
	var esh := CollisionShape2D.new()
	var erec := RectangleShape2D.new()
	erec.size = Vector2(50, 90)
	esh.shape = erec
	esh.position = Vector2(0, -45)
	exit_area.add_child(esh)
	var ev := ColorRect.new()
	ev.color = Color(0.9, 0.95, 1.0, 0.35)
	ev.size = Vector2(50, 90)
	ev.position = Vector2(-25, -90)
	exit_area.add_child(ev)

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#050508"), Color("#14141a"), Color("#26262e"), Color("#34343e"), Color("#101014")])
	b.add_scene_art(pbg, ground, "04")
	b.make_environment(root, Color("#0a0a0c"))
	b.make_light_rig(root, Color(0.25, 0.25, 0.3), [])

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

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/04_fangdong.tscn")
	root.free()
	return ok