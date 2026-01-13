extends Control

var hide_progression: float = 1.0
var hide_from_bottom: bool

@onready var textbox = $Textbox
@onready var title = $Title

@onready var shader_nodes = [textbox, title]

func _ready():
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
