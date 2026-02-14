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
	Setting.category(Setting.OptionType.AudioCategory, [
		Setting.slider(Setting.OptionType.MasterVolume),
		Setting.slider(Setting.OptionType.SoundEffects),
		Setting.slider(Setting.OptionType.MusicVolume)
	]),
	Setting.category(Setting.OptionType.TextCategory, [
		Setting.option(Setting.OptionType.Language),
		Setting.option(Setting.OptionType.TextSpeed, Enum.TextSpeedType),
		Setting.boolean(Setting.OptionType.SkippingAllowed)
	]),
	Setting.slider(Setting.OptionType.Brightness),
	Setting.button(Setting.OptionType.Keybinds),
	Setting.button(Setting.OptionType.Credits)
]

var used_settings: Array[Setting] = settings_tree

var category_trace: Array[int] = []

func _ready():
	description_timer.timeout.connect(show_next_decription_char)
	var header_settings_cog_icon_bb_code = "[img=15]res://Textures/Title Screen/Icons/Settings.png[/img]"
	Localization.link_label_to_key(header, "mainmenu_option_settings", {}, header_settings_cog_icon_bb_code, header_settings_cog_icon_bb_code)
	Localization.link_label_to_key(controls_text, "settings_controls")
	Localization.link_label_to_key(back_notice, "settings_back_notice")
	header.position.y = initial_settings_y_position
	description_box.position = initial_description_box_position
	description_box.size = initial_description_box_size
	selector.position = Vector2(initial_selector_x_position, get_selector_y_position(selector_releative_setting_index))
	description_text.modulate.a = 0
	controls_text.modulate.a = 0
	category_trace = []
	
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
var able_to_play_value_change_sound_effect = true
var current_settings_as_nodes := []

func display_settings(display_at_once = false):
	for i in range(used_settings.size()):
		var current_setting: Setting = used_settings[i]
		display_setting_helper(current_setting, i)
		if i+1 <= amount_of_settings_at_once and not display_at_once: await Helper.wait(wait_between_settings)
	Helper.tween(selector, "position:x", show_tween_final_selector_x_position, selector_show_tween_duration)
	if not display_at_once: input_discarded = false

func display_setting_helper(setting_resource: Setting, index: int):
	var scene_to_be_instantiated
	match setting_resource.setting_type:
		Setting.SettingType.TypeSlider: scene_to_be_instantiated = UID.SCN_SETTINGS_SLIDER
		Setting.SettingType.TypeOption: scene_to_be_instantiated = UID.SCN_SETTINGS_CHOICE
		Setting.SettingType.TypeButton: scene_to_be_instantiated = UID.SCN_SETTINGS_BUTTON
	var instance = scene_to_be_instantiated.instantiate()
	instance.setting_resource = setting_resource
	instance.settings_node = self
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

func _unhandled_input(_event):
	if input_discarded: return
	var vertical_direction = 0
	var horizontal_direction = 0
	if Input.is_action_just_pressed("move_down"): vertical_direction += 1
	if Input.is_action_just_pressed("move_up"): vertical_direction -= 1
	if Input.is_action_pressed("move_left"): horizontal_direction -= 1
	if Input.is_action_pressed("move_right"): horizontal_direction += 1
	if vertical_direction != 0:
		move_selector_vertically(vertical_direction)
		return
	if horizontal_direction != 0:
		handling_value_changing_action(horizontal_direction)
		return
	if Input.is_action_just_pressed("continue"):
		open_category()
		return
	if Input.is_action_just_pressed("go_back"):
		exit_current_category()
		return

const settings_selector_tween_duration = 0.15

func handling_value_changing_action(direction: int):
	var current_settings_node = current_settings_as_nodes[selector_actual_setting_index]
	var current_setting_resource = used_settings[selector_actual_setting_index]
	if current_setting_resource.setting_type == Setting.SettingType.TypeButton: return
	current_settings_node.change_value(direction)
	if current_setting_resource.option_type == Setting.OptionType.TextSpeed: update_description()

func move_selector_vertically(dir):
	var actual_index_if_valid = selector_actual_setting_index + dir
	if actual_index_if_valid < 0 or actual_index_if_valid >= used_settings.size(): return
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
	var current_setting_resource = used_settings[selector_actual_setting_index]
	Localization.link_label_to_key(description_text, current_setting_resource.description_localization_key)
	description_timer.stop()
	var is_text_speed = current_setting_resource.option_type == Setting.OptionType.TextSpeed
	description_text.visible_characters = 0 if is_text_speed else -1
	if not is_text_speed: return
	var text_speed = PresetSystem.default_text_speed * TextSystem.speed_multiplier_options[SaveData.setting_text_speed]
	description_timer.start(text_speed)

func show_next_decription_char():
	description_text.visible_characters += 1
	if description_text.visible_characters == description_text.text.length():
		description_timer.stop()
		return

func open_category():
	var selected_setting = used_settings[selector_actual_setting_index]
	if selected_setting.setting_type != Setting.SettingType.TypeButton: return
	input_discarded = true
	Audio.play_sound_shifted(UID.SFX_MAIN_MENU_CHOICE_CHANGE)
	go_to_inner_category()
	update_description()
	end_category_handling()

func end_category_handling():
	await remove_current_options()
	await Helper.wait(pause_between_removed_and_shown_options)
	await display_settings(true)
	await Helper.wait(pause_between_removed_and_shown_options)
	Helper.tween(selector, "modulate:a", 1, selector_modulate_tween_duration)
	selector.position.y = get_selector_y_position(selector_releative_setting_index)
	input_discarded = false

func go_to_inner_category():
	category_trace.append(selector_actual_setting_index)
	used_settings = used_settings[selector_actual_setting_index].category_subsettings
	selector_actual_setting_index = 0
	selector_releative_setting_index = 0

const setting_remove_duration = 0.45
const pause_between_removed_and_shown_options := 0.3
const selector_modulate_tween_duration := 0.2

func remove_current_options():
	for setting_node in current_settings_as_nodes:
		Helper.tween(setting_node, "position:x", initial_setting_pos_x, setting_remove_duration)
		Helper.tween(setting_node, "modulate:a", 0, setting_remove_duration)
	Helper.tween(selector, "modulate:a", 0, selector_modulate_tween_duration)
	await Helper.wait(setting_remove_duration)
	for setting_node in current_settings_as_nodes:
		setting_node.queue_free()
	current_settings_as_nodes = []

func exit_current_category():
	if category_trace.size() == 0: return
	Audio.play_sound_shifted(UID.SFX_EXIT_CATEGORY)
	input_discarded = true
	used_settings = settings_tree
	selector_actual_setting_index = 0
	selector_releative_setting_index = 0
	category_trace.pop_back()
	
	for category_index in category_trace:
		var subsetting = used_settings[category_index]
		used_settings = used_settings[category_index].category_subsettings
	
	update_description()
	await end_category_handling()
	selector.position.y = get_selector_y_position(selector_releative_setting_index)
