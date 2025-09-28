extends Area2D

@export var lever_color: Color
@export var lever_on = false
@export var belongs_to_ladder_index := -1

@onready var color_part = $Color
@onready var main_sprite = $Main

const confirmation_notice_tween_duration = 0.45
const original_confirmatiom_notice_y = -20
const final_cofirmation_notice_y = -35
const maximum_rotation = 30

var lever_interaction_disabled = false
var current_pull_progress: float

signal lever_pulled

func _ready():
	color_part.self_modulate = lever_color
	var start_pull_progress = 1 if lever_on else -1
	progress_lever_pull(start_pull_progress)

func can_interact_with_lever():
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"): return true
	return false

func _process(_delta):
	if not can_interact_with_lever() or not Input.is_action_just_pressed("continue"): return
	interact_with_lever()

const lever_pull_tween_duration = 0.4

func interact_with_lever():
	if lever_interaction_disabled or CutsceneManager.action_lock: return
	if Player.climbing_ladder_index != belongs_to_ladder_index: return
	var final_pull_progress = -1 if lever_on else 1
	lever_on = not lever_on
	lever_interaction_disabled = true
	Audio.play_sound(UID.SFX_LEVER_INTERACT, 0.2)
	emit_signal("lever_pulled")
	var lever_pull_tween = create_tween().tween_method(
		func(value): progress_lever_pull(value),
		current_pull_progress,
		final_pull_progress,
		lever_pull_tween_duration
	)
	lever_pull_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await lever_pull_tween.finished
	lever_interaction_disabled = false

func progress_lever_pull(new_progress):
	var actual_rotation = maximum_rotation * new_progress
	main_sprite.rotation_degrees = actual_rotation
	color_part.rotation_degrees = actual_rotation
	current_pull_progress = new_progress
