extends SceneTree
## 帧表归一化：去底、逐帧紧裁、底对齐、合成等宽单行动画条。

var _dst := "res://assets/player_frames_norm"

func _init() -> void:
	var jobs := [
		{ "src": "res://assets/player_frames/idle.png", "out": "idle_n.png", "count": 8 },
		{ "src": "res://assets/player_frames/walk.png", "out": "walk_n.png", "count": 8 },
		{ "src": "res://assets/player_frames/jump.png", "out": "jump_n.png", "count": 8 },
		{ "src": "res://assets/player_frames/interact.png", "out": "interact_n.png", "count": 8 },
	]
	var code := 0
	for j in jobs:
		if not _process_sheet(j["src"], j["out"], j["count"]):
			code = 1
	print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
	quit(code)

func _process_sheet(src: String, out: String, count: int) -> bool:
	var img := Image.new()
	var err := img.load(src)
	if err != OK:
		print("[FAIL] 无法加载 %s (%d)" % [src, err])
		return false
	var bw := img.get_width()
	var bh := img.get_height()
	var bg := _detect_bg(img)
	var col_w := bw / count
	var boxes: Array = []
	var max_w := 0
	var max_h := 0
	for f in range(count):
		var min_x := col_w
		var max_x := 0
		var min_y := bh
		var max_y := 0
		var x0 := col_w * f
		for y in range(bh):
			for x in range(col_w):
				if not _is_bg(img.get_pixel(x0 + x, y), bg):
					var lx := x
					if lx < min_x: min_x = lx
					if lx > max_x: max_x = lx
					if y < min_y: min_y = y
					if y > max_y: max_y = y
		if max_x >= min_x and max_y >= min_y:
			var w := max_x - min_x + 1
			var h := max_y - min_y + 1
			boxes.append([min_x, min_y, w, h])
			max_w = maxi(max_w, w)
			max_h = maxi(max_h, h)
	if boxes.is_empty():
		print("[FAIL] %s 无可裁剪内容" % out)
		return false
	var pad := 4
	var fw := max_w + pad * 2
	var fh := max_h + pad * 2
	var sheet := Image.create_empty(fw * count, fh, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for f in range(boxes.size()):
		var b: Array = boxes[f]
		var ox := f * fw + pad
		var oy := pad
		var x0 := col_w * f + int(b[0])
		for y in range(int(b[3])):
			for x in range(int(b[2])):
				var c := img.get_pixel(x0 + x, int(b[1]) + y)
				if not _is_bg(c, bg):
					sheet.set_pixel(ox + x, oy + y, c)
	var serr := sheet.save_png(_dst + "/" + out)
	if serr != OK:
		print("[FAIL] 保存 %s 失败 %d" % [out, serr])
		return false
	print("[PASS] %s -> %dx%d (frame %dx%d x%d)" % [out, sheet.get_width(), sheet.get_height(), fw, fh, count])
	return true

func _detect_bg(img: Image) -> Color:
	var w := img.get_width()
	var h := img.get_height()
	var c1 := img.get_pixel(2, 2)
	var c2 := img.get_pixel(w - 3, 2)
	if c1.a < 0.12 and c2.a < 0.12:
		return Color(0, 0, 0, 0)
	return Color((c1.r + c2.r) * 0.5, (c1.g + c2.g) * 0.5, (c1.b + c2.b) * 0.5, 1.0)

func _is_bg(c: Color, bg: Color) -> bool:
	if bg.a < 0.5:
		return c.a < 0.1
	var d := sqrt((c.r - bg.r) * (c.r - bg.r) + (c.g - bg.g) * (c.g - bg.g) + (c.b - bg.b) * (c.b - bg.b))
	return d < 0.16
