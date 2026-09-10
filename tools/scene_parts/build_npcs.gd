extends RefCounted
## NPC 实例场景生成：scenes/renwu/npc/<拼音>/<拼音>.tscn（Area2D + 碰撞 + 提示圈 + 对话脚本）

const NPCS := ["chuandanayi", "youke", "tanfan", "jianglishilaoren", "laojiangren", "aming", "laozhanggui", "pangzhanggui", "banggong", "laozhou", "binanzhongqun"]

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var ok := true
	for name in NPCS:
		var root := Area2D.new()
		root.name = name
		root.set_script(load("res://scripts/npc/npc_base.gd"))
		# 碰撞体积 <拼音>_pengzhuangtiji
		var csh := CollisionShape2D.new()
		csh.name = name + "_pengzhuangtiji"
		var crec := RectangleShape2D.new()
		crec.size = Vector2(24, 40)
		csh.shape = crec
		csh.position = Vector2(0, -20)
		root.add_child(csh)
		# 交互提示圈 <拼音>_tishi
		var pr := ColorRect.new()
		pr.name = name + "_tishi"
		pr.color = Color("#7fd4ff")
		pr.size = Vector2(12, 12)
		pr.position = Vector2(-6, -50)
		root.add_child(pr)
		if not b.save_scene(root, "res://scenes/renwu/npc/" + name + "/" + name + ".tscn"):
			ok = false
		root.free()
	return ok
