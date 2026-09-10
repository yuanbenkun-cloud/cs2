extends RefCounted
## 主角实例场景：scenes/renwu/zhujue/zhujue.tscn（独立角色，供关卡实例化）

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var zhujue := CharacterBody2D.new()
	zhujue.name = "zhujue"
	zhujue.position = Vector2.ZERO
	zhujue.set_script(load("res://scripts/player/player_controller.gd"))
	# 碰撞体积 zhujue_pengzhuangtiji
	var pshape := CollisionShape2D.new()
	pshape.name = "zhujue_pengzhuangtiji"
	var prec := RectangleShape2D.new()
	prec.size = Vector2(24, 26)
	pshape.shape = prec
	pshape.position = Vector2(0, -13)
	zhujue.add_child(pshape)
	# 交互区 zhujue_jiaohuquyu
	var zone: Area2D = b.add_node(zhujue, "Area2D", "zhujue_jiaohuquyu")
	var zsh := CollisionShape2D.new()
	var zrec := RectangleShape2D.new()
	zrec.size = Vector2(36, 42)
	zsh.shape = zrec
	zsh.position = Vector2(0, -18)
	zone.add_child(zsh)
	# 相机 zhujue_shexiangji
	var cam: Camera2D = b.add_node(zhujue, "Camera2D", "zhujue_shexiangji")
	b.bind_script(cam, "res://scripts/systems/camera_rig.gd")
	cam.position_smoothing_enabled = true
	cam.offset = Vector2(0, -140)
	# 动画 zhujue_donghua（帧表）
	var anim_sp := AnimatedSprite2D.new()
	anim_sp.name = "zhujue_donghua"
	anim_sp.centered = false
	b.bind_script(anim_sp, "res://scripts/player/hero_anim.gd")
	zhujue.add_child(anim_sp)
	# 动画控制节点
	var kongzhi := Node.new()
	kongzhi.name = "zhujue_anim_kongzhi"
	b.bind_script(kongzhi, "res://scripts/player/player_animator.gd")
	zhujue.add_child(kongzhi)
	var ok: bool = b.save_scene(zhujue, "res://scenes/renwu/zhujue/zhujue.tscn")
	zhujue.free()
	return ok