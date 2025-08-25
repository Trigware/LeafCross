extends Node2D

@onready var plus_label = $"Plus/New Game"
@onready var player_name = $"Icons/Player Name"
@onready var current_location = $"Icons/Current Location"
@onready var playtime = $Icons/Playtime
@onready var icons = $"Icons"
@onready var plus_icon = $Plus

func setup_file_info(file_num):
	plus_label.text = Localization.get_text("mainmenu_saveinfo_newgame")
	if not SaveData.save_file_exists(file_num): return
	icons.show()
	plus_icon.hide()
	player_name.text = str(SaveData.access_other_file_data(file_num, "playerName"))
	var current_room = SaveData.access_other_file_data(file_num, "currentRoom")
	var current_location_as_str = Overworld.get_room_ingame_name(current_room)
	current_location.text = current_location_as_str
	var time_since_save_started = SaveData.access_other_autosave_data(file_num, "PlayTime")
	playtime.text = SaveMenu.convert_to_time_format(time_since_save_started)
