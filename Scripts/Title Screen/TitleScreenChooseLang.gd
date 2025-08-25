extends Node2D

@onready var prompt = $Text/Prompt
@onready var controls = $Text/Controls
@onready var text_root = $Text
@onready var options_root = $"Options Root"
@onready var selector = $Selector

const initial_x_position = -1500

signal language_selected

func _ready():
	selector.texture = UID.IMG_NOLEAF_SELECTOR
	if SaveData.seen_leaf: selector.texture = UID.IMG_LEAF

const choose_lang_ui_show_duration = 1

func show_choose_lang_ui():
	load_language()
	set_text_to_labels()
	var move_tween = create_tween().tween_property(self, "position:x", 0, choose_lang_ui_show_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	create_language_options()
	await move_tween.finished
	able_to_change_selected_language = true

var selected_language = 0
var previous_language = 0
var able_to_change_selected_language = false
const selector_move_duration := 0.15

func load_language():
	var user_language = OS.get_locale_language()
	var language_as_str = "english"
	match user_language:
		"cs": language_as_str = "czech"
	selected_language = Localization.language_list.find(language_as_str)
	selector.position.y = get_selector_y_position()
	var new_lang = Localization.language_list[selected_language]
	Localization.load_language(new_lang)

func _unhandled_input(_event):
	if not able_to_change_selected_language: return
	previous_language = selected_language
	if Input.is_action_just_pressed("move_up"):
		if selected_language > 0: selected_language -= 1
	if Input.is_action_just_pressed("move_down"):
		if selected_language + 1 < Localization.language_list.size(): selected_language += 1
	if previous_language != selected_language:
		move_selector()
		return
	if Input.is_action_just_pressed("continue"):
		on_language_selected()

const selection_color = Color.SKY_BLUE

func move_selector():
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)
	able_to_change_selected_language = false
	var selector_y_destination = get_selector_y_position()
	var move_tween = create_tween().tween_property(selector, "position:y", selector_y_destination, selector_move_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	var select_label = language_labels[selected_language]
	var unselect_label = language_labels[previous_language]
	create_tween().tween_property(select_label, "modulate", selection_color, selector_move_duration)
	create_tween().tween_property(unselect_label, "modulate", Color.WHITE, selector_move_duration)
	
	var selected_lang_as_str = Localization.language_list[selected_language]
	Localization.load_language(selected_lang_as_str)
	set_text_to_labels()
	
	await move_tween.finished
	able_to_change_selected_language = true

const language_root_y_hide_destination = 300
const language_root_hide_duration = 1

func get_selector_y_position():
	return initial_y_flag_position + flag_y_space * selected_language

func on_language_selected():
	able_to_change_selected_language = false
	Audio.play_sound(UID.SFX_CONFIRM_CHOICE)
	var move_tween = create_tween().tween_property(self, "position:y", language_root_y_hide_destination, language_root_hide_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	SaveData.language_chosen = true
	SaveData.save_global_file()
	emit_signal("language_selected")

var language_labels := []
const flag_x_position = 435
const initial_y_flag_position := 425
const initial_y_label_position := 380
const flag_y_space := 75
var language_index = 0

func set_text_to_labels():
	prompt.text = Localization.get_text("choose_lang_language")
	controls.text = Localization.get_text("choose_lang_controls")

func create_language_options():
	language_labels = []
	language_index = 0
	for language in Localization.language_list:
		create_flag(language)
		create_label(language)
		language_index += 1
	language_labels[selected_language].modulate = selection_color

func create_flag(language):
	var flag_node = Sprite2D.new()
	flag_node.texture = load("res://Textures/Flags/" + language + ".png")
	flag_node.scale = 2 * Vector2.ONE
	flag_node.position.x = flag_x_position
	flag_node.position.y = initial_y_flag_position + flag_y_space * language_index
	options_root.add_child(flag_node)

func create_label(language):
	var label_node = UID.SCN_LANGUAGE_LABEL.instantiate()
	label_node.text = Localization.get_text("choose_lang_" + language)
	label_node.position.y = initial_y_label_position + flag_y_space * language_index
	language_labels.append(label_node)
	options_root.add_child(label_node)
