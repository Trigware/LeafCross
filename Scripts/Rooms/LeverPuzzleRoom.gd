extends "res://Scripts/Overworld/BaseRoom.gd"

@onready var info_tablet = $"Info Tablet"
@onready var exclamation_point_tutorial_trigger = $CutsceneTrigger
@onready var puzzle_door = $"Puzzle Door"

func _ready():
	if Overworld.puzzles_solved != 0: info_tablet.queue_free()
	if Overworld.puzzles_solved != 2: exclamation_point_tutorial_trigger.deactivated = true
	if Overworld.puzzles_solved == 2: puzzle_door.roomDestination = Overworld.Room.Tester_DangerousCaterpillars
