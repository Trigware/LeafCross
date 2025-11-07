extends Node2D

@onready var ladder_sprite = $"Ladder Sprite"
@onready var lever_platform = $"Lever Platform"
@onready var lever = $Lever
@onready var lasers_parent = $Lasers
@onready var shadow = $Shadow

func _ready():
	make_shader_unique(ladder_sprite, 86, 0.92)
	make_shader_unique(lever_platform, 170, 0.23)

func make_shader_unique(node, image_pixel_height, progress_normalizer):
	var shader_resource = UID.SHD_HIDE_SPRITE.duplicate(true)
	shader_resource.set_shader_parameter("image_pixel_height", image_pixel_height)
	shader_resource.set_shader_parameter("progress_normalizer", progress_normalizer)
	node.material = shader_resource

func update_hide_progression(hide_progress):
	ladder_sprite.material.set_shader_parameter("hide_progression", hide_progress)
	lever_platform.material.set_shader_parameter("hide_progression", hide_progress)
	shadow.modulate.a = 1 - hide_progress

func set_lever_and_laser_alpha(alpha):
	lever.modulate.a = alpha
	lasers_parent.modulate.a = alpha

func lasers_and_levers_alpha_tween(start: float, end: float, duration: float):
	await create_tween().tween_method(
		func(value):
			set_lever_and_laser_alpha(value),
		start,
		end,
		duration
	).finished

func hide_progression_tween(start: float, end: float, duration: float, ladder_level = 0):
	await create_tween().tween_method(
		func(value):
			update_hide_progression(value),
		start,
		end,
		duration
	).finished
