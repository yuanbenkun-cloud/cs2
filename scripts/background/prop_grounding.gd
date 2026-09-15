extends StaticBody2D
## 将带透明底边的独立建筑摆件按实际不透明像素落到 Ground 顶面。

func _ready() -> void:
	for child in get_children():
		if not child is Sprite2D:
			continue
		var sprite := child as Sprite2D
		if sprite.texture == null or not sprite.texture.resource_path.begins_with("res://assets/objects/"):
			continue
		var image := sprite.texture.get_image()
		if image == null or image.is_empty():
			continue
		var used := image.get_used_rect()
		if used.size.y <= 0:
			continue
		var opaque_bottom := used.position.y + used.size.y
		var bottom_padding := float(image.get_height() - opaque_bottom)
		# 再压入地面少许，遮住像素插值产生的细亮缝。
		sprite.position.y += bottom_padding * absf(sprite.scale.y) + 9.0
		sprite.set_meta("grounded_to_opaque_pixels", true)
