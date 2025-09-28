extends CanvasLayer

@onready var current_file = $"Current File"
@onready var save_confirm = $"Save Confirm"

var menu_openned = false
var saved_game = false

const change_visibility_duration = 0.5
const change_visibility_save_confirm = 0.4
const save_confirm_full_visibility_duration = 0.75

signal game_saved
signal game_saved_menu_closed

func _ready():
	current_file.modulate.a = 0
	save_confirm.modulate.a = 0

func on_menu_open():
	if menu_openned: return
	current_file.labels.modulate = Color.WHITE
	menu_openned = true
	TextSystem.lockAction = true
	saved_game = false
	Player.move_camera_by(175, 0, change_visibility_duration)
	Overlay.alpha_tween(0.25, change_visibility_duration)
	current_file_tween(1)
	current_file.set_player_name(SaveData.playerName)
	var get_previously_saved_room = SaveData.access_loaded_file_data("currentRoom")
	var previous_room_name = Overworld.get_room_ingame_name(get_previously_saved_room).replace('\n', ' ')
	current_file.set_current_room(previous_room_name)
	var playTime = SaveData.access_loaded_autosave_data("PlayTime")
	current_file.set_playtime(convert_to_time_format(playTime, true))
	Player.end_leaf_flashes()
	await ChoicerSystem.give_localized_choice(["OverworldSaving_SaveGame", "OverworldSaving_DontSave"])
	await after_choice_behavior()
	on_menu_close()

func current_file_tween(final):
	create_tween().tween_property(current_file, "modulate:a", final, change_visibility_duration)

func after_choice_behavior():
	SaveData.save_choice_seen = true
	if ChoicerSystem.is_player_choice("OverworldSaving_DontSave"):
		NPCData.set_data(NPCData.ID.BibleInteractPrompt_SAVEINTROROOM, NPCData.Field.Suffix, "Save_Refused")
		NPCData.set_data(NPCData.ID.BibleInteractPrompt_SAVEINTROROOM, NPCData.Field.OnlyInteraction, true)
		return
	SaveData.game_saved_times += 1
	SaveData.save_game()
	emit_signal("game_saved")
	Player.update_animation("praying")
	Audio.play_sound(UID.SFX_SIT, 0.2)
	await get_tree().create_timer(0.2).timeout
	Audio.play_sound(UID.SFX_PRAYING)
	Player.play_animation("praying")
	await get_tree().create_timer(1).timeout
	post_pray()

func post_pray():
	Audio.play_sound(UID.SFX_GAME_SAVED, 0.2)
	current_file.labels.modulate = Color.YELLOW
	saved_game = true
	current_file.set_current_room(Overworld.get_room_ingame_name(Overworld.currentRoom))
	current_file.set_playtime(convert_to_time_format(SaveData.PlayTime))
	save_confirm_tween(Color.WHITE)

func save_confirm_tween(final: Color):
	save_confirm.text = Localization.get_text("OverworldSaving_GameSavedConfirm")
	var show_confirm = create_tween().tween_property(save_confirm, "modulate", final, change_visibility_save_confirm)
	await show_confirm.finished
	await get_tree().create_timer(save_confirm_full_visibility_duration).timeout
	create_tween().tween_property(save_confirm, "modulate:a", 0, change_visibility_save_confirm)

func on_menu_close():
	Player.return_camera(change_visibility_duration)
	current_file_tween(0)
	await Overlay.alpha_tween(0, change_visibility_duration)
	if saved_game: emit_signal("game_saved_menu_closed")
	menu_openned = false

func convert_to_time_format(seconds, ignore_empty = false):
	if str(seconds) == "":
		return "0:00" if ignore_empty else ""
	var sec = str(int(seconds) % 60)
	if sec.length() == 1: sec = "0" + sec
	@warning_ignore("integer_division")
	var minutes = str((int(seconds) / 60) % 60) + ":"
	@warning_ignore("integer_division")
	var hours = str(int(seconds) / 3600) + ":"
	if hours == "0:": hours = ""
	elif minutes.length() == 2: minutes = "0" + minutes[0] + ":"
	return hours + minutes + sec
