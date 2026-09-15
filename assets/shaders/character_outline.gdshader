shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.025, 0.035, 0.055, 0.92);
uniform float outline_px : hint_range(1.0, 12.0, 1.0) = 7.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 step_size = TEXTURE_PIXEL_SIZE * outline_px;
	float around = 0.0;
	around = max(around, texture(TEXTURE, UV + vec2(step_size.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV - vec2(step_size.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV + vec2(0.0, step_size.y)).a);
	around = max(around, texture(TEXTURE, UV - vec2(0.0, step_size.y)).a);
	around = max(around, texture(TEXTURE, UV + step_size).a);
	around = max(around, texture(TEXTURE, UV - step_size).a);
	around = max(around, texture(TEXTURE, UV + vec2(step_size.x, -step_size.y)).a);
	around = max(around, texture(TEXTURE, UV + vec2(-step_size.x, step_size.y)).a);
	COLOR = base;
	if (base.a < 0.05 && around > 0.05) {
		COLOR = outline_color;
	}
}
