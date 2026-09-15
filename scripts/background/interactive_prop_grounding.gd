class_name InteractivePropGrounding
extends Sprite2D
## 将互动道具按真正可见的像素底边压入地面，忽略透明留白和柔光。

@export var target_ground_y := 247.0
@export_range(0.0, 1.0, 0.01) var alpha_cutoff := 0.12

static var _bottom_cache: Dictionary = {}

func _ready() -> void:
	ground_sprite(self, target_ground_y, alpha_cutoff)

static func ground_sprite(sprite: Sprite2D, ground_y: float = 247.0, cutoff: float = 0.12) -> void:
	if sprite == null or sprite.texture == null:
		return
	var visible_bottom := _get_visible_bottom(sprite.texture, cutoff)
	if visible_bottom < 0:
		return
	var origin_y := float(sprite.texture.get_height()) * 0.5 if sprite.centered else 0.0
	var bottom_global_y := sprite.global_position.y + (float(visible_bottom) - origin_y) * absf(sprite.global_scale.y)
	sprite.global_position.y += ground_y - bottom_global_y
	sprite.set_meta("grounded_visible_bottom_y", ground_y)

static func _get_visible_bottom(source: Texture2D, cutoff: float) -> int:
	var cache_key := "%s@%.2f" % [source.resource_path, cutoff]
	if _bottom_cache.has(cache_key):
		return int(_bottom_cache[cache_key])
	var image := source.get_image()
	if image == null or image.is_empty():
		return -1
	for y in range(image.get_height() - 1, -1, -1):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a >= cutoff:
				_bottom_cache[cache_key] = y + 1
				return y + 1
	_bottom_cache[cache_key] = -1
	return -1
