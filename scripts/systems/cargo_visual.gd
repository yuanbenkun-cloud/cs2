extends Sprite2D
## 染布货包随完整度切换外观，让第三关后果不只停留在数字上。

const TEXTURES := {
	"完好": "res://assets/production/props/gameplay/cargo-intact.png",
	"受损": "res://assets/production/props/gameplay/cargo-damaged.png",
	"严重受损": "res://assets/production/props/gameplay/cargo-ruined.png",
}

func _ready() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if not gs.is_connected("goods_changed", _on_goods_changed):
			gs.connect("goods_changed", _on_goods_changed)
		_refresh(int(gs.get("goods_integrity")))
	else:
		InteractivePropGrounding.ground_sprite(self)

func _on_goods_changed(current: int, _delta: int, _event_name: String) -> void:
	_refresh(current)

func _refresh(value: int) -> void:
	var tier := "完好" if value >= 70 else ("受损" if value >= 40 else "严重受损")
	texture = load(TEXTURES[tier]) as Texture2D
	position = Vector2(0, -20)
	InteractivePropGrounding.ground_sprite(self)
	if value < 100:
		modulate = Color("#fff0da")
		var tween := create_tween()
		tween.tween_property(self, "position:x", 2.0, 0.05)
		tween.tween_property(self, "position:x", -2.0, 0.05)
		tween.tween_property(self, "position:x", 0.0, 0.05)
