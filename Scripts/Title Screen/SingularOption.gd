extends Node2D
 
@onready var label = $Label
@onready var icon = $Icon
@onready var options_tree = get_parent()

func _ready() -> void:
	await options_tree.moving_option_tree
	var lowered_name = name.to_lower()
	var text_key = "mainmenu_option_" + lowered_name
	var translated_text = Localization.get_text(text_key)
	label.text = translated_text
	
	var texture_path = "res://Textures/Title Screen/Icons/" + name + ".png"
	var texture = load(texture_path)
	icon.texture = texture
