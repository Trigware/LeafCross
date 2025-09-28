extends Node2D

@onready var options_tree = get_parent().get_node("Options Tree")
@onready var logo = get_parent().get_node("Logo")
@onready var background = get_parent().get_node("Background")
@onready var stars = get_parent().get_node("Background/Stars")
@onready var extra_info_labels_root = get_parent().get_node("Extra Info Labels")
@onready var menu_title = $"Menu Title"
@onready var files_info_root = $Files
@onready var selector = $Selector
@onready var root = get_parent()

@onready var file_select_labels_root = $Labels
@onready var go_back_label = $"Labels/Go Back"
@onready var previous_chapter_label = $"Labels/Previous Chapter"
@onready var next_chapter_label = $"Labels/Next Chapter"

const file_select_x_dest = -400
const file_select_tween_duration := 0.4
const file_select_logo_destination = Vector2(0, -5)
const file_select_logo_scale := 0.35

const menu_title_initial_x := 1500
const menu_title_destination_x := 825
const menu_title_y_offset = 90

var selected_chapter = Enum.Chapter.WeirdForest
var current_label_selection := LabelSelection.Files
var prohibited_label_selections := []

enum LabelSelection {
	Files,
	PrevChapter,
	GoBack,
	NextChapter
}

func _ready():
	menu_title.position = Vector2(menu_title_initial_x, file_select_logo_destination.y + menu_title_y_offset)
	selector.hide()

const no_leaf_selector_degrees = 270

func show_file_select():
	go_back_label.text = Localization.get_text("mainmenu_choosefile_goback")
	selector.texture = UID.IMG_LEAF
	if not SaveData.seen_leaf:
		selector.texture = UID.IMG_NOLEAF_SELECTOR
		selector.rotation_degrees = no_leaf_selector_degrees
	set_menu_title_image()
	background_transition()
	await start_file_select_tweens()
	setup_selector()

func background_transition():
	make_tween(extra_info_labels_root, "position:y", root.hide_labels_position_y, file_select_tween_duration)
	await make_tween(background, "modulate", Color.BLACK, file_select_tween_duration).finished
	background.texture = UID.IMG_CHAPTER_BACKGROUNDS[selected_chapter]
	stars.hide()
	update_prohibited_label_selections()
	await make_tween(background, "modulate", Color.GRAY, file_select_tween_duration).finished

var selected_column = 0
const selector_y_destination = 500
const selector_setup_tween_duration = 0.4
var can_move_selector = false

func update_prohibited_label_selections():
	prohibited_label_selections = []
	if selected_chapter == 0: prohibited_label_selections.append(LabelSelection.PrevChapter)
	if selected_chapter + 1 == Enum.Chapter.size(): prohibited_label_selections.append(LabelSelection.NextChapter)
	previous_chapter_label.visible = not LabelSelection.PrevChapter in prohibited_label_selections
	next_chapter_label.visible = not LabelSelection.NextChapter in prohibited_label_selections

func get_label_from_label_selection(label_selection):
	match label_selection:
		LabelSelection.PrevChapter: return previous_chapter_label
		LabelSelection.GoBack: return go_back_label
		LabelSelection.NextChapter: return next_chapter_label

func setup_selector():
	selector.show()
	selector.position.x = get_x_pos_at_save_file(selected_column)
	selector.position.y = initial_file_info_y_pos
	await make_tween(selector, "position:y", selector_y_destination, selector_setup_tween_duration).finished
	can_move_selector = true

func _unhandled_input(_event):
	var previous_selection = selected_column
	if Input.is_action_just_pressed("move_left"): move_horizontally(-1)
	if Input.is_action_just_pressed("move_right"): move_horizontally(1)
	
	if previous_selection != selected_column: move_selector()
	if Input.is_action_just_pressed("continue"): option_selected()
	if Input.is_action_just_pressed("move_down"): move_down()
	if Input.is_action_just_pressed("move_up"): move_up()

const selector_change_choice_tween_duration := 0.15

func move_down():
	if current_reset_option != ResetOption.None:
		move_selector_inside_reset_options(1)
		return
	if file_info_option != FileInfoOption.NotInsideOption:
		move_selector_inside_save_file_options(1)
		return
	if current_label_selection != LabelSelection.Files: return
	go_down_to_options()

