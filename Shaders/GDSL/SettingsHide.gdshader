shader_type canvas_item;

uniform float hide_progression : hint_range(0.0, 1.0) = 0.0;
uniform bool hide_from_bottom = true;

void fragment() {
	if (UV.y >= hide_progression && hide_from_bottom ||
		UV.y <= 1.0 - hide_progression && !hide_from_bottom) { COLOR.a = 0.0; }
}