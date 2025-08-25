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

func show_file_select():
	go_back_label.text = Localization.get_text("mainmenu_choosefile_goback")
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
	if not can_move_selector: return
	var previous_selection = selected_column
	if Input.is_action_just_pressed("move_left"): move_horizontally(-1)
	if Input.is_action_just_pressed("move_right"): move_horizontally(1)
	
	if previous_selection != selected_column:
		move_selector()
		return
	if Input.is_action_just_pressed("continue"): option_selected()
	if Input.is_action_just_pressed("move_down") and current_label_selection == LabelSelection.Files: go_down_to_options()
	if Input.is_action_just_pressed("move_up") and current_label_selection != LabelSelection.Files: go_up_to_file_info()

const selector_change_choice_tween_duration := 0.15

func move_horizontally(direction):
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
	match current_label_selection:
		LabelSelection.Files: save_file_selected()
		LabelSelection.GoBack: go_back_to_title()

func save_file_selected():
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN)
	Overlay.change_scene(UID.SCN_LEGEND, scene_hide_duration, 1, 2)
	SaveData.load_game(selected_column + 1)
	make_tween(selector, "position:y", destination_file_info_y_pos, scene_hide_duration)
	var file_info = files_info_root.get_child(selected_column)
	make_tween(file_info, "modulate", Color.LIME_GREEN, scene_hide_duration)
	can_move_selector = false

const selector_options_y = 625
const selector_change_selection_type_tween_duration := 0.4

func go_down_to_options():
	change_vertical_selection(LabelSelection.GoBack, 0, Color.GREEN, get_x_pos_from_label_selection(LabelSelection.GoBack), selector_options_y)

func go_up_to_file_info():
	change_vertical_selection(LabelSelection.Files, 1, Color.WHITE, get_x_pos_at_save_file(selected_column), selector_y_destination)

func change_vertical_selection(label_selection, final_alpha, final_label_color, x_dest, final_y):
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
