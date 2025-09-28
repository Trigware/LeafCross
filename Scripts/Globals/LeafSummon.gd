extends Node2D

@onready var leaf = $"CanvasLayer/Leaf Body/Leaf"
@onready var light = $"CanvasLayer/Leaf Body/Leaf/Light"
@onready var movement_arrows = $"CanvasLayer/Leaf Body/Leaf/Movement Arrows"
@onready var leaf_collider = $"CanvasLayer/Leaf Body/Collider"
@onready var leaf_body = $"CanvasLayer/Leaf Body"

const leaf_tween_duration = 1
const leaf_start_end_offset = 75
var leaf_start_position
const change_choice_times = 20
const original_choice_wait_duration = 1.75
const normal_leaf_scale = 1.5
const light_final_scale = 0.4
const leaf_y_destination_hover_offset = 70
const leaf_hover_y_anchor = 70

func _ready():
	leaf_start_position = leaf.global_position
	movement_arrows.modulate.a = 0
	await show_normal_leaf()
	show_leaf_machine()

func flowing_water_ambience():
	Audio.play_sound(UID.SFX_FLOWING_WATER)
	await wait(randf_range(10, 25))
	flowing_water_ambience()

func wait(duration: float):
	await get_tree().create_timer(duration).timeout

func change_choice(wait_time: float):
	await wait(wait_time)
	Audio.play_sound(UID.SFX_MAIN_MENU_CHOICE_CHANGE)
	if leaf.frame == 3: leaf.frame = 0
	else: leaf.frame += 1

func show_normal_leaf():
	leaf.frame = 0
	leaf.animation = &"default"
	light.scale = Vector2(0, 0)
	leaf.position.x -= leaf_start_end_offset
	leaf.modulate.a = 0
	await wait(1.25)
	create_tween().tween_property(leaf, "global_position:x", leaf_start_position.x, leaf_tween_duration/2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(leaf, "modulate:a", 1, leaf_tween_duration)
	leaf.play()
	await wait(0.25)
	Audio.play_sound(UID.SFX_LEAF_APPEAR)
	leaf.stop()
	leaf.animation = &"elements"
	for i in range(change_choice_times):
		await change_choice(original_choice_wait_duration / (i+1))
	leaf.animation = &"small_leaf"
	await wait(0.5)
	create_tween().tween_property(leaf, "scale", leaf.scale/2, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await create_tween().tween_property(leaf_collider, "scale", leaf_collider.scale/2, 1).finished

func show_leaf_machine():
	flowing_water_ambience()
	await wait(0.75)
	leaf_hover()

func leaf_hover():
	var direction = 1
	create_tween().tween_property(light, "scale", Vector2(light_final_scale, light_final_scale), 0.7)
	for i in range(3):
		if i == 2: direction = 0
		var y_dest = leaf_hover_y_anchor + leaf_y_destination_hover_offset * direction
		var move_tween = create_tween().tween_property(leaf_body, "position:y", y_dest, 2)
		move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		await move_tween.finished
		direction *= -1
	create_tween().tween_property(movement_arrows, "modulate:a", 1, 0.5)
	movement_arrows.play()
	leaf_body.lock_movement = false
