extends Control

@onready var header = $Header
@onready var dashes_up = $DashesUp
@onready var dashes_down = $DashesDown
@onready var description_box = $DescriptionBox
@onready var description_text = $DescriptionText
@onready var options_root = $Options
@onready var back_notice = $Back
@onready var selector = $Selector
@onready var description_timer = $"Description Timer"
@onready var controls_text = $ControlsText

const initial_settings_y_position = -135
const initial_description_box_position = Vector2(785, 305)
const initial_description_box_size = Vector2(160, 34)
const final_description_box_size_change = 160
const initial_back_notice_y_pos = 650
const final_back_notice_y_pos = 550
const description_box_size_pos_tween_duration = 0.75
const description_box_alpha_modulation_duration = 0.25
const back_notice_tween_duration = 0.5
const initial_selector_x_position = -100
const show_tween_final_selector_x_position = 60
const selector_show_tween_duration = 0.2

var settings_tree: Array[Setting] = [
	Setting.category("audio", [
		Setting.slider("master_volume"),
		Setting.slider("sfx_volume"),
		Setting.slider("music_volume")
	]),
	Setting.category("text", [
		Setting.option("lang", ["choose_lang_czech", "choose_lang_english"], Setting.CustomBehaviour.TextSpeed),
		Setting.option("text_speed", ["settings_choice_slow", "settings_choice_regular", "settings_choice_speedrun"]),
	]),
	Setting.custom_button("credits", Setting.CustomBehaviour.Credits),
	Setting.value_slider("brightness", -25, 25)
]

func _ready():
	description_timer.timeout.connect(show_next_decription_char)
	current_category_settings_count = settings_tree.size()
	var header_settings_cog_icon_bb_code = "[img=15]res://Textures/Title Screen/Icons/Settings.png[/img]"
	header.text = header_settings_cog_icon_bb_code + Localization.get_text("mainmenu_option_settings") + header_settings_cog_icon_bb_code
	controls_text.text = Localization.get_text("settings_controls")
	back_notice.text = Localization.get_text("settings_back_notice")
	header.position.y = initial_settings_y_position
	description_box.position = initial_description_box_position
	description_box.size = initial_description_box_size
	selector.position = Vector2(initial_selector_x_position, get_selector_y_position(selector_releative_setting_index))
	description_text.modulate.a = 0
	controls_text.modulate.a = 0
	
	Helper.tween(header, "position:y", 0, 0.5)
	dashes_up.visible_ratio = 0
	dashes_down.visible_ratio = 0
	description_box.modulate.a = 0
	back_notice.position.y = initial_back_notice_y_pos
	
	await Helper.wait(0.5)
	display_settings()
	Helper.tween(dashes_up, "visible_ratio", 1)
	Helper.tween(dashes_down, "visible_ratio", 1)
	
	Helper.tween(description_box, "modulate:a", 1, description_box_alpha_modulation_duration)
	Helper.tween(description_box, "size:y", initial_description_box_size.y + final_description_box_size_change, description_box_size_pos_tween_duration)
	Helper.tween(description_box, "position:y", initial_description_box_position.y - final_description_box_size_change, description_box_size_pos_tween_duration)
	Helper.tween(back_notice, "position:y", final_back_notice_y_pos, back_notice_tween_duration)
	update_description()
	await Helper.wait(description_box_size_pos_tween_duration/2)
	Helper.tween_multiple([description_text, controls_text], "modulate:a", 1, description_box_size_pos_tween_duration)

const selector_y_pos_offset = 150

func get_selector_y_position(selection_index):
	return selector_y_pos_offset + selector_y_offset * selection_index

const wait_between_settings := 0.25
const initial_setting_pos_x := -1000
const setting_y_offset = 105
const selector_y_offset = 80
const setting_tween_duration := 0.5
const amount_of_settings_at_once = 5
var input_discarded = true
var current_settings_as_nodes := []

func display_settings():
	for i in range(settings_tree.size()):
		var current_setting: Setting = settings_tree[i]
		match current_setting.setting_type:
			Setting.SettingType.TypeSlider: display_settings_slider(i, current_setting)
			Setting.SettingType.TypeOption: display_settings_option(i, current_setting)
			Setting.SettingType.TypeButton: display_settings_button(i, current_setting)
		if i+1 <= amount_of_settings_at_once: await Helper.wait(wait_between_settings)
	Helper.tween(selector, "position:x", show_tween_final_selector_x_position, selector_show_tween_duration)
	input_discarded = false

func display_settings_slider(index, setting_resource: Setting):
	var setting_slider = display_setting_helper(Setting.SettingType.TypeSlider, index)
	setting_slider.title.text = Localization.get_text(setting_resource.title_localization_key)

func display_settings_option(index, setting_resource: Setting):
	var setting_option = display_setting_helper(Setting.SettingType.TypeOption, index)

