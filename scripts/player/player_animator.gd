class_name PlayerAnimator
extends Node

## 占位动画：优先翻转 Kenney 精灵（KenneyHero.flip_h）；无精灵时翻转白块指示朝向。

var _face: ColorRect = null
var _hero: Sprite2D = null

func _ready() -> void:
	_face = get_node_or_null("FaceRect") as ColorRect
	_hero = get_node_or_null("zhujue_donghua") as Sprite2D
	if _hero == null:
		_hero = get_node_or_null("KenneyHero") as Sprite2D

func set_look(dir: int) -> void:
	if _hero != null:
		_hero.flip_h = dir < 0
		return
	if _face != null:
		_face.position.x = 10.0 if dir > 0 else -14.0