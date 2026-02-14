extends Control

var hide_progression: float = 0.0
var hide_from_bottom: bool
var setting_resource: Setting
var settings_node: Control

@onready var textbox = $Textbox
@onready var title = $Title
@onready var progress = $Progress
@onready var procentage = $Procentage

@onready var shader_nodes = [textbox, title, progress, procentage]

func _ready():
	title.text = Localization.get_text(setting_resource.title_localization_key)
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
	change_value()

const field_map : Dictionary[Setting.OptionType, String] = {
	Setting.OptionType.Brightness: "setting_brightness",
	Setting.OptionType.MasterVolume: "setting_master_volume",
	Setting.OptionType.SoundEffects: "setting_sound_effects",
	Setting.OptionType.MusicVolume: "setting_music_volume"
}

const wait_between_sound_effect = 0.15

func change_value(direction := 0):
	var used_field_name = field_map[setting_resource.option_type]
	var field_value = SaveData.get(used_field_name)
	var modified_value = clamp(field_value + direction, 0, 100)
	if field_value == modified_value and direction != 0: return
	SaveData.set(used_field_name, modified_value)
	procentage.text = str(modified_value) + "%"
	progress.value = modified_value
	SaveData.save_global_file()
	if not settings_node.able_to_play_value_change_sound_effect or direction == 0: return
	Audio.play_sound_shifted(UID.SFX_CHANGE_SLIDER_VALUE, -2)
	settings_node.able_to_play_value_change_sound_effect = false
	await Helper.wait(wait_between_sound_effect)
	settings_node.able_to_play_value_change_sound_effect = true
