extends SceneTree

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _run() -> void:
	change_scene_to_file("res://scenes/guanqia/02_ciqikou.tscn")
	await process_frame
	await process_frame
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	if player.has_method("freeze"):
		player.call("freeze", true)
	var destination := player.global_position
	var portal := ArrivalPortal.new()
	portal.name = "ArrivalPortal"
	current_scene.add_child(portal)
	portal.play_arrival(player)
	await create_timer(0.16).timeout
	_check(is_instance_valid(portal) and portal.modulate.a > 0.2, "传送门在场景内展开")
	_check(player.global_position.x < destination.x - 20.0, "玩家从传送门内部出现")
	await create_timer(1.1).timeout
	_check(not is_instance_valid(portal), "玩家出现后传送门消失")
	_check(player.global_position.distance_to(destination) < 0.5 and player.modulate.a > 0.99, "玩家抵达关卡出生点并恢复显示")
	if player.has_method("freeze"):
		player.call("freeze", false)
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
