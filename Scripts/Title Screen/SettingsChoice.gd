extends Control

var hide_progression: float = 1.0
var hide_from_bottom: bool

@onready var textbox = $Textbox
@onready var title = $Title
@onready var option = $Option
@onready var arrow_left = $ArrowLeft
@onready var arrow_right = $ArrowRight

@onready var shader_nodes = [textbox, title, option, arrow_left, arrow_right]

func _ready():
	Helper.assign_shader_multiple(shader_nodes, UID.SHD_SETTING_HIDE)
