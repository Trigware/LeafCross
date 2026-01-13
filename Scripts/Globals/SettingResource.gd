extends Resource
class_name Setting

enum SettingType {
	Unknown = -1,
	TypeSlider,
	TypeOption,
	TypeButton
}

enum CustomBehaviour {
	None,
	Credits,
	TextSpeed
}

@export var save_data_key: String
@export var setting_type := SettingType.Unknown
@export var title_localization_key: String
@export var description_localization_key: String
@export var available_options_as_keys: Array[String]
@export var display_percentage: bool
@export var minimum_value: int
@export var maximum_value: int
@export var category_subsettings: Array[Setting]
@export var type_of_custom_behaviour: CustomBehaviour

static func ctor(data_key: String, type: SettingType, title_key: String, options: Array[String] = [],
				 show_percentage := false, min_value := 0, max_value := 0, subsetings: Array[Setting] = [], custom_behaviour := CustomBehaviour.None) -> Setting:
	var result = Setting.new()
	result.save_data_key = data_key
	result.setting_type = type
	result.title_localization_key = title_key
	result.available_options_as_keys = options
	result.display_percentage = show_percentage
	result.minimum_value = min_value
	result.maximum_value = max_value
	result.category_subsettings = subsetings
	result.type_of_custom_behaviour = custom_behaviour
	result.description_localization_key = title_key + "_description"
	return result

static func slider(data_key: String) -> Setting:
	return Setting.ctor(data_key, SettingType.TypeSlider, "settings_slider_" + data_key, [], true, 0, 100)

static func value_slider(data_key: String, min_value: int, max_value: int) -> Setting:
	return Setting.ctor(data_key, SettingType.TypeSlider, "settings_slider_" + data_key, [], false, min_value, max_value)

static func option(data_key: String, options_as_keys: Array[String], custom_behaviour := CustomBehaviour.None) -> Setting:
	return Setting.ctor(data_key, SettingType.TypeOption, "settings_option_" + data_key, options_as_keys, false, 0, 0, [], custom_behaviour)

static func category(button_identifier: String, subsettings: Array[Setting]) -> Setting:
	return Setting.ctor("", SettingType.TypeButton, "settings_button_" + button_identifier, [], false, 0, 0, subsettings)

static func custom_button(button_identifier: String, behaviour: CustomBehaviour) -> Setting:
	return Setting.ctor("", SettingType.TypeButton, "settings_custom_button_" + button_identifier, [], false, 0, 0, [], behaviour)
