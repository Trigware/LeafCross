shader_type canvas_item;

const float screen_texture_size = 192.0;
const float half_frame_dist = 0.25;
uniform float progress;
varying float used_progress;

void vertex() {
	used_progress = mod(progress, 1.0);
	VERTEX += vec2(used_progress, used_progress) * screen_texture_size / 2.0;
}

void fragment() {
	
	float center_frame_point = 1.0 - half_frame_dist - used_progress / 2.0;
	
	if (UV.x < center_frame_point - half_frame_dist ||
		UV.x > center_frame_point + half_frame_dist ||
		UV.y < center_frame_point - half_frame_dist ||
		UV.y > center_frame_point + half_frame_dist) discard;
}