func display_settings_button(index, setting_resource: Setting):
	var setting_button = display_setting_helper(Setting.SettingType.TypeButton, index)
	var title_text = Localization.get_text(setting_resource.title_localization_key)
	if setting_resource.type_of_custom_behaviour == Setting.CustomBehaviour.None:
		title_text = "-- " + title_text + " --"
	setting_button.title.text = title_text

func display_setting_helper(type: Setting.SettingType, index: int):
	var scene_to_be_instantiated
	match type:
		Setting.SettingType.TypeSlider: scene_to_be_instantiated = UID.SCN_SETTINGS_SLIDER
		Setting.SettingType.TypeOption: scene_to_be_instantiated = UID.SCN_SETTINGS_CHOICE
		Setting.SettingType.TypeButton: scene_to_be_instantiated = UID.SCN_SETTINGS_BUTTON
	var instance = scene_to_be_instantiated.instantiate()
	instance.position = Vector2(initial_setting_pos_x, setting_y_offset * index)
	options_root.add_child(instance)
	current_settings_as_nodes.append(instance)
	if index+1 <= amount_of_settings_at_once: Helper.tween(instance, "position:x", 0, setting_tween_duration)
	else:
		instance.position.x = 0
		update_setting_hide_progress(instance, 0)
	return instance

var selector_releative_setting_index = 0
var selector_actual_setting_index = 0
var current_category_settings_count = 0

func _unhandled_input(_event):
	if input_discarded: return
	var vertical_direction = 0
	if Input.is_action_just_pressed("move_down"): vertical_direction += 1
	if Input.is_action_just_pressed("move_up"): vertical_direction -= 1
	if vertical_direction != 0:
		move_selector_vertically(vertical_direction)
		return

const settings_selector_tween_duration = 0.15

func move_selector_vertically(dir):
	var actual_index_if_valid = selector_actual_setting_index + dir
	if actual_index_if_valid < 0 or actual_index_if_valid >= current_category_settings_count: return
	var relative_index_if_valid = selector_releative_setting_index + dir
	Audio.play_sound_shifted(UID.SFX_MENU_CHANGED_CHOICE)
	selector_actual_setting_index = actual_index_if_valid
	update_description()
	
	if dir == 1 and relative_index_if_valid >= amount_of_settings_at_once:
		move_settings_options(dir)
		return
	if dir == -1 and relative_index_if_valid < 0:
		move_settings_options(dir)
		return
	
	input_discarded = true
	selector_releative_setting_index += dir
	var new_y_pos = get_selector_y_position(selector_releative_setting_index)
	await Helper.tween(selector, "position:y", new_y_pos, settings_selector_tween_duration)
	input_discarded = false

func move_settings_options(dir):
	var hidden_option_index = selector_actual_setting_index - amount_of_settings_at_once if dir == 1 else selector_actual_setting_index + amount_of_settings_at_once
	var shown_option_index = selector_actual_setting_index if dir == 1 else selector_actual_setting_index
	
	var to_be_hidden_setting_option = current_settings_as_nodes[hidden_option_index]
	var to_be_shown_setting_option = current_settings_as_nodes[shown_option_index]
	
	update_setting_hide_from_bottom_uniform(to_be_shown_setting_option, dir == 1)
	update_setting_hide_from_bottom_uniform(to_be_hidden_setting_option, dir == -1)
	
	Helper.tween_method(func(value): update_setting_hide_progress(to_be_shown_setting_option, value),
		0.0, 1.0, settings_selector_tween_duration)
	Helper.tween_method(func(value): update_setting_hide_progress(to_be_hidden_setting_option, value),
		1.0, 0.0, settings_selector_tween_duration)
	
	shift_position_of_options(dir)

func update_setting_hide_progress(setting_instance, value: float):
	setting_instance.hide_progression = value
	Helper.hide_progress_multiple(setting_instance.shader_nodes, value)

func update_setting_hide_from_bottom_uniform(setting_instance, value: bool):
	setting_instance.hide_from_bottom = value
	Helper.set_uniform_multiple(setting_instance.shader_nodes, "hide_from_bottom", value)

func shift_position_of_options(dir):
	input_discarded = true
	var final_y_pos = options_root.position.y + setting_y_offset * options_root.scale.y * -dir
	await Helper.tween(options_root, "position:y", final_y_pos, settings_selector_tween_duration)
	input_discarded = false

func update_description():
	var current_setting_resource = settings_tree[selector_actual_setting_index]
	description_text.text = Localization.get_text(current_setting_resource.description_localization_key)
	var is_text_speed = current_setting_resource.type_of_custom_behaviour == Setting.CustomBehaviour.TextSpeed
	description_text.visible_characters = 0 if is_text_speed else -1
	if not is_text_speed: return
	description_timer.start(PresetSystem.default_text_speed)

func show_next_decription_char():
	description_text.visible_characters += 1
	if description_text.visible_characters == description_text.text.length():
		description_timer.stop()
		return
