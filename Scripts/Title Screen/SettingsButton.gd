extends Control

var hide_progression: float = 1.0
var hide_from_bottom: bool
var setting_resource: Setting
var settings_node: Control

@onready var textbox = $Textbox
@onready var title = $Title

@onready var shader_nodes = [textbox, title]

func _ready():
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
	var localization_contents = Localization.get_text(setting_resource.title_localization_key)
	var title_text = localization_contents
	if not setting_resource.is_category: title_text = "-- " + localization_contents + " --"
	title.text = title_text
