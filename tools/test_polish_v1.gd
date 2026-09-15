extends SceneTree
## 音效/设置/正式物件/真实检查点回归。

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] " + message)
	else:
		_ok = false
		print("[FAIL] " + message)

func _run() -> void:
	await process_frame
	var audio := root.get_node_or_null("AudioManager")
	_check(audio != null, "AudioManager 已加载")
	_check(AudioServer.get_bus_index("SFX") >= 0 and AudioServer.get_bus_index("UI") >= 0, "音效总线已建立")
	if audio != null:
		audio.call("play_event", "ui_confirm", 1.0, -30.0)

	var access := root.get_node_or_null("Accessibility")
	_check(access != null, "暂停与无障碍设置已加载")
	if access != null:
		access.call("_toggle_menu")
		_check(paused, "设置菜单会暂停游戏")
		access.call("_close_menu")
		_check(not paused, "关闭设置后恢复游戏")

	change_scene_to_file("res://scenes/guanqia/03_zhongshan.tscn")
	await process_frame
	await process_frame
	var cargo := current_scene.find_child("CargoVisual", true, false) as Sprite2D
	_check(cargo != null and cargo.texture != null, "第三关正式货包素材已接入")
	root.get_node("GameState").call("reset_goods")
	root.get_node("GameState").call("apply_goods_event", "robbed")
	await process_frame
	_check(cargo != null and "cargo-damaged" in cargo.texture.resource_path, "货损会切换货包外观")

	change_scene_to_file("res://scenes/guanqia/04_fangdong.tscn")
	await process_frame
	await process_frame
	var shield := current_scene.find_child("BlastShield2", true, false)
	var player := current_scene.find_child("zhujue", true, false) as Node2D
	_check(shield != null and shield.find_child("Panel", false, false) is Sprite2D, "第四关正式挡板素材已接入")
	shield.set("durability", 1)
	shield.call("_refresh")
	var lm := root.get_node("LevelManager")
	lm.call("register_checkpoint", Vector2(700, 200))
	shield.set("durability", 0)
	lm.call("respawn")
	await create_timer(0.35, true, false, true).timeout
	await process_frame
	await process_frame
	player = current_scene.find_child("zhujue", true, false) as Node2D
	shield = current_scene.find_child("BlastShield2", true, false)
	_check(player != null and absf(player.global_position.x - 700.0) < 2.0 and player.global_position.y >= 200.0 and player.global_position.y <= 242.0, "死亡后恢复检查点位置并重新落地")
	_check(shield != null and int(shield.get("durability")) == 1, "检查点恢复挡板耐久")

	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
