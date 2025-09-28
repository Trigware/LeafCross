extends Control

@onready var SaveFiles = $"Save Files"
@onready var HeaderLabel = $"Save Files/Header Label"
@onready var leaf = $"Save Files/Leaf"
@onready var copyLabel = $"Save Files/Copy Label"
@onready var eraseLabel = $"Save Files/Erase Label"
@onready var languageLabel = $"Save Files/Language Label"

var current_selected_file = 1
var disable_actions = false
var file_selected = false
var booleanChoice = 0
var file_option = -1
var current_file_mode := FileModes.PLAY
var erase_file_sure = false
var file_paste_destination = 0
var return_on_process = false

enum FileModes {
	PLAY = -1,
	COPY = 0,
	ERASE = 2
}

const leaf_y_offset = 50
const leaf_move_speed = 0.185

func _ready():
	Audio.play_music("A Weird File")
	interact_with_file_option(true)
	var next_final = 1
	load_player_data()
	while true:
		var tween = create_tween()
		tween.tween_property(SaveFiles, "modulate:a", next_final, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		next_final = 0.5 if next_final == 1 else 1.0

func load_player_data():
	for i in range(1, 4):
		for data in ["playerName", "PlayTime", "currentRoom"]:
			var node_path = "Save Files/File " + str(i) + "/Labels/" + data
			var label_node = get_node(node_path)
			var accessed_data = SaveData.access_other_file_data(i, data)
			if data == "PlayTime":
				accessed_data = SaveData.access_other_autosave_data(i, data)
			match data:
				"PlayTime": accessed_data = SaveMenu.convert_to_time_format(accessed_data)
				"currentRoom": accessed_data = Overworld.get_room_ingame_name(accessed_data)
			var handled_file = get_file_node(i)
			var save_file_exists = SaveData.save_file_exists(i)
			handled_file.modulate = Color.WHITE
			if not save_file_exists:
				handled_file.modulate = Color.ORANGE_RED
				if data == "playerName": accessed_data = Localization.get_text("save_file_not_found")
			if data != "playerName" and not save_file_exists: accessed_data = ""
			label_node.text = str(accessed_data)

func get_file_node(file_num):
	return get_node("Save Files/File " + str(file_num))

func _process(_delta) -> void:
	return_on_process = false
	if disable_actions: return
	var previous_selected_file = current_selected_file
	var previous_file_option = file_option
	handle_inputs()
	if return_on_process: return
	
	if current_selected_file <= 0:
		current_selected_file = 1
		return
	if current_selected_file >= 5:
		current_selected_file = 4
		return
	if Input.is_action_just_pressed("continue"):
		if file_selected: confirm_on_selected_file()
		else: selected_file()
		return
	if previous_selected_file == current_selected_file and previous_file_option == file_option: return
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)
	if previous_selected_file != current_selected_file:
		move_unselected_file(leaf_move_speed)
	if previous_file_option != file_option:
		move_inside_file_option()

