extends RefCounted
## 第 3 关（中山古镇·规矩与诚信）构建（Phase 5）。

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root: Node2D = b.new_scene("LevelRoot")

	# (旧生成背景条已移除，远景=每关主背景)
	var ground: StaticBody2D = b.add_node(root, "StaticBody2D", "Ground")
	ground.position = Vector2(900, 260)
	b.bind_script(ground, "res://scripts/background/prop_grounding.gd")
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

	var player: CharacterBody2D = b.instantiate_scene(
		root, "res://scenes/renwu/zhujue/zhujue.tscn", "zhujue", Vector2(60, 200)
	) as CharacterBody2D

	# ChoiceSystem 节点保留命名兼容；脚本升级为顺序护货路线导演。
	var cs: Node = b.add_node(root, "Node", "ChoiceSystem")
	b.bind_script(cs, "res://scripts/systems/trade_route_manager.gd")

	var ui: CanvasLayer = b.add_node(root, "CanvasLayer", "UI_Base")
	ui.layer = 10
	var dlg := Control.new()
	dlg.name = "DialoguePanel"
	b.bind_script(dlg, "res://scripts/ui/dialogue_panel.gd")
	ui.add_child(dlg)

	# NPC 工厂：四段式
	var npcs := [
		["laozhanggui", 180, "old_shopkeeper", 0, 1],
		["pangzhanggui", 430, "teahouse", 1, 2],
		["banggong", 660, "helper", 2, 3],
	]
	for n in npcs:
		var nm: String = n[0]
		var px: float = n[1]
		var dialogue_node: String = n[2]
		var required_stage: int = n[3]
		var next_stage: int = n[4]
		b.instantiate_npc(
			root, nm, nm, Vector2(px, 240), "res://scripts/npc/route_npc.gd",
			{"dialogue_node": dialogue_node, "required_stage": required_stage, "next_stage": next_stage}
		)

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
	b.instantiate_npc(
		root, "laozhou", "laozhou", Vector2(920, 240),
		"res://scripts/npc/laozhou.gd"
	)

	# 完整交货后开启，玩家主动穿门进入防空洞年代。
	var exit_area: Area2D = b.add_node(root, "Area2D", "disanguan_chukou")
	exit_area.position = Vector2(1040, 215)
	b.bind_script(exit_area, "res://scripts/systems/locked_exit_portal.gd")
	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()
	exit_rect.size = Vector2(50, 90)
	exit_shape.shape = exit_rect
	exit_shape.position = Vector2(0, -45)
	exit_area.add_child(exit_shape)
	b.add_goal_portal_visual(exit_area, false)

	# 货包（交互查看）
	var bag: Area2D = b.add_node(root, "Area2D", "disanguan_huobao")
	bag.position = Vector2(300, 215)
	b.bind_script(bag, "res://scripts/npc/npc_base.gd")
	var bsh := CollisionShape2D.new()
	var brec := RectangleShape2D.new()
	brec.size = Vector2(26, 18)
	bsh.shape = brec
	bag.add_child(bsh)
	var bvis := Sprite2D.new()
	bvis.name = "CargoVisual"
	bvis.texture = load("res://assets/production/props/gameplay/cargo-intact.png")
	bvis.position = Vector2(0, -20)
	bvis.set_script(load("res://scripts/systems/cargo_visual.gd"))
	bag.add_child(bvis)
	var bpr := ColorRect.new()
	bpr.name = "Prompt"
	bpr.color = Color("#7fd4ff")
	bpr.size = Vector2(12, 12)
	bpr.position = Vector2(-6, -43)
	bag.add_child(bpr)
	bag.set("dialogue_file", "res://assets/dialogue_level3.json")
	bag.set("dialogue_node", "goods_bag")

	# --- Phase 8：背景系统（视差5层 + WorldEnvironment + LightRig）---
	var pbg = b.make_background(root, [Color("#5b6670"), Color("#7e8b99"), Color("#9aa88f"), Color("#b7c0a8"), Color("#4f5a4a")], "03")
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

	var ok: bool = b.save_scene(root, "res://scenes/guanqia/03_zhongshan.tscn")
	root.free()
	return ok
