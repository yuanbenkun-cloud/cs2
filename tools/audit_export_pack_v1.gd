extends SceneTree
## Read-only inventory of files visible in a mounted exported PCK.

var files: Array[Dictionary] = []
var groups: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _walk(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		var full := path.path_join(name)
		if dir.current_is_dir():
			_walk(full)
		else:
			var file := FileAccess.open(full, FileAccess.READ)
			if file == null:
				continue
			var bytes := file.get_length()
			files.append({"path": full, "bytes": bytes})
			var parts := full.trim_prefix("res://").split("/")
			var group := parts[0] if parts.size() <= 2 else parts[0] + "/" + parts[1]
			groups[group] = int(groups.get(group, 0)) + bytes
	dir.list_dir_end()

func _run() -> void:
	_walk("res://")
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["bytes"]) > int(b["bytes"]))
	var sorted_groups: Array[Dictionary] = []
	for key in groups:
		sorted_groups.append({"group": key, "bytes": groups[key]})
	sorted_groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["bytes"]) > int(b["bytes"]))
	var total := 0
	for item in files:
		total += int(item["bytes"])
	print("TOTAL\t%d\t%d" % [files.size(), total])
	for item in sorted_groups:
		print("GROUP\t%s\t%d" % [item["group"], item["bytes"]])
	for i in mini(80, files.size()):
		print("TOP\t%s\t%d" % [files[i]["path"], files[i]["bytes"]])
	quit()
