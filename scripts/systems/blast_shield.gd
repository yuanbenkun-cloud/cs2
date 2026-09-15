extends Node2D
## 顶部挡板：拦截落在水平范围内的导弹；两次命中后损毁。

@export var half_width := 92.0
@export var durability := 2
const STATE_TEXTURES := [
	"res://assets/production/props/gameplay/blast-shield-ruined.png",
	"res://assets/production/props/gameplay/blast-shield-damaged.png",
	"res://assets/production/props/gameplay/blast-shield-intact.png",
]
var _panel: Sprite2D
var _durability_label: Label

func _ready() -> void:
	_panel = get_node_or_null("Panel") as Sprite2D
	_durability_label = get_node_or_null("Durability") as Label
	_refresh()

func covers_x(world_x: float) -> bool:
	return durability > 0 and absf(world_x - global_position.x) <= half_width

func get_impact_y() -> float:
	return global_position.y - 8.0

func absorb_hit() -> void:
	durability = maxi(0, durability - 1)
	if _panel != null:
		var base_pos := _panel.position
		var tween := create_tween()
		tween.tween_property(_panel, "position", base_pos + Vector2(3, 0), 0.05)
		tween.tween_property(_panel, "position", base_pos - Vector2(3, 0), 0.05)
		tween.tween_property(_panel, "position", base_pos, 0.05)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_event", "shield_hit", randf_range(0.9, 1.05), -1.0)
	_refresh()

func _refresh() -> void:
	if _durability_label != null:
		_durability_label.text = "%s%s" % ["◆".repeat(durability), "◇".repeat(2 - durability)]
		_durability_label.add_theme_color_override("font_color", Color("#e8b04b") if durability > 0 else Color("#b23a48"))
	if _panel != null:
		_panel.texture = load(STATE_TEXTURES[clampi(durability, 0, 2)]) as Texture2D
	var safe_zone := get_node_or_null("SafeZone") as CanvasItem
	if safe_zone != null:
		safe_zone.visible = durability > 0

func get_checkpoint_state() -> Dictionary:
	return {"durability": durability}

func restore_checkpoint_state(state: Dictionary) -> void:
	durability = clampi(int(state.get("durability", 2)), 0, 2)
	_refresh()
