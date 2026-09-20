extends SceneTree
## 将三视图的纯洋红生成底转为真实透明通道，并清理边缘洋红溢色。

const SOURCE := "res://assets/production/opening/yudeng_history/raw-yudeng-turnaround-chroma-v1.png"
const OUTPUT := "res://assets/production/opening/yudeng_history/yudeng-turnaround-v1.png"

func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if image == null or image.is_empty():
		push_error("无法读取渝灯三视图色键源图")
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	var transparent_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			# 生成底为高饱和洋红；将边缘抗锯齿留下的暗紫色也去除。
			# 角色本体为赤、金、青蓝配色，没有紫色部位。
			var key_core := color.r > 0.78 and color.b > 0.78 and color.g < 0.42
			var key_fringe := color.r > color.g * 1.18 and color.b > color.g * 1.18 \
				and absf(color.r - color.b) < 0.28 and maxf(color.r, color.b) > 0.08
			if key_core or key_fringe:
				color.a = 0.0
				color.r = 0.0
				color.g = 0.0
				color.b = 0.0
				image.set_pixel(x, y, color)
				transparent_pixels += 1
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("[PASS] 三视图透明像素：%d" % transparent_pixels)
	quit(0 if error == OK else 1)
