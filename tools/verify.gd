extends SceneTree
## 冒烟测试（SPEC 6.8）：关键对象 + 队伍人数 + JSON 解析 + Phase8 背景/环境/灯光。

const SCENES := {
	"res://scenes/guanqia/01_hongyadong.tscn": ["zhujue", "HeartSystem", "chuandanayi", "diyiguan_mupai", "diyiguan_husongdizhuan"],
	"res://scenes/guanqia/02_ciqikou.tscn": ["zhujue", "ForgeSequence", "di_erguan_yanbi", "di_erguan_mutou", "laojiangren", "aming", "UI_Timer"],
	"res://scenes/guanqia/03_zhongshan.tscn": ["zhujue", "ChoiceSystem", "laozhanggui", "pangzhanggui", "banggong", "laozhou", "disanguan_huobao"],
	"res://scenes/guanqia/04_fangdong.tscn": ["zhujue", "GroupFollower", "BombWarning", "NPC_Group", "PointLight2D", "Checkpoint", "BlastShield1", "BlastShield2", "BlastShield3", "disiguan_chukou"],
	"res://scenes/guanqia/05_hongyadong_return.tscn": ["zhujue", "MemoryRoute", "diwuguan_mupai", "jianglishilaoren", "diwuguan_jingguandian", "diwuguan_zhaoxiangdian"],
}

func _init() -> void:
	var failed := 0
	for path: String in SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			print("[FAIL] 无法加载 %s" % path)
			failed += 1
			continue
		var inst := packed.instantiate()
		root.add_child(inst)
		for node_name: String in SCENES[path]:
			if inst.find_child(node_name, true, false) == null:
				print("[FAIL] %s 缺少 %s" % [path, node_name])
				failed += 1
			else:
				print("[PASS] %s 含 %s" % [path, node_name])
		if path.ends_with("04_fangdong.tscn"):
			var cnt := 0
			var grp := inst.find_child("NPC_Group", true, false)
			if grp != null:
				for c in grp.get_children():
					if str(c.name).begins_with("NPC_Follower"):
						cnt += 1
			if cnt >= 6:
				print("[PASS] 04 队伍 NPC 数量 %d >= 6" % cnt)
			else:
				print("[FAIL] 04 队伍 NPC 数量 %d < 6" % cnt)
				failed += 1
		# Phase 8：BG_* 视差层 >= 3、WorldEnvironment、LightRig
		var bgc := inst.find_children("BG_*", "ParallaxLayer", true, false).size()
		if bgc >= 3:
			print("[PASS] %s 含 %d 个 BG_* 视差层" % [path, bgc])
		else:
			print("[FAIL] %s BG_* 视差层 %d < 3" % [path, bgc])
			failed += 1
		if inst.find_child("WorldEnvironment", true, false) == null:
			print("[FAIL] %s 缺少 WorldEnvironment" % path)
			failed += 1
		else:
			print("[PASS] %s 含 WorldEnvironment" % path)
		if inst.find_child("LightRig", true, false) == null:
			print("[FAIL] %s 缺少 LightRig" % path)
			failed += 1
		else:
			print("[PASS] %s 含 LightRig" % path)
		inst.queue_free()
	var dir := DirAccess.open("res://assets")
	if dir != null:
		for f in dir.get_files():
			if f.begins_with("dialogue_level") and f.ends_with(".json"):
				var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/" + f))
				if parsed is Dictionary:
					print("[PASS] JSON 可解析: %s" % f)
					for node_id: String in parsed:
						var dialogue_node: Dictionary = parsed[node_id]
						for option: Dictionary in dialogue_node.get("options", []):
							var next_id := str(option.get("next", ""))
							if next_id != "" and not parsed.has(next_id):
								print("[FAIL] %s 节点 %s 指向不存在的 %s" % [f, node_id, next_id])
								failed += 1
				else:
					print("[FAIL] JSON 解析失败: %s" % f)
					failed += 1
	print("[RESULT] " + ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