func move_up():
	if current_reset_option != ResetOption.None:
		move_selector_inside_reset_options(-1)
		return
	if file_info_option != FileInfoOption.NotInsideOption:
		move_selector_inside_save_file_options(-1)
		return
	if current_label_selection == LabelSelection.Files: return
	go_up_to_file_info()

func move_horizontally(direction):
	if not can_move_selector: return
	if current_label_selection != LabelSelection.Files:
		return
	var selected_column_copy = selected_column
	selected_column_copy += direction
	if selected_column_copy >= 0 and selected_column + direction < save_file_count:
		selected_column = selected_column_copy

func move_selector():
	play_change_choice_audio()
	can_move_selector = false
	var selector_x_destination = get_x_pos_at_save_file(selected_column)
	await make_tween(selector, "position:x", selector_x_destination, selector_change_choice_tween_duration).finished
	can_move_selector = true

func play_change_choice_audio():
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)

const scene_hide_duration := 2

func option_selected():
	if can_move_inside_file_option and file_info_option != FileInfoOption.NotInsideOption:
		confirm_inside_file_info_option()
	if not can_move_selector: return
	match current_label_selection:
		LabelSelection.Files: save_file_selected()
		LabelSelection.GoBack: go_back_to_title()

func save_file_selected(always_start = false):
	var save_file_number = selected_column + 1
	if SaveData.save_file_exists(save_file_number) and not always_start:
		display_save_info_options_menu()
		return
	can_move_inside_file_option = false
	if always_start:
		var file_info_node = get_file_info_node()
		make_tween(file_info_node.play_game_label, "modulate", Color.WHITE, file_select_tween_duration)
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN)
	start_game(save_file_number)
	if not always_start: make_tween(selector, "position:y", destination_file_info_y_pos, scene_hide_duration)
	var file_info = files_info_root.get_child(selected_column)
	make_tween(file_info, "modulate", Color.LIME_GREEN, scene_hide_duration)
	can_move_selector = false

const selector_options_y = 625
const selector_change_selection_type_tween_duration := 0.4

func start_game(save_file_number):
	var next_scene = UID.SCN_LEAF_SUMMON
	if root.wmt_easter_egg_active: next_scene = UID.SCN_LEGEND
	Overlay.change_scene(next_scene, scene_hide_duration, 1, 2)
	SaveData.load_game(save_file_number)

func go_down_to_options():
	change_vertical_selection(LabelSelection.GoBack, 0, Color.GREEN, get_x_pos_from_label_selection(LabelSelection.GoBack), selector_options_y)

func go_up_to_file_info():
	change_vertical_selection(LabelSelection.Files, 1, Color.WHITE, get_x_pos_at_save_file(selected_column), selector_y_destination)

func change_vertical_selection(label_selection, final_alpha, final_label_color, x_dest, final_y):
	if not can_move_selector: return
	play_change_choice_audio()
	can_move_selector = false
	current_label_selection = label_selection
	make_tween(selector, "modulate:a", final_alpha, selector_change_selection_type_tween_duration)
	make_tween(go_back_label, "modulate", final_label_color, selector_change_selection_type_tween_duration)
	await make_tween(selector, "position", Vector2(x_dest, final_y), selector_change_selection_type_tween_duration).finished
	can_move_selector = true

const file_select_labels_y_destination := -80

func start_file_select_tweens():
	make_tween(options_tree, "position:x", file_select_x_dest, file_select_tween_duration)
	make_tween(logo, "position", file_select_logo_destination, file_select_tween_duration)
	make_tween(logo, "scale", Vector2(file_select_logo_scale, file_select_logo_scale), file_select_tween_duration)
	make_tween(menu_title, "position:x", menu_title_destination_x, file_select_tween_duration)
	await create_file_info()

func set_menu_title_image():
	var texture_path = "res://Textures/Title Screen/File Select/" + Localization.current_language + ".png"
	var texture = load(texture_path)
	menu_title.texture = texture

func make_tween(object, property, final, duration, ease_param := Tween.EASE_IN_OUT, trans := Tween.TRANS_SINE):
	var tween = create_tween().tween_property(object, property, final, duration)
	tween.set_ease(ease_param).set_trans(trans)
	return tween

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

const save_file_count = 3
const save_info_offset_x = 375
const file_info_scale = 2.85
const destination_file_info_y_pos = 325
const initial_file_info_y_pos = 800
const file_info_tween_duration = 0.5

