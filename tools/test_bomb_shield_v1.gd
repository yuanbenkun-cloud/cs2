extends SceneTree
## 第四关落弹/挡板回归测试。

var failed := 0

func _check(condition: bool, message: String) -> void:
	print("[%s] %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failed += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	var bomb := current_scene.find_child("BombWarning", true, false)
	var shield := current_scene.find_child("BlastShield1", true, false)
	await create_timer(0.2).timeout
	bomb.set("_pending_x", shield.global_position.x)
	bomb.call("_launch_missile")
	var missile := current_scene.find_child("FallingMissile", true, false) as Node2D
	var start_y := missile.global_position.y
	await create_timer(0.25).timeout
	_check(missile.visible and missile.global_position.y > start_y, "导弹从画面顶部可见下落")
	await create_timer(0.65).timeout
	_check(int(shield.get("durability")) == 1 and not missile.visible, "导弹撞击挡板并消耗一格耐久")
	var audio := root.get_node_or_null("AudioManager")
	var bombing_heard := false
	for voice in audio.find_children("Voice*", "AudioStreamPlayer", true, false):
		if voice.stream != null and voice.stream.resource_path.ends_with("第4关-航弹轰炸.ogg"):
			bombing_heard = true
	_check(bombing_heard, "导弹命中使用第四关专属轰炸声，而非通用爆炸声")
	bomb.set("_pending_x", shield.global_position.x)
	missile.global_position = Vector2(shield.global_position.x, shield.global_position.y)
	bomb.call("_explode", shield)
	var feedback := bomb.call("_spawn_explosion", Vector2(500, 220), false) as Node2D
	var sparks := feedback.get_node_or_null("ExplosionSparks") as CPUParticles2D
	var flash_light := feedback.get_node_or_null("ExplosionFlashLight") as PointLight2D
	var outer_flame := feedback.get_node_or_null("GroundFlameOuter") as Polygon2D
	var shockwave := feedback.get_node_or_null("GroundShockwave") as Polygon2D
	var smoke := feedback.get_node_or_null("GroundBlastSmoke") as CPUParticles2D
	_check(outer_flame != null and shockwave != null and smoke != null and sparks != null and sparks.emitting, "落地爆炸由贴地火团、横向冲击波、火星和烟尘组成")
	_check(is_equal_approx(feedback.global_position.y, 238.0) and is_equal_approx(float(feedback.get_meta("contact_sink")), 18.0), "地面爆炸可见底边下压至路面接触线，不再浮空")
	_check(flash_light != null and flash_light.texture != null and flash_light.energy >= 3.0 and flash_light.texture_scale >= 8.8, "导弹爆炸暖光照亮范围扩大为上一版两倍")
	await create_timer(0.55).timeout
	_check(is_instance_valid(flash_light) and flash_light.energy < 0.08, "爆炸照明快速衰减并恢复原有黑暗")
	await create_timer(0.55).timeout
	_check(not is_instance_valid(feedback), "火花与爆炸光节点会自动销毁，不会永久留在场景")
	_check(int(shield.get("durability")) == 0, "挡板第二次受击后损毁")
	_check(bomb.call("_shield_at", shield.global_position.x) == null, "损毁挡板不再拦截后续导弹")
	_check(bomb.call("_shield_at", 500.0) == null, "挡板之间保留危险空隙")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
