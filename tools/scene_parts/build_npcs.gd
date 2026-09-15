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
		var visual_pivot := Node2D.new()
		visual_pivot.name = "VisualPivot"
		visual_pivot.z_index = 20
		root.add_child(visual_pivot)
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
		pr.color = Color(0.05, 0.08, 0.12, 0.92)
		pr.size = Vector2(18, 18)
		pr.position = Vector2(-9, -58)
		pr.z_index = 35
		var key_label := Label.new()
		key_label.name = "KeyLabel"
		key_label.text = "E"
		key_label.position = Vector2(5, 0)
		key_label.add_theme_font_size_override("font_size", 12)
		key_label.add_theme_color_override("font_color", Color("#ffd166"))
		pr.add_child(key_label)
		root.add_child(pr)
		var animation_player := AnimationPlayer.new()
		animation_player.name = "AmbientAnimationPlayer"
		root.add_child(animation_player)
		var library := AnimationLibrary.new()
		library.add_animation("ambient", _make_ambient_animation(name + "_tishi"))
		animation_player.add_animation_library("", library)
		animation_player.autoplay = "ambient"
		if not b.save_scene(root, "res://scenes/renwu/npc/" + name + "/" + name + ".tscn"):
			ok = false
		root.free()
	return ok

func _make_ambient_animation(prompt_name: String) -> Animation:
	var animation := Animation.new()
	animation.length = 1.6
	animation.loop_mode = Animation.LOOP_LINEAR
	var visual_position := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(visual_position, NodePath("VisualPivot:position"))
	animation.track_set_interpolation_type(visual_position, Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(visual_position, 0.0, Vector2.ZERO)
	animation.track_insert_key(visual_position, 0.8, Vector2(0, -1))
	animation.track_insert_key(visual_position, 1.6, Vector2.ZERO)
	var visual_rotation := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(visual_rotation, NodePath("VisualPivot:rotation"))
	animation.track_set_interpolation_type(visual_rotation, Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(visual_rotation, 0.0, -0.008)
	animation.track_insert_key(visual_rotation, 0.8, 0.008)
	animation.track_insert_key(visual_rotation, 1.6, -0.008)
	var prompt_position := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(prompt_position, NodePath(prompt_name + ":position"))
	animation.track_set_interpolation_type(prompt_position, Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(prompt_position, 0.0, Vector2(-9, -58))
	animation.track_insert_key(prompt_position, 0.8, Vector2(-9, -62))
	animation.track_insert_key(prompt_position, 1.6, Vector2(-9, -58))
	return animation
