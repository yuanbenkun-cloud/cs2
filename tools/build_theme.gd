extends SceneTree
## 生成全局主题 theme.tres：融合像素字体为默认 UI 字体（接线步骤）。

func _init() -> void:
	var code := 0
	var ttf_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf"
	var font = load(ttf_path)
	if font == null:
		print("[FAIL] 无法加载字体 %s" % ttf_path)
		code = 1
	else:
		var theme := Theme.new()
		theme.default_font = font
		theme.default_font_size = 12
		var err := ResourceSaver.save(theme, "res://assets/ui/theme.tres")
		if err == OK:
			print("[PASS] theme.tres 已保存（默认字体=%s，12px）" % font.resource_name)
		else:
			print("[FAIL] 保存 theme.tres 失败 code=%d" % err)
			code = 1
	print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
	quit(code)
