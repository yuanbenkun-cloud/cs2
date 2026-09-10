extends SceneTree
## 程序化像素美术生成器 v2：陈默/NPC 变体/灯笼/五关时代背景条。

const HERO_K := Color("#26262e")
const SKIN := Color("#f2c89a")
const EYE := Color("#1f2028")
const MOUTH := Color("#a0573f")

var _img: Image
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.seed = 20260906
	var code := 0
	if not _gen_hero():
		code = 1
	for idn in ["flyerlady", "oldartisan", "aming", "oldshopkeeper", "teahouse", "helper", "laozhou", "oldman"]:
		if not _gen_npc(idn):
			code = 1
	if not _gen_obj():
		code = 1
	for e in [["01", 3200], ["02", 3200], ["03", 3200], ["04", 3200], ["05", 3200]]:
		if not _gen_bg(e[0], e[1]):
			code = 1
	print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
	quit(code)

func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and x < _img.get_width() and y >= 0 and y < _img.get_height():
		_img.set_pixel(x, y, c)

func _rect(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(maxi(0, y0), mini(_img.get_height(), y1)):
		for x in range(maxi(0, x0), mini(_img.get_width(), x1)):
			_img.set_pixel(x, y, c)

func _scale2(src: Image) -> Image:
	var o := Image.create_empty(src.get_width() * 2, src.get_height() * 2, false, Image.FORMAT_RGBA8)
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.0:
				o.set_pixel(x * 2, y * 2, c); o.set_pixel(x * 2 + 1, y * 2, c)
				o.set_pixel(x * 2, y * 2 + 1, c); o.set_pixel(x * 2 + 1, y * 2 + 1, c)
	return o

func _save(src: Image, path: String) -> bool:
	var err := src.save_png(path)
	if err != OK:
		print("[FAIL] 保存 %s 失败 %d" % [path, err])
		return false
	print("[PASS] %s 生成（%dx%d）" % [path.get_file(), src.get_width(), src.get_height()])
	return true

func _gen_hero() -> bool:
	_img = Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	_rect(1, 0, 15, 4, HERO_K); _rect(1, 0, 2, 8, HERO_K); _rect(14, 0, 15, 8, HERO_K)
	_rect(3, 2, 13, 8, SKIN)
	for x in range(3, 13):
		if (x + 4) % 3 != 0:
			_px(x, 4, HERO_K)
	_px(5, 5, EYE); _px(6, 5, EYE); _px(10, 5, EYE); _px(11, 5, EYE)
	_rect(7, 6, 10, 7, MOUTH); _rect(6, 8, 10, 9, SKIN)
	_rect(2, 9, 14, 17, Color("#5a6f8c"))
	for y in range(14, 17):
		for x in range(2, 14):
			if (x + y) % 2 == 0:
				_px(x, y, Color("#46576e"))
	for i in range(4):
		_px(3 + i, 9 + i, Color("#c96f4a")); _px(11 - i, 15 + i, Color("#c96f4a"))
	_px(2, 15, SKIN); _px(2, 16, SKIN); _px(13, 15, SKIN); _px(13, 16, SKIN)
	_rect(4, 17, 12, 21, Color("#39404f")); _rect(3, 21, 13, 23, Color("#26262e"))
	return _save(_scale2(_img), "res://assets/generated/chenmo_idle.png")

## NPC 模板：16x24，palette 控制特征
func _gen_npc(idn: String) -> bool:
	var cfg: Dictionary = _npc_cfg(idn)
	_img = Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	var hair: Color = cfg["hair"]
	var skin: Color = cfg["skin"]
	var coat: Color = cfg["coat"]
	var coat2: Color = cfg["coat2"]
	var pants: Color = cfg["pants"]
	var boots: Color = cfg["boots"]
	var short: bool = cfg.get("short", false)
	var beard: Color = cfg.get("beard", Color(0, 0, 0, 0))
	var apron: bool = cfg.get("apron", false)
	var hat: bool = cfg.get("hat", false)
	var flyer: bool = cfg.get("flyer", false)
	var body_h: int = 16 if short else 24
	var head_h := 8
	# 头发
	_rect(1, 0, 15, 4, hair); _rect(1, 0, 2, 6, hair); _rect(14, 0, 15, 6, hair)
	# 帽（可选）
	if hat:
		_rect(1, 0, 15, 3, Color("#4a3a28")); _rect(1, 3, 3, 4, Color("#4a3a28")); _rect(13, 3, 15, 4, Color("#4a3a28"))
	# 脸
	_rect(3, 2, 13, 8, skin)
	for x in range(3, 13):
		if (x + 4) % 3 != 0:
			_px(x, 4, hair)
	_px(5, 5, EYE); _px(6, 5, EYE); _px(10, 5, EYE); _px(11, 5, EYE)
	# 胡须（老匠人/老周）
	if beard.a > 0.0:
		_rect(5, 6, 11, 7, beard)
		_px(5, 6, skin); _px(10, 6, skin)
	else:
		_rect(7, 6, 10, 7, MOUTH)
	_rect(6, 8, 10, 9, skin)
	# 身
	var y_top: int = 9
	var y_bot: int = body_h - 4
	_rect(2, y_top, 14, y_bot, coat)
	for y in range(y_top + 3, y_bot):
		for x in range(2, 14):
			if (x + y) % 2 == 0:
				_px(x, y, coat2)
	if apron:
		_rect(4, y_top + 1, 12, y_bot, Color("#8a7a5a"))
		_rect(5, y_top + 1, 6, y_top + 2, Color("#4a3a28"))
	if flyer:
		_px(13, y_top + 2, Color("#e8e4d8")); _px(14, y_top + 2, Color("#e8e4d8")); _px(13, y_top + 3, Color("#e8e4d8"))
	# 手
	_px(2, y_bot - 2, skin); _px(13, y_bot - 2, skin)
	# 裤+鞋
	_rect(4, y_bot, 12, y_bot + 4, pants)
	var shoe_y: int = y_bot + 4
	_rect(3, shoe_y, 13, shoe_y + 2, boots)
	return _save(_scale2(_img), "res://assets/generated/npc_" + idn + ".png")

func _npc_cfg(idn: String) -> Dictionary:
	match idn:
		"flyerlady":
			return { "hair": Color("#3a2a1e"), "skin": SKIN, "coat": Color("#b56576"), "coat2": Color("#934a58"), "pants": Color("#4a4a52"), "boots": Color("#26262e"), "flyer": true }
		"oldartisan":
			return { "hair": Color("#c8c2b4"), "skin": Color("#e0b088"), "coat": Color("#7a4a2e"), "coat2": Color("#5e3a24"), "pants": Color("#3a3f4d"), "boots": Color("#2a2a30"), "beard": Color("#c8c2b4") }
		"aming":
			return { "hair": Color("#26262e"), "skin": SKIN, "coat": Color("#c96f4a"), "coat2": Color("#a8573a"), "pants": Color("#5a4a3a"), "boots": Color("#26262e"), "short": true }
		"oldshopkeeper":
			return { "hair": Color("#8a8a94"), "skin": Color("#e0b088"), "coat": Color("#4d6b4a"), "coat2": Color("#3c553a"), "pants": Color("#3a3a42"), "boots": Color("#26262e"), "hat": true }
		"teahouse":
			return { "hair": Color("#26262e"), "skin": Color("#f0c090"), "coat": Color("#8a6a3b"), "coat2": Color("#6e542e"), "pants": Color("#3a3f4d"), "boots": Color("#26262e"), "apron": true }
		"helper":
			return { "hair": Color("#2e2e34"), "skin": Color("#e8b888"), "coat": Color("#4d5d6e"), "coat2": Color("#3c4a58"), "pants": Color("#3a3a42"), "boots": Color("#26262e") }
		"laozhou":
			return { "hair": Color("#8a8a94"), "skin": Color("#e0b088"), "coat": Color("#3f5f6b"), "coat2": Color("#324a54"), "pants": Color("#3a3a42"), "boots": Color("#26262e"), "beard": Color("#c2c2c8") }
		"oldman":
			return { "hair": Color("#c8c2b4"), "skin": Color("#e0b088"), "coat": Color("#b8b0a0"), "coat2": Color("#98907e"), "pants": Color("#4a4a52"), "boots": Color("#2a2a30"), "beard": Color("#d8d2c4") }
	return { "hair": Color("#26262e"), "skin": SKIN, "coat": Color("#8a8a94"), "coat2": Color("#6e6e78"), "pants": Color("#3a3f4d"), "boots": Color("#26262e") }

func _gen_obj() -> bool:
	# 灯笼 16x24 -> 32x48（挂绳+红身+光带+穗）
	_img = Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	_px(7, 0, Color("#3a2a1e")); _px(8, 0, Color("#3a2a1e"))
	_rect(6, 1, 10, 3, Color("#3a2a1e"))
	_rect(5, 3, 11, 4, Color("#a8573a"))
	_rect(4, 4, 12, 16, Color("#d94f30"))
	_rect(6, 7, 10, 13, Color("#ffd166"))
	_rect(5, 16, 11, 17, Color("#a8573a"))
	_rect(7, 17, 9, 22, Color("#e05840"))
	_px(7, 22, Color("#e05840")); _px(8, 22, Color("#e05840")); _px(8, 23, Color("#c04930"))
	var ok := _save(_scale2(_img), "res://assets/generated/obj_lantern.png")
	# 瓦顶纹样条 48x16（复用铺顶）
	_img = Image.create_empty(48, 16, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	var roof: Color = Color("#4a3a2e")
	for row in range(0, 16, 2):
		for x in range(48):
			_px(x, row, roof)
			_px(x, row + 1, Color("#6e5a48") if (x + row / 2) % 4 < 2 else Color("#3a2e24"))
	ok = ok and _save(_img, "res://assets/generated/obj_roof.png")
	return ok

## 五关时代背景条（宽 x 270）
func _gen_bg(idn: String, w: int) -> bool:
	var h := 270
	_img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var era := _era(idn)
	var sky := era["sky"] as Array
	for y in range(h):
		var t := float(y) / float(h)
		var c: Color = (sky[0] as Color).lerp(sky[1] as Color, clampf(t * 2.4, 0.0, 1.0))
		_rect(0, y, w, y + 1, c)
	# 星辰/灯点
	for i in range(120):
		var x := _rng.randi_range(0, w - 1)
		var y := _rng.randi_range(2, int(h * 0.5))
		var cc: Color = era["stars"]
		cc.a = 0.6 + 0.4 * _rng.randf()
		_px(x, y, cc)
	# 天象（月/晨光/烟）
	match idn:
		"01":
			_rect(w - 300, 40, w - 230, 72, Color("#f2e6c8"))
			_rect(w - 292, 48, w - 238, 64, sky[0])
		"02":
			for i in range(6):
				var sx := _rng.randi_range(60, w - 80)
				_rect(sx, 20, sx + 3, 90, Color(1.0, 0.75, 0.5, 0.18))
		"04":
			_rect(60, 24, 84, 44, Color("#ff6a5c")); _rect(68, 24, 76, 44, Color("#3a1614"))
	# 地平剪影（按 era.kind）
	var sil: Color = era["sil"]
	var kind: String = era["kind"]
	if kind == "hongya":
		_draw_hongya(w, sil, era["win"])
	elif kind == "kiln":
		_draw_kiln(w, sil)
	elif kind == "town":
		_draw_town(w, sil)
	elif kind == "cave":
		_draw_cave(w, sil, era["win"])
	else:
		_draw_hills(w, sil)
	return _save(_img, "res://assets/generated/bg_" + idn + ".png")

func _era(idn: String) -> Dictionary:
	match idn:
		"01":
			return { "sky": [Color("#060a18"), Color("#16224e")], "stars": Color("#cfd8ff"), "sil": Color("#0b1226"), "win": Color("#ffd166"), "kind": "hongya" }
		"02":
			return { "sky": [Color("#2a1008"), Color("#7a3c1e")], "stars": Color("#ffb066"), "sil": Color("#3a1a10"), "win": Color("#ffd166"), "kind": "kiln" }
		"03":
			return { "sky": [Color("#3c454e"), Color("#78858f")], "stars": Color("#d8e2ea"), "sil": Color("#2e353c"), "win": Color("#ffd9a0"), "kind": "town" }
		"04":
			return { "sky": [Color("#050507"), Color("#14141c")], "stars": Color("#5a5a66"), "sil": Color("#050507"), "win": Color("#ff6a5c"), "kind": "cave" }
		"05":
			return { "sky": [Color("#c8d6e8"), Color("#f0d9a0")], "stars": Color("#fff8e0"), "sil": Color("#6e7d8a"), "win": Color("#ffffff"), "kind": "dawn" }
	return { "sky": [Color(0.2, 0.2, 0.2), Color(0.4, 0.4, 0.4)], "stars": Color.WHITE, "sil": Color.BLACK, "win": Color.YELLOW, "kind": "dawn" }

func _draw_hongya(w: int, sil: Color, win: Color) -> void:
	var ground_y := 232
	_rect(0, ground_y, w, 270, sil)
	var x := 0
	while x < w - 30:
		var bw := _rng.randi_range(26, 46)
		var bh := _rng.randi_range(18, 52)
		_rect(x, ground_y - bh, x + bw, ground_y, sil)
		# 吊脚楼：二层小屋 + 脚柱
		if _rng.randf() > 0.4:
			var tw := bw - 6
			var ty := ground_y - bh - _rng.randi_range(12, 18)
			_rect(x + 3, ty, x + 3 + tw, ground_y - bh, sil)
			_rect(x + 2, ground_y - bh, x + bw - 2, ground_y - bh + 2, sil)
			for i in range(2):
				_px(x + 2 + i, ground_y, sil)
		# 窗灯
		for i in range((bw * bh) / 160):
			var wx := x + _rng.randi_range(2, bw - 4)
			var wy := ground_y - bh + _rng.randi_range(2, bh - 5)
			_px(wx, wy, win)
			if _rng.randf() > 0.6:
				_px(wx + 1, wy, win)
		x += bw + _rng.randi_range(2, 10)

func _draw_kiln(w: int, sil: Color) -> void:
	var ground_y := 238
	_rect(0, ground_y, w, 270, sil)
	var x := 0
	while x < w:
		var bw := _rng.randi_range(30, 60)
		var bh := _rng.randi_range(14, 34)
		_rect(x, ground_y - bh, x + bw, ground_y, Color("#5e2c18"))
		_rect(x, ground_y - bh, x + bw, ground_y - bh + 3, Color("#8a4a22"))
		# 窑口红光
		if _rng.randf() > 0.5:
			_rect(x + bw / 2 - 2, ground_y - 4, x + bw / 2 + 2, ground_y, Color("#ff9c5b"))
		x += bw + _rng.randi_range(2, 8)

func _draw_town(w: int, sil: Color) -> void:
	var ground_y := 240
	_rect(0, ground_y, w, 270, sil)
	var x := 0
	while x < w:
		var bw := _rng.randi_range(24, 44)
		var bh := _rng.randi_range(12, 20)
		var top := ground_y - bh
		_rect(x, top, x + bw, ground_y, sil)
		# 瓦顶三角形
		var hw := bw / 2
		for yy in range(bh + 2):
			var half := hw * (1.0 - float(yy) / float(bh + 2))
			var x0 := int(x + bw / 2 - half)
			var x1 := int(x + bw / 2 + half)
			_rect(x0, top - yy, x1, top - yy + 1, Color("#262c33"))
		x += bw + _rng.randi_range(2, 10)

func _draw_cave(w: int, sil: Color, win: Color) -> void:
	_rect(0, 230, w, 270, sil)
	var x := 0
	while x < w:
		var bw := _rng.randi_range(50, 110)
		# 石柱 + 开口
		_rect(x, 150, x + 6, 240, Color("#1a1a22"))
		_rect(x + bw - 6, 150, x + bw, 240, Color("#1a1a22"))
		var cx := x + 8
		var cw := bw - 16
		_rect(cx, 230, cx + cw, 244, Color("#0d0d12"))
		if _rng.randf() > 0.4:
			_rect(cx + 2, 236, cx + 6, 240, win)
		x += bw
	_rect(0, 244, w, 270, Color("#050508"))

func _draw_hills(w: int, sil: Color) -> void:
	for x in range(w):
		var yy := int(208 + 26.0 * sin(x * 0.018) + 10.0 * sin(x * 0.045 + 2.0))
		_rect(x, yy, x + 1, 270, sil)
