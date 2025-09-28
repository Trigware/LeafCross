extends Node

func _ready():
	SaveData.load_game(1)
	Overworld.enable()
