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
	bomb.set("_pending_x", shield.global_position.x)
	missile.global_position = Vector2(shield.global_position.x, shield.global_position.y)
	bomb.call("_explode", shield)
	_check(int(shield.get("durability")) == 0, "挡板第二次受击后损毁")
	_check(bomb.call("_shield_at", shield.global_position.x) == null, "损毁挡板不再拦截后续导弹")
	_check(bomb.call("_shield_at", 500.0) == null, "挡板之间保留危险空隙")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
