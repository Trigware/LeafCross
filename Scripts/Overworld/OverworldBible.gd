extends Node2D

@onready var sprite = $Sprite
@onready var light = $Sprite/Light
var rotation_multiplier = 0.5
var activated = false

const initial_rotation_multiplier = 0.5
const sprite_show_duration = 0.85
const light_show_duration = 2
const final_energy = 10
const second_duration_travel_distance = 600
const prepare_destination = -50
const prepare_destination_duration = 0.2
const move_delay = 0.2
const final_scale = Vector2(3, 3)

func _process(_delta):
	sprite.rotate(PI/8*rotation_multiplier)

func show_bible():
	rotation_multiplier = initial_rotation_multiplier
	global_position = Player.get_body_pos()
	var sprite_tween = create_tween()
	sprite_tween.tween_property(sprite, "modulate:a", 1, sprite_show_duration).\
		set_ease(Tween.EASE_IN_OUT)
	tween_light(final_energy)

func tween_light(final):
	var light_tween = create_tween()
	light_tween.tween_property(light, "energy", final, light_show_duration).\
		set_ease(Tween.EASE_IN_OUT)

func go_towards_stand(marker: Marker2D):
	await get_tree().create_timer(move_delay).timeout
	var used_prepare_destination = Player.get_newest_dir() * prepare_destination
	var prepare_tween = create_tween().tween_property(sprite, "position", used_prepare_destination, prepare_destination_duration)
	prepare_tween.set_ease(Tween.EASE_OUT)
	await prepare_tween.finished
	
	var destination = marker.global_position
	var duration = destination.length() / second_duration_travel_distance
	var final_tween = create_tween().tween_property(sprite, "global_position", destination, duration)
	final_tween.set_ease(Tween.EASE_IN_OUT)
	final_tween.set_trans(Tween.TRANS_EXPO)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", final_scale, duration)
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	
	tween_light(0)
	
	var final_rotation_tween = create_tween()
	final_rotation_tween.tween_property(self, "rotation_multiplier", 0, duration/4)
	await final_rotation_tween.finished
	
	sprite.rotation = angle_normalize(sprite.rotation)
	create_tween().tween_property(sprite, "rotation", 0, duration/4)
	sprite.play()

func angle_normalize(angle: float): # normalizes angle to a range between -PI and PI
	return fmod(angle + PI, TAU) - PI

func reset():
	rotation_multiplier = initial_rotation_multiplier
	sprite.position = Vector2(0, 0)
	sprite.scale = Vector2(1, 1)
	sprite.modulate.a = 0
	light.energy = 0
	sprite.frame = 0
	sprite.rotation = 0
	activated = false

func attempt_to_load_bible():
	rotation_multiplier = 0
	sprite.rotation = 0
	var bible_stand = null
	for child in Overworld.activeRoom.get_children():
		if not child.has_meta("bible_stand"): continue
		bible_stand = child
	if bible_stand == null: return
	var marker = bible_stand.get_node("Bible Stand Point")
	activated = true
	sprite.global_position = marker.global_position * Overworld.scaleConst
	sprite.scale = final_scale
	sprite.frame = sprite.sprite_frames.get_frame_count("default")
	sprite.modulate.a = 1