func move_inside_file_option():
	var final_position = Vector2(250 + 250 * file_option, 552)
	if file_option == 1 and current_file_mode == FileModes.PLAY: final_position.x = 470
	var move_tween = create_tween().tween_property(leaf, "position", final_position, leaf_move_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	disable_actions = true
	await move_tween.finished
	disable_actions = false

func move_unselected_file(duration):
	if current_selected_file == 4:
		file_options()
		return
	resize_leaf(3, duration)
	var final_position = Vector2(180, 152 + 170 * (current_selected_file - 1) - leaf_y_offset)
	var tween_move = create_tween().tween_property(leaf, "position", final_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	disable_actions = true
	await tween_move.finished
	disable_actions = false

func file_options():
	file_option = 1
	resize_leaf(1.5, leaf_move_speed)
	move_inside_file_option()

func handle_inputs():
	var previous_boolean_choice = booleanChoice
	var pressed_left = Input.is_action_just_pressed("move_left")
	var pressed_right = Input.is_action_just_pressed("move_right")
	var pressed_back = Input.is_action_just_pressed("move_fast")
	if file_selected:
		if pressed_back:
			cancel_file_selection()
			return
		if pressed_left: booleanChoice = 0
		if pressed_right: booleanChoice = 1
		if previous_boolean_choice == booleanChoice: return
		Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)
		boolean_choice_move(leaf_move_speed)
		return
	if pressed_back and current_file_mode != FileModes.PLAY:
		file_option = FileModes.PLAY
		current_selected_file = 4
		selected_file()
		return_on_process = true
		return
	if Input.is_action_pressed("move_up"): current_selected_file -= 1
	if Input.is_action_pressed("move_down"): current_selected_file += 1
	if current_selected_file != 4: return
	if pressed_left and current_file_mode == FileModes.PLAY: file_option = max(0, file_option - 1)
	if pressed_right and current_file_mode == FileModes.PLAY: file_option = min(2, file_option + 1)

func selected_file():
	erase_file_sure = false
	Audio.play_sound(UID.SFX_MENU_CANCEL, 0.2)
	if current_selected_file == 4:
		interact_with_file_option()
		return
	
	if current_file_mode == FileModes.COPY and not is_space_for_file_copy():
		HeaderLabel.text = Localization.get_text("save_file_UNABLETOCOPY_header")
		return
	
	var save_file_exists = SaveData.save_file_exists(current_selected_file)
	if current_file_mode != FileModes.PLAY and not save_file_exists: return
	booleanChoice = 0
	file_selected = true
	var question_label = get_question_label()
	var question_text = Localization.get_text("save_file_create")
	if save_file_exists:
		question_text = Localization.get_text("save_file_choice_" + get_file_mode_name(current_file_mode))
	question_label.text = question_text
	var file_node_path = get_current_selected_file_node_path()
	get_node(file_node_path + "currentRoom").text = Localization.get_text("save_file_choice")
	get_node(file_node_path + "PlayTime").text = ""
	resize_leaf(1.5, leaf_move_speed)
	boolean_choice_move(leaf_move_speed)

func get_question_label():
	var file_node_path = get_current_selected_file_node_path()
	return get_node(file_node_path + "playerName")

func get_current_selected_file_node_path():
	return "Save Files/File " + str(current_selected_file) + "/Labels/"

func interact_with_file_option(in_ready := false):
	var option_name = get_file_mode_name(file_option)
	if option_name == null:
		if current_file_mode != FileModes.PLAY:
			file_option = FileModes.PLAY
			interact_with_file_option()
		else: transition_to_language_select()
		return
	if option_name == "COPY" and not is_space_for_file_copy():
		HeaderLabel.text = Localization.get_text("save_file_UNABLETOCOPY_header")
		return
	current_selected_file = 1
	current_file_mode = file_option
	if not in_ready: move_unselected_file(leaf_move_speed)
	HeaderLabel.text = Localization.get_text("save_file_" + option_name + "_header")
	if file_option != FileModes.PLAY:
		copyLabel.text = ""
		eraseLabel.text = ""
		languageLabel.text = Localization.get_text("save_file_back_label")
		return
	copyLabel.text = Localization.get_text("save_file_copy_label")
	eraseLabel.text = Localization.get_text("save_file_erase_label")
	languageLabel.text = "LANGUAGE"

func transition_to_language_select():
	if Overlay.sceneChangingDisabled: return
	disable_actions = true
	Overlay.change_scene(UID.SCN_CHOOSE_LANGUAGE, 1, 1)

func get_file_mode_name(mode: FileModes):
	return FileModes.find_key(mode)

func resize_leaf(final, duration):
	create_tween().tween_property(leaf, "scale", Vector2(final, final), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

const original_x_position = 315
const x_boolean_choice_gap = 200
const base_y_position = 170

func boolean_choice_move(duration):
	disable_actions = true
	var final_position = Vector2(original_x_position + x_boolean_choice_gap * booleanChoice,
		base_y_position * current_selected_file - leaf_y_offset)
	var move_tween = create_tween().tween_property(leaf, "position", final_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await move_tween.finished
	disable_actions = false

func confirm_on_selected_file():
	if Overlay.sceneChangingDisabled: return
	var file_node = get_file_node(current_selected_file)
	match current_file_mode:
		FileModes.ERASE:
			if booleanChoice == 0:
				if not erase_file_sure:
					Audio.play_sound(UID.SFX_MENU_CANCEL, 0.2)
					get_question_label().text = Localization.get_text("save_file_choice_ACTUALLY_ERASE")
					file_node.modulate = Color.RED
					erase_file_sure = true
					return
				delete_file()
				return
			else: file_node.modulate = Color.WHITE
		FileModes.COPY:
			if booleanChoice == 0:
				copy_file()
				return
	if booleanChoice == 1:
		cancel_file_selection()
		return
	disable_actions = true
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN)
	Overlay.change_scene(UID.SCN_LEGEND, 2, 1, 2)
	SaveData.load_game(current_selected_file)
	Audio.fade_music(1)

func cancel_file_selection():
	Audio.play_sound(UID.SFX_MENU_CANCEL, 0.2)
	file_selected = false
	move_unselected_file(leaf_move_speed)
	resize_leaf(3, leaf_move_speed)
	if current_file_mode != FileModes.PLAY:
		get_file_node(current_selected_file).modulate = Color.WHITE
	load_player_data()

func delete_file():
	SaveData.delete_file(current_selected_file)
	cancel_file_selection()
	Audio.play_sound(UID.SFX_FILE_SELECT_DELETE_FILE, 0.2)

func is_space_for_file_copy():
	file_paste_destination = 0
	for i in range(1, 4):
		var file_path = SaveData.get_save_file_path(i)
		if not FileAccess.file_exists(file_path):
			file_paste_destination = i
			return true
	return false

func copy_file():
	var regular_save_copy = SaveData.get_save_file_path(current_selected_file)
	var regular_save_paste = SaveData.get_save_file_path(file_paste_destination)
	copy_file_on_disk(regular_save_copy, regular_save_paste)
	
	var autosave_copy = SaveData.get_autosave_file_path(current_selected_file)
	var autosave_paste = SaveData.get_autosave_file_path(file_paste_destination)
	copy_file_on_disk(autosave_copy, autosave_paste)
	
	cancel_file_selection()
	Audio.play_sound(UID.SFX_FILE_SELECT_COPY, 0.2)

func copy_file_on_disk(copy_origin_path, paste_destination_path):
	var origin_file = FileAccess.open(copy_origin_path, FileAccess.READ)
	if origin_file == null: return
	var file_contents = origin_file.get_as_text()
	origin_file.close()
	
	var destination_file = FileAccess.open(paste_destination_path, FileAccess.WRITE)
	if destination_file == null: return
	destination_file.store_string(file_contents)
	destination_file.close()
