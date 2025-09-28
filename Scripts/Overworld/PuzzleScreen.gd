extends Node2D

@onready var puzzle_screen = $Screen
const progress_speed = 0.085

func _process(delta):
	puzzle_screen.material.set_shader_parameter("progress", puzzle_screen.material.get_shader_parameter("progress") + delta * progress_speed)
