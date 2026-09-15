extends SceneTree
## 关卡 1/2 核心玩法回归：追兵、人群节奏、移动条成功与失误。

var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print("[%s] %s" % ["PASS" if condition else "FAIL", message])
	if not condition:
		failed += 1

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/01_hongyadong.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	var chaser := current_scene.find_child("chuandanayi", true, false) as Node2D
	var manager := current_scene.find_child("ChaseManager", true, false)
	var hud := current_scene.find_child("UI_Chase", true, false)
	var crowd := current_scene.find_child("diyiguan_renqun_01", true, false) as Node2D
	var roof := current_scene.find_child("LowRoof1", true, false)
	var composure := current_scene.find_child("ComposureHUD", true, false)
	player.global_position.x = 0.0
	var chaser_before := chaser.global_position.x
	manager.call("begin")
	await create_timer(0.3).timeout
	_check(chaser.global_position.x > chaser_before, "第一关：传单阿姨本人开始追赶")
	_check(hud.visible, "第一关：追逐压力 HUD 可见")
	player.global_position.x = 650.0
	var crowd_before_x := crowd.position.x
	await create_timer(0.85).timeout
	_check(crowd.position.x < crowd_before_x, "第一关：路人预警后逆向走来阻挡")
	var crowd_actor := crowd.find_child("CrowdActor1", false, false) as AnimatedSprite2D
	_check(crowd_actor != null, "第一关：群众改为独立低帧动画角色")
	_check(crowd_actor != null and is_equal_approx(crowd_actor.sprite_frames.get_animation_speed("walk"), 2.5), "第一关：群众行走动画降至 2.5 FPS")
	_check(roof != null and bool(roof.get_meta("blocks_jump", false)), "第一关：关键人流上方配置低顶棚限制跳跃")
	_check(composure != null and composure.visible, "第一关：三段式镇定值 HUD 已加载")
	var hero_anim := player.find_child("zhujue_donghua", true, false) as AnimatedSprite2D
	_check(hero_anim != null and is_equal_approx(hero_anim.sprite_frames.get_animation_speed("walk"), 5.5), "主角行走动画降至 5.5 FPS")
	manager.call("finish")
	crowd.set("_state", 3)
	crowd.set("_timer", 5.0)
	crowd.position.x = 740.0
	player.global_position = Vector2(650, 240)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await create_timer(0.65).timeout
	Input.action_release("move_right")
	_check(player.global_position.x < 691.0, "第一关：群众阻挡水平方向但不再形成可站立平台")
	player.global_position = Vector2(1000, 240)
	player.velocity = Vector2(0, -320)
	var highest_y := player.global_position.y
	for _i in range(16):
		await physics_frame
		highest_y = minf(highest_y, player.global_position.y)
	_check(highest_y >= 226.0, "第一关：低顶棚实体碰撞会压住跳跃高度")

	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var forge := current_scene.find_child("ForgeSequence", true, false)
	var hero := current_scene.find_child("zhujue", true, false)
	var panel := current_scene.find_child("ForgeTimingPanel", true, false)
	forge.call("advance")
	_check(panel.visible and bool(hero.get("frozen")), "第二关：交互打开移动条并锁定走位")
	forge.set("_cursor_value", forge.get("_target_center"))
	forge.call("_judge")
	await create_timer(0.7).timeout
	_check(int(forge.get("current_step")) == 1 and int(forge.get("score")) == 100, "第二关：完美判定推进到淬水并计分")
	forge.set("_target_center", 0.7)
	forge.set("_cursor_value", 0.0)
	var time_before: float = forge.get("time_left")
	forge.call("_judge")
	_check(int(forge.get("current_step")) == 1 and float(forge.get("time_left")) < time_before - 4.5, "第二关：失误不推进工序且扣除时间")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
