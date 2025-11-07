shader_type canvas_item;

uniform float image_pixel_height = 36.0;
uniform float hide_progression = 0.0;
uniform float moving_speed = 1.0;
uniform float progress_normalizer = 1.0;
varying float local_y;

void vertex()
{
	float used_progress = hide_progression / (1.0 - progress_normalizer + 1.0);
	float pixel_step = 1.0 / image_pixel_height;
	float floored_progress = floor(used_progress / pixel_step) * pixel_step;
	float offset = image_pixel_height * floored_progress;
	local_y = VERTEX.y + offset;
	VERTEX.y += offset * moving_speed;
}

void fragment()
{
	if (local_y > image_pixel_height / 2.0) {
        COLOR.a = 0.0;
    }
}