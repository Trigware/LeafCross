shader_type canvas_item;

uniform float brightness : hint_range(-1.0, 1.0);

void fragment() {
	vec4 currentColor = texture(TEXTURE, UV);
	if (brightness > 0.0) {
		COLOR = mix(currentColor, vec4(1, 1, 1, currentColor.a), brightness);
	} else {
		float used_brightness = 1.0 - (-brightness);
		COLOR = mix(vec4(0, 0, 0, currentColor.a), currentColor, used_brightness);
	}
}
