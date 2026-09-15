extends SceneTree
## 角色描边、接触阴影、NPC 脚底与地面资源回归。

const CASES := {
	"res://scenes/guanqia/01_hongyadong.tscn": ["chuandanayi"],
	"res://scenes/guanqia/02_ciqikou.tscn": ["laojiangren", "aming"],
	"res://scenes/guanqia/03_zhongshan.tscn": ["laozhanggui", "pangzhanggui", "banggong", "laozhou"],
	"res://scenes/guanqia/04_fangdong.tscn": ["NPC_Follower1", "NPC_Follower6"],
	"res://scenes/guanqia/05_hongyadong_return.tscn": ["jianglishilaoren", "chuandanayi"],
}

var _ok := true

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	print(("[PASS] " if condition else "[FAIL] ") + message)
	_ok = _ok and condition

func _run() -> void:
	for scene_path: String in CASES:
		change_scene_to_file(scene_path)
		await process_frame
		await process_frame
		var terrain := current_scene.find_child("TerrainTile", true, false) as Sprite2D
		_check(terrain != null and "/assets/production/terrain/" in terrain.texture.resource_path, "%s 使用校准地面" % scene_path.get_file())
		var hero := current_scene.find_child("zhujue_donghua", true, false) as AnimatedSprite2D
		_check(hero != null and hero.material == null, "%s 主角无强制黑描边" % scene_path.get_file())
		_check(current_scene.find_child("GroundShadow", true, false) is Polygon2D, "%s 有柔和接触阴影" % scene_path.get_file())
		var interaction_hint := current_scene.find_child("InteractionHint", true, false) as Control
		_check(interaction_hint != null and interaction_hint.position.y >= 300.0, "%s 互动提示位于屏幕下方" % scene_path.get_file())
		var mid_layer := current_scene.find_child("BG_Mid", true, false)
		var mid_plate := mid_layer.get_node_or_null("Plate_00") as Sprite2D if mid_layer != null else null
		_check(mid_plate != null and absf(float(mid_plate.get_meta("visible_ground_y", -999.0)) - 247.0) < 0.1, "%s 中景建筑按可见底边贴地" % scene_path.get_file())
		for npc_name: String in CASES[scene_path]:
			var npc := current_scene.find_child(npc_name, true, false) as Node2D
			_check(npc != null and absf(npc.global_position.y - 240.0) < 1.0, "%s 脚底落在地面线" % npc_name)
		if scene_path.ends_with("01_hongyadong.tscn"):
			var building := current_scene.find_child("@Sprite2D@54", true, false) as Sprite2D
			_check(building != null and bool(building.get_meta("grounded_to_opaque_pixels", false)), "第一关独立建筑按不透明底边接地")
		if scene_path.ends_with("02_ciqikou.tscn"):
			var wood_visual := current_scene.find_child("@Sprite2D@60", true, false) as Sprite2D
			var wall := current_scene.find_child("di_erguan_yanbi", true, false) as Node2D
			var wall_prompt := wall.find_child("Prompt", false, false) as CanvasItem if wall != null else null
			_check(wall != null and absf(wall.global_position.y - 250.0) < 1.0, "第二关石壁压入地面 10 像素")
			_check(wall_prompt != null and not wall_prompt.visible, "石壁不再显示悬空方块提示")
			_check(wood_visual != null and absf(float(wood_visual.get_meta("grounded_visible_bottom_y", -999.0)) - 247.0) < 0.1, "第二关木头压入地面")
		if scene_path.ends_with("03_zhongshan.tscn"):
			var cargo := current_scene.find_child("CargoVisual", true, false) as Sprite2D
			_check(cargo != null and absf(float(cargo.get_meta("grounded_visible_bottom_y", -999.0)) - 247.0) < 0.1, "第三关货包压入地面")
		if scene_path.ends_with("05_hongyadong_return.tscn"):
			for prop_name in ["InfoBoardVisual", "ScenicViewerVisual", "PhotoCameraVisual"]:
				var prop := current_scene.find_child(prop_name, true, false) as Sprite2D
				_check(prop != null and absf(float(prop.get_meta("grounded_visible_bottom_y", -999.0)) - 247.0) < 0.1, "%s 压入地面" % prop_name)
	print("[RESULT] %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
