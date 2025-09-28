extends Node2D

var rock_destinations := {}
const initial_position_x_offset = 200
const y_start_point = 400
const throw_tween_minimal_duration = 1.25
const throw_tween_maximum_duration = 1.65

func _ready():
	rock_destinations.clear()
	for rock in get_children():
		rock_destinations[rock] = rock.position
		var used_offset = randf_range(-initial_position_x_offset, initial_position_x_offset)
		rock.position.x += used_offset
		rock.position.y = y_start_point

func rocks_animation():
	for rock in get_children():
		var destination = rock_destinations[rock]
		var throw_tween = create_tween().tween_property(rock, "position", destination, randf_range(throw_tween_minimal_duration, throw_tween_maximum_duration))
		throw_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await wait(1)
	Audio.play_sound(UID.SFX_ROCKS_FALL)

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout
