extends Resource
class_name Setting

enum SettingType {
	Unknown = -1,
	TypeSlider,
	TypeOption,
	TypeButton
}

enum OptionType {
	Unknown,
	AudioCategory,
	MasterVolume,
	SoundEffects,
	MusicVolume,
	TextCategory,
	Language,
	TextSpeed,
	SkippingAllowed,
	Brightness,
	Credits,
	Keybinds
}

var option_type: OptionType
var setting_type := SettingType.Unknown
var title_localization_key: String
var description_localization_key: String
var options_localization_key: String
var options: Array
var category_subsettings: Array[Setting]
var is_category := false
var is_boolean := false

static func ctor(option_type: OptionType, setting_type: SettingType, options_enum: Dictionary = {}, subsettings: Array[Setting] = []) -> Setting:
	var result = Setting.new()
	result.option_type = option_type
	var data_key = OptionType.find_key(option_type).to_snake_case()
	var title_key = "settings_" + data_key
	result.setting_type = setting_type
	result.title_localization_key = title_key
	result.options = options_enum.keys()
	result.category_subsettings = subsettings
	result.description_localization_key = title_key + "_description"
	result.options_localization_key = title_key + "_options"
	return result

static func slider(option_type: OptionType) -> Setting:
	return ctor(option_type, SettingType.TypeSlider)

static func option(option_type: OptionType, options_enum: Dictionary = {}) -> Setting:
	return ctor(option_type, SettingType.TypeOption, options_enum)

static func category(option_type: OptionType, subsettings: Array[Setting]) -> Setting:
	return ctor(option_type, SettingType.TypeButton, {}, subsettings)

static func button(option_type: OptionType) -> Setting:
	var setting = ctor(option_type, SettingType.TypeButton)
	setting.is_category = true
	return setting

static func boolean(option_type: OptionType) -> Setting:
	var setting = option(option_type, {"on": 0, "off": 1})
	setting.is_boolean = true
	return setting
