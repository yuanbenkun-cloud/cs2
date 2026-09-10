extends SceneTree

func _init() -> void:
	var code := 0
	for part in ["build_common", "build_start", "build_zhujue", "build_npcs", "build_01", "build_02", "build_03", "build_04", "build_05"]:
		var script := load("res://tools/scene_parts/%s.gd" % part)
		if script == null:
			print("[FAIL] 无法加载 scene_parts/%s.gd" % part)
			code = 1
			continue
		var built: bool = script.new().run(self)
		print("[%s] %s" % ["PASS" if built else "FAIL", part])
		if not built:
			code = 1
	print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
	quit(code)