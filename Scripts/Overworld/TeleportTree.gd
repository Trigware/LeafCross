extends Node

@onready var windNode = $"Tree Root/Wind"

func _ready():
	windNode.finished.connect(on_wind_finished)

func on_wind_finished():
	await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
	windNode.pitch_scale = randf_range(0, 1)
	windNode.play()
