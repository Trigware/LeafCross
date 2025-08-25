extends Label

const particle_x_offset = 35
const particle_final_y_offset = 100
const alpha_tween_duration = 0.2
const scale_divident = 3

func _ready():
	modulate.a = 0
	var parent = get_parent()
	parent.scale = Vector2.ONE / scale_divident

func set_hp_delta(delta):
	var printed_text = str(delta)
	if delta > 0: printed_text = "+" + printed_text
	play_anim(printed_text)

func play_anim(shown_text):
	text = str(shown_text)
	var used_particle_x_offset = particle_x_offset
	var last_player_face_left = Player.node.is_left_last_horizontal_dir
	if last_player_face_left:
		used_particle_x_offset *= -1
	position.x += used_particle_x_offset
	
	move_damage_particle_up()
	var show_tween = create_tween().tween_property(self, "modulate:a", 1, alpha_tween_duration)
	await show_tween.finished
	await get_tree().create_timer(alpha_tween_duration/2).timeout
	var hide_tween = create_tween().tween_property(self, "modulate:a", 0, alpha_tween_duration)
	await hide_tween.finished
	queue_free()

func move_damage_particle_up():
	var final_y_position = position.y - particle_final_y_offset
	create_tween().tween_property(self, "position:y", final_y_position, 1)
