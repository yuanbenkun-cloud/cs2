extends SceneTree
## 将生图工具烘焙的浅灰棋盘格转换为真实透明背景。

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("用法：-- <源图片路径> <目标 PNG 路径>")
		quit(2)
		return
	var source: String = args[0]
	var target: String = args[1]
	var image := Image.load_from_file(source)
	if image == null or image.is_empty():
		push_error("无法读取窑炉源图")
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var high := maxf(color.r, maxf(color.g, color.b))
			var low := minf(color.r, minf(color.g, color.b))
			var chroma := high - low
			# 棋盘格由高亮中性灰构成；砖、火、烟都有暖色差，深色描边也会保留。
			if low > 0.66 and chroma < 0.035:
				color.a = 0.0
			elif low > 0.62 and chroma < 0.085:
				color.a = clampf((chroma - 0.025) / 0.06, 0.0, 1.0)
			else:
				color.a = 1.0
			image.set_pixel(x, y, color)
	var output_path := target if target.is_absolute_path() else ProjectSettings.globalize_path(target)
	var error := image.save_png(output_path)
	print("[PASS] 右向窑炉已转换为真实透明 PNG" if error == OK else "[FAIL] 窑炉透明化失败")
	quit(0 if error == OK else 1)
