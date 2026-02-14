extends Control

var hide_progression: float = 1.0
var hide_from_bottom: bool
var setting_resource: Setting
var settings_node: Control
var current_option_index: int

@onready var textbox = $Textbox
@onready var title = $Title
@onready var option = $Option
@onready var arrow_left = $ArrowLeft
@onready var arrow_right = $ArrowRight

@onready var shader_nodes = [textbox, title, option, arrow_left, arrow_right]

func _ready():
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
	title.text = Localization.get_text(setting_resource.title_localization_key)
	if setting_resource.option_type == Setting.OptionType.Language: setting_resource.options = Localization.language_list
	update_choice_index()

func update_choice_index():
	match setting_resource.option_type:
		Setting.OptionType.Language: current_option_index = Localization.language_list.find(Localization.current_language)
		_: current_option_index = SaveData.get(field_map[setting_resource.option_type])
	change_value()

const field_map : Dictionary[Setting.OptionType, String] = {
	Setting.OptionType.TextSpeed: "setting_text_speed",
	Setting.OptionType.SkippingAllowed: "setting_text_skipping_allowed"
}

func change_value(direction := 0):
	var previous_option = current_option_index
	current_option_index = clamp(current_option_index + direction, 0, setting_resource.options.size()-1)
	if previous_option == current_option_index and direction != 0: return
	if direction != 0: Audio.play_sound_shifted(UID.SFX_MENU_CHANGED_CHOICE)
	
	match setting_resource.option_type:
		Setting.OptionType.Language: Localization.load_language(Localization.language_list[current_option_index])
		_: SaveData.set(field_map[setting_resource.option_type], current_option_index)
	
	var used_key = setting_resource.options_localization_key
	if setting_resource.option_type == Setting.OptionType.Language: used_key = "choose_lang_" + Localization.current_language
	option.text = Localization.get_text(used_key, {"option": current_option_index})
	arrow_left.visible = current_option_index > 0
	arrow_right.visible = current_option_index < setting_resource.options.size()-1
	SaveData.save_global_file()
