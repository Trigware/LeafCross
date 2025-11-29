extends Node

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

func tween(object, property: String, final, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
	var tween_v = create_tween().tween_property(object, property, final, duration)
	tween_v.set_ease(ease_param).set_trans(trans_param)
	await tween_v.finished
	return tween_v

func alpha_tween(object, final, duration := 0.5, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
	await tween(object, "modulate:a", final, duration, ease_param, trans_param)

func offset_axis_tween(object, axis, offset, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
	var axis_number = 0 if axis == "x" else 1
	await tween(object, "position:" + axis, object.position[axis_number] + offset, duration, ease_param, trans_param)

func offset_x_tween(object, offset, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE): await offset_axis_tween(object, "x", offset, duration, ease_param, trans_param)
func offset_y_tween(object, offset, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE): await offset_axis_tween(object, "y", offset, duration, ease_param, trans_param)

func get_vec_depending_on_dist_and_rot_of_vec(original_vec: Vector2, distance: float, rotation_radians: float):
	var resulting_vec = original_vec
	resulting_vec.x += distance * cos(rotation_radians)
	resulting_vec.y += distance * sin(rotation_radians)
	return resulting_vec

func tween_uniform(object, uniform_name: String, final, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
	var value_at_start = object.material.get_shader_parameter(uniform_name)
	var tween_v = create_tween().tween_method(
		func(value): object.material.set_shader_parameter(uniform_name, value),
		value_at_start,
		final,
		duration
	)
	tween_v.set_ease(ease_param).set_trans(trans_param)
	await tween_v.finished
	return tween_v

func tween_multiple(objects: Array, property: String, final, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
	for obj in objects: tween(obj, property, final, duration, ease_param, trans_param)
	await wait(duration)

func get_rectangle_shape_points(collision_shape: CollisionShape2D) -> Array[Vector2]:
	if not collision_shape.shape is RectangleShape2D:
		push_error("Collider is not a rectangle shape!")
		return []
	var rect_shape = collision_shape.shape
	var shape_pos = collision_shape.global_position
	var dist_to_x_edge = rect_shape.size.x / 2
	var dist_to_y_edge = rect_shape.size.y / 2
	
	var top_left = Vector2(shape_pos.x - dist_to_x_edge, shape_pos.y - dist_to_y_edge)
	var top_right = Vector2(shape_pos.x + dist_to_x_edge, shape_pos.y - dist_to_y_edge)
	var bottom_left = Vector2(shape_pos.x - dist_to_x_edge, shape_pos.y + dist_to_y_edge)
	var bottom_right = Vector2(shape_pos.x + dist_to_x_edge, shape_pos.y + dist_to_y_edge)
	return [top_left, top_right, bottom_left, bottom_right]

func get_closest_distance_from_rect_shape_points(shape_a: CollisionShape2D, shape_b: CollisionShape2D):
	var pts_a = get_rectangle_shape_points(shape_a)
	var pts_b = get_rectangle_shape_points(shape_b)
	var closest_distance = INF
	for point_a in pts_a: for point_b in pts_b:
		var current_dist = point_a.distance_to(point_b)
		if current_dist < closest_distance: closest_distance = current_dist
	return closest_distance

func await_any_movement_or_continue_key_press(stop_when_pressed = true):
	while true:
		var key_pressed = is_any_movement_or_continue_key_pressed()
		if key_pressed:
			if stop_when_pressed: break
		else:
			if not stop_when_pressed: break
		await get_tree().process_frame

func is_any_movement_or_continue_key_pressed():
	return Input.is_action_pressed("continue") or Input.is_action_pressed("move_down") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")

func convert_time_to_words(time_to_be_converted: float) -> String:
	var number_of_hours = floori(time_to_be_converted / 3600)
	var seconds_in_latest_hour = fmod(time_to_be_converted, 3600)
	var number_of_minutes = floori(seconds_in_latest_hour / 60)
	var number_of_seconds_exact = fmod(seconds_in_latest_hour, 60)
	var number_of_seconds = floori(number_of_seconds_exact)
	var number_of_milliseconds = floori((number_of_seconds_exact - floor(number_of_seconds_exact)) * 1000)
	
	var result = ""
	if number_of_hours > 0: result += str(number_of_hours) + "h "
	if number_of_minutes > 0 or number_of_hours > 0: result += str(number_of_minutes) + "min "
	if number_of_seconds >= 1:
		result += str(number_of_seconds) + "s"
		if time_to_be_converted < 10: result += " "
	if time_to_be_converted < 10: result += str(number_of_milliseconds) + "ms"
	return result
