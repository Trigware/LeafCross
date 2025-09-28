extends Node2D

@onready var top_part = $Top
@onready var bottom_part = $Bottom
@onready var eye_center = $"Eye Center"
@onready var light = $Light

var eye_part_y_offset : int
const inital_y_offset := 10
const first_anim_duration := 0.5

func _ready():
	eye_part_y_offset = bottom_part.position.y
	top_part.position.y = -inital_y_offset
	bottom_part.position.y = inital_y_offset
	modulate.a = 0
	eye_center.hide()

func first_eye_animation():
	create_tween().tween_property(self, "modulate:a", 1, first_anim_duration)
	tween_eye_part(top_part, -eye_part_y_offset)
	tween_eye_part(bottom_part, eye_part_y_offset)

func tween_eye_part(part, offset):
	var tween = create_tween().tween_property(part, "position:y", offset, first_anim_duration)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

func eye_center_show():
	eye_center.show()

const final_glow_energy = 0.75
const glow_visibility_duration := 0.5

func glowing_eye_tween():
	await wait(2)
	create_tween().tween_property(light, "energy", final_glow_energy, glow_visibility_duration) # show glow tween
	await wait(4)
	create_tween().tween_property(light, "energy", 0, glow_visibility_duration) # hide glow tween
	await wait(4)

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout
