shader_type canvas_item;

const int directions_count = 8;
const vec4 outline_color = vec4(0.87, 0.79, 0.24, 1);
const float color_offset = 0.15;
const float flash_speed = 5.5;

const vec2 directions[directions_count] = vec2[directions_count](
	vec2(-1.0, 0.0),
	vec2( 1.0, 0.0),
	vec2( 0.0,-1.0),
	vec2( 0.0, 1.0),
	vec2(-1.0,-1.0),
	vec2( 1.0,-1.0),
	vec2(-1.0, 1.0),
	vec2( 1.0, 1.0)
);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a == 0.0) {
		int empty_neighbours = 0;
		for (int i = 0; i < directions_count; i++) {
			vec2 neighbour_position = UV + directions[i] * TEXTURE_PIXEL_SIZE;
			vec4 neighbour_color = texture(TEXTURE, neighbour_position);
			if (neighbour_color.a < 1.0) empty_neighbours++;
		}
		if (empty_neighbours < directions_count) COLOR = outline_color;
	} else {
		float color_component_value = 1.0 - color_offset;
		bool black_shock = mod(floor(TIME * flash_speed), 2.0) == 0.0;
		if (black_shock) color_component_value = color_offset;
		COLOR = vec4(color_component_value, color_component_value, color_component_value, 1.0);
	}
}