func create_file_info():
	await wait(0.2)
	for i in range(save_file_count):
		var file_info = UID.SCN_FILE_INFO.instantiate()
		files_info_root.add_child(file_info)
		file_info.setup_file_info(i+1)
		file_info.position.x = get_x_pos_at_save_file(i)
		file_info.scale = Vector2(file_info_scale, file_info_scale)
	files_info_root.position.y = initial_file_info_y_pos
	await make_tween(files_info_root, "position:y", destination_file_info_y_pos, file_info_tween_duration).finished
	make_tween(file_select_labels_root, "position:y", file_select_labels_y_destination, file_select_tween_duration)

func get_x_pos_at_save_file(file_num):
	var center_pos_x = get_viewport().get_visible_rect().size.x / 2
	var modified_index = file_num - 1
	return center_pos_x + modified_index * save_info_offset_x

func get_x_pos_from_label_selection(label_selection):
	var used_num = (label_selection as int) - 1
	return get_x_pos_at_save_file(used_num)

func go_back_to_title():
	can_move_selector = false
	Audio.play_sound(UID.SFX_CONFIRM_CHOICE)
	make_tween(file_select_labels_root, "position:y", 0, file_select_tween_duration)
	make_tween(menu_title, "position:x", menu_title_initial_x, file_select_tween_duration)
	make_tween(files_info_root, "position:y", initial_file_info_y_pos, file_select_tween_duration)
	make_tween(logo, "position", root.main_menu_logo_position, file_select_tween_duration)
	make_tween(logo, "scale", Vector2(root.main_menu_logo_scale, root.main_menu_logo_scale), file_select_tween_duration)
	make_tween(options_tree, "position", options_tree.options_tree_destination, file_select_tween_duration)
	make_tween(go_back_label, "modulate", Color.WHITE, file_select_tween_duration)
	await make_tween(background, "modulate", Color.BLACK, file_select_tween_duration).finished
	make_tween(extra_info_labels_root, "position:y", 0, file_select_tween_duration)
	delete_file_info_nodes()
	options_tree.can_change_option = true
	background.texture = UID.IMG_MAIN_MENU_BG
	stars.show()
	current_label_selection = LabelSelection.Files
	selector.hide()
	selector.modulate.a = 1
	selected_column = 0
	make_tween(background, "modulate", Color.WHITE, file_select_tween_duration)

func delete_file_info_nodes():
	for child in files_info_root.get_children():
		child.queue_free()

const selector_x_offset = -115
const selector_save_info_scale = 1.35

enum FileInfoOption {
	NotInsideOption = -2,
	PlayGame = -1,
	ResetGame,
	Cancel
}

var file_info_option := FileInfoOption.NotInsideOption
var can_move_inside_file_option = false
const selected_option_color := Color.WEB_GREEN
const no_leaf_selector_rotation_file_info_options = 360

func display_save_info_options_menu():
	Audio.play_sound(UID.SFX_MENU_CANCEL)
	change_file_info_node_visibility(true)
	file_info_option = FileInfoOption.PlayGame
	can_move_selector = false
	make_tween(selector, "position:x", selector.position.x + selector_x_offset, file_select_tween_duration)
	make_tween(selector, "scale", Vector2(selector_save_info_scale, selector_save_info_scale), file_select_tween_duration)
	var file_info_play_game_label = get_file_info_node().play_game_label
	make_tween(file_info_play_game_label, "modulate", selected_option_color, file_select_tween_duration)
	make_tween(selector, "rotation_degrees", no_leaf_selector_rotation_file_info_options, file_select_tween_duration)
	var selector_y_global_dest = get_file_info_option_y_pos()
	await make_tween(selector, "global_position:y", selector_y_global_dest, file_select_tween_duration).finished
	can_move_inside_file_option = true

func change_file_info_node_visibility(shown):
	var file_info_node = get_file_info_node()
	file_info_node.change_options_visibility(shown)

const y_option_offset = 50

func get_file_info_option_y_pos():
	var result = get_file_info_node().global_position.y
	result += file_info_option * y_option_offset
	return result

func get_file_info_node():
	return files_info_root.get_child(selected_column)

