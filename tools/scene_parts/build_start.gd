extends RefCounted
## 开始界面构建（scenes/kaishi.tscn）

func run(_tree: SceneTree) -> bool:
	var b = load("res://tools/scene_parts/build_common.gd").new()
	var root := Control.new()
	root.name = "StartRoot"
	var menu := Control.new()
	menu.name = "KaishiMenu"
	b.bind_script(menu, "res://scripts/ui/kaishi_menu.gd")
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var ok: bool = b.save_scene(root, "res://scenes/kaishi.tscn")
	root.free()
	return ok
