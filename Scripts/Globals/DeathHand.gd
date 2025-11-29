extends Node2D

@onready var hand = $Hand
@onready var wires = $Wires
@onready var leaf_particles = $"Leaf Particles"

const before_tween_delay := 0.15
var texture_size: Vector2
var fully_hidden_hand_x: float
var fully_extended_hand_x: float
const movement_tween_duration = 0.75
const after_crush_delay := 0.45

func _ready():
	initialize_position()
	await show_hand_first_time()
	await crush_leaf()
	await Helper.wait(after_crush_delay)
	await Helper.tween(self, "position:x", fully_hidden_hand_x, movement_tween_duration, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_SINE)
	LeafMode.emit_signal("end_death_hand")
	queue_free()

func initialize_position():
	Overlay.alpha_tween(0)
	Player.leaf_flash_disabled = true
	global_position = Player.leafNode.global_position
	LeafMode.death_hand_extended_position = global_position
	texture_size = hand.texture.get_size()
	position.x -= get_viewport_rect().size.x / 2
	fully_extended_hand_x = position.x
	position.x -= texture_size.x * scale.x
	fully_hidden_hand_x = position.x
	position.y -= texture_size.y

func show_hand_first_time():
	Overworld.activeRoom.hide()
	await Helper.wait(before_tween_delay / 2)
	Helper.tween(self, "position:x", fully_extended_hand_x, movement_tween_duration, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_SINE)
	await Helper.wait(before_tween_delay * 2)
	await Helper.tween_uniform(wires, "progress", 0.5, movement_tween_duration, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_SINE)

func close_hand(power):
	hand.frame_coords.y = 1
	Player.leafNode.visible = false
	LeafMode.screen_shake_multiple(3, Player.camera, LeafMode.screen_shake_offset, LeafMode.screen_shake_duration/2, power)
	leaf_particles.emitting = true

const wait_between_crushing_leaf = 0.4

const crush_leaf_count = 3

func crush_leaf():
	for i in range(crush_leaf_count+1):
		close_hand(min(i, 2))
		if i != crush_leaf_count:
			Audio.play_sound(UID.SFX_PLAYER_HIT, 0.2, 5, true)
			await Helper.wait(wait_between_crushing_leaf)
	Audio.play_sound(UID.SFX_LEAF_BREAK, 0, 3, true)
	leaf_particles.emitting = false
	Audio.music_tween(-24, -6, 0.25)
	Audio.play_music_no_loop("Disintegration")
