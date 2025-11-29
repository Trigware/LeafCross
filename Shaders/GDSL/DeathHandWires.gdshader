shader_type canvas_item;

const float image_pixel_width = 192.0;
uniform float progress = 0;

void fragment() {
	float pixel_step = 1.0 / image_pixel_width;
	float floored_progress = floor(progress / pixel_step) * pixel_step;
	if (floored_progress <= UV.x) {
		COLOR.a = 0.0;
	}
}