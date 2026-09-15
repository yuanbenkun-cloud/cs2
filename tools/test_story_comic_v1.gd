extends SceneTree
## 序章及关间漫画的逐格输入、动机链与安全结束回归。

var failed := 0
var prologue_finished := false

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + label)
	if not ok:
		failed += 1

func _run() -> void:
	await process_frame
	await process_frame
	var director := root.get_node("StoryDirector")
	var constants: Dictionary = director.get_script().get_script_constant_map()
	var prologue: Array = constants.get("PROLOGUE_COMIC", [])
	var comics: Dictionary = constants.get("COMIC_STORIES", {})
	_check(prologue.size() == 4, "序章包含赶路、抄小路、遇见阿姨和追逐四格")
	_check(str(prologue[1].get("body", "")).contains("窄巷") and str(prologue[2].get("body", "")).contains("两单"), "序章明确抄小路仍遇见传单阿姨")
	var prologue_text := str(prologue)
	_check(not prologue_text.contains("石扣") and not prologue_text.contains("历史残影"), "序章不提前触发石头机关")
	for index in prologue.size():
		var beat := prologue[index] as Dictionary
		var art_path := str(beat.get("art", ""))
		_check(art_path.contains("prologue-v2/panel-%d.png" % (index + 1)) and ResourceLoader.exists(art_path), "序章第%d格使用独立重绘画面" % (index + 1))
		_check((beat.get("actors", []) as Array).is_empty(), "序章第%d格不再叠加僵硬角色贴片" % (index + 1))
	_check(str((comics[3] as Array)[1].get("body", "")).contains("渡船") and str((comics[3] as Array)[2].get("body", "")).contains("工钱"), "第三关交代送货期限与受益者")
	_check(str((comics[4] as Array)[2].get("body", "")).contains("六个人") and str((comics[4] as Array)[3].get("body", "")).contains("一个也别落下"), "第四关交代救人委托与主角选择")

	director.call("play_prologue", Callable(self, "_on_prologue_finished"))
	await process_frame
	var comic := director.find_child("StoryComic", true, false)
	_check(comic != null and int(comic.get("_revealed")) == 0, "序章初始等待玩家揭格")
	for expected in range(1, 5):
		comic.set("_guard_until", 0)
		comic.call("_request_advance")
		await create_timer(0.25).timeout
		_check(int(comic.get("_revealed")) == expected, "一次输入只揭开第%d格" % expected)
	comic.set("_guard_until", 0)
	comic.call("_request_advance")
	await create_timer(0.4).timeout
	_check(prologue_finished and not bool(director.get("busy")), "全部画格后再按一次才结束序章")
	print("[RESULT] %s" % ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)

func _on_prologue_finished() -> void:
	prologue_finished = true
