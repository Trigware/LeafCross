shader_type canvas_item;

uniform float vertical_tile_amount = 4.0;
uniform float aspect_ratio = 1.0;
uniform float wave_amplitude = 0.1;
uniform float wave_speed = 1.0;
uniform float[16] begining_and_end_unvisible;
uniform vec2[2] begining_and_end_deep_water;
uniform bool apply_tint = false;

const vec4 deep_water_tint = vec4(0.2, 0.225, 0.25, 0.0);
const float deep_water_hint = 0.15;

float inverse_lerp(float a, float b, float v) {
	return (v - a) / (b - a);
}

void fragment() {
	vec2 used_tile_amount = vec2(vertical_tile_amount * aspect_ratio, vertical_tile_amount);
	vec2 tiled_uv = UV * used_tile_amount;
	vec2 waves_uv_offset = vec2(cos(TIME * wave_speed + tiled_uv.x + tiled_uv.y), sin(TIME * wave_speed + tiled_uv.x + tiled_uv.y)) * wave_amplitude;
	tiled_uv = fract(UV * used_tile_amount + waves_uv_offset);
	COLOR = texture(TEXTURE, tiled_uv);

	vec2 top_left_uv = begining_and_end_deep_water[0], bottom_right = begining_and_end_deep_water[1];
	float dist_to_left = UV.x - top_left_uv.x, dist_to_right = bottom_right.x - UV.x;
	float dist_to_top = UV.y - top_left_uv.y, dist_to_bottom = bottom_right.y - UV.y;
	float closest_dist = min(min(min(dist_to_left, dist_to_right), dist_to_top), dist_to_bottom);
	float deep_water_intensity = clamp(inverse_lerp(0.0, deep_water_hint, closest_dist), 0.0, 1.0);

	if (apply_tint) { COLOR = mix(COLOR, COLOR - deep_water_tint, deep_water_intensity); }

	for (int i = 0; i < 16; i += 2) {
		float gap_start = begining_and_end_unvisible[i];
		float gap_end = begining_and_end_unvisible[i + 1];
		if (aspect_ratio > 1.0) {
			if (UV.x >= gap_start && UV.x <= gap_end) { COLOR = vec4(0.0, 0.0, 0.0, 0.0); break; }
		} else {
			if (UV.y >= gap_start && UV.y <= gap_end) { COLOR = vec4(0.0, 0.0, 0.0, 0.0); break; }
		}
	}}