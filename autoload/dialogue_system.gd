extends Node

## DialogueSystem（SPEC 6.4）：自研对话系统。无第三方插件。
## - load_data(path): 解析 JSON（每关一个 dialogue_levelN.json）
## - start_dialogue(node_id, speaker): 打开节点 → 逐行打字 → 选项/结束
## - choose(index): 选项回调；节点带 goods_event 时写入 GameState

signal ended

var active: bool = false
var _data: Dictionary = {}
var _queue: Array = []
var _options: Array = []
var _player: Node = null
var _panel: Control = null

func load_data(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_data = parsed
		return true
	return false

func start_dialogue(node_id: String, speaker: String = "") -> void:
	if active:
		return
	var p := _get_panel()
	if p == null:
		return
	active = true
	_panel = p
	_player = _get_player()
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", true)
	if speaker != "" and _panel.has_method("set_name_label"):
		_panel.call("set_name_label", speaker)
	## 关键：连接面板“推进请求”信号（每句按 E 后由面板发出）
	if not _panel.is_connected("advance_requested", _on_advance):
		_panel.connect("advance_requested", _on_advance)
	_panel.show()
	_open_node(node_id)

func _open_node(node_id: String) -> void:
	if not _data.has(node_id):
		_finish()
		return
	var node: Dictionary = _data[node_id]
	if node.has("goods_event") and str(node["goods_event"]) != "":
		GameState.apply_goods_event(str(node["goods_event"]))
	_queue = (node.get("lines", []) as Array).duplicate()
	_options = node.get("options", [])
	_next_line()

func _next_line() -> void:
	if _queue.size() > 0:
		var line: Dictionary = _queue.pop_front()
		_panel.call("play_line", str(line.get("speaker", "")), str(line.get("text", "")))
	else:
		if _options.size() > 0:
			_panel.call("show_options", _options)
		else:
			_finish()

func _on_advance() -> void:
	if _panel != null and bool(_panel.call("has_options")):
		return
	_next_line()

func choose(index: int) -> void:
	if index < 0 or index >= _options.size():
		_finish()
		return
	var opt: Dictionary = _options[index]
	var nxt := str(opt.get("next", ""))
	if nxt == "":
		_finish()
	else:
		_open_node(nxt)

func _finish() -> void:
	if _panel != null:
		_panel.call("hide_panel")
	if _player != null and _player.has_method("freeze"):
		_player.call("freeze", false)
	active = false
	ended.emit()

func _get_panel() -> Control:
	var cur := get_tree().current_scene
	if cur == null:
		return null
	var n := cur.find_child("DialoguePanel", true, false)
	return n as Control

func _get_player() -> Node:
	var cur := get_tree().current_scene
	if cur == null:
		return null
	return cur.find_child("zhujue", true, false)