func move_selector_inside_save_file_options(direction):
	if not can_move_inside_file_option: return
	var option_if_successful = file_info_option + direction
	if option_if_successful < FileInfoOption.PlayGame or option_if_successful > FileInfoOption.Cancel: return
	play_change_choice_audio()
	can_move_inside_file_option = false
	var file_info_options = get_file_info_node().options_root
	var previous_selection_label = file_info_options.get_child(file_info_option + 1)
	var current_selection_label = file_info_options.get_child(option_if_successful + 1)
	make_tween(previous_selection_label, "modulate", Color.WHITE, selector_change_choice_tween_duration)
	make_tween(current_selection_label, "modulate", selected_option_color, selector_change_choice_tween_duration)
	file_info_option = option_if_successful
	await make_tween(selector, "global_position:y", get_file_info_option_y_pos(), selector_change_choice_tween_duration).finished
	can_move_inside_file_option = true

func confirm_inside_file_info_option():
	match current_reset_option:
		ResetOption.Cancel: cancel_on_file_info_option()
		ResetOption.ResetAndDelete:
			reset_and_delete_save_file()
			return
	match file_info_option:
		FileInfoOption.PlayGame: save_file_selected(true)
		FileInfoOption.ResetGame: reset_and_delete_game()
		FileInfoOption.Cancel: cancel_on_file_info_option()

const cancel_selector_scale = 2.25
enum ResetOption {
	None,
	Cancel,
	ResetAndDelete
}
var current_reset_option = ResetOption.None
var can_change_reset_option_selection = false

func cancel_on_file_info_option():
	can_move_inside_file_option = false
	file_info_option = FileInfoOption.NotInsideOption
	Audio.play_sound(UID.SFX_MENU_CANCEL)
	change_file_info_node_visibility(false)
	var file_info_node = get_file_info_node()
	file_info_node.cancel_game_label.modulate = Color.WHITE
	current_reset_option = ResetOption.None
	make_tween(file_info_node.main_sprite, "modulate", Color.WHITE, file_select_tween_duration)
	file_info_node.reset_game_label.modulate = Color.WHITE
	file_info_node.reset_option_root.hide()
	if not SaveData.seen_leaf: make_tween(selector, "rotation_degrees", no_leaf_selector_degrees, file_select_tween_duration)
	var selector_x_destination = get_x_pos_at_save_file(selected_column)
	make_tween(selector, "position", Vector2(selector_x_destination, selector_y_destination), file_select_tween_duration)
	await make_tween(selector, "scale", Vector2(cancel_selector_scale, cancel_selector_scale), file_select_tween_duration).finished
	can_move_selector = true

func reset_and_delete_game():
	Audio.play_sound(UID.SFX_MENU_CANCEL)
	var file_info_node = get_file_info_node()
	file_info_node.change_reset_option_visibility(true)
	make_tween(file_info_node.main_sprite, "modulate", Color.RED, file_select_tween_duration)
	make_tween(file_info_node.caution_text_label, "modulate", Color.RED, file_select_tween_duration)
	current_reset_option = ResetOption.Cancel
	await make_tween(selector, "global_position:y", get_y_position_from_reset_option(), selector_change_choice_tween_duration).finished
	can_change_reset_option_selection = true

const reset_option_y_offset = 12
const reset_option_offset_if_reset_and_delete = 50

func get_y_position_from_reset_option():
	var y_glob = get_file_info_node().global_position.y + reset_option_y_offset
	if current_reset_option == ResetOption.ResetAndDelete:
		y_glob += reset_option_offset_if_reset_and_delete
	return y_glob

func move_selector_inside_reset_options(direction):
	if not can_change_reset_option_selection: return
	var option_if_successful = current_reset_option + direction
	if option_if_successful < ResetOption.Cancel or option_if_successful > ResetOption.ResetAndDelete: return
	play_change_choice_audio()
	current_reset_option = option_if_successful
	var y_dest = get_y_position_from_reset_option()
	can_change_reset_option_selection = false
	await make_tween(selector, "position:y", y_dest, selector_change_choice_tween_duration).finished
	can_change_reset_option_selection = true

func reset_and_delete_save_file():
	can_change_reset_option_selection = false
	var selected_save_file = selected_column + 1
	SaveData.delete_file(selected_save_file)
	Audio.play_sound(UID.SFX_FILE_SELECT_DELETE_FILE)
	start_game(selected_save_file)
