extends SceneTree
## NPC 帧表归一化：取第 1 行（待机）自动按列切帧 → 单行动画条 + meta.json。

const SRC := "res://assets/npc_src"
const DST := "res://assets/npc_anim"
const KEYS := ["flyer_lady", "tourist", "vendor", "old_man", "old_artisan", "aming", "old_shopkeeper", "fat_teahouse", "helper", "laozhou", "crowd"]

var meta := {}

func _init() -> void:
	var code := 0
	for key in KEYS:
		if not _process_key(key):
			code = 1
	var f := FileAccess.open(DST + "/meta.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta))
		f.close()
	print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
	quit(code)

func _process_key(key: String) -> bool:
	var img := Image.new()
	if img.load(SRC + "/" + key + ".png") != OK:
		print("[FAIL] load %s" % key)
		return false
	var bg := _detect_bg(img)
	var w := img.get_width()
	var h := img.get_height()
	# 行检测：每行非背景像素量
	var row_hits := []
	for y in range(h):
		var n := 0
		for x in range(0, w, 3):
			if not _is_bg(img.get_pixel(x, y), bg):
				n += 1
		row_hits.append(n)
	var bands := _find_bands(row_hits, 4)
	if bands.is_empty():
		print("[FAIL] %s 无行带" % key)
		return false
	var band: Array = bands[0]  # 待机行
	var y0 := int(band[0])
	var y1 := int(band[1])
	# 列检测
	var col_active := []
	for x in range(w):
		var n := 0
		for y in range(y0, y1, 2):
			if not _is_bg(img.get_pixel(x, y), bg):
				n += 1
		col_active.append(n > 0)
	var segs := _find_segments(col_active)
	if segs.is_empty():
		print("[FAIL] %s 无列段" % key)
		return false
	# 每帧纵向范围
	var frames := []
	var max_w := 0
	var max_h := 0
	for s in segs:
		var sx := int(s[0])
		var ex := int(s[1])
		var min_y := y1
		var max_y := y0
		for y in range(y0, y1):
			for x in range(sx, ex + 1):
				if not _is_bg(img.get_pixel(x, y), bg):
					min_y = mini(min_y, y)
					max_y = maxi(max_y, y)
		if max_y >= min_y:
			var fw := ex - sx + 1
			var fh := max_y - min_y + 1
			frames.append([sx, min_y, fw, fh])
			max_w = maxi(max_w, fw)
			max_h = maxi(max_h, fh)
	if frames.is_empty():
		print("[FAIL] %s 帧为空" % key)
		return false
	var pad := 3
	var fw := max_w + pad * 2
	var fh := max_h + pad * 2
	var count := frames.size()
	var sheet := Image.create_empty(fw * count, fh, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in range(count):
		var fr: Array = frames[i]
		for y in range(int(fr[3])):
			for x in range(int(fr[2])):
				var c := img.get_pixel(int(fr[0]) + x, int(fr[1]) + y)
				if not _is_bg(c, bg):
					sheet.set_pixel(i * fw + pad + x, pad + y, c)
	var perr := sheet.save_png(DST + "/" + key + ".png")
	if perr != OK:
		print("[FAIL] save %s" % key)
		return false
	meta[key] = { "file": DST + "/" + key + ".png", "fw": fw, "fh": fh, "count": count, "fps": 6 }
	print("[PASS] %s %dx%d frames=%d fw=%d fh=%d" % [key, sheet.get_width(), sheet.get_height(), count, fw, fh])
	return true

func _find_bands(hits: Array, min_h: int) -> Array:
	var bands := []
	var i := 0
	while i < hits.size():
		if int(hits[i]) > 2:
			var j := i
			while j < hits.size() and int(hits[j]) > 2:
				j += 1
			if j - i >= min_h:
				bands.append([i, j])
			i = j
		else:
			i += 1
	return bands

func _find_segments(active: Array) -> Array:
	var segs := []
	var i := 0
	while i < active.size():
		if active[i]:
			var j := i
			while j < active.size() and active[j]:
				j += 1
			segs.append([i, j - 1])
			i = j
		else:
			i += 1
	return segs

func _detect_bg(img: Image) -> Color:
	var w := img.get_width()
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