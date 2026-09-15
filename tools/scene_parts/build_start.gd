extends RefCounted
## 开始界面构建（scenes/kaishi.tscn）

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root := Control.new()
	root.name = "StartRoot"
	root.size = Vector2(640, 360)
	var menu := Control.new()
	menu.name = "KaishiMenu"
	b.bind_script(menu, "res://scripts/ui/kaishi_menu.gd")
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ok: bool = b.save_scene(root, "res://scenes/kaishi.tscn")
	root.free()
	return ok
