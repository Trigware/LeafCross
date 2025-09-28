extends Node2D

@onready var logo_tree = $Tree
@onready var logo_mushroom = $Mushroom
@onready var logo_leaf = $Leaf
@onready var logo_crowbar = $Crowbar
@onready var blue_magnet = $"Blue Magnet"
@onready var red_magnet = $"Red Magnet"
@onready var camera = get_parent().get_node("Camera")
@onready var rocks = $Rocks
@onready var eye = $Eye
@onready var blue_dna = $"Blue DNA"
@onready var orange_dna = $"Orange DNA"
@onready var cross = $Cross

const logo_tree_x_destination := 144
const logo_mushroom_y_destination := 276
const logo_leaf_y_destination = 265

const setup_logo_tree_x := -120
const setup_logo_mushroom_y := -200
const setup_logo_leaf_y = 300
const magnet_y_offset = 500
const camera_shake_offset = 35
const initial_cross_position_x = -550

var cross_destination_x : float
signal after_flash

func _ready():
	setup_positions()
	start_animation()

func start_animation():
	tree_animation()
	await wait(0.5)
	mushroom_animation()
	await wait(0.6)
	leaf_animation()
	await wait(0.7)
	crowbar_animation()
	await wait(0.4)
	rocks.rocks_animation()
	await wait(0.2)
	magnet_animation()
	await wait(0.4)
	eye.first_eye_animation()
	await wait(0.2)
	dna_animation()
	await wait(0.3)
	cross_animation()

func setup_positions():
	logo_tree.frame = 0
	logo_tree.position.x = setup_logo_tree_x
	logo_mushroom.position.y = setup_logo_mushroom_y
	logo_mushroom.rotation = PI
	logo_leaf.position.y = setup_logo_leaf_y
	set_leaf_brightness(-1)
	logo_crowbar.modulate.a = 0
	logo_crowbar.rotation = -PI/2
	blue_magnet.position.y -= magnet_y_offset
	red_magnet.position.y += magnet_y_offset
	logo_leaf.frame = 0
	logo_crowbar.frame = 0
	blue_dna.hide()
	orange_dna.hide()
	cross_destination_x = cross.position.x
	cross.position.x = initial_cross_position_x

const loading_screen_tween_duration := 0.6

func tree_animation():
	var movement_anim = create_tween().tween_property(logo_tree, "position:x", logo_tree_x_destination, 1)
	movement_anim.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await wait(0.3)
	Audio.play_sound(UID.SFX_SWOOSH)
	await movement_anim.finished
	logo_tree.play()

func mushroom_animation():
	var fall_anim = create_tween().tween_property(logo_mushroom, "position:y", logo_mushroom_y_destination, 1)
	fall_anim.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var rotation_anim = create_tween().tween_property(logo_mushroom, "rotation", 0, 1)
	rotation_anim.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await wait(0.5)
	Audio.play_sound(UID.SFX_MUSHROOM_FALL)
	await fall_anim.finished

const leaf_hover_height = 75
const hover_duration = 0.75

func leaf_animation():
	tween_leaf_brightness(0, 1)
	var move_tween = create_tween().tween_property(logo_leaf, "position:y", logo_leaf_y_destination, hover_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	logo_leaf.play()
	await wait(0.5)
	Audio.play_sound(UID.SFX_LEAF_APPEAR)

const crowbar_alpha_duration = 0.25
const crowbar_rotation_duration = 0.35

func crowbar_animation():
	var alpha_tween = create_tween()
	alpha_tween.tween_property(logo_crowbar, "modulate:a", 1, crowbar_alpha_duration)
	var first_rotation_tween = create_tween().tween_property(logo_crowbar, "rotation", 0, crowbar_rotation_duration)
	first_rotation_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await wait(0.2)
	logo_crowbar.play()
	await wait(0.2)
	Audio.play_sound(UID.SFX_CROWBAR)

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

func set_leaf_brightness(value: float):
	logo_leaf.material.set_shader_parameter("brightness", value)

func get_leaf_brightness() -> float:
	return logo_leaf.material.get_shader_parameter("brightness")

func tween_leaf_brightness(final, duration):
	var brightness_tween = create_tween().tween_method(
		func(value): set_leaf_brightness(value),
		get_leaf_brightness(),
		final,
		duration
	)
	brightness_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await brightness_tween.finished

const magnet_tween_duration = 0.5

func magnet_animation():
	var red_magnet_tween = create_tween().tween_property(red_magnet, "position:y", red_magnet.position.y - magnet_y_offset, magnet_tween_duration)
	red_magnet_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var blue_magnet_tween = create_tween().tween_property(blue_magnet, "position:y", blue_magnet.position.y + magnet_y_offset, magnet_tween_duration)
	blue_magnet_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await blue_magnet_tween.finished
	LeafMode.screen_shake_multiple(3, camera, camera_shake_offset)
	Audio.play_sound(UID.SFX_MAGNET)

func dna_animation():
	blue_dna.show()
	blue_dna.play()
	orange_dna.show()
	orange_dna.play()
	Audio.play_sound(UID.SFX_DNA_APPEAR)

const cross_show_duration = 0.6
const visibility_overlay_duration = 0.25
const stay_overlay_duration = 0.15

func cross_animation():
	var move_tween = create_tween().tween_property(cross, "position:x", cross_destination_x, cross_show_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	Audio.play_sound(UID.SFX_PRAYING)
	await wait(0.35)
	await Overlay.overlay_tween(Color("cccccc"), visibility_overlay_duration)
	await wait(stay_overlay_duration)
	eye.eye_center_show()
	emit_signal("after_flash")
	await Overlay.overlay_tween(Color.TRANSPARENT, visibility_overlay_duration)
