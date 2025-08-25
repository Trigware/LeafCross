extends Node

@onready var errorTitle = $"CanvasLayer/Error Title"
@onready var errorDescription = $"CanvasLayer/Error Description"

func _ready():
	Audio.play_music("Blue")
	errorTitle.text = Localization.get_text("errorhandler_room_title")
	await get_tree().create_timer(2.85).timeout
	create_tween().tween_property(errorDescription, "modulate:a", 1, 1)
	var extraInfo = Overworld.get_room_enum(Overworld.latestExitRoom)
	if Overworld.latestExitRoom == Overworld.Room.ErrorHandlerer: extraInfo = Localization.get_text("errorhandler_extrainfo_onload")
	if Overworld.saveFileCorrupted:
		Overworld.currentRoom = Overworld.Room.ErrorHandlerer
		extraInfo = Localization.get_text("errorhandler_extrainfo_savecorrupted")
	errorDescription.text = Localization.get_text("errorhandler_room_description", {
		"roomID": Overworld.currentRoom,
		"extraInfo": extraInfo
	})
