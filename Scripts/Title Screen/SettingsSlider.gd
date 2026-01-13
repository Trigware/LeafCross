extends Control

var hide_progression: float = 0.0
var hide_from_bottom: bool

@onready var textbox = $Textbox
@onready var title = $Title
@onready var progress = $Progress
@onready var procentage = $Procentage

@onready var shader_nodes = [textbox, title, progress, procentage]

func _ready():
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
