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
	# 角色立绘宽于物理体；交互区使用舒适距离，避免画面上已经贴近 NPC 却检测不到。
	zrec.size = Vector2(112, 70)
	zsh.shape = zrec
	zsh.position = Vector2(0, -18)
	zone.add_child(zsh)
	# 相机 zhujue_shexiangji
	var cam: Camera2D = b.add_node(zhujue, "Camera2D", "zhujue_shexiangji")
	b.bind_script(cam, "res://scripts/systems/camera_rig.gd")
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.offset = Vector2(0, -72)
	cam.limit_left = -700
	cam.limit_right = 2500
	cam.limit_top = -120
	cam.limit_bottom = 360
	cam.limit_smoothed = true
	# 视觉枢轴只承载表现动画，不影响 CharacterBody2D 碰撞与运动。
	var visual_pivot := Node2D.new()
	visual_pivot.name = "VisualPivot"
	visual_pivot.z_index = 20
	zhujue.add_child(visual_pivot)
	# 动画 zhujue_donghua（帧表）
	var anim_sp := AnimatedSprite2D.new()
	anim_sp.name = "zhujue_donghua"
	anim_sp.centered = false
	b.bind_script(anim_sp, "res://scripts/player/hero_anim.gd")
	visual_pivot.add_child(anim_sp)
	# Godot 原生 AnimationPlayer：起跳、落地与交互反馈集中在角色场景。
	var feedback_player := AnimationPlayer.new()
	feedback_player.name = "FeedbackAnimationPlayer"
	zhujue.add_child(feedback_player)
	var library := AnimationLibrary.new()
	library.add_animation("RESET", _make_feedback_animation([
		[0.0, Vector2.ONE, Vector2.ZERO, 0.0],
	]))
	library.add_animation("jump_takeoff", _make_feedback_animation([
		[0.0, Vector2(1.12, 0.88), Vector2(0, 2), 0.0],
		[0.10, Vector2(0.94, 1.08), Vector2(0, -1), 0.0],
		[0.20, Vector2.ONE, Vector2.ZERO, 0.0],
	]))
	library.add_animation("land", _make_feedback_animation([
		[0.0, Vector2(1.20, 0.80), Vector2(0, 3), 0.0],
		[0.10, Vector2(0.94, 1.06), Vector2(0, -1), 0.0],
		[0.22, Vector2.ONE, Vector2.ZERO, 0.0],
	]))
	library.add_animation("interact", _make_feedback_animation([
		[0.0, Vector2.ONE, Vector2.ZERO, 0.0],
		[0.08, Vector2(1.04, 0.96), Vector2(2, 0), 0.035],
		[0.20, Vector2.ONE, Vector2.ZERO, 0.0],
	]))
	feedback_player.add_animation_library("", library)
	# 动画控制节点
	var kongzhi := Node.new()
	kongzhi.name = "zhujue_anim_kongzhi"
	b.bind_script(kongzhi, "res://scripts/player/player_animator.gd")
	zhujue.add_child(kongzhi)
	var ok: bool = b.save_scene(zhujue, "res://scenes/renwu/zhujue/zhujue.tscn")
	zhujue.free()
	return ok

func _make_feedback_animation(keys: Array) -> Animation:
	var animation := Animation.new()
	animation.length = float(keys[keys.size() - 1][0])
	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	var position_track := animation.add_track(Animation.TYPE_VALUE)
	var rotation_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath("VisualPivot:scale"))
	animation.track_set_path(position_track, NodePath("VisualPivot:position"))
	animation.track_set_path(rotation_track, NodePath("VisualPivot:rotation"))
	animation.track_set_interpolation_type(scale_track, Animation.INTERPOLATION_CUBIC)
	animation.track_set_interpolation_type(position_track, Animation.INTERPOLATION_CUBIC)
	animation.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_CUBIC)
	for key in keys:
		var time := float(key[0])
		animation.track_insert_key(scale_track, time, key[1])
		animation.track_insert_key(position_track, time, key[2])
		animation.track_insert_key(rotation_track, time, key[3])
	return animation
