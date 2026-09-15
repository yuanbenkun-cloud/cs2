extends RefCounted
## 第 4 关（防空洞·黑暗中的脊梁）构建（Phase 6）。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# 洞顶与洞壁已经进入独立的远景/中景透明景片，不再叠加旧纯色横条。

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

	# 主角使用独立 PackedScene；本关只追加随身煤油灯。
	var player: CharacterBody2D = b.instantiate_scene(
		root, "res://scenes/renwu/zhujue/zhujue.tscn", "zhujue", Vector2(80, 200)
	) as CharacterBody2D
	var light: PointLight2D = b.add_node(player, "PointLight2D", "PointLight2D")
	light.color = Color(1.0, 0.85, 0.6)
	light.energy = 1.4
	light.texture_scale = 6.0
	light.position = Vector2(0, -20)
	# 这是添加到子场景实例上的关卡专属节点，需显式归外层场景所有。
	light.owner = root
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
	var bomb_status := Label.new()
	bomb_status.name = "UI_BombStatus"
	bomb_status.position = Vector2(96, 18)
	bomb_status.size = Vector2(448, 28)
	bomb_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bomb_status.add_theme_font_size_override("font_size", 13)
	bomb_status.add_theme_color_override("font_color", Color("#ffd166"))
	bomb_status.visible = false
	ui.add_child(bomb_status)
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# 队伍容器（NPC_Group：6 个跟随者）
	var group := Node2D.new()
	group.name = "NPC_Group"
	root.add_child(group)
	for i in range(6):
		# 复用群众 PackedScene，让碰撞、视觉枢轴、待机动画和提示结构保持一致。
		# 24px 间距避免六人初始状态挤成一团，同时仍保持“护送队伍”的压迫感。
		b.instantiate_npc(
			group, "binanzhongqun", "NPC_Follower%d" % (i + 1),
			Vector2(20 - i * 24, 240), "res://scripts/npc/npc_base.gd"
		)

	# GroupFollower 组件（start_following 由关卡逻辑触发——玩家起步后）
	var gf: Node = b.add_node(root, "Node", "GroupFollower")
	b.bind_script(gf, "res://scripts/npc/group_follower.gd")
	var story_intro: Node = b.add_node(root, "Node", "LevelStoryIntro")
	b.bind_script(story_intro, "res://scripts/systems/level_story_intro.gd")

	# BombWarning 组件
	var bw: Node = b.add_node(root, "Node", "BombWarning")
	b.bind_script(bw, "res://scripts/systems/bomb_warning.gd")

	# 三段防空挡板：能拦住两枚导弹，之后损毁，迫使队伍继续换位。
	for shield_data in [[1, 315.0, 92.0], [2, 660.0, 92.0], [3, 1005.0, 92.0]]:
		_add_blast_shield(root, b, int(shield_data[0]), float(shield_data[1]), float(shield_data[2]))

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

	# 出口传送门
	var exit_area: Area2D = b.add_node(root, "Area2D", "disiguan_chukou")
	exit_area.position = Vector2(1320, 215)
	b.bind_script(exit_area, "res://scripts/systems/exit_portal.gd")
	var esh := CollisionShape2D.new()
	var erec := RectangleShape2D.new()
	erec.size = Vector2(50, 90)
	esh.shape = erec
	esh.position = Vector2(0, -45)
	exit_area.add_child(esh)
	b.add_goal_portal_visual(exit_area, true)

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#050508"), Color("#14141a"), Color("#26262e"), Color("#34343e"), Color("#101014")], "04")
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

func _add_blast_shield(root: Node2D, b: RefCounted, shield_id: int, x: float, half_width: float) -> void:
	var shield := Node2D.new()
	shield.name = "BlastShield%d" % shield_id
	shield.position = Vector2(x, 128)
	var shield_material := CanvasItemMaterial.new()
	shield_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	shield.material = shield_material
	root.add_child(shield)
	b.bind_script(shield, "res://scripts/systems/blast_shield.gd")
	shield.set("half_width", half_width)
	var safe_zone := ColorRect.new()
	safe_zone.name = "SafeZone"
	safe_zone.color = Color(1.0, 0.76, 0.28, 0.62)
	safe_zone.position = Vector2(-half_width, 98)
	safe_zone.size = Vector2(half_width * 2.0, 3)
	safe_zone.z_index = 30
	shield.add_child(safe_zone)
	var panel := Sprite2D.new()
	panel.name = "Panel"
	panel.use_parent_material = true
	panel.z_index = 24
	panel.texture = load("res://assets/production/props/gameplay/blast-shield-intact.png")
	panel.centered = false
	panel.position = Vector2(-half_width, -18)
	shield.add_child(panel)
	var label := Label.new()
	label.name = "Durability"
	label.use_parent_material = true
	label.position = Vector2(-38, -35)
	label.size = Vector2(76, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_outline_color", Color("#211817"))
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 27
	shield.add_child(label)
