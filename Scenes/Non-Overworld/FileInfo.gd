extends Node2D

@onready var plus_label = $"Plus/New Game"
@onready var player_name = $"Icons/Player Name"
@onready var current_location = $"Icons/Current Location"
@onready var playtime = $Icons/Playtime
@onready var icons = $"Icons"
@onready var plus_icon = $Plus
@onready var options_root = $Options
@onready var play_game_label = $"Options/Play Game"
@onready var reset_game_label = $"Options/Reset Game"
@onready var cancel_game_label = $"Options/Cancel"
@onready var reset_option_root = $"Reset Option"
@onready var caution_text_label = $"Reset Option/Caution Text"
@onready var go_back_label = $"Reset Option/Go back"
@onready var reset_game_confirmation = $"Reset Option/Reset Game"
@onready var main_sprite = $"Main Sprite"

func setup_file_info(file_num):
	set_default_visibility()
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
	play_game_label.text = Localization.get_text("mainmenu_fileoption_playgame")
	reset_game_label.text = Localization.get_text("mainmenu_fileoption_resetgame")
	cancel_game_label.text = Localization.get_text("mainmenu_fileoption_cancel")
	caution_text_label.text = Localization.get_text("mainmenu_fileoption_resetgame_cautiontext")
	go_back_label.text = Localization.get_text("mainmenu_fileoption_cancel")
	reset_game_confirmation.text = Localization.get_text("mainmenu_fileoption_resetgame_confirmreset")

func set_default_visibility():
	icons.hide()
	plus_icon.show()
	options_root.hide()
	reset_option_root.hide()

func change_options_visibility(showing):
	icons.visible = not showing
	options_root.visible = showing

func change_reset_option_visibility(showing):
	options_root.visible = not showing
	reset_option_root.visible = showing
