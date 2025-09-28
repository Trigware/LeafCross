extends Node

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

func tween(object, property, final, duration := 1.0, ease_param := Tween.EASE_IN_OUT, trans_param := Tween.TRANS_SINE):
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
